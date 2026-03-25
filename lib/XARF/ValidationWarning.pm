package XARF::ValidationWarning;

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

1;

__END__

=head1 NAME

XARF::ValidationWarning - Non-fatal advisory returned in result objects

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::ValidationWarning;

    my $warn = XARF::ValidationWarning->new(
        field   => 'confidence',
        message => 'Recommended field is missing',
    );

    say $warn->field;    # confidence
    say $warn->message;  # Recommended field is missing

=head1 DESCRIPTION

C<XARF::ValidationWarning> represents a non-fatal advisory produced during
parsing or report creation. Warnings typically indicate that a recommended
(C<x-recommended: true>) field is absent, or that a value is technically valid
but unusual.

Like L<XARF::ValidationError>, warnings are collected and returned inside result
objects rather than thrown as exceptions.

=head1 ATTRIBUTES

=head2 field

The dot-notation path to the field that triggered the warning, e.g.
C<"confidence">. Defaults to an empty string for warnings not tied to a
specific field.

=head2 message

A human-readable description of the advisory. Required.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::ValidationError>, L<XARF::Result::Parse>

=cut
