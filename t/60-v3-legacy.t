use v5.40;
use Test2::V0;

use MIME::Base64 qw(decode_base64);
use Digest::SHA  qw(sha256_hex);

use XARF::V3Legacy qw(is_v3_report convert_v3_to_v4 get_v3_deprecation_warning);
use XARF::ParseError;

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# Minimal reporter block — no ReporterOrg so tests that need org control it
# explicitly.
sub _reporter {
    my (%extra) = @_;
    return {
        ReporterOrg      => 'Test Org',
        ReporterOrgEmail => 'abuse@test.example',
        %extra,
    };
}

# Build a minimal v3 report with the given Report-block fields.
sub _make_v3 {
    my (%report_fields) = @_;
    return {
        Version      => '3',
        ReporterInfo => _reporter(),
        Report       => {
            Date => '2024-01-15T10:00:00Z',
            %report_fields,
        },
    };
}

# Minimal valid fixtures per category (provide exactly the fields the
# implementation requires — no more, so tests stay focused).
sub _spam_v3 {
    _make_v3( ReportType => 'Spam',    SourceIp => '192.0.2.1', Protocol => 'smtp' );
}
sub _ddos_v3 {
    _make_v3( ReportType => 'DDoS',    SourceIp => '192.0.2.1', Protocol => 'tcp'  );
}
sub _phishing_v3 {
    _make_v3( ReportType => 'Phishing', SourceIp => '192.0.2.1', Url => 'http://evil.example/' );
}
sub _botnet_v3 {
    _make_v3( ReportType => 'Botnet',  SourceIp => '192.0.2.1' );
}
sub _copyright_v3 {
    _make_v3( ReportType => 'Copyright', SourceIp => '192.0.2.1' );
}

# UUID v4 regex: 8-4-4-4-12 lower-hex, version nibble 4, variant bits 8/9/a/b
my $UUID_RE = qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

# ISO 8601 UTC timestamp regex (the format produced by _now_iso8601)
my $ISO8601_RE = qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;

# ---------------------------------------------------------------------------
# is_v3_report()
# ---------------------------------------------------------------------------

subtest 'is_v3_report: version "3" detected' => sub {
    my $r = { Version => '3', ReporterInfo => {}, Report => {} };
    ok( is_v3_report($r), 'Version "3" is recognised' );
};

subtest 'is_v3_report: version "3.0" detected' => sub {
    my $r = { Version => '3.0', ReporterInfo => {}, Report => {} };
    ok( is_v3_report($r), 'Version "3.0" is recognised' );
};

subtest 'is_v3_report: version "3.0.0" detected' => sub {
    my $r = { Version => '3.0.0', ReporterInfo => {}, Report => {} };
    ok( is_v3_report($r), 'Version "3.0.0" is recognised' );
};

subtest 'is_v3_report: version "4.0.0" not detected' => sub {
    my $r = { Version => '4.0.0', ReporterInfo => {}, Report => {} };
    ok( !is_v3_report($r), 'Version "4.0.0" is not v3' );
};

subtest 'is_v3_report: missing Version key returns false' => sub {
    my $r = { ReporterInfo => {}, Report => {} };
    ok( !is_v3_report($r), 'no Version key → false' );
};

subtest 'is_v3_report: missing ReporterInfo returns false' => sub {
    my $r = { Version => '3', Report => {} };
    ok( !is_v3_report($r), 'no ReporterInfo key → false' );
};

subtest 'is_v3_report: missing Report key returns false' => sub {
    my $r = { Version => '3', ReporterInfo => {} };
    ok( !is_v3_report($r), 'no Report key → false' );
};

subtest 'is_v3_report: non-hashref (arrayref) returns false' => sub {
    ok( !is_v3_report( [] ), 'arrayref → false' );
};

subtest 'is_v3_report: non-hashref (undef) returns false' => sub {
    ok( !is_v3_report(undef), 'undef → false' );
};

subtest 'is_v3_report: empty hashref returns false' => sub {
    ok( !is_v3_report( {} ), 'empty hashref → false' );
};

# ---------------------------------------------------------------------------
# get_v3_deprecation_warning()
# ---------------------------------------------------------------------------

