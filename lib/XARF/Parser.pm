package XARF::Parser;

use v5.40;
use Exporter 'import';

our $VERSION   = '0.01';
our @EXPORT_OK = qw(parse);

use JSON::MaybeXS qw(decode_json);

use XARF::ParseError;
use XARF::Report;
use XARF::Result::Parse;
use XARF::SchemaValidator;
use XARF::V3Legacy qw(is_v3_report convert_v3_to_v4 get_v3_deprecation_warning);
use XARF::ValidationWarning;

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

=head2 parse( $json_data, %opts )

Parses a XARF report and returns an L<XARF::Result::Parse> object.

C<$json_data> may be a JSON string or an already-decoded hashref.

Accepted options:

=over 4

=item C<strict =E<gt> 0|1>

When true, C<x-recommended> fields are treated as required and unknown fields
become errors.  Defaults to C<0>.

=item C<show_missing_optional =E<gt> 0|1>

When true, the result's C<info> attribute is populated with an arrayref of
C<< { field => $name, message => $text } >> entries for every optional and
recommended field absent from the report.  Defaults to C<0>.

=back

Dies with L<XARF::ParseError> if C<$json_data> is a string that cannot be
decoded as JSON, or if an auto-detected v3 report cannot be converted (e.g.
unknown C<ReportType> or missing required v3 fields).

=cut

sub parse {
    my ( $json_data, %opts ) = @_;
    my $strict       = $opts{strict}                // 0;
    my $show_missing = $opts{show_missing_optional} // 0;

    # 1. Decode JSON string → hashref
    my $data;
    if ( ref $json_data ) {
        $data = $json_data;
    } else {
        my $ok = eval { $data = decode_json($json_data); 1 };
        unless ($ok) {
            ( my $err = $@ ) =~ s/ at \S+ line \d+.*//s;
            die XARF::ParseError->new( message => "Invalid JSON: $err" );
        }
    }

    # 2. v3 detection and automatic conversion
    my @warnings;
    if ( is_v3_report($data) ) {
        my @conv_strings;
        $data = convert_v3_to_v4( $data, \@conv_strings );

        warn get_v3_deprecation_warning() . "\n";

        push @warnings,
            XARF::ValidationWarning->new(
            field   => '',
            message => get_v3_deprecation_warning(),
            );
        for my $w (@conv_strings) {
            push @warnings, XARF::ValidationWarning->new( field => '', message => $w );
        }
    }

    # 3. Schema validation + unknown-field detection (via SchemaValidator)
    my $val = XARF::SchemaValidator->instance->validate(
        $data,
        strict                => $strict,
        show_missing_optional => $show_missing,
    );
    my @errors = @{ $val->{errors} };
    push @warnings, @{ $val->{warnings} };
    my $info = $val->{info};

    # 4. Instantiate typed report via dispatch table (may return undef for unknown type)
    my $report = XARF::Report->from_hashref($data);

    # 5. Build result
    my %args = (
        report   => $report,
        errors   => \@errors,
        warnings => \@warnings,
    );
    $args{info} = $info if defined $info;

    return XARF::Result::Parse->new(%args);
}

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Parser - Parse XARF v4 (and v3) reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF qw(parse);

    # From a JSON string
    my $result = parse($json_string);

    # From an already-decoded hashref
    my $result = parse($hashref);

    # Strict mode: recommended fields required, unknown fields are errors
    my $result = parse($json_string, strict => 1);

    # Discover missing optional/recommended fields
    my $result = parse($json_string, show_missing_optional => 1);

    # Inspect the result
    if ( @{ $result->errors } ) {
        say "Validation errors:";
        say "  $_->field: $_->message" for @{ $result->errors };
    }
    if ( @{ $result->warnings } ) {
        say "Warnings:";
        say "  $_->message" for @{ $result->warnings };
    }

    my $report = $result->report;   # XARF::Report subclass or undef
    if ( $report && $report->isa('XARF::Report::Messaging::Spam') ) {
        say "Spam from protocol: ", $report->protocol;
    }

    # Type narrowing via category/type attributes
    if ( $report ) {
        say $report->category, '/', $report->type;
    }

=head1 DESCRIPTION

C<XARF::Parser> implements the XARF report parser.  It is a Perl port of
C<parser.ts> from the JavaScript reference implementation.

The C<parse()> function is the sole public entry point.  It accepts a JSON
string or a pre-decoded hashref, auto-detects and converts XARF v3 reports,
validates the data against the official JSON schemas via
L<XARF::SchemaValidator>, and returns a typed L<XARF::Report> subclass
wrapped in an L<XARF::Result::Parse> object.

Validation errors and warnings are always returned in the result object rather
than thrown as exceptions.  The only exception thrown by this function is
L<XARF::ParseError>, which covers truly unrecoverable situations: malformed
JSON input, and v3 reports that cannot be mapped to a v4 type.

=head1 FUNCTIONS

=head2 parse

    my $result = parse( $json_data, %opts );

See the L</SYNOPSIS> for usage examples.  The function is exported on request;
it is also re-exported by the top-level L<XARF> module.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::Result::Parse>, L<XARF::SchemaValidator>, L<XARF::V3Legacy>

=cut
