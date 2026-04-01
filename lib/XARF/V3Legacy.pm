package XARF::V3Legacy;

use v5.40;
use Exporter 'import';

our $VERSION   = '0.01';
our @EXPORT_OK = qw(is_v3_report convert_v3_to_v4 get_v3_deprecation_warning);

use Digest::SHA  qw(sha256_hex);
use MIME::Base64 qw(decode_base64);

use XARF::ParseError;

# ---------------------------------------------------------------------------
# v3 → v4 type mapping (mirrors JS V3_TYPE_MAPPING exactly — 16 entries)
# ---------------------------------------------------------------------------

my %V3_TYPE_MAP = (
    'Spam'         => { category => 'messaging',      type => 'spam' },
    'spam'         => { category => 'messaging',      type => 'spam' },
    'Login-Attack' => { category => 'connection',     type => 'login_attack' },
    'login-attack' => { category => 'connection',     type => 'login_attack' },
    'Port-Scan'    => { category => 'connection',     type => 'port_scan' },
    'port-scan'    => { category => 'connection',     type => 'port_scan' },
    'DDoS'         => { category => 'connection',     type => 'ddos' },
    'ddos'         => { category => 'connection',     type => 'ddos' },
    'Phishing'     => { category => 'content',        type => 'phishing' },
    'phishing'     => { category => 'content',        type => 'phishing' },
    'Malware'      => { category => 'content',        type => 'malware' },
    'malware'      => { category => 'content',        type => 'malware' },
    'Botnet'       => { category => 'infrastructure', type => 'botnet' },
    'botnet'       => { category => 'infrastructure', type => 'botnet' },
    'Copyright'    => { category => 'copyright',      type => 'copyright' },
    'copyright'    => { category => 'copyright',      type => 'copyright' },
);

# ---------------------------------------------------------------------------
# Public functions
# ---------------------------------------------------------------------------

=head2 is_v3_report( $data )

Returns true if C<$data> (a hashref decoded from JSON) looks like an XARF v3
report.  Checks for the presence of C<Version>, C<ReporterInfo>, and C<Report>
keys with a version string of C<"3">, C<"3.0">, or C<"3.0.0">.

=cut

sub is_v3_report {
    my ($data) = @_;
    return unless ref($data) eq 'HASH';
    return
           unless exists $data->{Version}
        && defined $data->{Version}
        && $data->{Version} =~ /^3(?:\.0(?:\.0)?)?$/;
    return exists $data->{ReporterInfo} && exists $data->{Report};
}

=head2 convert_v3_to_v4( $v3_data, \@warnings )

Converts a decoded XARF v3 report hashref to a v4 report hashref.  Any
non-fatal conversion warnings (plain strings) are pushed onto C<\@warnings>.

Dies with L<XARF::ParseError> if the report cannot be converted (for example
when the C<ReportType> is not one of the 8 supported v3 types, or when
required source/reporter fields are missing).

=cut

