package XARF::Report::Content::Csem;

use v5.40;
use Moo;
use Types::Standard qw( ArrayRef Maybe Str );

extends 'XARF::Report::Content';

our $VERSION = '0.01';

has detection_method => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has exploitation_type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has evidence_type => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has platform => (
    is  => 'ro',
    isa => Maybe [Str],
);

has reporting_obligations => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has victim_age_range => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content::Csem - XARF report class for child sexual exploitation material incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Content::Csem;

    my $report = XARF::Report::Content::Csem->new(
        # inherited required fields from XARF::Report::Content ...
        detection_method      => 'manual_review',
        exploitation_type     => 'grooming',
        evidence_type         => [ 'image', 'chat_log' ],
        platform              => 'social_media',
        reporting_obligations => [ 'NCMEC', 'IWF' ],
        victim_age_range      => '12-15',
    );

=head1 DESCRIPTION

C<XARF::Report::Content::Csem> represents a child sexual exploitation material
(CSEM) report in the XARF v4 format. It extends L<XARF::Report::Content> with
mandatory fields for detection method and exploitation type, plus optional
fields for evidence types, platform, applicable reporting obligations, and
victim age range.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Content>.

=head2 detection_method

    is => 'ro', isa => Str, required => 1

The method used to detect the content (e.g. C<manual_review>, C<hash_match>).
Required.

=head2 exploitation_type

    is => 'ro', isa => Str, required => 1

The type of exploitation depicted or facilitated (e.g. C<grooming>,
C<trafficking>). Required.

=head2 evidence_type

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing the types of evidence present in the report (e.g.
C<image>, C<video>, C<chat_log>). Optional.

=head2 platform

    is => 'ro', isa => Maybe[Str]

The platform or service where the content was found (e.g. C<social_media>,
C<file_hosting>). Optional.

=head2 reporting_obligations

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing applicable legal or organisational reporting
requirements (e.g. C<NCMEC>, C<IWF>). Optional.

=head2 victim_age_range

    is => 'ro', isa => Maybe[Str]

Estimated age range of the victim (e.g. C<12-15>). Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Content>, L<XARF::Report>

=cut
