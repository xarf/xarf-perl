package XARF::Report::Infrastructure::Botnet;

use v5.40;
use Moo;
use Types::Standard qw( ArrayRef Maybe Str );

extends 'XARF::Report::Infrastructure';

our $VERSION = '0.01';

has compromise_evidence => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has bot_capabilities => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has c2_protocol => (
    is  => 'ro',
    isa => Maybe [Str],
);

has c2_server => (
    is  => 'ro',
    isa => Maybe [Str],
);

has malware_family => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Infrastructure::Botnet - XARF report class for botnet infrastructure incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Infrastructure::Botnet;

    my $report = XARF::Report::Infrastructure::Botnet->new(
        # inherited required fields from XARF::Report::Infrastructure ...
        compromise_evidence => 'Observed C2 beacon traffic to 198.51.100.42:4444',
        bot_capabilities    => [ 'ddos', 'spam', 'credential_theft' ],
        c2_protocol         => 'IRC',
        c2_server           => '198.51.100.42',
        malware_family      => 'Mirai',
    );

=head1 DESCRIPTION

C<XARF::Report::Infrastructure::Botnet> represents a botnet infrastructure
abuse report in the XARF v4 format. It extends
L<XARF::Report::Infrastructure> with fields that describe the evidence of
compromise, the capabilities the bot exposes, and the command-and-control
infrastructure used to operate it.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Infrastructure>.

=head2 compromise_evidence

    is => 'ro', isa => Str, required => 1

Evidence that the host has been compromised and is participating in a botnet.
Required.

=head2 bot_capabilities

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing the capabilities of the botnet (e.g. C<ddos>,
C<spam>, C<credential_theft>). Optional.

=head2 c2_protocol

    is => 'ro', isa => Maybe[Str]

The protocol used by the command-and-control channel (e.g. C<IRC>,
C<HTTP>, C<peer-to-peer>). Optional.

=head2 c2_server

    is => 'ro', isa => Maybe[Str]

The address of the command-and-control server (hostname or IP). Optional.

=head2 malware_family

    is => 'ro', isa => Maybe[Str]

The name of the malware family associated with the botnet (e.g. C<Mirai>,
C<Emotet>). Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Infrastructure>, L<XARF::Report>

=cut