subtest 'get_v3_deprecation_warning: contains expected phrases' => sub {
    my $w = get_v3_deprecation_warning();
    like( $w, qr/DEPRECATION WARNING/,   'contains "DEPRECATION WARNING"' );
    like( $w, qr/v3 format/,             'contains "v3 format"' );
    like( $w, qr/converted to v4/,       'contains "converted to v4"' );
    like( $w, qr/future major version/,  'contains "future major version"' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — type mapping (all 8 types × both case variants)
# ---------------------------------------------------------------------------
#
# The extra fields per category are the minimum required by the conversion:
#   messaging    → Protocol (direct in Report block)
#   connection   → Protocol (direct in Report block)
#   content      → Url
#   infrastructure / copyright → no extra fields

my %_CATEGORY_EXTRAS = (
    messaging      => { SourceIp => '192.0.2.1', Protocol => 'smtp' },
    connection     => { SourceIp => '192.0.2.1', Protocol => 'tcp'  },
    content        => { SourceIp => '192.0.2.1', Url => 'http://evil.example/' },
    infrastructure => { SourceIp => '192.0.2.1' },
    copyright      => { SourceIp => '192.0.2.1' },
);

my @TYPE_CASES = (
    [ 'Spam',         'messaging',      'spam'        ],
    [ 'spam',         'messaging',      'spam'        ],
    [ 'Login-Attack', 'connection',     'login_attack' ],
    [ 'login-attack', 'connection',     'login_attack' ],
    [ 'Port-Scan',    'connection',     'port_scan'   ],
    [ 'port-scan',    'connection',     'port_scan'   ],
    [ 'DDoS',         'connection',     'ddos'        ],
    [ 'ddos',         'connection',     'ddos'        ],
    [ 'Phishing',     'content',        'phishing'    ],
    [ 'phishing',     'content',        'phishing'    ],
    [ 'Malware',      'content',        'malware'     ],
    [ 'malware',      'content',        'malware'     ],
    [ 'Botnet',       'infrastructure', 'botnet'      ],
    [ 'botnet',       'infrastructure', 'botnet'      ],
    [ 'Copyright',    'copyright',      'copyright'   ],
    [ 'copyright',    'copyright',      'copyright'   ],
);

subtest 'type mapping — all 8 types, both case variants (16 entries)' => sub {
    for my $case (@TYPE_CASES) {
        my ( $report_type, $expected_cat, $expected_type ) = @$case;
        subtest "ReportType '$report_type' → $expected_cat/$expected_type" => sub {
            my $v3 = _make_v3(
                ReportType => $report_type,
                %{ $_CATEGORY_EXTRAS{$expected_cat} },
            );
            my $v4 = convert_v3_to_v4($v3);
            is( $v4->{category}, $expected_cat,   'category' );
            is( $v4->{type},     $expected_type,  'type'     );
        };
    }
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — core v4 fields
# ---------------------------------------------------------------------------

subtest 'core fields: xarf_version is 4.2.0' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    is( $v4->{xarf_version}, '4.2.0', 'xarf_version' );
};

subtest 'core fields: report_id is a UUID v4' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    like( $v4->{report_id}, $UUID_RE, 'report_id looks like UUID v4' );
};

subtest 'core fields: report_id is unique across calls' => sub {
    my $a = convert_v3_to_v4( _spam_v3() );
    my $b = convert_v3_to_v4( _spam_v3() );
    isnt( $a->{report_id}, $b->{report_id}, 'each call gets a distinct report_id' );
};

subtest 'core fields: timestamp comes from v3 Date' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    is( $v4->{timestamp}, '2024-01-15T10:00:00Z', 'timestamp' );
};

subtest 'core fields: legacy_version is "3"' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    is( $v4->{legacy_version}, '3', 'legacy_version' );
};

subtest 'core fields: description from AttackDescription when present' => sub {
    my $v3 = _make_v3(
        ReportType        => 'Spam',
        SourceIp          => '192.0.2.1',
        Protocol          => 'smtp',
        AttackDescription => 'Bulk email campaign',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{description}, 'Bulk email campaign', 'description' );
};

subtest 'core fields: description absent when AttackDescription not present' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    ok( !exists $v4->{description}, 'description key absent when not in v3' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — _internal marker
# ---------------------------------------------------------------------------

subtest '_internal: marker is a hashref' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    ok( ref( $v4->{_internal} ) eq 'HASH', '_internal is a hashref' );
};

subtest '_internal: original_report_type matches v3 ReportType' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    is( $v4->{_internal}{original_report_type}, 'Spam', 'original_report_type' );
};

subtest '_internal: lowercase variant preserves original casing in original_report_type' => sub {
    my $v3 = _make_v3( ReportType => 'spam', SourceIp => '192.0.2.1', Protocol => 'smtp' );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{_internal}{original_report_type}, 'spam', 'lowercase variant preserved' );
};

