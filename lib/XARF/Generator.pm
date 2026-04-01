package XARF::Generator;

use v5.40;
use Exporter 'import';

our $VERSION   = '0.01';
our @EXPORT_OK = qw(create_report create_evidence);

use Digest::MD5  ();
use Digest::SHA  ();
use Encode       ();
use MIME::Base64 qw(encode_base64);
use POSIX        qw(strftime);

use XARF::Evidence;
use XARF::Report;
use XARF::Result::CreateReport;
use XARF::SchemaValidator;

# Spec version as expected by the schema (no 'v' prefix; matches pattern ^4\.\d+\.\d+$)
our $SPEC_VERSION = '4.2.0';

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

=head2 create_report( %args )

Builds a validated XARF report with auto-generated metadata.

C<xarf_version>, C<report_id>, and C<timestamp> are auto-filled if not
supplied.  All other fields are passed through to schema validation and
report construction.

Required named arguments:

=over 4

=item C<category>

One of the 7 XARF categories (messaging, connection, content, infrastructure,
copyright, vulnerability, reputation).

=item C<type>

The report type within the category (e.g. C<spam>, C<ddos>).

=item C<source_identifier>

IP address, hostname, or other identifier of the source.

=item C<reporter>

Hashref with C<org>, C<contact>, and C<domain>.

=item C<sender>

Hashref with C<org>, C<contact>, and C<domain>.

=back

Optional named arguments:

=over 4

=item C<report_id>

Override the auto-generated UUID v4 report identifier.

=item C<timestamp>

Override the auto-generated ISO 8601 UTC timestamp.

=item C<strict =E<gt> 0|1>

When true, recommended fields are treated as required and unknown fields
become errors.  Defaults to C<0>.

=item C<show_missing_optional =E<gt> 0|1>

When true, the result's C<info> attribute is populated with entries for every
optional and recommended field absent from the report.  Defaults to C<0>.

=item C<evidence>

Arrayref of L<XARF::Evidence> objects or plain hashrefs.  Evidence objects
are serialised via C<to_hashref> before validation.

=back

Returns an L<XARF::Result::CreateReport> object.  The C<report> attribute is
always populated when the category and type are recognisable -- validation
errors are informational, not fatal (mirroring the JavaScript reference
implementation).

=cut

sub create_report {
    my (%args) = @_;

    my $strict       = delete $args{strict}                // 0;
    my $show_missing = delete $args{show_missing_optional} // 0;

    # Serialise any XARF::Evidence objects to plain hashrefs
    if ( my $ev = $args{evidence} ) {
        $args{evidence} = [ map { $_ isa XARF::Evidence ? $_->to_hashref : $_ } @{$ev} ];
    }

    # Auto-fill metadata — caller may override report_id / timestamp
    my $report_href = {
        %args,
        xarf_version => $SPEC_VERSION,
        report_id    => $args{report_id} // _generate_uuid(),
        timestamp    => $args{timestamp} // _current_timestamp(),
    };

    # Validate against JSON schemas
    my $val = XARF::SchemaValidator->instance->validate(
        $report_href,
        strict                => $strict,
        show_missing_optional => $show_missing,
    );

    # Instantiate typed report — always attempt, even when there are errors
    # (mirrors JS createReport which always returns the report object)
    my $report = XARF::Report->from_hashref($report_href);

    my %result_args = (
        report   => $report,
        errors   => $val->{errors},
        warnings => $val->{warnings},
    );
    $result_args{info} = $val->{info} if defined $val->{info};

    return XARF::Result::CreateReport->new(%result_args);
}

=head2 create_evidence( %args )

Creates an L<XARF::Evidence> object with automatic base64 encoding, hashing,
and size calculation.

Required named arguments:

=over 4

=item C<content_type>

MIME type of the evidence (e.g. C<message/rfc822>).

=item C<payload>

The evidence data as a string or raw bytes.  Strings with the Perl UTF-8
internal flag set are encoded to UTF-8 bytes before hashing and base64
encoding.

=back

Optional named arguments:

=over 4

=item C<description>

Human-readable description of the evidence.

=item C<hash_algorithm>

One of C<sha256> (default), C<sha512>, C<sha1>, or C<md5>.

=back

Returns an L<XARF::Evidence> object with C<payload> base64-encoded and C<hash>
set to C<"algorithm:hexdigest">.

=cut

