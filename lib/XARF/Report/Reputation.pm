package XARF::Report::Reputation;

use v5.40;
use Moo;
use Types::Standard qw(Str);

extends 'XARF::Report';

our $VERSION = '0.01';

has threat_type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Reputation - Base class for XARF reputation category reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # Not used directly; use a concrete subclass
    use XARF::Report::Reputation::Blocklist;

=head1 DESCRIPTION

C<XARF::Report::Reputation> extends L<XARF::Report> with the single shared
field for all reputation-category report types.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report>, plus:

=head2 threat_type

Required string.  Type of threat being reported (e.g. C<"botnet">,
C<"spam_source">).

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report>, L<XARF::Report::Reputation::Blocklist>,
L<XARF::Report::Reputation::ThreatIntelligence>

=cut
