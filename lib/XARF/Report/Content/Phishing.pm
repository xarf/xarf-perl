package XARF::Report::Content::Phishing;

use v5.40;
use Moo;
use Types::Standard qw( ArrayRef Maybe Str );

extends 'XARF::Report::Content';

our $VERSION = '0.01';

has cloned_site => (
    is  => 'ro',
    isa => Maybe [Str],
);

has credential_fields => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has lure_type => (
    is  => 'ro',
    isa => Maybe [Str],
);

has submission_url => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content::Phishing - XARF report class for phishing incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Content::Phishing;

    my $report = XARF::Report::Content::Phishing->new(
        # inherited required fields from XARF::Report::Content ...
        cloned_site       => 'https://www.realbank.example.com/',
        credential_fields => [ 'username', 'password', 'pin' ],
        lure_type         => 'bank',
        submission_url    => 'https://evil.example.com/collect.php',
    );

=head1 DESCRIPTION

C<XARF::Report::Content::Phishing> represents a phishing abuse report in the
XARF v4 format. It extends L<XARF::Report::Content> with fields that describe
the mechanics of a phishing site: the legitimate site being cloned, the form
fields harvesting credentials, the social-engineering lure type, and the URL
where harvested credentials are submitted.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Content>.

=head2 cloned_site

    is => 'ro', isa => Maybe[Str]

URL of the legitimate site being cloned by the phishing page. Optional.

=head2 credential_fields

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing the form field names that harvest credentials (e.g.
C<username>, C<password>). Optional.

=head2 lure_type

    is => 'ro', isa => Maybe[Str]

Type of social-engineering lure used to deceive victims, such as C<bank> or
C<social_media>. Optional.

=head2 submission_url

    is => 'ro', isa => Maybe[Str]

URL to which harvested credentials are submitted by the phishing form. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Content>, L<XARF::Report>

=cut
