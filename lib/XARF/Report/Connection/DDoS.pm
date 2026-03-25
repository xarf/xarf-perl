package XARF::Report::Connection::DDoS;

use v5.40;
use Moo;
use Types::Standard qw(Str Num Bool Maybe);

extends 'XARF::Report::Connection';

our $VERSION = '0.01';

has amplification_factor => (
    is  => 'ro',
    isa => Maybe [Num],
);

has attack_vector => (
    is  => 'ro',
    isa => Maybe [Str],
);

has duration_seconds => (
    is  => 'ro',
    isa => Maybe [Num],
);

has mitigation_applied => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has peak_bps => (
    is  => 'ro',
    isa => Maybe [Num],
);

has peak_pps => (
    is  => 'ro',
    isa => Maybe [Num],
);

has service_impact => (
    is  => 'ro',
    isa => Maybe [Str],
);

has threshold_exceeded => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Connection::DDoS - XARF report class for DDoS attack incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Connection::DDoS;

    my $report = XARF::Report::Connection::DDoS->new(
        # inherited required fields from XARF::Report::Connection ...
        attack_vector        => 'syn_flood',
        peak_bps             => 10_000_000_000,
        peak_pps             => 5_000_000,
        duration_seconds     => 3600,
        amplification_factor => 50,
        service_impact       => 'unavailable',
        mitigation_applied   => 1,
        threshold_exceeded   => '2026-03-25T10:00:00Z',
    );

=head1 DESCRIPTION

C<XARF::Report::Connection::DDoS> represents a Distributed Denial-of-Service
attack abuse report in the XARF v4 format. It extends
L<XARF::Report::Connection> with fields that describe attack volume, method,
duration, and service impact.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Connection>.

=head2 amplification_factor

    is => 'ro', isa => Maybe[Num]

The amplification factor for reflection-based DDoS attacks (e.g. C<50> for a
50x amplification). Optional.

=head2 attack_vector

    is => 'ro', isa => Maybe[Str]

The specific DDoS method or vector used (e.g. C<syn_flood>, C<udp_amplification>,
C<http_flood>). Optional.

=head2 duration_seconds

    is => 'ro', isa => Maybe[Num]

The duration of the attack in seconds. Optional.

=head2 mitigation_applied

    is => 'ro', isa => Maybe[Bool]

Whether mitigation measures were applied during the attack. Optional.

=head2 peak_bps

    is => 'ro', isa => Maybe[Num]

The peak attack bandwidth in bits per second. Optional.

=head2 peak_pps

    is => 'ro', isa => Maybe[Num]

The peak attack rate in packets per second. Optional.

=head2 service_impact

    is => 'ro', isa => Maybe[Str]

The impact on the targeted service. Expected values are C<none>,
C<degraded>, or C<unavailable>. Optional.

=head2 threshold_exceeded

    is => 'ro', isa => Maybe[Str]

An ISO 8601 timestamp recording when the attack threshold was first exceeded.
Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Connection>, L<XARF::Report>

=cut
