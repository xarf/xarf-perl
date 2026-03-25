package XARF::Report::Connection;

use v5.40;
use Moo;
use Types::Standard qw(Str Num Maybe);

extends 'XARF::Report';

our $VERSION = '0.01';

has first_seen => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has protocol => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has destination_ip => (
    is  => 'ro',
    isa => Maybe [Str],
);

has destination_port => (
    is  => 'ro',
    isa => Maybe [Num],
);

has last_seen => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Connection - Base class for XARF connection category reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # Not used directly; use a concrete subclass
    use XARF::Report::Connection::DDoS;

=head1 DESCRIPTION

C<XARF::Report::Connection> extends L<XARF::Report> with the fields shared
by all connection-category report types.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report>, plus:

=head2 first_seen

Required string.  ISO 8601 date-time when the connection abuse was first
observed.

=head2 protocol

Required string.  Network protocol (e.g. C<"tcp">, C<"udp">).

=head2 destination_ip

Optional string (recommended).  Destination IP address of the abusive
traffic.

=head2 destination_port

Optional number (recommended).  Destination port number.

=head2 last_seen

Optional string.  ISO 8601 date-time when the abuse was last observed.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report>, L<XARF::Report::Connection::DDoS>,
L<XARF::Report::Connection::LoginAttack>

=cut
