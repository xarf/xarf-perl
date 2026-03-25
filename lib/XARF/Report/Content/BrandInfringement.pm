package XARF::Report::Content::BrandInfringement;

use v5.40;
use Moo;
use Types::Standard qw( ArrayRef Maybe Num Str );

extends 'XARF::Report::Content';

our $VERSION = '0.01';

has infringement_type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has legitimate_site => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has infringing_elements => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has similarity_score => (
    is  => 'ro',
    isa => Maybe [Num],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content::BrandInfringement - XARF report class for brand infringement incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Content::BrandInfringement;

    my $report = XARF::Report::Content::BrandInfringement->new(
        # inherited required fields from XARF::Report::Content ...
        infringement_type   => 'lookalike_domain',
        legitimate_site     => 'https://www.example-brand.com/',
        infringing_elements => [ 'logo', 'colour_scheme', 'layout' ],
        similarity_score    => 0.93,
    );

=head1 DESCRIPTION

C<XARF::Report::Content::BrandInfringement> represents a brand infringement
abuse report in the XARF v4 format. It extends L<XARF::Report::Content> with
mandatory fields for the infringement type and the URL of the legitimate brand
site, plus optional fields for the specific infringing elements and a
quantitative similarity score.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Content>.

=head2 infringement_type

    is => 'ro', isa => Str, required => 1

The type of brand infringement (e.g. C<lookalike_domain>, C<trademark_misuse>,
C<counterfeit_goods>). Required.

=head2 legitimate_site

    is => 'ro', isa => Str, required => 1

URL of the legitimate brand site being infringed upon. Required.

=head2 infringing_elements

    is => 'ro', isa => Maybe[ArrayRef]

Array reference listing the specific brand elements that are being infringed
(e.g. C<logo>, C<colour_scheme>, C<layout>). Optional.

=head2 similarity_score

    is => 'ro', isa => Maybe[Num]

A numeric similarity score between 0 and 1 indicating how closely the
infringing site resembles the legitimate brand. Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Content>, L<XARF::Report>

=cut