subtest '_internal: converted_at is an ISO 8601 UTC timestamp' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    like( $v4->{_internal}{converted_at}, $ISO8601_RE, 'converted_at is ISO 8601' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — reporter / sender contact extraction
# ---------------------------------------------------------------------------

subtest 'contact: org from ReporterOrg' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    is( $v4->{reporter}{org},     'Test Org',         'reporter.org' );
    is( $v4->{sender}{org},       'Test Org',         'sender.org'   );
};

subtest 'contact: ReporterContactEmail preferred over ReporterOrgEmail' => sub {
    my $v3 = _make_v3( ReportType => 'Spam', SourceIp => '192.0.2.1', Protocol => 'smtp' );
    $v3->{ReporterInfo}{ReporterContactEmail} = 'contact@test.example';
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{reporter}{contact}, 'contact@test.example', 'contact from ReporterContactEmail' );
};

subtest 'contact: falls back to ReporterOrgEmail when no ReporterContactEmail' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    is( $v4->{reporter}{contact}, 'abuse@test.example', 'contact from ReporterOrgEmail' );
};

subtest 'contact: domain extracted from email' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    is( $v4->{reporter}{domain}, 'test.example', 'domain' );
};

subtest 'contact: reporter and sender carry the same contact data' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    is( $v4->{reporter}{org},     $v4->{sender}{org},     'org matches'     );
    is( $v4->{reporter}{contact}, $v4->{sender}{contact}, 'contact matches' );
    is( $v4->{reporter}{domain},  $v4->{sender}{domain},  'domain matches'  );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — source identifier extraction
# ---------------------------------------------------------------------------

subtest 'source_identifier: from Source.IP (highest priority)' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        Protocol   => 'smtp',
        Source     => { IP => '10.0.0.1', URL => 'http://other.example/' },
        SourceIp   => '192.0.2.99',
        Url        => 'http://yet-another.example/',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{source_identifier}, '10.0.0.1', 'Source.IP wins' );
};

subtest 'source_identifier: from SourceIp when no Source.IP' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        Protocol   => 'smtp',
        SourceIp   => '192.0.2.50',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{source_identifier}, '192.0.2.50', 'SourceIp used' );
};

subtest 'source_identifier: from Source.URL when no IP fields' => sub {
    my $v3 = _make_v3(
        ReportType => 'Phishing',
        Source     => { URL => 'https://evil.example/login' },
        Url        => 'https://evil.example/login',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{source_identifier}, 'https://evil.example/login', 'Source.URL used' );
};

subtest 'source_identifier: from top-level Url when nothing else present' => sub {
    my $v3 = _make_v3(
        ReportType => 'Malware',
        Url        => 'http://malware.example/payload.exe',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{source_identifier}, 'http://malware.example/payload.exe', 'Url used' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — warning emission
# ---------------------------------------------------------------------------

subtest 'warnings: missing ReporterOrg pushes warning and uses fallback org' => sub {
    my $v3 = _make_v3( ReportType => 'Spam', SourceIp => '192.0.2.1', Protocol => 'smtp' );
    delete $v3->{ReporterInfo}{ReporterOrg};

    my @warnings;
    my $v4 = convert_v3_to_v4( $v3, \@warnings );

    ok( scalar(@warnings) > 0, 'at least one warning' );
    ok( ( grep { /No ReporterOrg found/ } @warnings ), 'warning mentions ReporterOrg' );
    is( $v4->{reporter}{org}, 'Unknown Organization', 'org falls back to "Unknown Organization"' );
};

subtest 'warnings: attachment without description pushes warning' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        SourceIp   => '192.0.2.1',
        Protocol   => 'smtp',
        Attachment => [
            { ContentType => 'message/rfc822', Data => 'aGVsbG8=' },    # no Description
        ],
    );
    my @warnings;
    convert_v3_to_v4( $v3, \@warnings );

    ok( ( grep { /no description/ } @warnings ), 'warning about missing description' );
};

