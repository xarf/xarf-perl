package XARF::Report::Connection::PortScan;

use v5.40;
use Moo;

extends 'XARF::Report::Connection';

our $VERSION = '0.01';

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Connection::PortScan - XARF report class for port scan incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Connection::PortScan;

    my $report = XARF::Report::Connection::PortScan->new(
        # inherited required fields from XARF::Report::Connection ...
    );

=head1 DESCRIPTION

C<XARF::Report::Connection::PortScan> represents a port scanning abuse report
in the XARF v4 format. It extends L<XARF::Report::Connection> without adding
any fields of its own; all relevant data is captured by the parent class
attributes.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Connection>. This class defines
no additional attributes.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Connection>, L<XARF::Report>

=cut