sub convert_v3_to_v4 {
    my ( $v3, $warnings ) = @_;
    $warnings //= [];

    my $report_block = $v3->{Report}
        or die XARF::ParseError->new( message => 'Cannot convert v3 report: missing Report block' );
    my $reporter_block = $v3->{ReporterInfo}
        or die XARF::ParseError->new(
        message => 'Cannot convert v3 report: missing ReporterInfo block' );

    my $report_type = $report_block->{ReportType} // '';
    my $mapping     = $V3_TYPE_MAP{$report_type}
        or die XARF::ParseError->new(
              message => "Cannot convert v3 report: unknown ReportType '$report_type'. "
            . 'Supported types: '
            . join( ', ', sort keys %V3_TYPE_MAP ) );

    my $source_id = _extract_source_identifier($report_block);
    my $contact   = _extract_contact_info( $reporter_block, $warnings );
    my $evidence
        = _convert_evidence( $report_block->{Attachment} // $report_block->{Samples}, $warnings );

    my %v4 = (
        xarf_version      => '4.2.0',
        report_id         => _new_uuid(),
        timestamp         => $report_block->{Date},
        reporter          => $contact,
        sender            => $contact,
        source_identifier => $source_id,
        category          => $mapping->{category},
        type              => $mapping->{type},
        legacy_version    => '3',
        _internal         => {
            original_report_type => $report_type,
            converted_at         => _now_iso8601(),
        },
    );

    $v4{description} = $report_block->{AttackDescription}
        if defined $report_block->{AttackDescription};

    $v4{evidence} = $evidence if defined $evidence;

    my $evidence_source
        = $report_block->{AdditionalInfo} && $report_block->{AdditionalInfo}{DetectionMethod};
    $v4{evidence_source} = $evidence_source if $evidence_source;

    _add_category_fields( \%v4, $mapping->{category}, $report_block );

    return \%v4;
}

=head2 get_v3_deprecation_warning

Returns the standard deprecation warning string emitted whenever a v3 report
is automatically converted to v4.

=cut

sub get_v3_deprecation_warning {
    return join( ' ',
        'DEPRECATION WARNING: XARF v3 format detected.',
        'The v3 format has been automatically converted to v4.',
        'Please update your systems to generate v4 reports directly.',
        'v3 support will be removed in a future major version.',
    );
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

sub _extract_source_identifier {
    my ($report) = @_;
    return $report->{Source}{IP}  if ref( $report->{Source} ) && $report->{Source}{IP};
    return $report->{SourceIp}    if $report->{SourceIp};
    return $report->{Source}{URL} if ref( $report->{Source} ) && $report->{Source}{URL};
    return $report->{Url}         if $report->{Url};
    die XARF::ParseError->new(
        message => 'Cannot convert v3 report: no source identifier found '
            . '(expected Source.IP, SourceIp, Source.URL, or Url)' );
}

sub _extract_contact_info {
    my ( $reporter, $warnings ) = @_;

    my $contact = $reporter->{ReporterContactEmail} // $reporter->{ReporterOrgEmail}
        or die XARF::ParseError->new(
        message => 'Cannot convert v3 report: missing reporter email '
            . '(ReporterContactEmail and ReporterOrgEmail are both absent)' );

    my ($domain) = $contact =~ /\@(.+)$/;
    die XARF::ParseError->new( message => "Cannot convert v3 report: reporter email '$contact' "
            . 'is not a valid email address' )
        unless $domain;

    my $org = $reporter->{ReporterOrg};
    unless ($org) {
        push @$warnings, 'No ReporterOrg found in v3 report, using "Unknown Organization"';
        $org = 'Unknown Organization';
    }

    return { org => $org, contact => $contact, domain => $domain };
}

sub _convert_evidence {
    my ( $attachments, $warnings ) = @_;
    return unless ref($attachments) eq 'ARRAY' && @$attachments;

    my @evidence;
    for my $att (@$attachments) {
        unless ( $att->{Description} ) {
            push @$warnings, 'Evidence attachment has no description, omitting field';
        }
        my $raw  = eval { decode_base64( $att->{Data} ) } // '';
        my $hash = sha256_hex($raw);
        my $size = length($raw);

        my %item = (
            content_type => $att->{ContentType},
            payload      => $att->{Data},
            hash         => "sha256:$hash",
            size         => $size,
        );
        $item{description} = $att->{Description} if $att->{Description};
        push @evidence, \%item;
    }
    return \@evidence;
}

sub _add_category_fields {
    my ( $v4, $category, $report ) = @_;
    if ( $category eq 'messaging' ) {
        _add_messaging_fields( $v4, $report );
    } elsif ( $category eq 'connection' ) {
        _add_connection_fields( $v4, $report );
    } elsif ( $category eq 'content' ) {
        _add_content_fields( $v4, $report );
    }
    return;
}

sub _add_messaging_fields {
    my ( $v4, $report ) = @_;

    my $protocol = $report->{Protocol}
        // ( ref( $report->{AdditionalInfo} ) && $report->{AdditionalInfo}{Protocol} )
        or die XARF::ParseError->new(
        message => 'Cannot convert v3 report: missing protocol for messaging type' );

    $v4->{protocol} = $protocol;

    my $smtp_from = $report->{SmtpMailFromAddress}
        // ( ref( $report->{AdditionalInfo} ) && $report->{AdditionalInfo}{SMTPFrom} );
    $v4->{smtp_from} = $smtp_from if $smtp_from;

    $v4->{smtp_to} = $report->{SmtpRcptToAddress} if $report->{SmtpRcptToAddress};

    my $subject = $report->{SmtpMessageSubject}
        // ( ref( $report->{AdditionalInfo} ) && $report->{AdditionalInfo}{Subject} );
    $v4->{subject} = $subject if $subject;

    my $src_port;
    $src_port = $report->{Source}{Port} if ref( $report->{Source} );
    $src_port //= $report->{SourcePort};
    $v4->{source_port} = $src_port if defined $src_port;

    return;
}

sub _add_connection_fields {
    my ( $v4, $report ) = @_;

    $report->{Protocol}
        or die XARF::ParseError->new(
        message => 'Cannot convert v3 report: missing protocol for connection type' );

    $v4->{protocol}   = $report->{Protocol};
    $v4->{first_seen} = $report->{Date};       # required for connection types in v4

    $v4->{destination_ip}   = $report->{DestinationIp}   if $report->{DestinationIp};
    $v4->{destination_port} = $report->{DestinationPort} if defined $report->{DestinationPort};

    my $src_port;
    $src_port = $report->{Source}{Port} if ref( $report->{Source} );
    $src_port //= $report->{SourcePort};
    $v4->{source_port} = $src_port if defined $src_port;

    # AttackCount has no direct v4 equivalent; pass through as additional property
    $v4->{attack_count} = $report->{AttackCount} if defined $report->{AttackCount};

    return;
}

sub _add_content_fields {
    my ( $v4, $report ) = @_;

    my $url = $report->{Url}
        || ( ref( $report->{AdditionalInfo} ) && $report->{AdditionalInfo}{URL} )
        || ( ref( $report->{Source} )         && $report->{Source}{URL} )
        or die XARF::ParseError->new(
        message => "Cannot convert v3 report: missing URL for content type '$v4->{type}'. "
            . 'Content reports require a URL field' );

    $v4->{url} = $url;
    return;
}

# Generate a UUID v4 string from /dev/urandom, matching the approach used in
# XARF::Generator.  No external dependencies required.
sub _new_uuid {
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

sub _now_iso8601 {
    my @t = gmtime;
    return sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ',
        $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0];
}

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::V3Legacy - XARF v3 backward compatibility and conversion

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF::V3Legacy qw(is_v3_report convert_v3_to_v4 get_v3_deprecation_warning);

    if ( is_v3_report($data) ) {
        my @warnings;
        $data = convert_v3_to_v4($data, \@warnings);
        warn get_v3_deprecation_warning() . "\n";
    }

=head1 DESCRIPTION

C<XARF::V3Legacy> provides backward compatibility with the legacy XARF v3
report format.  It can detect v3 reports and automatically convert them to
the current XARF v4 format.

Conversion is a best-effort mapping: 8 v3 C<ReportType> values (16 dict
entries, case-variant pairs) are supported.  Fatal conversion failures die
with L<XARF::ParseError>; minor issues such as a missing C<ReporterOrg> or
evidence attachments without descriptions are collected as plain strings via
the C<\@warnings> arrayref argument.

This module is a Perl port of C<v3-legacy.ts> from the JavaScript reference
implementation.

=head1 FUNCTIONS

All functions are exportable via C<@EXPORT_OK>.

=head2 is_v3_report( $data )

    if ( is_v3_report($decoded_hashref) ) { ... }

Returns true (1) when C<$data> contains the three structural markers of an
XARF v3 report: a C<Version> key equal to C<"3">, C<"3.0">, or C<"3.0.0">,
plus C<ReporterInfo> and C<Report> keys.

=head2 convert_v3_to_v4( $v3_data, \@warnings )

    my @warnings;
    my $v4 = convert_v3_to_v4($v3_hashref, \@warnings);

Converts a decoded XARF v3 report hashref to a v4 hashref.  Non-fatal
conversion notes are pushed onto C<\@warnings> as plain strings.

Supported C<ReportType> values (case-insensitive pairs):
C<Spam>, C<Login-Attack>, C<Port-Scan>, C<DDoS>, C<Phishing>, C<Malware>,
C<Botnet>, C<Copyright>.

Dies with L<XARF::ParseError> for:

=over 4

=item * Unknown C<ReportType>

=item * Missing C<Report> or C<ReporterInfo> blocks

=item * No usable source identifier (C<Source.IP>, C<SourceIp>, C<Source.URL>, C<Url>)

=item * No reporter email (C<ReporterContactEmail> and C<ReporterOrgEmail> both absent)

=item * Missing C<Protocol> for messaging or connection types

=item * Missing C<Url> for content types

=back

=head2 get_v3_deprecation_warning

    my $msg = get_v3_deprecation_warning();

Returns the standard multi-sentence deprecation warning string that should be
emitted (via C<warn>) whenever a v3 report is auto-converted.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::Parser>, L<XARF::ParseError>

=cut