subtest 'warnings: no warnings when all optional fields present' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        SourceIp   => '192.0.2.1',
        Protocol   => 'smtp',
        Attachment => [
            {   ContentType => 'message/rfc822',
                Description => 'Test',
                Data        => 'aGVsbG8=',
            },
        ],
    );
    my @warnings;
    convert_v3_to_v4( $v3, \@warnings );
    is( scalar(@warnings), 0, 'no warnings' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — evidence conversion
# ---------------------------------------------------------------------------

# Known payload: base64('hello') = 'aGVsbG8='
# sha256('hello') = 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
my $_HELLO_B64    = 'aGVsbG8=';
my $_HELLO_SHA256 = '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
my $_HELLO_SIZE   = length( decode_base64($_HELLO_B64) );    # 5

subtest 'evidence: Attachment converted to evidence array' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        SourceIp   => '192.0.2.1',
        Protocol   => 'smtp',
        Attachment => [
            {   ContentType => 'message/rfc822',
                Description => 'Original spam message',
                Data        => $_HELLO_B64,
            },
        ],
    );
    my $v4  = convert_v3_to_v4($v3);
    my $evi = $v4->{evidence};

    ok( ref($evi) eq 'ARRAY',      'evidence is an arrayref'   );
    is( scalar(@$evi), 1,          'one evidence item'          );
    is( $evi->[0]{content_type}, 'message/rfc822', 'content_type' );
    is( $evi->[0]{payload},      $_HELLO_B64,      'payload'      );
    is( $evi->[0]{description},  'Original spam message', 'description' );
    is( $evi->[0]{hash},  "sha256:$_HELLO_SHA256", 'hash is sha256 of decoded bytes' );
    is( $evi->[0]{size},  $_HELLO_SIZE,             'size is byte count of decoded payload' );
};

subtest 'evidence: Samples used when no Attachment present' => sub {
    my $v3 = _make_v3(
        ReportType => 'Malware',
        SourceIp   => '192.0.2.1',
        Url        => 'http://malware.example/',
        Samples    => [
            { ContentType => 'application/octet-stream', Data => $_HELLO_B64 },
        ],
    );
    my $v4  = convert_v3_to_v4($v3);
    my $evi = $v4->{evidence};

    ok( ref($evi) eq 'ARRAY', 'evidence from Samples' );
    is( $evi->[0]{content_type}, 'application/octet-stream', 'content_type from Samples' );
};

subtest 'evidence: description key absent when attachment has no description' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        SourceIp   => '192.0.2.1',
        Protocol   => 'smtp',
        Attachment => [
            { ContentType => 'text/plain', Data => $_HELLO_B64 },
        ],
    );
    my @warnings;
    my $v4 = convert_v3_to_v4( $v3, \@warnings );

    ok( !exists $v4->{evidence}[0]{description}, 'description key absent' );
};

subtest 'evidence: absent when neither Attachment nor Samples present' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    ok( !defined $v4->{evidence}, 'evidence undef when no attachments' );
};

subtest 'evidence: multiple attachments all converted' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        SourceIp   => '192.0.2.1',
        Protocol   => 'smtp',
        Attachment => [
            { ContentType => 'text/plain', Description => 'First',  Data => $_HELLO_B64 },
            { ContentType => 'text/plain', Description => 'Second', Data => $_HELLO_B64 },
        ],
    );
    my $v4 = convert_v3_to_v4($v3);
    is( scalar( @{ $v4->{evidence} } ), 2, 'two evidence items' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — messaging category-specific fields
# ---------------------------------------------------------------------------

subtest 'messaging: protocol from Report.Protocol directly' => sub {
    my $v3 = _make_v3( ReportType => 'Spam', SourceIp => '192.0.2.1', Protocol => 'smtp' );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{protocol}, 'smtp', 'protocol from direct field' );
};

subtest 'messaging: protocol falls back to AdditionalInfo.Protocol' => sub {
    my $v3 = _make_v3(
        ReportType     => 'Spam',
        SourceIp       => '192.0.2.1',
        AdditionalInfo => { Protocol => 'nntp' },
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{protocol}, 'nntp', 'protocol from AdditionalInfo' );
};

subtest 'messaging: smtp_from from SmtpMailFromAddress' => sub {
    my $v3 = _make_v3(
        ReportType          => 'Spam',
        SourceIp            => '192.0.2.1',
        Protocol            => 'smtp',
        SmtpMailFromAddress => 'spammer@evil.example',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{smtp_from}, 'spammer@evil.example', 'smtp_from' );
};

subtest 'messaging: smtp_from falls back to AdditionalInfo.SMTPFrom' => sub {
    my $v3 = _make_v3(
        ReportType     => 'Spam',
        SourceIp       => '192.0.2.1',
        Protocol       => 'smtp',
        AdditionalInfo => { SMTPFrom => 'bulk@other.example' },
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{smtp_from}, 'bulk@other.example', 'smtp_from from AdditionalInfo' );
};

