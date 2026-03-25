package XARF::Report::Messaging::BulkMessaging;

use v5.40;
use Moo;
use Types::Standard qw(Num Bool HashRef Maybe);

extends 'XARF::Report::Messaging';

our $VERSION = '0.01';

has recipient_count => (
    is       => 'ro',
    isa      => Num,
    required => 1,
);

has bulk_indicators => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

has opt_in_evidence => (
    is  => 'ro',
    isa => Maybe [Bool],
);

has unsubscribe_provided => (
    is  => 'ro',
    isa => Maybe [Bool],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Messaging::BulkMessaging - XARF report class for bulk messaging incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Messaging::BulkMessaging;

    my $report = XARF::Report::Messaging::BulkMessaging->new(
        # inherited required fields from XARF::Report::Messaging ...
        recipient_count      => 10_000,
        bulk_indicators      => {
            high_volume       => 1,
            template_based    => 1,
            commercial_sender => 0,
        },
        opt_in_evidence      => 0,
        unsubscribe_provided => 1,
    );

=head1 DESCRIPTION

C<XARF::Report::Messaging::BulkMessaging> represents a bulk messaging abuse
report in the XARF v4 format. It extends L<XARF::Report::Messaging> with
fields that capture high-volume mailing behaviour, opt-in status, and
unsubscribe availability.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Messaging>.

=head2 recipient_count

    is => 'ro', isa => Num, required => 1

The number of recipients that received the bulk message. Required.

=head2 bulk_indicators

    is => 'ro', isa => Maybe[HashRef]

A hash reference of bulk mailing indicators. Recognised keys are
C<high_volume>, C<template_based>, and C<commercial_sender>. Optional.

=head2 opt_in_evidence

    is => 'ro', isa => Maybe[Bool]

Whether evidence of recipient opt-in is available. Optional.

=head2 unsubscribe_provided

    is => 'ro', isa => Maybe[Bool]

Whether the message contained an unsubscribe link or mechanism. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Messaging>, L<XARF::Report>

=cut
