package XARF::Report::Reputation::ThreatIntelligence;

use v5.40;
use Moo;

extends 'XARF::Report::Reputation';

our $VERSION = '0.01';

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Reputation::ThreatIntelligence - XARF report class for threat intelligence reputation incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Reputation::ThreatIntelligence;

    my $report = XARF::Report::Reputation::ThreatIntelligence->new(
        # inherited required fields from XARF::Report::Reputation ...
    );

=head1 DESCRIPTION

C<XARF::Report::Reputation::ThreatIntelligence> represents a threat
intelligence reputation abuse report in the XARF v4 format. It extends
L<XARF::Report::Reputation> without adding any fields of its own; all
relevant data is captured by the parent class attributes.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Reputation>. This class defines
no additional attributes.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Reputation>, L<XARF::Report>

=cut
