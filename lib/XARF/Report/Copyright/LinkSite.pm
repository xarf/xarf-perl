package XARF::Report::Copyright::LinkSite;

use v5.40;
use Moo;
use Types::Standard qw(Str HashRef ArrayRef Maybe);

extends 'XARF::Report::Copyright';

our $VERSION = '0.01';

has infringing_url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has site_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has link_info => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has linked_content => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has search_terms => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has site_category => (
    is  => 'ro',
    isa => Maybe [Str],
);

has site_ranking => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Copyright::LinkSite - XARF report class for link-site copyright infringement

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Copyright::LinkSite;

    my $report = XARF::Report::Copyright::LinkSite->new(
        # inherited required fields from XARF::Report::Copyright ...
        infringing_url => 'https://linksite.example.com/movies/example-film',
        site_name      => 'ExampleLinks',
        link_info      => {
            page_title     => 'Example Film (2024) Download Links',
            posting_date   => '2024-03-05',
            uploader       => 'linker99',
            download_count => 8700,
            link_count     => 5,
        },
        linked_content => [
            {
                target_url      => 'https://locker.example.com/file/xyz',
                link_type       => 'direct',
                hosting_service => 'ExampleLocker',
                file_size       => 4294967296,
            },
        ],
        search_terms  => [ 'example film 2024 download', 'example film full movie' ],
        site_category => 'movie_index',
        site_ranking  => {
            alexa_rank       => 12500,
            popularity_score => 87,
        },
    );

=head1 DESCRIPTION

C<XARF::Report::Copyright::LinkSite> represents a copyright infringement report
targeting a linking or index site that aggregates download links to infringing
content in the XARF v4 format. It extends L<XARF::Report::Copyright> with fields
that identify the linking page, the site itself, and optional metadata about the
links posted, the search terms used to find the content, and the site's traffic
ranking.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Copyright>.

=head2 infringing_url

    is => 'ro', isa => Str, required => 1

URL of the linking page containing the infringing download links. Required.

=head2 site_name

    is => 'ro', isa => Str, required => 1

Name of the linking site. Required.

=head2 link_info

    is => 'ro', isa => Maybe[HashRef]

Hash reference with metadata about the linking page. Recognised keys are
C<page_title>, C<posting_date>, C<uploader>, C<download_count>, and
C<link_count>. Optional.

=head2 linked_content

    is => 'ro', isa => Maybe[ArrayRef]

Array reference of hash references, each describing one linked content item.
Recognised keys per item are C<target_url>, C<link_type>, C<hosting_service>,
and C<file_size>. Optional.

=head2 search_terms

    is => 'ro', isa => Maybe[ArrayRef]

Array reference of strings representing search terms used to locate the
infringing content on the link site. Optional.

=head2 site_category

    is => 'ro', isa => Maybe[Str]

Category of the link site (e.g. C<"movie_index">, C<"music_blog">,
C<"warez_forum">). Optional.

=head2 site_ranking

    is => 'ro', isa => Maybe[HashRef]

Hash reference with traffic or popularity ranking data for the site.
Recognised keys are C<alexa_rank> and C<popularity_score>. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Copyright>, L<XARF::Report>

=cut
