package XARF::Error;

use v5.40;
use Moo;
use overload '""' => sub { $_[0]->message }, fallback => 1;

our $VERSION = '0.01';

has message => (
    is       => 'ro',
    required => 1,
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Error - Base exception class for the XARF library

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::Error;

    die XARF::Error->new( message => 'Something went wrong' );

=head1 DESCRIPTION

C<XARF::Error> is the base class for all exceptions thrown by the XARF library.
It stringifies to its message, so it works naturally with C<die>/C<eval> and
C<try>/C<catch> blocks.

Subclasses cover specific failure modes:

=over 4

=item * L<XARF::ParseError> — malformed or non-JSON input

=item * L<XARF::SchemaError> — schema loading or initialisation failures

=back

Validation problems (invalid field values, missing required fields, etc.) are
B<not> represented as exceptions; they are returned as structured
L<XARF::ValidationError> objects inside result objects.

=head1 METHODS

=head2 new( message => $str )

Constructor. C<message> is required.

=head2 message

Returns the error message string.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::ParseError>, L<XARF::SchemaError>

=cut
