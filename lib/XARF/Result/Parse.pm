package XARF::Result::Parse;

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

=head1 NAME

XARF::Result::Parse - Result object returned by XARF::parse()

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF qw(parse);

    my $result = parse($json_string);

    if ( @{ $result->errors } ) {
        for my $err ( @{ $result->errors } ) {
            say $err->field . ': ' . $err->message;
        }
    }
    else {
        my $report = $result->report;
    }

    for my $warn ( @{ $result->warnings } ) {
        say 'Warning: ' . $warn->message;
    }

=head1 DESCRIPTION

C<XARF::Result::Parse> is the value returned by L<XARF/parse>. It bundles the
parsed report object together with any validation errors and warnings collected
during parsing, allowing callers to inspect all problems at once.

A successful parse has an empty C<errors> list and a defined C<report>.
A failed parse has one or more entries in C<errors> and C<report> is C<undef>.

=head1 ATTRIBUTES

=head2 report

An L<XARF::Report> subclass instance, or C<undef> if parsing failed. The
concrete subclass depends on the report's category and type
(e.g. L<XARF::Report::Messaging::Spam>).

=head2 errors

An arrayref of L<XARF::ValidationError> objects. Empty on success.

=head2 warnings

An arrayref of L<XARF::ValidationWarning> objects. May be non-empty even on
success (e.g. when recommended fields are absent).

=head2 info

A hashref of optional-field metadata, or C<undef>. Populated when
C<show_missing_optional> is enabled in the parser.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::Result::CreateReport>, L<XARF::ValidationError>,
L<XARF::ValidationWarning>

=cut
