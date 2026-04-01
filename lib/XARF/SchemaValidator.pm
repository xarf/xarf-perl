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
use XARF::ValidationWarning;

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

=head2 validate( $report_hashref, %opts )

Validates C<$report_hashref> against the XARF v4 master schema and checks for
unknown fields.  Returns a hashref with two keys:

=over 4

=item C<errors>

Arrayref of L<XARF::ValidationError> objects.  Empty on success.

=item C<warnings>

Arrayref of L<XARF::ValidationWarning> objects for unknown fields.  In strict
mode unknown-field warnings are promoted to errors and this arrayref will be
empty.

=item C<info>

Only present when C<show_missing_optional =E<gt> 1> is passed.  Arrayref of
plain hashrefs C<< { field => $name, message => $text } >> describing optional
and recommended fields absent from the report.

=back

Accepted options:

=over 4

=item C<strict =E<gt> 0|1>

When true, C<x-recommended> fields are promoted to required before schema
validation, and any unknown-field warnings are converted to errors.

=item C<show_missing_optional =E<gt> 0|1>

When true, the returned hashref includes an C<info> key listing every optional
and recommended field that is absent from the report.

=back

=cut

sub validate {
    my ( $self, $report, %opts ) = @_;
    my $strict       = $opts{strict}                // 0;
    my $show_missing = $opts{show_missing_optional} // 0;

    # 1. JSON Schema validation
    my $jsm        = $strict ? $self->_strict_jsm : $self->_jsm;
    my $master_uri = 'https://xarf.org/schemas/v4/xarf-v4-master.json';

    my $jsm_result = $jsm->evaluate( $report, $master_uri );
    my @errors;
    unless ( $jsm_result->valid ) {
        @errors = map { _format_validation_error($_) } $jsm_result->errors;

        # Deduplicate on (field, message) pair — same strategy as JS reference
        my %seen;
        @errors = grep { !$seen{ $_->field . "\0" . $_->message }++ } @errors;
    }

    # 2. Unknown field warnings
    my @warnings = @{ $self->_collect_unknown_fields($report) };

    # 3. In strict mode, unknown-field warnings become errors (mirrors JS XARFValidator)
    if ( $strict && @warnings ) {
        push @errors,
            map { XARF::ValidationError->new( field => $_->field, message => $_->message ) }
            @warnings;
        @warnings = ();
    }

    # 4. Missing optional / recommended fields
    my $info;
    if ($show_missing) {
        $info = $self->_collect_missing_optional($report);
    }

    my %result = ( errors => \@errors, warnings => \@warnings );
    $result{info} = $info if $show_missing;
    return \%result;
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
# Private helpers — unknown field detection
# ---------------------------------------------------------------------------

sub _collect_unknown_fields {
    my ( $self, $report ) = @_;
    my $reg = XARF::SchemaRegistry->instance;

    # Build set of all known fields: core + category-specific
    my %known = map { $_ => 1 } @{ $reg->get_core_property_names() };
    if ( $report->{category} && $report->{type} ) {
        $known{$_} = 1
            for @{ $reg->get_category_fields( $report->{category}, $report->{type} ) };
    }

    my @warnings;
    for my $field ( sort keys %$report ) {
        unless ( $known{$field} ) {
            push @warnings,
                XARF::ValidationWarning->new(
                field   => $field,
                message => "Unknown field '$field' is not defined in the XARF schema",
                );
        }
    }
    return \@warnings;
}

# ---------------------------------------------------------------------------
# Private helpers — missing optional/recommended field discovery
# ---------------------------------------------------------------------------

sub _collect_missing_optional {
    my ( $self, $report ) = @_;
    my $reg = XARF::SchemaRegistry->instance;

    my @info;
    my %seen;

    # Core optional/recommended fields (skip required and _internal)
    my %req = map { $_ => 1 } @{ $reg->get_required_fields() };
    for my $field ( @{ $reg->get_core_property_names() } ) {
        next if $req{$field} || $field eq '_internal';
        next if exists $report->{$field};
        $seen{$field} = 1;
        my $meta   = $reg->get_field_metadata($field);
        my $prefix = ( $meta && $meta->recommended ) ? 'RECOMMENDED' : 'OPTIONAL';
        my $desc   = $meta ? $meta->description                      : "Optional field: $field";
        push @info, { field => $field, message => "$prefix: $desc" };
    }

    # Type-specific optional/recommended fields
    my ( $cat, $type ) = ( $report->{category}, $report->{type} );
    if ( $cat && $type ) {
        my $schema = $reg->get_type_schema( $cat, $type );
        $self->_extract_optional_fields( $schema, $report, \@info, \%seen ) if $schema;
    }

    return \@info;
}

# Recursively extracts optional fields from a schema node (handles allOf
# and follows -base.json $refs, mirroring JS extractOptionalFields).
sub _extract_optional_fields {
    my ( $self, $schema, $report, $info, $seen ) = @_;
    return unless ref($schema) eq 'HASH';

    # Direct properties in this schema node
    if ( ref( $schema->{properties} ) eq 'HASH' ) {
        my %req = map { $_ => 1 } @{ $schema->{required} // [] };
        for my $field ( sort keys %{ $schema->{properties} } ) {
            next if $req{$field} || $seen->{$field} || exists $report->{$field};
            $seen->{$field} = 1;
            my $prop   = $schema->{properties}{$field};
            my $prefix = $prop->{'x-recommended'} ? 'RECOMMENDED' : 'OPTIONAL';
            my $desc   = $prop->{description} // "Optional field: $field";
            push @$info, { field => $field, message => "$prefix: $desc" };
        }
    }

    # Recurse into allOf entries
    for my $sub ( @{ $schema->{allOf} // [] } ) {
        if ( my $ref = $sub->{'$ref'} ) {

            # Follow only -base.json refs (mirrors JS resolveBaseRef); skip core ref
            if ( $ref =~ /-base\.json/ ) {
                my $base = $self->_load_ref_schema($ref);
                $self->_extract_optional_fields( $base, $report, $info, $seen ) if $base;
            }
        } else {
            $self->_extract_optional_fields( $sub, $report, $info, $seen );
        }
    }
    return;
}

sub _load_ref_schema {
    my ( $self, $ref ) = @_;
    ( my $filename = $ref ) =~ s{^\./}{};
    $filename =~ s{^\.\./}{};
    my $path = File::Spec->catfile( $self->_schemas_dir, 'types', $filename );
    return _load_json($path);
}

# ---------------------------------------------------------------------------
# Private helpers — shared
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
    my $result = $validator->validate($report_hashref);
    if ( @{ $result->{errors} } ) {
        for my $err ( @{ $result->{errors} } ) {
            printf "  %s: %s\n", $err->field || '(root)', $err->message;
        }
    }

    # Warnings for unknown fields
    for my $w ( @{ $result->{warnings} } ) {
        printf "  WARNING %s: %s\n", $w->field, $w->message;
    }

    # Strict mode: x-recommended fields become required; unknown fields → errors
    my $strict_result = $validator->validate($report_hashref, strict => 1);

    # Discover missing optional/recommended fields
    my $full = $validator->validate(
        $report_hashref,
        show_missing_optional => 1,
    );
    for my $item ( @{ $full->{info} } ) {
        printf "  %s: %s\n", $item->{field}, $item->{message};
    }

    # Introspect supported types
    my $types = $validator->get_supported_types;    # arrayref of "category/type"
    my $ok    = $validator->has_type_schema('messaging', 'spam');  # 1 or 0

=head1 DESCRIPTION

C<XARF::SchemaValidator> validates XARF report hashrefs against the official
XARF v4 JSON schemas using L<JSON::Schema::Modern> (Draft 2020-12).  It also
detects unknown fields (fields not defined in any XARF schema) and can
enumerate missing optional/recommended fields on request.

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

    my $result = $validator->validate($report_hashref);
    my $result = $validator->validate($report_hashref, strict => 1);
    my $result = $validator->validate($report_hashref, show_missing_optional => 1);

Validates C<$report_hashref> against the master XARF v4 schema and checks for
unknown fields.

Returns a hashref with:

=over 4

=item C<errors>

Arrayref of L<XARF::ValidationError> objects (empty when valid).  Errors are
deduplicated on C<(field, message)> pair.

=item C<warnings>

Arrayref of L<XARF::ValidationWarning> objects for any unknown fields.  Empty
in strict mode (unknown-field warnings are promoted to errors instead).

=item C<info>

Only present when C<show_missing_optional =E<gt> 1> is passed.  Arrayref of
plain hashrefs C<< { field => $name, message => $text } >> where C<$text>
begins with C<RECOMMENDED:> or C<OPTIONAL:>.

=back

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

L<XARF>, L<XARF::SchemaRegistry>, L<XARF::ValidationError>,
L<XARF::ValidationWarning>

=cut
