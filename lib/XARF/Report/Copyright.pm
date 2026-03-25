package XARF::Report::Copyright;

use v5.40;
use Moo;
use Types::Standard qw(Str Maybe);

extends 'XARF::Report';

our $VERSION = '0.01';

has rights_holder => (
    is  => 'ro',
    isa => Maybe [Str],
);

has work_category => (
    is  => 'ro',
    isa => Maybe [Str],
);

has work_title => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Copyright - Base class for XARF copyright category reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    # Not used directly; use a concrete subclass
    use XARF::Report::Copyright::P2P;

=head1 DESCRIPTION

C<XARF::Report::Copyright> extends L<XARF::Report> with the fields shared by
all copyright-category report types.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report>, plus:

=head2 rights_holder

Optional string (recommended).  Name of the copyright rights holder.

=head2 work_category

Optional string.  Category of the copyrighted work (e.g. C<"music">,
C<"film">).

=head2 work_title

Optional string (recommended).  Title of the copyrighted work.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report>, L<XARF::Report::Copyright::P2P>,
L<XARF::Report::Copyright::Cyberlocker>

=cut
