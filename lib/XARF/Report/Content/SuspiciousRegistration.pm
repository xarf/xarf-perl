package XARF::Report::Content::SuspiciousRegistration;

use v5.40;
use Moo;
use Types::Standard qw( ArrayRef HashRef Maybe Num Str );

extends 'XARF::Report::Content';

our $VERSION = '0.01';

has registration_date => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has suspicious_indicators => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has days_since_registration => (
    is  => 'ro',
    isa => Maybe [Num],
);

has predicted_usage => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has registrant_details => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has risk_score => (
    is  => 'ro',
    isa => Maybe [Num],
);

has targeted_brands => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content::SuspiciousRegistration - XARF report class for suspicious domain registration incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Content::SuspiciousRegistration;

    my $report = XARF::Report::Content::SuspiciousRegistration->new(
        # inherited required fields from XARF::Report::Content ...
        registration_date       => '2026-03-20',
        suspicious_indicators   => [ 'typosquatting', 'brand_keyword', 'new_tld' ],
        days_since_registration => 5,
        predicted_usage         => [ 'phishing', 'brand_impersonation' ],
        registrant_details      => {
            email_domain       => 'disposable.example.com',
            country            => 'XX',
            privacy_protected  => 1,
            bulk_registrations => 1,
        },
        risk_score      => 0.87,
        targeted_brands => [ 'ExampleBank', 'ExamplePay' ],
    );

=head1 DESCRIPTION

C<XARF::Report::Content::SuspiciousRegistration> represents a suspicious domain
registration abuse report in the XARF v4 format. It extends
L<XARF::Report::Content> with mandatory fields for the domain registration date
and a list of suspicious indicators, plus optional fields for days since
registration, predicted abusive uses, registrant details, a quantitative risk
score, and the brands the domain appears to target.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Content>.

=head2 registration_date

    is => 'ro', isa => Str, required => 1

ISO 8601 date on which the domain was registered (e.g. C<2026-03-20>).
Required.

=head2 suspicious_indicators

    is => 'ro', isa => ArrayRef, required => 1

Array reference listing the specific indicators that make the registration
suspicious (e.g. C<typosquatting>, C<brand_keyword>, C<new_tld>). Required.

=head2 days_since_registration

    is => 'ro', isa => Maybe[Num]

Number of days that have elapsed since the domain was registered at the time
of the report. Optional.

=head2 predicted_usage

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing predicted abusive uses for the domain (e.g.
C<phishing>, C<brand_impersonation>, C<malware_distribution>). Optional.

=head2 registrant_details

    is => 'ro', isa => Maybe[HashRef]

Hash reference containing registrant information. Recognised keys are
C<email_domain> (domain part of the registrant email), C<country> (two-letter
country code), C<privacy_protected> (boolean), and C<bulk_registrations>
(boolean indicating whether the registrant has registered many domains).
Optional.

=head2 risk_score

    is => 'ro', isa => Maybe[Num]

A numeric risk score between 0 and 1 indicating the likelihood that the
domain will be used for abuse. Optional.

=head2 targeted_brands

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing the brand names the domain appears to be targeting
or impersonating. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Content>, L<XARF::Report>

=cut
