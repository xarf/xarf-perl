package XARF::Report::Content;

use v5.40;
use Moo;
use Types::Standard qw(Str Maybe);

extends 'XARF::Report';

our $VERSION = '0.01';

has url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has domain => (
    is  => 'ro',
    isa => Maybe [Str],
);

has target_brand => (
    is  => 'ro',
    isa => Maybe [Str],
);

has verified_at => (
    is  => 'ro',
    isa => Maybe [Str],
);

has verification_method => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content - Base class for XARF content category reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # Not used directly; use a concrete subclass
    use XARF::Report::Content::Phishing;

=head1 DESCRIPTION

C<XARF::Report::Content> extends L<XARF::Report> with the fields shared by
all content-category report types.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report>, plus:

=head2 url

Required string.  URL of the abusive content.

=head2 domain

Optional string.  Domain hosting the abusive content.

=head2 target_brand

Optional string.  Brand being impersonated or targeted.

=head2 verified_at

Optional string.  ISO 8601 date-time when the content was verified.

=head2 verification_method

Optional string.  How the content was verified (e.g. C<"manual_review">).

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report>, L<XARF::Report::Content::Phishing>,
L<XARF::Report::Content::Malware>

=cut
