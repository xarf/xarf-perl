package XARF::ValidationError;

use v5.40;
use Moo;

our $VERSION = '0.01';

has field => (
    is      => 'ro',
    default => '',
);

has message => (
    is       => 'ro',
    required => 1,
);

has value => ( is => 'ro', );

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::ValidationError - Structured validation error returned in result objects

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::ValidationError;

    my $err = XARF::ValidationError->new(
        field   => 'source_identifier',
        message => 'Must be a valid IP address or domain name',
        value   => 'not-an-ip',
    );

    say $err->field;    # source_identifier
    say $err->message;  # Must be a valid IP address or domain name
    say $err->value;    # not-an-ip

=head1 DESCRIPTION

C<XARF::ValidationError> represents a single validation problem found during
parsing or report creation. Unlike L<XARF::ParseError> and L<XARF::SchemaError>,
validation errors are B<not> exceptions — they are collected and returned inside
L<XARF::Result::Parse> or L<XARF::Result::CreateReport> objects so that callers
can inspect all problems at once rather than catching a single fatal exception.

=head1 ATTRIBUTES

=head2 field

The dot-notation path to the field that failed validation, e.g.
C<"reporter.contact">. Defaults to an empty string for errors that are not
tied to a specific field.

=head2 message

A human-readable description of the validation failure. Required.

=head2 value

The offending value that triggered the error, if applicable. May be any scalar
or reference; C<undef> when not relevant.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::ValidationWarning>, L<XARF::Result::Parse>

=cut
