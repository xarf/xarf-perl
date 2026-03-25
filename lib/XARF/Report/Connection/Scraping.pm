package XARF::Report::Connection::Scraping;

use v5.40;
use Moo;
use Types::Standard qw(Str Num Bool Maybe);

extends 'XARF::Report::Connection';

our $VERSION = '0.01';

has total_requests => (
    is       => 'ro',
    isa      => Num,
    required => 1,
);

has bot_signature => (
    is  => 'ro',
    isa => Maybe [Str],
);

has concurrent_connections => (
    is  => 'ro',
    isa => Maybe [Num],
);

has data_volume => (
    is  => 'ro',
    isa => Maybe [Num],
);

has request_rate => (
    is  => 'ro',
    isa => Maybe [Num],
);

has respects_robots_txt => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has scraping_pattern => (
    is  => 'ro',
    isa => Maybe [Str],
);

has session_duration => (
    is  => 'ro',
    isa => Maybe [Num],
);

has target_content => (
    is  => 'ro',
    isa => Maybe [Str],
);

has unique_urls => (
    is  => 'ro',
    isa => Maybe [Num],
);

has user_agent => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Connection::Scraping - XARF report class for web scraping incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Connection::Scraping;

    my $report = XARF::Report::Connection::Scraping->new(
        # inherited required fields from XARF::Report::Connection ...
        total_requests         => 120_000,
        bot_signature          => 'ScraperBot/2.0',
        concurrent_connections => 20,
        data_volume            => 524_288_000,
        request_rate           => 33.3,
        respects_robots_txt    => 0,
        scraping_pattern       => 'full_site_crawl',
        session_duration       => 3600,
        target_content         => 'product_listings',
        unique_urls            => 45_000,
        user_agent             => 'ScraperBot/2.0',
    );

=head1 DESCRIPTION

C<XARF::Report::Connection::Scraping> represents a web scraping abuse report
in the XARF v4 format. It extends L<XARF::Report::Connection> with fields
that characterise the scraping session, its volume, rate, and the type of
content targeted.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Connection>.

=head2 total_requests

    is => 'ro', isa => Num, required => 1

The total number of HTTP requests made during the scraping session. Required.

=head2 bot_signature

    is => 'ro', isa => Maybe[Str]

A signature or identifier for the bot performing the scraping. Optional.

=head2 concurrent_connections

    is => 'ro', isa => Maybe[Num]

The number of simultaneous connections maintained by the scraper. Optional.

=head2 data_volume

    is => 'ro', isa => Maybe[Num]

The total volume of data scraped, in bytes. Optional.

=head2 request_rate

    is => 'ro', isa => Maybe[Num]

The observed request rate in requests per second. Optional.

=head2 respects_robots_txt

    is => 'ro', isa => Maybe[Bool]

Whether the scraper honours the site's C<robots.txt> directives. Optional.

=head2 scraping_pattern

    is => 'ro', isa => Maybe[Str]

A description of the observed scraping pattern (e.g. C<full_site_crawl>,
C<targeted_extraction>). Optional.

=head2 session_duration

    is => 'ro', isa => Maybe[Num]

The duration of the scraping session in seconds. Optional.

=head2 target_content

    is => 'ro', isa => Maybe[Str]

The type of content being scraped (e.g. C<product_listings>, C<contact_details>).
Optional.

=head2 unique_urls

    is => 'ro', isa => Maybe[Num]

The number of unique URLs accessed during the scraping session. Optional.

=head2 user_agent

    is => 'ro', isa => Maybe[Str]

The HTTP User-Agent string presented by the scraper. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Connection>, L<XARF::Report>

=cut
