package XARF::SchemaRegistry;

use v5.40;
use Moo;
use File::Basename qw(dirname);
use File::ShareDir qw(dist_dir);
use File::Spec;
use JSON::MaybeXS qw(decode_json);

use XARF::FieldMetadata;
use XARF::SchemaError;

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

has _core_schema => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__core_schema',
);

has _type_schemas => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__type_schemas',
);

has _categories => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__categories',
);

has _categories_set => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__categories_set',
);

has _types_per_category => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__types_per_category',
);

has _required_fields => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__required_fields',
);

has _required_fields_set => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__required_fields_set',
);

has _contact_required_fields => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__contact_required_fields',
);

# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------

sub _build__schemas_dir {
    my ($self) = @_;

    # Installed or blib (when -Iblib/lib is in effect)
    my $share = eval { dist_dir('XARF') };
    if ( $share && -d "$share/schemas" ) {
        return "$share/schemas";
    }

    # Dev fallback: walk up from __FILE__ (lib/XARF/SchemaRegistry.pm -> project root)
    my $mod_dir = dirname( File::Spec->rel2abs(__FILE__) );
    my $dev_dir
        = File::Spec->canonpath( File::Spec->catdir( $mod_dir, '..', '..', 'share', 'schemas' ) );
    return $dev_dir if -d $dev_dir;

    die XARF::SchemaError->new(
        message => 'Cannot find XARF schemas directory. Run `make` or install the distribution.' );
}

sub _build__core_schema {
    my ($self) = @_;
    return _load_json( File::Spec->catfile( $self->_schemas_dir, 'xarf-core.json' ) );
}

sub _build__type_schemas {
    my ($self) = @_;

    my $types_dir = File::Spec->catdir( $self->_schemas_dir, 'types' );
    return {} unless -d $types_dir;

    opendir my $dh, $types_dir or return {};
    my @files = sort
        grep { /\.json$/i && $_ ne 'content-base.json' } readdir $dh;
    closedir $dh;

    my %schemas;
    for my $file (@files) {
        next unless $file =~ /^([^-]+)-(.+)\.json$/;
        my ( $cat, $type_raw ) = ( $1, $2 );
        my $type   = $type_raw =~ s/-/_/gr;
        my $path   = File::Spec->catfile( $types_dir, $file );
        my $schema = _load_json($path);
        $schemas{"$cat/$type"} = $schema if $schema;
    }

    return \%schemas;
}

sub _build__categories {
    my ($self) = @_;
    my $core = $self->_core_schema;
    return [] unless $core;
    my $enum = $core->{properties}{category}{enum};
    return $enum ? [@$enum] : [];
}

sub _build__categories_set {
    my ($self) = @_;
    return { map { $_ => 1 } @{ $self->_categories } };
}

sub _build__types_per_category {
    my ($self) = @_;
    my %by_cat;
    for my $key ( keys %{ $self->_type_schemas } ) {
        my ( $cat, $type ) = split m{/}, $key, 2;
        push @{ $by_cat{$cat} }, $type;
    }
    for my $cat ( keys %by_cat ) {
        $by_cat{$cat} = [ sort @{ $by_cat{$cat} } ];
    }
    return \%by_cat;
}

sub _build__required_fields {
    my ($self) = @_;
    my $core = $self->_core_schema;
    return [] unless $core && $core->{required};
    return [ @{ $core->{required} } ];
}

sub _build__required_fields_set {
    my ($self) = @_;
    return { map { $_ => 1 } @{ $self->_required_fields } };
}