subtest 'messaging: smtp_to from SmtpRcptToAddress' => sub {
    my $v3 = _make_v3(
        ReportType         => 'Spam',
        SourceIp           => '192.0.2.1',
        Protocol           => 'smtp',
        SmtpRcptToAddress  => 'victim@example.com',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{smtp_to}, 'victim@example.com', 'smtp_to' );
};

subtest 'messaging: subject from SmtpMessageSubject' => sub {
    my $v3 = _make_v3(
        ReportType         => 'Spam',
        SourceIp           => '192.0.2.1',
        Protocol           => 'smtp',
        SmtpMessageSubject => 'Buy now!',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{subject}, 'Buy now!', 'subject' );
};

subtest 'messaging: subject falls back to AdditionalInfo.Subject' => sub {
    my $v3 = _make_v3(
        ReportType     => 'Spam',
        SourceIp       => '192.0.2.1',
        Protocol       => 'smtp',
        AdditionalInfo => { Subject => 'Get rich quick' },
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{subject}, 'Get rich quick', 'subject from AdditionalInfo' );
};

subtest 'messaging: source_port from Source.Port' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        Protocol   => 'smtp',
        Source     => { IP => '192.0.2.1', Port => 25 },
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{source_port}, 25, 'source_port from Source.Port' );
};

subtest 'messaging: source_port from top-level SourcePort when no Source block' => sub {
    my $v3 = _make_v3(
        ReportType => 'Spam',
        SourceIp   => '192.0.2.1',
        Protocol   => 'smtp',
        SourcePort => 587,
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{source_port}, 587, 'source_port from SourcePort' );
};

