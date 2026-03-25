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

1;

__END__

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
    }
    else {
        my $report = $result->report;
        say $report->to_json;
    }

=head1 DESCRIPTION

C<XARF::Result::CreateReport> is the value returned by L<XARF/create_report>.
It has the same shape as L<XARF::Result::Parse> but without the C<info>
attribute (optional-field discovery is a parsing-time concept).

A successful creation has an empty C<errors> list and a fully-populated
C<report>. A failed creation has one or more entries in C<errors> and
C<report> is C<undef>.

=head1 ATTRIBUTES

=head2 report

An L<XARF::Report> subclass instance, or C<undef> if creation failed.

=head2 errors

An arrayref of L<XARF::ValidationError> objects. Empty on success.

=head2 warnings

An arrayref of L<XARF::ValidationWarning> objects. May be non-empty even on
success (e.g. when recommended fields were not supplied).

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::Result::Parse>, L<XARF::ValidationError>,
L<XARF::ValidationWarning>

=cut