sub _build__contact_required_fields {
    my ($self)      = @_;
    my $core        = $self->_core_schema;
    my $contact_def = $core && $core->{'$defs'}{contact_info};
    return $contact_def && $contact_def->{required}
        ? [ @{ $contact_def->{required} } ]
        : [qw(org contact domain)];
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

sub get_categories {
    my ($self) = @_;
    return $self->_categories;
}

sub get_types_for_category {
    my ( $self, $category ) = @_;
    return $self->_types_per_category->{$category} // [];
}

sub get_all_types {
    my ($self) = @_;
    return $self->_types_per_category;
}

sub is_valid_category {
    my ( $self, $category ) = @_;
    return $self->_categories_set->{$category} ? 1 : 0;
}

sub is_valid_type {
    my ( $self, $category, $type ) = @_;
    return exists $self->_type_schemas->{"$category/$type"} ? 1 : 0;
}

sub get_required_fields {
    my ($self) = @_;
    return $self->_required_fields;
}

sub get_contact_required_fields {
    my ($self) = @_;
    return $self->_contact_required_fields;
}

sub get_type_schema {
    my ( $self, $category, $type ) = @_;
    return $self->_type_schemas->{"$category/$type"};
}

sub get_field_metadata {
    my ( $self, $field_name ) = @_;
    my $core = $self->_core_schema;
    return unless $core;

    my $prop = $core->{properties}{$field_name};
    return unless $prop;

    return XARF::FieldMetadata->new(
        description => $prop->{description} // '',
        required    => $self->_required_fields_set->{$field_name} ? 1 : 0,
        recommended => ( $prop->{'x-recommended'} // 0 )          ? 1 : 0,
        type        => $prop->{type},
        enum        => $prop->{enum},
        format      => $prop->{format},
        minimum     => $prop->{minimum},
        maximum     => $prop->{maximum},
    );
}

sub get_core_property_names {
    my ($self) = @_;
    my $core = $self->_core_schema;
    return [] unless $core && $core->{properties};
    return [ sort keys %{ $core->{properties} } ];
}

sub get_category_fields {
    my ( $self, $category, $type ) = @_;
    my $schema = $self->get_type_schema( $category, $type );
    return [] unless $schema;

    my %core = map { $_ => 1 } @{ $self->get_core_property_names() };
    my @result;
    $self->_extract_fields_from_schema( $schema, \%core, \@result );
    return \@result;
}

sub get_all_fields_for_category {
    my ( $self, $category ) = @_;
    my %seen;
    for my $type ( @{ $self->get_types_for_category($category) } ) {
        for my $field ( @{ $self->get_category_fields( $category, $type ) } ) {
            $seen{$field} = 1;
        }
    }
    return [ sort keys %seen ];
}

sub is_loaded {
    my ($self) = @_;
    return $self->_core_schema ? 1 : 0;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _load_json {
    my ($path) = @_;
    return unless $path && -f $path;
    open my $fh, '<:encoding(UTF-8)', $path or return;
    my $content = do { local $/; <$fh> };
    close $fh;
    return eval { decode_json($content) };
}

sub _extract_fields_from_schema {
    my ( $self, $schema, $core, $result ) = @_;
    $self->_extract_direct_properties( $schema, $core, $result );
    $self->_extract_from_all_of( $schema, $core, $result );
    return;
}

sub _extract_direct_properties {
    my ( $self, $schema, $core, $result ) = @_;
    return unless $schema->{properties};
    for my $field ( keys %{ $schema->{properties} } ) {
        next if $core->{$field} || $field eq 'category' || $field eq 'type';
        push @$result, $field unless grep { $_ eq $field } @$result;
    }
    return;
}

sub _extract_from_all_of {
    my ( $self, $schema, $core, $result ) = @_;
    return unless $schema->{allOf};
    for my $sub_schema ( @{ $schema->{allOf} } ) {
        $self->_process_sub_schema( $sub_schema, $core, $result );
    }
    return;
}

sub _process_sub_schema {
    my ( $self, $sub_schema, $core, $result ) = @_;
    if ( $sub_schema->{'$ref'} ) {
        $self->_process_schema_reference( $sub_schema->{'$ref'}, $core, $result );
    } else {
        $self->_extract_fields_from_schema( $sub_schema, $core, $result );
    }
    return;
}

sub _process_schema_reference {
    my ( $self, $ref, $core, $result ) = @_;
    return unless $ref =~ /-base\.json/;
    my $base = $self->_load_base_schema($ref);
    $self->_extract_fields_from_schema( $base, $core, $result ) if $base;
    return;
}

sub _load_base_schema {
    my ( $self, $ref ) = @_;
    ( my $filename = $ref ) =~ s{^\./}{};
    $filename =~ s{^\.\./}{};
    my $path = File::Spec->catfile( $self->_schemas_dir, 'types', $filename );
    return _load_json($path);
}

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::SchemaRegistry - Schema-driven registry of XARF categories, types, and field metadata

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::SchemaRegistry;

    my $registry = XARF::SchemaRegistry->instance;

    # Enumerate what the spec defines
    my $cats  = $registry->get_categories;
    my $types = $registry->get_types_for_category('messaging');  # ['bulk_messaging', 'spam']

    # Validate before processing
    if ( $registry->is_valid_type('messaging', 'spam') ) { ... }

    # Inspect a field
    my $meta = $registry->get_field_metadata('source_port');
    say $meta->recommended;    # 1
    say $meta->type;           # "integer"
    say $meta->minimum;        # 1
    say $meta->maximum;        # 65535

    # Category-specific fields (not in core schema)
    my $fields = $registry->get_category_fields('messaging', 'spam');

=head1 DESCRIPTION

C<XARF::SchemaRegistry> is a lazily-initialised singleton that derives
validation rules directly from the bundled XARF JSON schemas.  No
category names, type names, or enum values are hardcoded in the library -
all metadata is read from the canonical F<xarf-core.json> and the per-type
schemas under F<schemas/types/>.

The schemas are located via L<File::ShareDir> (installed or C<blib/>)
with an automatic dev fallback that walks up from this module file to
find the C<share/schemas/> directory in a working checkout.

=head1 CLASS METHODS

=head2 instance

    my $registry = XARF::SchemaRegistry->instance;

Returns the singleton instance, constructing it on first call.

=head2 _reset_instance

    XARF::SchemaRegistry->_reset_instance;

Destroys the singleton, forcing re-initialisation on the next call to
C<instance>.  Intended for test isolation only.

=head1 METHODS

=head2 get_categories

    my $cats = $registry->get_categories;

Returns an arrayref of all valid category names derived from the
C<"category"> enum in F<xarf-core.json>.

=head2 get_types_for_category( $category )

    my $types = $registry->get_types_for_category('connection');

Returns an arrayref of valid type names for C<$category>, sorted
alphabetically.  Returns an empty arrayref for unknown categories.

=head2 get_all_types

    my $all = $registry->get_all_types;

Returns a hashref mapping each category name to an arrayref of its type names.

=head2 is_valid_category( $category )

    if ( $registry->is_valid_category('messaging') ) { ... }

Returns C<1> if C<$category> is a known category, C<0> otherwise.

=head2 is_valid_type( $category, $type )

    if ( $registry->is_valid_type('messaging', 'spam') ) { ... }

Returns C<1> if C<$type> is valid for C<$category>, C<0> otherwise.

=head2 get_required_fields

    my $fields = $registry->get_required_fields;

Returns an arrayref of field names listed in the core schema C<"required">
array.

=head2 get_contact_required_fields

    my $fields = $registry->get_contact_required_fields;

Returns an arrayref of field names required inside C<reporter> and C<sender>
contact objects (from the C<contact_info> C<$defs> entry in
F<xarf-core.json>).  Falls back to C<['org', 'contact', 'domain']> if the
schema definition is absent.

=head2 get_type_schema( $category, $type )

    my $schema = $registry->get_type_schema('messaging', 'spam');

Returns the raw parsed schema hashref for the given C<$category>/C<$type>
combination, or C<undef> if the combination is unknown.

=head2 get_field_metadata( $field_name )

    my $meta = $registry->get_field_metadata('source_port');

Returns an L<XARF::FieldMetadata> object for C<$field_name> if the field is
defined in F<xarf-core.json>, or C<undef> if the field is not found.

=head2 get_core_property_names

    my $names = $registry->get_core_property_names;

Returns a sorted arrayref of all property names defined in F<xarf-core.json>.

=head2 get_category_fields( $category, $type )

    my $fields = $registry->get_category_fields('messaging', 'spam');

Returns an arrayref of field names that are specific to the given
C<$category>/C<$type> combination - i.e. fields defined in the type schema
that are I<not> part of the core schema (and not C<category> or C<type>).

=head2 get_all_fields_for_category( $category )

    my $fields = $registry->get_all_fields_for_category('connection');

Returns a sorted arrayref of all field names used by any type within
C<$category>, excluding core fields.

=head2 is_loaded

    if ( $registry->is_loaded ) { ... }

Returns C<1> if the core schema was successfully loaded, C<0> otherwise.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::FieldMetadata>, L<XARF::SchemaValidator>

=cut
