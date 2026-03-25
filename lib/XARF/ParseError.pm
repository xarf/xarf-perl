package XARF::ParseError;

use v5.40;
use Moo;

our $VERSION = '0.01';

extends 'XARF::Error';

1;

__END__

=head1 NAME

XARF::ParseError - Exception thrown when input cannot be parsed as JSON

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::ParseError;

    die XARF::ParseError->new( message => 'Invalid JSON: unexpected token at position 42' );

=head1 DESCRIPTION

C<XARF::ParseError> is thrown when the input passed to C<parse()> is not valid
JSON or is otherwise structurally unreadable before schema validation can begin.

It extends L<XARF::Error> and inherits its C<message> attribute and
string-overloading behaviour.

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

L<XARF>, L<XARF::Error>, L<XARF::SchemaError>

=cut
