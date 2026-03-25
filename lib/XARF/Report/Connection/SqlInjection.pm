package XARF::Report::Connection::SqlInjection;

use v5.40;
use Moo;
use Types::Standard qw(Str Num Maybe);

extends 'XARF::Report::Connection';

our $VERSION = '0.01';

has attack_technique => (
    is  => 'ro',
    isa => Maybe [Str],
);

has attempts_count => (
    is  => 'ro',
    isa => Maybe [Num],
);

has http_method => (
    is  => 'ro',
    isa => Maybe [Str],
);

has injection_point => (
    is  => 'ro',
    isa => Maybe [Str],
);

has payload_sample => (
    is  => 'ro',
    isa => Maybe [Str],
);

has target_url => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Connection::SqlInjection - XARF report class for SQL injection incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Connection::SqlInjection;

    my $report = XARF::Report::Connection::SqlInjection->new(
        # inherited required fields from XARF::Report::Connection ...
        attack_technique => 'union_based',
        attempts_count   => 42,
        http_method      => 'POST',
        injection_point  => 'login_form_username',
        payload_sample   => "' OR '1'='1",
        target_url       => 'https://example.com/login',
    );

=head1 DESCRIPTION

C<XARF::Report::Connection::SqlInjection> represents a SQL injection attack
abuse report in the XARF v4 format. It extends L<XARF::Report::Connection>
with fields that describe the injection technique, target, and payload details.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Connection>.

=head2 attack_technique

    is => 'ro', isa => Maybe[Str]

The SQL injection technique used (e.g. C<union_based>, C<blind_boolean>,
C<time_based>). Optional.

=head2 attempts_count

    is => 'ro', isa => Maybe[Num]

The number of injection attempts observed. Optional.

=head2 http_method

    is => 'ro', isa => Maybe[Str]

The HTTP method used in the attack (e.g. C<GET>, C<POST>). Optional.

=head2 injection_point

    is => 'ro', isa => Maybe[Str]

A description of where the injection was attempted (e.g. C<query_string>,
C<login_form_username>). Optional.

=head2 payload_sample

    is => 'ro', isa => Maybe[Str]

A representative sample of the injection payload observed. Optional.

=head2 target_url

    is => 'ro', isa => Maybe[Str]

The URL that was targeted by the SQL injection attack. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Connection>, L<XARF::Report>

=cut
