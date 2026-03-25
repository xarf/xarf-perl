package XARF::Report::Messaging::Spam;

use v5.40;
use Moo;
use Types::Standard qw(Str Num HashRef Maybe);

extends 'XARF::Report::Messaging';

our $VERSION = '0.01';

has language => (
    is  => 'ro',
    isa => Maybe [Str],
);

has message_id => (
    is  => 'ro',
    isa => Maybe [Str],
);

has recipient_count => (
    is  => 'ro',
    isa => Maybe [Num],
);

has smtp_to => (
    is  => 'ro',
    isa => Maybe [Str],
);

has spam_indicators => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has user_agent => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Messaging::Spam - XARF report class for spam incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Messaging::Spam;

    my $report = XARF::Report::Messaging::Spam->new(
        # inherited required fields from XARF::Report::Messaging ...
        language        => 'en',
        message_id      => '<abc123@example.com>',
        recipient_count => 500,
        smtp_to         => 'victim@example.com',
        spam_indicators => {
            suspicious_links      => 1,
            commercial_content    => 1,
            bulk_characteristics  => 1,
        },
        user_agent      => 'Mozilla/5.0',
    );

=head1 DESCRIPTION

C<XARF::Report::Messaging::Spam> represents a spam abuse report in the XARF v4
format. It extends L<XARF::Report::Messaging> with additional fields specific
to spam incidents, such as language detection, message identification, recipient
counts, and spam signal indicators.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Messaging>.

=head2 language

    is => 'ro', isa => Maybe[Str]

ISO 639-1 language code identifying the language of the spam message (e.g.
C<en>, C<de>). Optional.

=head2 message_id

    is => 'ro', isa => Maybe[Str]

The Message-ID header value extracted from the spam message. Optional.

=head2 recipient_count

    is => 'ro', isa => Maybe[Num]

The number of recipients that received the spam message. Optional.

=head2 smtp_to

    is => 'ro', isa => Maybe[Str]

The SMTP envelope recipient address (the C<RCPT TO> value). Optional.

=head2 spam_indicators

    is => 'ro', isa => Maybe[HashRef]

A hash reference of spam detection indicators. Recognised keys are
C<suspicious_links>, C<commercial_content>, and C<bulk_characteristics>.
Optional.

=head2 user_agent

    is => 'ro', isa => Maybe[Str]

The user agent string associated with the spam submission, if available.
Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Messaging>, L<XARF::Report>

=cut
