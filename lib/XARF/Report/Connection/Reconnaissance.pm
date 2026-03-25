package XARF::Report::Connection::Reconnaissance;

use v5.40;
use Moo;
use Types::Standard qw(Str Num Bool ArrayRef Maybe);

extends 'XARF::Report::Connection';

our $VERSION = '0.01';

has probed_resources => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has automated_tool => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has http_methods => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has resource_categories => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has response_codes => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has successful_probes => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has total_probes => (
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

XARF::Report::Connection::Reconnaissance - XARF report class for reconnaissance incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Connection::Reconnaissance;

    my $report = XARF::Report::Connection::Reconnaissance->new(
        # inherited required fields from XARF::Report::Connection ...
        probed_resources    => ['/admin', '/wp-login.php', '/.env'],
        automated_tool      => 1,
        http_methods        => ['GET', 'POST'],
        resource_categories => ['admin_panels', 'config_files'],
        response_codes      => [200, 403, 404],
        successful_probes   => ['/admin'],
        total_probes        => 300,
        user_agent          => 'sqlmap/1.7',
    );

=head1 DESCRIPTION

C<XARF::Report::Connection::Reconnaissance> represents a web reconnaissance
abuse report in the XARF v4 format. It extends L<XARF::Report::Connection>
with fields that describe which resources were probed, the methods used, and
the results observed.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Connection>.

=head2 probed_resources

    is => 'ro', isa => ArrayRef, required => 1

An array reference of resource paths or identifiers that were probed during
the reconnaissance activity. Required.

=head2 automated_tool

    is => 'ro', isa => Maybe[Bool]

Whether an automated tool was used to conduct the reconnaissance. Optional.

=head2 http_methods

    is => 'ro', isa => Maybe[ArrayRef]

An array reference of HTTP methods observed during the reconnaissance (e.g.
C<GET>, C<POST>, C<OPTIONS>). Optional.

=head2 resource_categories

    is => 'ro', isa => Maybe[ArrayRef]

An array reference of categories describing the types of resources that were
probed (e.g. C<admin_panels>, C<config_files>). Optional.

=head2 response_codes

    is => 'ro', isa => Maybe[ArrayRef]

An array reference of HTTP response codes observed during probing. Optional.

=head2 successful_probes

    is => 'ro', isa => Maybe[ArrayRef]

An array reference of resources that were successfully probed (i.e. returned
an exploitable or informative response). Optional.

=head2 total_probes

    is => 'ro', isa => Maybe[Num]

The total number of probe attempts made. Optional.

=head2 user_agent

    is => 'ro', isa => Maybe[Str]

The HTTP User-Agent string used during reconnaissance. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Connection>, L<XARF::Report>

=cut
