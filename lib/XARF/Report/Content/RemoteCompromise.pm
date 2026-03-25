package XARF::Report::Content::RemoteCompromise;

use v5.40;
use Moo;
use Types::Standard qw( ArrayRef HashRef Maybe Str );

extends 'XARF::Report::Content';

our $VERSION = '0.01';

has compromise_type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has affected_cms => (
    is  => 'ro',
    isa => Maybe [Str],
);

has compromise_indicators => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has malicious_activities => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has persistence_mechanisms => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has webshell_details => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content::RemoteCompromise - XARF report class for remotely compromised host incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Content::RemoteCompromise;

    my $report = XARF::Report::Content::RemoteCompromise->new(
        # inherited required fields from XARF::Report::Content ...
        compromise_type       => 'webshell',
        affected_cms          => 'WordPress',
        compromise_indicators => [
            { type => 'file', value => '/wp-content/uploads/shell.php',
              description => 'Obfuscated PHP webshell' },
        ],
        malicious_activities   => [ 'spam_sending', 'phishing_hosting' ],
        persistence_mechanisms => [ 'cron_job', 'modified_core_file' ],
        webshell_details       => {
            family             => 'b374k',
            capabilities       => [ 'file_manager', 'command_execution' ],
            password_protected => 1,
        },
    );

=head1 DESCRIPTION

C<XARF::Report::Content::RemoteCompromise> represents a remotely compromised
host abuse report in the XARF v4 format. It extends L<XARF::Report::Content>
with a mandatory field for the compromise type, plus optional fields for the
affected CMS platform, indicators of compromise, observed malicious activities,
installed persistence mechanisms, and webshell details.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Content>.

=head2 compromise_type

    is => 'ro', isa => Str, required => 1

The type of compromise (e.g. C<webshell>, C<credential_theft>,
C<supply_chain>). Required.

=head2 affected_cms

    is => 'ro', isa => Maybe[Str]

The content management system running on the compromised host, if applicable
(e.g. C<WordPress>, C<Joomla>). Optional.

=head2 compromise_indicators

    is => 'ro', isa => Maybe[ArrayRef]

Array reference of indicator records. Each element is a hash reference with
keys C<type>, C<value>, and C<description> describing a single indicator of
compromise. Optional.

=head2 malicious_activities

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing the malicious activities observed on the compromised
host (e.g. C<spam_sending>, C<phishing_hosting>, C<cryptomining>). Optional.

=head2 persistence_mechanisms

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing persistence mechanisms installed by the attacker (e.g.
C<cron_job>, C<modified_core_file>, C<backdoor_account>). Optional.

=head2 webshell_details

    is => 'ro', isa => Maybe[HashRef]

Hash reference with details about any webshell found on the host. Recognised
keys are C<family> (webshell family name), C<capabilities> (array reference of
capability strings), and C<password_protected> (boolean). Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Content>, L<XARF::Report>

=cut
