package XARF::FieldMetadata;

use v5.40;
use Moo;
use Types::Standard qw(Bool Maybe Str ArrayRef Num);

our $VERSION = '0.01';

has description => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

has required => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has recommended => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has type => (
    is  => 'ro',
    isa => Maybe [Str],
);

has enum => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has format => (
    is  => 'ro',
    isa => Maybe [Str],
);

has minimum => (
    is  => 'ro',
    isa => Maybe [Num],
);

has maximum => (
    is  => 'ro',
    isa => Maybe [Num],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::FieldMetadata - Field metadata extracted from an XARF JSON schema

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::SchemaRegistry;

    my $registry = XARF::SchemaRegistry->instance;
    my $meta     = $registry->get_field_metadata('confidence');

    if ($meta) {
        say $meta->description;   # "Confidence level of the abuse report (0-100)"
        say $meta->required;      # 0 (false)
        say $meta->recommended;   # 0 (false)
        say $meta->type;          # "number"
        say $meta->minimum;       # 0
        say $meta->maximum;       # 100
    }

=head1 DESCRIPTION

C<XARF::FieldMetadata> is a lightweight value object that holds schema-derived
metadata for a single XARF report field. Instances are returned by
L<XARF::SchemaRegistry/get_field_metadata> and are read-only once constructed.

All attributes are optional except that C<description>, C<required>, and
C<recommended> always have defaults so callers can use them unconditionally.

=head1 ATTRIBUTES

=head2 description

Human-readable description of the field taken from the schema C<"description">
key. Defaults to an empty string.

=head2 required

Boolean (C<1>/C<0>). True if the field appears in the schema C<"required">
array. Defaults to C<0>.

=head2 recommended

Boolean (C<1>/C<0>). True if the schema property carries C<"x-recommended":
true>. Defaults to C<0>.

=head2 type

The JSON Schema C<"type"> value for this field (e.g. C<"string">, C<"number">),
or C<undef> if no type is specified.

=head2 enum

Arrayref of allowed string values taken from the schema C<"enum"> array, or
C<undef> if the field is not enum-constrained.

=head2 format

The JSON Schema C<"format"> value (e.g. C<"date-time">, C<"uuid">), or C<undef>
if not specified.

=head2 minimum

Numeric lower bound from the schema C<"minimum"> keyword, or C<undef>.

=head2 maximum

Numeric upper bound from the schema C<"maximum"> keyword, or C<undef>.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::SchemaRegistry>

=cut
