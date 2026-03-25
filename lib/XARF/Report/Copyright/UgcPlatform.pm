package XARF::Report::Copyright::UgcPlatform;

use v5.40;
use Moo;
use Types::Standard qw(Str HashRef Maybe);

extends 'XARF::Report::Copyright';

our $VERSION = '0.01';

has infringing_url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has platform_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has content_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has infringement_type => (
    is  => 'ro',
    isa => Maybe [Str],
);

has match_details => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has monetization_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has uploader_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Copyright::UgcPlatform - XARF report class for UGC platform copyright infringement

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Copyright::UgcPlatform;

    my $report = XARF::Report::Copyright::UgcPlatform->new(
        # inherited required fields from XARF::Report::Copyright ...
        infringing_url => 'https://ugcplatform.example.com/watch?v=abc123',
        platform_name  => 'ExampleTube',
        content_info   => {
            content_id    => 'abc123',
            content_title => 'Copyrighted Film Clip',
            upload_date   => '2024-03-10',
            view_count    => 15000,
        },
        infringement_type => 'reproduction',
        match_details     => {
            match_confidence  => 0.98,
            match_duration    => 120,
            match_percentage  => 85,
            reference_id      => 'ref-00099',
        },
        monetization_info => {
            monetized       => 1,
            ad_revenue      => 42.50,
            premium_content => 0,
        },
        uploader_info => {
            username          => 'uploader_handle',
            user_id           => 'uid-88812',
            account_verified  => 1,
            subscriber_count  => 3200,
        },
    );

=head1 DESCRIPTION

C<XARF::Report::Copyright::UgcPlatform> represents a copyright infringement report
targeting content hosted on a user-generated content platform in the XARF v4
format. It extends L<XARF::Report::Copyright> with fields that capture the
platform identity, the infringing content URL, and optional evidence about the
content itself, content-matching results, monetization, and the uploader's account.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Copyright>.

=head2 infringing_url

    is => 'ro', isa => Str, required => 1

URL of the infringing content on the UGC platform. Required.

=head2 platform_name

    is => 'ro', isa => Str, required => 1

Name of the UGC platform hosting the infringing content. Required.

=head2 content_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference with metadata about the infringing content item. Recognised
keys include C<content_id>, C<content_title>, C<upload_date>, and
C<view_count>. Optional.

=head2 infringement_type

    is => 'ro', isa => Maybe[Str]

Type of infringement (e.g. C<"reproduction">, C<"distribution">,
C<"public_performance">). Optional.

=head2 match_details

    is => 'ro', isa => Maybe[HashRef]

Hash reference with content-matching evidence. Recognised keys are
C<match_confidence>, C<match_duration>, C<match_percentage>, and
C<reference_id>. Optional.

=head2 monetization_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference describing whether and how the infringing content is monetized.
Recognised keys are C<monetized>, C<ad_revenue>, and C<premium_content>.
Optional.

=head2 uploader_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference with information about the user who uploaded the content.
Recognised keys are C<username>, C<user_id>, C<account_verified>, and
C<subscriber_count>. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Copyright>, L<XARF::Report>

=cut
