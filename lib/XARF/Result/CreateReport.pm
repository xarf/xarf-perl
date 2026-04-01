package XARF::Result::CreateReport;

use v5.40;
use Moo;

our $VERSION = '0.01';

has report => ( is => 'ro', );

has errors => (
    is      => 'ro',
    default => sub { [] },
);

has warnings => (
    is      => 'ro',
    default => sub { [] },
);

has info => ( is => 'ro', );

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Result::CreateReport - Result object returned by XARF::create_report()

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF qw(create_report);

    my $result = create_report(
        category          => 'messaging',
        type              => 'spam',
        source_identifier => '192.0.2.1',
        reporter          => { org => 'Example', contact => 'abuse@example.com', domain => 'example.com' },
        sender            => { org => 'Sender',  contact => 'abuse@sender.com',  domain => 'sender.com' },
    );

    if ( @{ $result->errors } ) {
        for my $err ( @{ $result->errors } ) {
            say $err->field . ': ' . $err->message;
        }
    } else {
        my $report = $result->report;
        say $report->to_json;
    }

    # Optional-field discovery
    my $result2 = create_report( %fields, show_missing_optional => 1 );
    for my $item ( @{ $result2->info // [] } ) {
        say $item->{field} . ': ' . $item->{message};
    }

=head1 DESCRIPTION

C<XARF::Result::CreateReport> is the value returned by L<XARF/create_report>.
It has the same shape as L<XARF::Result::Parse>, including the optional C<info>
attribute populated when C<show_missing_optional =E<gt> 1> is passed.

Unlike the parse path, C<report> is always populated when the category and type
are recognisable — validation errors are informational and do not suppress the
report object.  This mirrors the behaviour of the JavaScript reference
implementation's C<createReport()>.

=head1 ATTRIBUTES

=head2 report

An L<XARF::Report> subclass instance, or C<undef> if the category/type could
not be resolved (e.g. completely unknown type).

=head2 errors

An arrayref of L<XARF::ValidationError> objects. Empty on success.

=head2 warnings

An arrayref of L<XARF::ValidationWarning> objects. May be non-empty even on
success (e.g. when recommended fields were not supplied).

=head2 info

An arrayref of optional-field metadata hashrefs, or C<undef>.  Populated when
C<show_missing_optional =E<gt> 1> is passed to L<XARF/create_report>.  Each
entry is a plain hashref with C<field> and C<message> keys.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::Result::Parse>, L<XARF::ValidationError>,
L<XARF::ValidationWarning>

=cut
