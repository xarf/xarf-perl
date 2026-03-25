package XARF::Report::Connection::InfectedHost;

use v5.40;
use Moo;
use Types::Standard qw(Str Num Bool ArrayRef Maybe);

extends 'XARF::Report::Connection';

our $VERSION = '0.01';

has bot_type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has accepts_cookies => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has api_endpoints_accessed => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has behavior_pattern => (
    is  => 'ro',
    isa => Maybe [Str],
);

has bot_name => (
    is  => 'ro',
    isa => Maybe [Str],
);

has follows_crawl_delay => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has javascript_execution => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has request_rate => (
    is  => 'ro',
    isa => Maybe [Num],
);

has respects_robots_txt => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has total_requests => (
    is  => 'ro',
    isa => Maybe [Num],
);

has user_agent => (
    is  => 'ro',
    isa => Maybe [Str],
);

has verification_status => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Connection::InfectedHost - XARF report class for infected host / bot incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Connection::InfectedHost;

    my $report = XARF::Report::Connection::InfectedHost->new(
        # inherited required fields from XARF::Report::Connection ...
        bot_type               => 'crawler',
        bot_name               => 'MalBot/1.0',
        accepts_cookies        => 0,
        api_endpoints_accessed => ['/api/v1/users', '/api/v1/products'],
        behavior_pattern       => 'aggressive_crawl',
        follows_crawl_delay    => 0,
        javascript_execution   => 1,
        request_rate           => 150.5,
        respects_robots_txt    => 0,
        total_requests         => 50_000,
        user_agent             => 'MalBot/1.0',
        verification_status    => 'confirmed',
    );

=head1 DESCRIPTION

C<XARF::Report::Connection::InfectedHost> represents an infected host or
malicious bot abuse report in the XARF v4 format. It extends
L<XARF::Report::Connection> with fields that characterise the bot or malware
type, its behaviour, and detection metadata.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Connection>.

=head2 bot_type

    is => 'ro', isa => Str, required => 1

The type or classification of the bot or malware. Required.

=head2 accepts_cookies

    is => 'ro', isa => Maybe[Bool]

Whether the bot accepts and stores cookies. Optional.

=head2 api_endpoints_accessed

    is => 'ro', isa => Maybe[ArrayRef]

An array reference listing API endpoints that were accessed by the bot.
Optional.

=head2 behavior_pattern

    is => 'ro', isa => Maybe[Str]

A description of the observed behaviour pattern of the bot or infected host.
Optional.

=head2 bot_name

    is => 'ro', isa => Maybe[Str]

The bot or malware family name (e.g. C<Mirai>, C<ZeuS>). Optional.

=head2 follows_crawl_delay

    is => 'ro', isa => Maybe[Bool]

Whether the bot honours the C<Crawl-delay> directive in C<robots.txt>.
Optional.

=head2 javascript_execution

    is => 'ro', isa => Maybe[Bool]

Whether the bot is capable of executing JavaScript. Optional.

=head2 request_rate

    is => 'ro', isa => Maybe[Num]

The observed request rate in requests per second. Optional.

=head2 respects_robots_txt

    is => 'ro', isa => Maybe[Bool]

Whether the bot respects the site's C<robots.txt> directives. Optional.

=head2 total_requests

    is => 'ro', isa => Maybe[Num]

The total number of requests made by the bot during the observed period.
Optional.

=head2 user_agent

    is => 'ro', isa => Maybe[Str]

The HTTP User-Agent string presented by the bot. Optional.

=head2 verification_status

    is => 'ro', isa => Maybe[Str]

The verification status of the detection (e.g. C<confirmed>, C<suspected>).
Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Connection>, L<XARF::Report>

=cut
