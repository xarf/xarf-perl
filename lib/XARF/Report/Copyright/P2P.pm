package XARF::Report::Copyright::P2P;

use v5.40;
use Moo;
use Types::Standard qw(Str HashRef Maybe);

extends 'XARF::Report::Copyright';

our $VERSION = '0.01';

has p2p_protocol => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has swarm_info => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has detection_method => (
    is  => 'ro',
    isa => Maybe [Str],
);

has peer_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has release_date => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Copyright::P2P - XARF report class for peer-to-peer copyright infringement

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Copyright::P2P;

    my $report = XARF::Report::Copyright::P2P->new(
        # inherited required fields from XARF::Report::Copyright ...
        p2p_protocol => 'BitTorrent',
        swarm_info   => {
            info_hash    => 'a1b2c3d4e5f6...',
            torrent_name => 'Example Album',
            file_count   => 12,
            total_size   => 52428800,
        },
        detection_method => 'automated_monitoring',
        peer_info        => {
            peer_id          => '-TR2940-...',
            client_version   => 'Transmission 2.94',
            upload_amount    => 1048576,
            download_amount  => 0,
        },
        release_date => '2024-01-15',
    );

=head1 DESCRIPTION

C<XARF::Report::Copyright::P2P> represents a peer-to-peer copyright infringement
report in the XARF v4 format. It extends L<XARF::Report::Copyright> with fields
specific to P2P file-sharing networks, capturing protocol details, swarm
identification data, and optional peer-level evidence.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Copyright>.

=head2 p2p_protocol

    is => 'ro', isa => Str, required => 1

P2P protocol used for the infringing distribution (e.g. C<"BitTorrent">,
C<"eDonkey">, C<"Gnutella">). Required.

=head2 swarm_info

    is => 'ro', isa => HashRef, required => 1

Hash reference containing swarm identification data. Recognised keys are
C<info_hash> or C<magnet_uri>, C<torrent_name>, C<file_count>, and
C<total_size>. Required.

=head2 detection_method

    is => 'ro', isa => Maybe[Str]

Description of how the infringement was detected (e.g. C<"automated_monitoring">,
C<"manual_review">). Optional.

=head2 peer_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference with details about the infringing peer. Recognised keys are
C<peer_id>, C<client_version>, C<upload_amount>, and C<download_amount>.
Optional.

=head2 release_date

    is => 'ro', isa => Maybe[Str]

Release date of the copyrighted work, in ISO 8601 format (C<YYYY-MM-DD>).
Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Copyright>, L<XARF::Report>

=cut
