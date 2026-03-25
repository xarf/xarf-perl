package XARF::Report::Infrastructure;

use v5.40;
use Moo;

extends 'XARF::Report';

our $VERSION = '0.01';

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Infrastructure - Base class for XARF infrastructure category reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # Not used directly; use a concrete subclass
    use XARF::Report::Infrastructure::Botnet;

=head1 DESCRIPTION

C<XARF::Report::Infrastructure> extends L<XARF::Report> for the
infrastructure abuse category.  It adds no shared fields beyond those in the
base class; the concrete types (L<XARF::Report::Infrastructure::Botnet> and
L<XARF::Report::Infrastructure::CompromisedServer>) each define their own
required fields.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report>.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report>, L<XARF::Report::Infrastructure::Botnet>,
L<XARF::Report::Infrastructure::CompromisedServer>

=cut
