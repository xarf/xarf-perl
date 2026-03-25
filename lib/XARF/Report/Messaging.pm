package XARF::Report::Messaging;

use v5.40;
use Moo;
use Types::Standard qw(Str Maybe);

extends 'XARF::Report';

our $VERSION = '0.01';

has protocol => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has sender_name => (
    is  => 'ro',
    isa => Maybe [Str],
);

has smtp_from => (
    is  => 'ro',
    isa => Maybe [Str],
);

has subject => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Messaging - Base class for XARF messaging category reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # Not used directly; use a concrete subclass
    use XARF::Report::Messaging::Spam;

=head1 DESCRIPTION

C<XARF::Report::Messaging> extends L<XARF::Report> with the fields shared
by all messaging-category report types (C<spam>, C<bulk_messaging>).

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report>, plus:

=head2 protocol

Required string.  Messaging protocol used for delivery
(e.g. C<"smtp">, C<"sms">, C<"whatsapp">).

=head2 sender_name

Optional string.  Display name of the message sender.

=head2 smtp_from

Optional string.  SMTP envelope sender address (required by the spec when
C<protocol> is C<"smtp">).

=head2 subject

Optional string (recommended).  Message subject line.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report>, L<XARF::Report::Messaging::Spam>,
L<XARF::Report::Messaging::BulkMessaging>

=cut
