package XARF::SchemaValidator;

use v5.40;
use Moo;
use File::Basename qw(dirname);
use File::ShareDir qw(dist_dir);
use File::Spec;
use JSON::MaybeXS qw(decode_json);
use JSON::Schema::Modern;
use Storable qw(dclone);

use XARF::SchemaError;
use XARF::SchemaRegistry;
use XARF::ValidationError;

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# Singleton
# ---------------------------------------------------------------------------

my $_instance;

sub instance {
    my ($class) = @_;
    $_instance //= $class->new;
    return $_instance;
}

sub _reset_instance {
    $_instance = undef;
    return;
}

# ---------------------------------------------------------------------------
# Internal attributes (lazy-loaded)
# ---------------------------------------------------------------------------

has _schemas_dir => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__schemas_dir',
);

has _jsm => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__jsm',
);

has _strict_jsm => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__strict_jsm',
);

# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------

sub _build__schemas_dir {
    my ($self) = @_;

    my $share = eval { dist_dir('XARF') };
    if ( $share && -d "$share/schemas" ) {
        return "$share/schemas";
    }

    my $mod_dir = dirname( File::Spec->rel2abs(__FILE__) );
    my $dev_dir
        = File::Spec->canonpath( File::Spec->catdir( $mod_dir, '..', '..', 'share', 'schemas' ) );
    return $dev_dir if -d $dev_dir;

    die XARF::SchemaError->new(
        message => 'Cannot find XARF schemas directory. Run `make` or install the distribution.' );
}

sub _build__jsm {
    my ($self) = @_;
    return $self->_build_jsm_instance(0);
}

sub _build__strict_jsm {
    my ($self) = @_;
    return $self->_build_jsm_instance(1);
}

sub _build_jsm_instance {
    my ( $self, $strict ) = @_;

    my $jsm = JSON::Schema::Modern->new( validate_formats => 1 );
    my $dir = $self->_schemas_dir;

    # Load core schema first
    my $core_path = File::Spec->catfile( $dir, 'xarf-core.json' );
    my $core      = _load_json($core_path)
        or die XARF::SchemaError->new( message => "Cannot load core schema: $core_path" );
    $core = _promote_recommended( dclone($core) ) if $strict;
    $jsm->add_schema($core);

    # Pre-load all type schemas so $refs resolve without network access
    my $types_dir = File::Spec->catdir( $dir, 'types' );
    if ( -d $types_dir ) {
        opendir my $dh, $types_dir
            or die XARF::SchemaError->new( message => "Cannot open types dir: $types_dir" );
        my @files = sort grep {/\.json$/i} readdir $dh;
        closedir $dh;

        for my $file (@files) {
            my $path   = File::Spec->catfile( $types_dir, $file );
            my $schema = _load_json($path) or next;
            $schema = _promote_recommended( dclone($schema) ) if $strict;
            $jsm->add_schema($schema);
        }
    }

    # Load master schema last — all its $refs are already registered above
    my $master_path = File::Spec->catfile( $dir, 'xarf-v4-master.json' );
    my $master      = _load_json($master_path)
        or die XARF::SchemaError->new( message => "Cannot load master schema: $master_path" );
    $master = _promote_recommended( dclone($master) ) if $strict;
    $jsm->add_schema($master);

    return $jsm;
}

# ---------------------------------------------------------------------------
# Strict-mode schema transformation
# ---------------------------------------------------------------------------

