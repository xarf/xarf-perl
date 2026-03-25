package XARF::Report::Copyright::Copyright;

use v5.40;
use Moo;
use Types::Standard qw(Str Maybe);

extends 'XARF::Report::Copyright';

our $VERSION = '0.01';

has infringing_url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has infringement_type => (
    is  => 'ro',
    isa => Maybe [Str],
);

has original_url => (
    is  => 'ro',
    isa => Maybe [Str],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Copyright::Copyright - XARF report class for general copyright infringement

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Copyright::Copyright;

    my $report = XARF::Report::Copyright::Copyright->new(
        # inherited required fields from XARF::Report::Copyright ...
        infringing_url    => 'https://example.com/infringing-file.mp3',
        infringement_type => 'reproduction',
        original_url      => 'https://rightsholder.example.com/original.mp3',
    );

=head1 DESCRIPTION

C<XARF::Report::Copyright::Copyright> represents a general copyright infringement
report in the XARF v4 format. It extends L<XARF::Report::Copyright> with fields
that identify the infringing content location, the nature of the infringement, and
the location of the original copyrighted work.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Copyright>.

=head2 infringing_url

    is => 'ro', isa => Str, required => 1

URL of the infringing content. Required.

=head2 infringement_type

    is => 'ro', isa => Maybe[Str]

Type of infringement (e.g. C<"reproduction">, C<"distribution">, C<"public_performance">).
Optional.

=head2 original_url

    is => 'ro', isa => Maybe[Str]

URL of the original copyrighted work, used to substantiate the claim. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Copyright>, L<XARF::Report>

=cut