subtest 'messaging: absent optional fields not set on result' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    ok( !exists $v4->{smtp_from},   'smtp_from absent' );
    ok( !exists $v4->{smtp_to},     'smtp_to absent'   );
    ok( !exists $v4->{subject},     'subject absent'   );
    ok( !exists $v4->{source_port}, 'source_port absent' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — connection category-specific fields
# ---------------------------------------------------------------------------

subtest 'connection: protocol from Report.Protocol' => sub {
    my $v4 = convert_v3_to_v4( _ddos_v3() );
    is( $v4->{protocol}, 'tcp', 'protocol' );
};

subtest 'connection: first_seen set from v3 Date' => sub {
    my $v4 = convert_v3_to_v4( _ddos_v3() );
    is( $v4->{first_seen}, '2024-01-15T10:00:00Z', 'first_seen = Date' );
};

subtest 'connection: destination_ip when present' => sub {
    my $v3 = _make_v3(
        ReportType    => 'DDoS',
        SourceIp      => '192.0.2.1',
        Protocol      => 'tcp',
        DestinationIp => '203.0.113.10',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{destination_ip}, '203.0.113.10', 'destination_ip' );
};

subtest 'connection: destination_port when present' => sub {
    my $v3 = _make_v3(
        ReportType      => 'DDoS',
        SourceIp        => '192.0.2.1',
        Protocol        => 'tcp',
        DestinationPort => 80,
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{destination_port}, 80, 'destination_port' );
};

subtest 'connection: source_port from Source.Port' => sub {
    my $v3 = _make_v3(
        ReportType => 'DDoS',
        Protocol   => 'tcp',
        Source     => { IP => '192.0.2.1', Port => 54321 },
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{source_port}, 54321, 'source_port from Source.Port' );
};

subtest 'connection: attack_count when present' => sub {
    my $v3 = _make_v3(
        ReportType  => 'DDoS',
        SourceIp    => '192.0.2.1',
        Protocol    => 'tcp',
        AttackCount => 10_000,
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{attack_count}, 10_000, 'attack_count' );
};

subtest 'connection: absent optional fields not set on result' => sub {
    my $v4 = convert_v3_to_v4( _ddos_v3() );
    ok( !exists $v4->{destination_ip},   'destination_ip absent'   );
    ok( !exists $v4->{destination_port}, 'destination_port absent' );
    ok( !exists $v4->{source_port},      'source_port absent'      );
    ok( !exists $v4->{attack_count},     'attack_count absent'     );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — content category-specific fields
# ---------------------------------------------------------------------------

subtest 'content: url from top-level Url' => sub {
    my $v3 = _make_v3(
        ReportType => 'Phishing',
        SourceIp   => '192.0.2.1',
        Url        => 'http://phishing.example/',
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{url}, 'http://phishing.example/', 'url from Url' );
};

subtest 'content: url falls back to AdditionalInfo.URL' => sub {
    my $v3 = _make_v3(
        ReportType     => 'Malware',
        SourceIp       => '192.0.2.1',
        AdditionalInfo => { URL => 'http://malware.example/payload' },
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{url}, 'http://malware.example/payload', 'url from AdditionalInfo.URL' );
};

subtest 'content: url falls back to Source.URL' => sub {
    my $v3 = _make_v3(
        ReportType => 'Phishing',
        Source     => { URL => 'https://evil.example/login' },
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{url}, 'https://evil.example/login', 'url from Source.URL' );
    is( $v4->{source_identifier}, 'https://evil.example/login', 'source_identifier also from Source.URL' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — evidence_source from AdditionalInfo.DetectionMethod
# ---------------------------------------------------------------------------

subtest 'evidence_source: set from AdditionalInfo.DetectionMethod when present' => sub {
    my $v3 = _make_v3(
        ReportType     => 'Spam',
        SourceIp       => '192.0.2.1',
        Protocol       => 'smtp',
        AdditionalInfo => { DetectionMethod => 'spamtrap' },
    );
    my $v4 = convert_v3_to_v4($v3);
    is( $v4->{evidence_source}, 'spamtrap', 'evidence_source' );
};

subtest 'evidence_source: absent when DetectionMethod not present' => sub {
    my $v4 = convert_v3_to_v4( _spam_v3() );
    ok( !exists $v4->{evidence_source}, 'evidence_source absent' );
};

# ---------------------------------------------------------------------------
# convert_v3_to_v4() — error cases (all die with XARF::ParseError)
# ---------------------------------------------------------------------------

subtest 'error: unknown ReportType throws ParseError' => sub {
    my $v3 = _make_v3( ReportType => 'UnknownType', SourceIp => '192.0.2.1' );
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
    like( "$err", qr/unknown ReportType/, 'error message mentions unknown ReportType' );
    like( "$err", qr/UnknownType/,        'error message includes the bad type name' );
};

subtest 'error: no source identifier throws ParseError' => sub {
    my $v3 = _make_v3( ReportType => 'Botnet' );    # no SourceIp, Source, or Url
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
    like( "$err", qr/no source identifier found/, 'error message' );
};

subtest 'error: missing reporter email throws ParseError' => sub {
    my $v3 = _make_v3( ReportType => 'Spam', SourceIp => '192.0.2.1', Protocol => 'smtp' );
    delete $v3->{ReporterInfo}{ReporterOrg};
    delete $v3->{ReporterInfo}{ReporterOrgEmail};
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
    like( "$err", qr/missing reporter email/, 'error message' );
};

subtest 'error: email without domain throws ParseError' => sub {
    my $v3 = _make_v3( ReportType => 'Spam', SourceIp => '192.0.2.1', Protocol => 'smtp' );
    $v3->{ReporterInfo}{ReporterOrgEmail} = 'not-an-email';
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
    like( "$err", qr/not a valid email address/, 'error message' );
};

subtest 'error: messaging without protocol throws ParseError' => sub {
    my $v3 = _make_v3( ReportType => 'Spam', SourceIp => '192.0.2.1' );    # no Protocol
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
    like( "$err", qr/missing protocol for messaging type/, 'error message' );
};

subtest 'error: connection without protocol throws ParseError' => sub {
    my $v3 = _make_v3( ReportType => 'DDoS', SourceIp => '192.0.2.1' );    # no Protocol
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
    like( "$err", qr/missing protocol for connection type/, 'error message' );
};

subtest 'error: content without URL throws ParseError' => sub {
    my $v3 = _make_v3( ReportType => 'Phishing', SourceIp => '192.0.2.1' );    # no Url
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
    like( "$err", qr/missing URL for content type/, 'error message' );
};

subtest 'error: missing Report block throws ParseError' => sub {
    my $v3 = { Version => '3', ReporterInfo => _reporter() };
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
};

subtest 'error: missing ReporterInfo block throws ParseError' => sub {
    my $v3 = {
        Version => '3',
        Report  => { ReportType => 'Spam', Date => '2024-01-15T10:00:00Z' },
    };
    my $err = dies { convert_v3_to_v4($v3) };
    isa_ok( $err, 'XARF::ParseError' );
};

done_testing;
