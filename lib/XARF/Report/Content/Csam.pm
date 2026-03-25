package XARF::Report::Content::Csam;

use v5.40;
use Moo;
use Types::Standard qw( Bool HashRef Maybe Str );

extends 'XARF::Report::Content';

our $VERSION = '0.01';

has classification => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has detection_method => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has content_removed => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has hash_values => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has media_type => (
    is  => 'ro',
    isa => Maybe [Str],
);

has ncmec_report_id => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content::Csam - XARF report class for child sexual abuse material incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Content::Csam;

    my $report = XARF::Report::Content::Csam->new(
        # inherited required fields from XARF::Report::Content ...
        classification   => 'A',
        detection_method => 'hash_match',
        content_removed  => 1,
        hash_values      => { sha1 => 'da39a3ee5e6b4b0d3255bfef95601890afd80709' },
        media_type       => 'image',
        ncmec_report_id  => 'NCMEC-2026-000123',
    );

=head1 DESCRIPTION

C<XARF::Report::Content::Csam> represents a child sexual abuse material (CSAM)
report in the XARF v4 format. It extends L<XARF::Report::Content> with mandatory
classification and detection fields, plus optional fields for content removal
status, cryptographic hashes, media type, and NCMEC report tracking.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Content>.

=head2 classification

    is => 'ro', isa => Str, required => 1

Content classification level as defined by the reporting framework. Required.

=head2 detection_method

    is => 'ro', isa => Str, required => 1

The method used to detect the content (e.g. C<hash_match>, C<manual_review>).
Required.

=head2 content_removed

    is => 'ro', isa => Maybe[Bool]

Whether the reported content has been removed from the hosting platform.
Optional.

=head2 hash_values

    is => 'ro', isa => Maybe[HashRef]

Hash reference mapping hash algorithm names to their corresponding digest
values for the reported content (e.g. C<< sha1 => '...' >>). Optional.

=head2 media_type

    is => 'ro', isa => Maybe[Str]

The media type of the content (e.g. C<image>, C<video>). Optional.

=head2 ncmec_report_id

    is => 'ro', isa => Maybe[Str]

The identifier assigned by the National Center for Missing and Exploited
Children (NCMEC) when the incident is reported to them. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Content>, L<XARF::Report>

=cut