sub create_evidence {
    my (%args) = @_;

    my $content_type = $args{content_type}
        or die "create_evidence: 'content_type' is required\n";
    my $payload = $args{payload};
    defined $payload
        or die "create_evidence: 'payload' is required\n";

    my $algorithm   = $args{hash_algorithm} // 'sha256';
    my $description = $args{description};

    # Always encode to UTF-8 bytes — mirrors JS Buffer.from(payload, 'utf8')
    # Encode::encode treats the scalar as a character string (Latin-1 if no UTF-8
    # flag is set, proper Unicode if the UTF-8 flag is set) and returns raw bytes.
    my $bytes = Encode::encode( 'UTF-8', $payload );

    my $hex_digest = _compute_hash( $bytes, $algorithm );
    my $b64        = encode_base64( $bytes, '' );           # no line breaks
    my $size       = length($bytes);

    return XARF::Evidence->new(
        content_type => $content_type,
        payload      => $b64,
        hash         => "$algorithm:$hex_digest",
        size         => $size,
        defined($description) ? ( description => $description ) : (),
    );
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _generate_uuid {

    # UUID v4: 16 random bytes from /dev/urandom, then set version and variant bits.
    open my $fh, '<:raw', '/dev/urandom'
        or die "Cannot open /dev/urandom: $!\n";
    read $fh, my $raw, 16;
    close $fh;

    my @octets = unpack 'C16', $raw;
    $octets[6] = ( $octets[6] & 0x0f ) | 0x40;    # version 4
    $octets[8] = ( $octets[8] & 0x3f ) | 0x80;    # variant 1

    return sprintf(
        '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x',
        @octets[ 0 .. 3 ],
        @octets[ 4 .. 5 ],
        @octets[ 6 .. 7 ],
        @octets[ 8 .. 9 ],
        @octets[ 10 .. 15 ]
    );
}

sub _current_timestamp {
    return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime );
}

sub _compute_hash {
    my ( $bytes, $algorithm ) = @_;

    if ( $algorithm eq 'sha256' ) {
        return Digest::SHA::sha256_hex($bytes);
    } elsif ( $algorithm eq 'sha512' ) {
        return Digest::SHA::sha512_hex($bytes);
    } elsif ( $algorithm eq 'sha1' ) {
        return Digest::SHA::sha1_hex($bytes);
    } elsif ( $algorithm eq 'md5' ) {
        return Digest::MD5::md5_hex($bytes);
    } else {
        die "create_evidence: unsupported hash_algorithm '$algorithm'"
            . " (must be sha256, sha512, sha1, or md5)\n";
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Generator - Generate validated XARF v4 reports

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF qw(create_report create_evidence);

    # Build an evidence object
    my $ev = create_evidence(
        content_type   => 'message/rfc822',
        payload        => $raw_email,
        description    => 'Original spam email',
        hash_algorithm => 'sha256',    # default
    );

    # Create a validated report
    my $result = create_report(
        category          => 'messaging',
        type              => 'spam',
        source_identifier => '192.0.2.1',
        reporter => { org => 'Example ISP', contact => 'abuse@example.com', domain => 'example.com' },
        sender   => { org => 'Spammer',     contact => 'postmaster@spammer.example', domain => 'spammer.example' },
        protocol => 'smtp',
        evidence => [$ev],
    );

    if ( @{ $result->errors } ) {
        say $_->field . ': ' . $_->message for @{ $result->errors };
    } else {
        my $report = $result->report;   # XARF::Report::Messaging::Spam
        say $report->to_json;
    }

    # Strict mode and optional-field discovery
    my $r2 = create_report(
        %fields,
        strict               => 1,
        show_missing_optional => 1,
    );
    say $_->{field} . ': ' . $_->{message} for @{ $r2->info // [] };

=head1 DESCRIPTION

C<XARF::Generator> is a Perl port of C<generator.ts> from the JavaScript
reference implementation.  It provides two exported functions:

=over 4

=item *

L</create_report> — builds a validated XARF report with auto-generated
metadata (C<xarf_version>, C<report_id>, C<timestamp>).

=item *

L</create_evidence> — creates an L<XARF::Evidence> object with automatic
base64 encoding and hash computation.

=back

Both functions are re-exported by the top-level L<XARF> module, so callers
normally C<use XARF qw(create_report create_evidence)>.

=head1 FUNCTIONS

=head2 create_report

    my $result = create_report( %args );

See L</SYNOPSIS> for usage.  Full parameter documentation is in the function's
POD above.

=head2 create_evidence

    my $evidence = create_evidence( %args );

See L</SYNOPSIS> for usage.  Full parameter documentation is in the function's
POD above.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::Evidence>, L<XARF::Result::CreateReport>,
L<XARF::SchemaValidator>

=cut