# Recursively promotes properties with x-recommended: true into the
# required array.  Mutates $node in place and returns it.
sub _promote_recommended {
    my ($node) = @_;
    return $node unless ref($node) eq 'HASH';

    if ( ref( $node->{properties} ) eq 'HASH' ) {
        my %req = map { $_ => 1 } @{ $node->{required} // [] };
        for my $name ( keys %{ $node->{properties} } ) {
            my $prop = $node->{properties}{$name};
            if ( ref($prop) eq 'HASH' && $prop->{'x-recommended'} ) {
                $req{$name} = 1;
            }
            _promote_recommended($prop);
        }
        $node->{required} = [ sort keys %req ] if %req;
    }

    # Recurse into combiners and conditional keywords
    for my $key (qw(allOf anyOf oneOf if then else not items additionalProperties)) {
        my $val = $node->{$key};
        next unless defined $val;
        if ( ref($val) eq 'ARRAY' ) {
            _promote_recommended($_) for @$val;
        } elsif ( ref($val) eq 'HASH' ) {
            _promote_recommended($val);
        }
    }

    # Recurse into $defs
    if ( ref( $node->{'$defs'} ) eq 'HASH' ) {
        _promote_recommended($_) for values %{ $node->{'$defs'} };
    }

    return $node;
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

=head2 validate( $report_hashref, strict => 0 )

Validates C<$report_hashref> against the XARF v4 master schema.  Returns an
arrayref of L<XARF::ValidationError> objects, or an empty arrayref on success.

When C<strict> is true, C<x-recommended> fields are promoted to required
before validation.

=cut

sub validate {
    my ( $self, $report, %opts ) = @_;
    my $strict = $opts{strict} // 0;

    my $jsm        = $strict ? $self->_strict_jsm : $self->_jsm;
    my $master_uri = 'https://xarf.org/schemas/v4/xarf-v4-master.json';

    my $result = $jsm->evaluate( $report, $master_uri );
    return [] if $result->valid;

    my @errors = map { _format_validation_error($_) } $result->errors;

    # Deduplicate on (field, message) pair — same strategy as JS reference
    my %seen;
    my @unique = grep { !$seen{ $_->field . "\0" . $_->message }++ } @errors;

    return \@unique;
}

=head2 get_supported_types

Returns an arrayref of C<"category/type"> strings for every type that has a
schema registered in L<XARF::SchemaRegistry>.

=cut

sub get_supported_types {
    my ($self) = @_;
    my $reg = XARF::SchemaRegistry->instance;
    my @types;
    for my $cat ( @{ $reg->get_categories } ) {
        for my $type ( @{ $reg->get_types_for_category($cat) } ) {
            push @types, "$cat/$type";
        }
    }
    return \@types;
}

=head2 has_type_schema( $category, $type )

Returns C<1> if a schema exists for the given C<$category>/C<$type>
combination, C<0> otherwise.

=cut

sub has_type_schema {
    my ( $self, $category, $type ) = @_;
    return XARF::SchemaRegistry->instance->is_valid_type( $category, $type );
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _format_validation_error {
    my ($err) = @_;

    # instance_location is a JSON Pointer like /reporter/contact
    my $pointer = "" . $err->instance_location;
    $pointer =~ s{^/}{};     # strip leading slash
    $pointer =~ s{/}{.}g;    # convert to dot notation

    my $message = $err->error // 'validation failed';

    return XARF::ValidationError->new(
        field   => $pointer,
        message => $message,
    );
}

sub _load_json {
    my ($path) = @_;
    return unless $path && -f $path;
    open my $fh, '<:encoding(UTF-8)', $path or return;
    my $content = do { local $/; <$fh> };
    close $fh;
    return eval { decode_json($content) };
}

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::SchemaValidator - JSON Schema validation for XARF reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::SchemaValidator;

    my $validator = XARF::SchemaValidator->instance;

    # Validate a report hashref
    my $errors = $validator->validate($report_hashref);
    if (@$errors) {
        for my $err (@$errors) {
            printf "  %s: %s\n", $err->field || '(root)', $err->message;
        }
    }

    # Strict mode: x-recommended fields become required
    my $strict_errors = $validator->validate($report_hashref, strict => 1);

    # Introspect supported types
    my $types = $validator->get_supported_types;    # arrayref of "category/type"
    my $ok    = $validator->has_type_schema('messaging', 'spam');  # 1 or 0

=head1 DESCRIPTION

C<XARF::SchemaValidator> validates XARF report hashrefs against the official
XARF v4 JSON schemas using L<JSON::Schema::Modern> (Draft 2020-12).

It is a singleton — call C<< XARF::SchemaValidator->instance >> to obtain the
shared instance.  Schemas are loaded lazily on first use from the bundled
F<share/schemas/> directory via L<File::ShareDir> (installed) or from the
source tree (development).

Two independent L<JSON::Schema::Modern> instances are maintained: one for
normal validation and one for strict mode.  The strict instance has all
C<x-recommended: true> properties pre-promoted to C<required> before the
schemas are loaded.

=head1 CLASS METHODS

=head2 instance

    my $v = XARF::SchemaValidator->instance;

Returns the singleton, constructing it on first call.

=head2 _reset_instance

    XARF::SchemaValidator->_reset_instance;

Destroys the singleton so the next call to C<instance> constructs a fresh
one.  Intended for test isolation only.

=head1 METHODS

=head2 validate

    my $errors = $validator->validate($report_hashref);
    my $errors = $validator->validate($report_hashref, strict => 1);

Validates C<$report_hashref> against the master XARF v4 schema.

Returns an arrayref of L<XARF::ValidationError> objects.  Returns an empty
arrayref when the report is valid.  Errors are deduplicated on
C<(field, message)> pair.

When C<strict =E<gt> 1> is passed, fields marked C<x-recommended: true> in
the schema are treated as required and their absence produces validation
errors.

=head2 get_supported_types

    my $types = $validator->get_supported_types;

Returns an arrayref of C<"category/type"> strings covering every type
registered in L<XARF::SchemaRegistry>.

=head2 has_type_schema

    my $ok = $validator->has_type_schema('messaging', 'spam');

Returns C<1> if the given C<$category>/C<$type> combination has a registered
schema, C<0> otherwise.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::SchemaRegistry>, L<XARF::ValidationError>

=cut
