package XARF::Report::Copyright::Cyberlocker;

use v5.40;
use Moo;
use Types::Standard qw(Str HashRef Maybe);

extends 'XARF::Report::Copyright';

our $VERSION = '0.01';

has hosting_service => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has infringing_url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has access_method => (
    is  => 'ro',
    isa => Maybe [Str],
);

has file_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has takedown_info => (
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

XARF::Report::Copyright::Cyberlocker - XARF report class for cyberlocker copyright infringement

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Copyright::Cyberlocker;

    my $report = XARF::Report::Copyright::Cyberlocker->new(
        # inherited required fields from XARF::Report::Copyright ...
        hosting_service => 'ExampleLocker',
        infringing_url  => 'https://examplelocker.example.com/files/abc123',
        access_method   => 'direct_download',
        file_info       => {
            filename       => 'Example.Film.2024.mkv',
            file_size      => 4294967296,
            file_hash      => 'sha256:deadbeef...',
            upload_date    => '2024-02-01',
            download_count => 4200,
        },
        takedown_info   => {
            previous_requests     => 2,
            service_response_time => '48h',
            automated_removal     => 0,
        },
        uploader_info   => {
            username     => 'uploader99',
            user_id      => 'u-00042',
            account_type => 'premium',
        },
    );

=head1 DESCRIPTION

C<XARF::Report::Copyright::Cyberlocker> represents a copyright infringement report
targeting a file hosted on a cyberlocker (direct-download) service in the XARF v4
format. It extends L<XARF::Report::Copyright> with fields that capture the hosting
service identity, the infringing file URL, and optional evidence about the file
itself, prior takedown attempts, and the uploader's account.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Copyright>.

=head2 hosting_service

    is => 'ro', isa => Str, required => 1

Name of the cyberlocker service hosting the infringing file. Required.

=head2 infringing_url

    is => 'ro', isa => Str, required => 1

URL of the infringing file on the cyberlocker service. Required.

=head2 access_method

    is => 'ro', isa => Maybe[Str]

How the infringing file is accessed (e.g. C<"direct_download">,
C<"streaming">, C<"premium_link">). Optional.

=head2 file_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference with metadata about the infringing file. Recognised keys are
C<filename>, C<file_size>, C<file_hash>, C<upload_date>, and
C<download_count>. Optional.

=head2 takedown_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference describing prior takedown activity. Recognised keys are
C<previous_requests>, C<service_response_time>, and C<automated_removal>.
Optional.

=head2 uploader_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference with information about the user who uploaded the file.
Recognised keys are C<username>, C<user_id>, and C<account_type>. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Copyright>, L<XARF::Report>

=cut
