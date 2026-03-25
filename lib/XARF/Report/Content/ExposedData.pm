package XARF::Report::Content::ExposedData;

use v5.40;
use Moo;
use Types::Standard qw( ArrayRef Maybe Num Str );

extends 'XARF::Report::Content';

our $VERSION = '0.01';

has data_types => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has exposure_method => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has affected_organization => (
    is  => 'ro',
    isa => Maybe [Str],
);

has encryption_status => (
    is  => 'ro',
    isa => Maybe [Str],
);

has record_count => (
    is  => 'ro',
    isa => Maybe [Num],
);

has sensitive_fields => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report::Content::ExposedData - XARF report class for exposed data incidents

=head1 VERSION

0.01

=head1 SYNOPSIS

    use XARF::Report::Content::ExposedData;

    my $report = XARF::Report::Content::ExposedData->new(
        # inherited required fields from XARF::Report::Content ...
        data_types            => [ 'email_address', 'password_hash', 'phone_number' ],
        exposure_method       => 'misconfigured_storage',
        affected_organization => 'Example Corp',
        encryption_status     => 'plaintext',
        record_count          => 150_000,
        sensitive_fields      => [ 'ssn', 'credit_card' ],
    );

=head1 DESCRIPTION

C<XARF::Report::Content::ExposedData> represents a data exposure abuse report
in the XARF v4 format. It extends L<XARF::Report::Content> with mandatory
fields for the types of data exposed and the exposure method, plus optional
fields for the affected organisation, encryption status, record count, and
the specific sensitive field names present in the dataset.

=head1 ATTRIBUTES

Inherits all attributes from L<XARF::Report::Content>.

=head2 data_types

    is => 'ro', isa => ArrayRef, required => 1

Array reference listing the categories of data exposed (e.g.
C<email_address>, C<password_hash>, C<phone_number>). Required.

=head2 exposure_method

    is => 'ro', isa => Str, required => 1

Description of how the data was exposed (e.g. C<misconfigured_storage>,
C<sql_injection>). Required.

=head2 affected_organization

    is => 'ro', isa => Maybe[Str]

Name of the organisation whose data was exposed. Optional.

=head2 encryption_status

    is => 'ro', isa => Maybe[Str]

Indicates whether the exposed data is encrypted (e.g. C<plaintext>,
C<encrypted>, C<partial>). Optional.

=head2 record_count

    is => 'ro', isa => Maybe[Num]

The number of individual records included in the exposure. Optional.

=head2 sensitive_fields

    is => 'ro', isa => Maybe[ArrayRef]

Array reference of field names within the dataset that are considered
sensitive (e.g. C<ssn>, C<credit_card>). Optional.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF::Report::Content>, L<XARF::Report>

=cut
