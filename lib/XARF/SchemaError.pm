package XARF::SchemaError;

use v5.40;
use Moo;

our $VERSION = '0.01';

extends 'XARF::Error';

1;

__END__

=head1 NAME

XARF::SchemaError - Exception thrown when JSON schemas cannot be loaded

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::SchemaError;

    die XARF::SchemaError->new( message => 'Cannot find schema directory: /usr/share/xarf/schemas' );

=head1 DESCRIPTION

C<XARF::SchemaError> is thrown when the L<XARF::SchemaRegistry> cannot locate
or load the bundled JSON schemas. This typically indicates a broken installation
or a misconfigured schema path.

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

L<XARF>, L<XARF::Error>, L<XARF::ParseError>

=cut
