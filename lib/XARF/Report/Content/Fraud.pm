package XARF::Report::Content::Fraud;

use v5.40;
use Moo;
use Types::Standard qw( ArrayRef Maybe Str );

extends 'XARF::Report::Content';

our $VERSION = '0.01';

has fraud_type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has claimed_entity => (
    is  => 'ro',
    isa => Maybe [Str],
);

has payment_methods => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content::Fraud - XARF report class for online fraud incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Content::Fraud;

    my $report = XARF::Report::Content::Fraud->new(
        # inherited required fields from XARF::Report::Content ...
        fraud_type      => 'advance_fee',
        claimed_entity  => 'United Nations Relief Fund',
        payment_methods => [ 'wire_transfer', 'cryptocurrency' ],
    );

=head1 DESCRIPTION

C<XARF::Report::Content::Fraud> represents an online fraud abuse report in the
XARF v4 format. It extends L<XARF::Report::Content> with a mandatory field for
the type of fraud, plus optional fields for the entity the fraudster claims to
represent and the payment methods used.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Content>.

=head2 fraud_type

    is => 'ro', isa => Str, required => 1

The category of fraud being reported (e.g. C<advance_fee>, C<investment_scam>,
C<romance_scam>). Required.

=head2 claimed_entity

    is => 'ro', isa => Maybe[Str]

The name of the organisation or person the fraudster claims to be. Optional.

=head2 payment_methods

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing the payment methods solicited or used in the fraud
(e.g. C<wire_transfer>, C<cryptocurrency>, C<gift_card>). Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Content>, L<XARF::Report>

=cut
