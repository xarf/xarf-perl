package XARF::Report::Copyright::Usenet;

use v5.40;
use Moo;
use Types::Standard qw(Str HashRef Maybe);

extends 'XARF::Report::Copyright';

our $VERSION = '0.01';

has newsgroup => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has message_info => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has detection_method => (
    is  => 'ro',
    isa => Maybe [Str],
);

has encoding_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has nzb_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has server_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Copyright::Usenet - XARF report class for Usenet copyright infringement

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Copyright::Usenet;

    my $report = XARF::Report::Copyright::Usenet->new(
        # inherited required fields from XARF::Report::Copyright ...
        newsgroup    => 'alt.binaries.example',
        message_info => {
            message_id   => '<abc123@example.nntp>',
            subject      => '"Example.Film.2024.mkv" yEnc (1/42)',
            from_header  => 'poster@example.invalid',
            posting_date => '2024-03-12T08:00:00Z',
            part_number  => 1,
            total_parts  => 42,
            file_size    => 4294967296,
        },
        detection_method => 'header_analysis',
        encoding_info    => {
            encoding_format => 'yEnc',
            par2_recovery   => 1,
            rar_compression => 1,
        },
        nzb_info => {
            nzb_name              => 'Example.Film.2024.nzb',
            nzb_url               => 'https://indexer.example.com/nzb/00099',
            indexer_site          => 'indexer.example.com',
            completion_percentage => 100,
        },
        server_info => {
            nntp_server    => 'news.example.com',
            server_group   => 'alt.binaries.example',
            retention_days => 1500,
        },
    );

=head1 DESCRIPTION

C<XARF::Report::Copyright::Usenet> represents a copyright infringement report
targeting binary content posted to a Usenet newsgroup in the XARF v4 format. It
extends L<XARF::Report::Copyright> with fields that identify the newsgroup and
the infringing message, along with optional evidence about encoding, NZB indexer
references, and the NNTP server involved.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Copyright>.

=head2 newsgroup

    is => 'ro', isa => Str, required => 1

Name of the Usenet newsgroup where the infringing content was posted
(e.g. C<"alt.binaries.movies">). Required.

=head2 message_info

    is => 'ro', isa => HashRef, required => 1

Hash reference with identification data for the infringing Usenet article.
C<message_id> is required; recognised optional keys are C<subject>,
C<from_header>, C<posting_date>, C<part_number>, C<total_parts>, and
C<file_size>. Required.

=head2 detection_method

    is => 'ro', isa => Maybe[Str]

Description of how the infringement was detected (e.g. C<"header_analysis">,
C<"binary_fingerprint">, C<"automated_monitoring">). Optional.

=head2 encoding_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference describing the encoding of the binary post. Recognised keys
are C<encoding_format>, C<par2_recovery>, and C<rar_compression>. Optional.

=head2 nzb_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference with NZB indexer metadata associated with the post. Recognised
keys are C<nzb_name>, C<nzb_url>, C<indexer_site>, and
C<completion_percentage>. Optional.

=head2 server_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference with details about the NNTP server. Recognised keys are
C<nntp_server>, C<server_group>, and C<retention_days>. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Copyright>, L<XARF::Report>

=cut
