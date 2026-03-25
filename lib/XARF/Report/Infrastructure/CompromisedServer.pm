package XARF::Report::Infrastructure::CompromisedServer;

use v5.40;
use Moo;
use Types::Standard qw( Str );

extends 'XARF::Report::Infrastructure';

our $VERSION = '0.01';

has compromise_method => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Infrastructure::CompromisedServer - XARF report class for compromised server incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Infrastructure::CompromisedServer;

    my $report = XARF::Report::Infrastructure::CompromisedServer->new(
        # inherited required fields from XARF::Report::Infrastructure ...
        compromise_method => 'sql_injection',
    );

=head1 DESCRIPTION

C<XARF::Report::Infrastructure::CompromisedServer> represents a compromised
server abuse report in the XARF v4 format. It extends
L<XARF::Report::Infrastructure> with a single field describing how the server
was compromised.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Infrastructure>.

=head2 compromise_method

    is => 'ro', isa => Str, required => 1

Method used to compromise the server (e.g. C<sql_injection>,
C<brute_force>, C<unpatched_cve>). Required.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Infrastructure>, L<XARF::Report>

=cut
