use v5.40;
use Test2::V0;

use JSON::MaybeXS qw(encode_json decode_json);

use XARF qw(parse);
use XARF::Parser;
use XARF::ParseError;
use XARF::SchemaValidator;
use XARF::ValidationError;
use XARF::ValidationWarning;
use XARF::V3Legacy qw(is_v3_report);

XARF::SchemaValidator->_reset_instance;

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

sub _contact {
    my ($org) = @_;
    return {
        org     => $org,
        contact => "abuse\@${\ lc($org =~ s/\s+/-/gr) }.example",
        domain  => "${\ lc($org =~ s/\s+/-/gr) }.example",
    };
}

sub _core {
    return (
        xarf_version      => '4.2.0',
        report_id         => '02eb480f-8172-431a-9276-c28ba90f694a',
        timestamp         => '2025-01-11T10:59:45Z',
        reporter          => _contact('Test Service'),
        sender            => _contact('Test Service'),
        source_identifier => '192.168.1.100',
    );
}

sub _spam_report {
    return {
        _core(),
        category  => 'messaging',
        type      => 'spam',
        protocol  => 'sms',
    };
}

sub _ddos_report {
    return {
        _core(),
        category       => 'connection',
        type           => 'ddos',
        first_seen     => '2025-01-11T08:45:00Z',
        protocol       => 'tcp',
        destination_ip => '203.0.113.1',
        source_port    => 8080,    # required when source_identifier is an IP
    };
}

sub _phishing_report {
    return {
        _core(),
        category => 'content',
        type     => 'phishing',
        url      => 'https://evil.example/login',
    };
}

sub _botnet_report {
    return {
        _core(),
        category            => 'infrastructure',
        type                => 'botnet',
        compromise_evidence => 'cnc_traffic',
    };
}

sub _copyright_report {
    return {
        _core(),
        category       => 'copyright',
        type           => 'copyright',
        infringing_url => 'https://pirate.example/movie.mp4',
    };
}

sub _cve_report {
    return {
        _core(),
        category     => 'vulnerability',
        type         => 'cve',
        service      => 'http',
        service_port => 80,
        cve_id       => 'CVE-2024-1234',
    };
}

sub _blocklist_report {
    return {
        _core(),
        category    => 'reputation',
        type        => 'blocklist',
        threat_type => 'spam_source',
    };
}

# XARF v3 spam sample (mirrors xarf-parser-tests/samples/valid/v3/spam_v3_sample.json)
sub _v3_spam {
    return {
        Version      => '3.0.0',
        ReporterInfo => {
            ReporterOrg          => 'Example Anti-Spam Service',
            ReporterOrgDomain    => 'antispam-service.example',
            ReporterOrgEmail     => 'reports@antispam-service.example',
            ReporterContactEmail => 'abuse@antispam-service.example',
        },
        Disclosure => JSON::MaybeXS->true,
        Report     => {
            ReportType => 'spam',
            Date       => '2024-01-15T14:30:25Z',
            Source     => { IP => '192.168.1.100', Port => 25, Type => 'ip' },
            AdditionalInfo => {
                Protocol        => 'smtp',
                SMTPFrom        => 'marketing@example.com',
                Subject         => 'Urgent: Claim Your Prize Now!',
                DetectionMethod => 'spamtrap',
            },
            Attachment => [
                {   ContentType => 'message/rfc822',
                    Description => 'Original spam message with headers',
                    Data =>
                        'UmVjZWl2ZWQ6IGZyb20gZXhhbXBsZS5jb20gKGV4YW1wbGUuY29tIFsxOTIuMTY4LjEuMTAwXSkK',
                },
            ],
        },
    };
}

# ---------------------------------------------------------------------------
# Basic call — JSON string input
# ---------------------------------------------------------------------------

subtest 'parse() accepts a JSON string' => sub {
    my $json   = encode_json( _spam_report() );
    my $result = parse($json);
    ok( defined $result, 'parse() returns a defined value' );
    ok( $result->isa('XARF::Result::Parse'), 'returns XARF::Result::Parse' );
};

subtest 'parse() accepts a hashref directly' => sub {
    my $result = parse( _spam_report() );
    ok( $result->isa('XARF::Result::Parse'), 'returns XARF::Result::Parse' );
};

# Also verify the re-export via the top-level XARF module works
subtest 'XARF::parse() re-export works' => sub {
    my $result = XARF::parse( _spam_report() );
    ok( $result->isa('XARF::Result::Parse'), 'top-level re-export functional' );
};

# ---------------------------------------------------------------------------
# Malformed JSON → XARF::ParseError
# ---------------------------------------------------------------------------

subtest 'malformed JSON dies with XARF::ParseError' => sub {
    my $err = dies { parse('{ not valid json !!') };
    ok( defined $err, 'dies on malformed JSON' );
    ok( ref($err) && $err->isa('XARF::ParseError'),
        'exception is XARF::ParseError, got: ' . ref($err) );
    ok( $err->message =~ /Invalid JSON/i, 'message mentions Invalid JSON' );
};

# ---------------------------------------------------------------------------
# Result shape
# ---------------------------------------------------------------------------

subtest 'successful parse result has report, errors, warnings' => sub {
    my $result = parse( _spam_report() );
    ok( defined $result->report,   'report is defined' );
    ok( ref( $result->errors )   eq 'ARRAY', 'errors is arrayref' );
    ok( ref( $result->warnings ) eq 'ARRAY', 'warnings is arrayref' );
    is( scalar @{ $result->errors },   0, 'no errors for valid report' );
    is( scalar @{ $result->warnings }, 0, 'no warnings for known-fields-only report' );
};

subtest 'invalid report has errors but still returns a report' => sub {
    my $bad = { xarf_version => '4.2.0', category => 'messaging', type => 'spam' };
    my $result = parse($bad);
    ok( scalar @{ $result->errors } > 0, 'errors present for incomplete report' );
    ok( $result->errors->[0]->isa('XARF::ValidationError'),
        'errors are XARF::ValidationError instances' );
    # report may be undef when Moo construction fails on missing required fields,
    # but the attribute must be accessible without dying.
    ok( !dies { $result->report }, 'report attribute is accessible without dying' );
};

# ---------------------------------------------------------------------------
# Typed report dispatch — one per category
# ---------------------------------------------------------------------------

subtest 'messaging/spam → XARF::Report::Messaging::Spam' => sub {
    my $result = parse( _spam_report() );
    is( scalar @{ $result->errors }, 0, 'no validation errors' );
    ok( $result->report->isa('XARF::Report::Messaging::Spam'),
        'report is XARF::Report::Messaging::Spam' );
    is( $result->report->category, 'messaging', 'category attribute' );
    is( $result->report->type,     'spam',       'type attribute' );
};

subtest 'connection/ddos → XARF::Report::Connection::DDoS' => sub {
    my $result = parse( _ddos_report() );
    is( scalar @{ $result->errors }, 0, 'no validation errors' );
    ok( $result->report->isa('XARF::Report::Connection::DDoS'),
        'report is XARF::Report::Connection::DDoS' );
};

subtest 'content/phishing → XARF::Report::Content::Phishing' => sub {
    my $result = parse( _phishing_report() );
    is( scalar @{ $result->errors }, 0, 'no validation errors' );
    ok( $result->report->isa('XARF::Report::Content::Phishing'),
        'report is XARF::Report::Content::Phishing' );
};

subtest 'infrastructure/botnet → XARF::Report::Infrastructure::Botnet' => sub {
    my $result = parse( _botnet_report() );
    is( scalar @{ $result->errors }, 0, 'no validation errors' );
    ok( $result->report->isa('XARF::Report::Infrastructure::Botnet'),
        'report is XARF::Report::Infrastructure::Botnet' );
};

subtest 'copyright/copyright → XARF::Report::Copyright::Copyright' => sub {
    my $result = parse( _copyright_report() );
    is( scalar @{ $result->errors }, 0, 'no validation errors' );
    ok( $result->report->isa('XARF::Report::Copyright::Copyright'),
        'report is XARF::Report::Copyright::Copyright' );
};

subtest 'vulnerability/cve → XARF::Report::Vulnerability::Cve' => sub {
    my $result = parse( _cve_report() );
    is( scalar @{ $result->errors }, 0, 'no validation errors' );
    ok( $result->report->isa('XARF::Report::Vulnerability::Cve'),
        'report is XARF::Report::Vulnerability::Cve' );
};

subtest 'reputation/blocklist → XARF::Report::Reputation::Blocklist' => sub {
    my $result = parse( _blocklist_report() );
    is( scalar @{ $result->errors }, 0, 'no validation errors' );
    ok( $result->report->isa('XARF::Report::Reputation::Blocklist'),
        'report is XARF::Report::Reputation::Blocklist' );
};

# ---------------------------------------------------------------------------
# v3 auto-detection and conversion
# ---------------------------------------------------------------------------

subtest 'v3 spam report is auto-detected and converted' => sub {
    my $result = parse( _v3_spam() );

    # Should have the deprecation warning
    my @depr = grep { $_->message =~ /DEPRECATION WARNING/i } @{ $result->warnings };
    ok( scalar @depr > 0, 'deprecation warning emitted' );

    # Converted report should pass schema validation
    is( scalar @{ $result->errors }, 0, 'no schema errors after v3 conversion' );

    # Report should be a valid v4 Spam report
    ok( defined $result->report, 'report defined after v3 conversion' );
    is( $result->report->category, 'messaging', 'category mapped to messaging' );
    is( $result->report->type,     'spam',       'type mapped to spam' );
    ok( $result->report->isa('XARF::Report::Messaging::Spam'),
        'report is correct subclass' );
};

subtest 'v3 conversion sets legacy_version to "3"' => sub {
    my $result = parse( _v3_spam() );
    is( $result->report->legacy_version, '3', 'legacy_version is "3"' );
};

subtest 'v3 conversion populates _internal marker' => sub {
    my $result = parse( _v3_spam() );
    my $int    = $result->report->_internal;
    ok( defined $int, '_internal is set' );
    ok( $int->{original_report_type}, '_internal has original_report_type' );
    ok( $int->{converted_at},         '_internal has converted_at timestamp' );
};

subtest 'v3 report with unknown ReportType dies with ParseError' => sub {
    my $bad_v3 = _v3_spam();
    $bad_v3->{Report}{ReportType} = 'UnknownType99';
    my $err = dies { parse($bad_v3) };
    ok( defined $err && $err->isa('XARF::ParseError'),
        'unknown v3 ReportType throws ParseError' );
    ok( $err->message =~ /UnknownType99/, 'message names the bad type' );
};

subtest 'v3 detection returns undef for a v4 report' => sub {
    ok( !is_v3_report( _spam_report() ), 'v4 report not detected as v3' );
    ok( is_v3_report( _v3_spam() ),      'v3 report detected correctly' );
};

# ---------------------------------------------------------------------------
# Strict mode
# ---------------------------------------------------------------------------

subtest 'strict mode: valid report with all recommended fields passes' => sub {
    my $full = {
        _core(),
        category        => 'messaging',
        type            => 'spam',
        protocol        => 'smtp',
        smtp_from       => 'sender@example.com',
        smtp_to         => 'victim@example.org',
        subject         => 'Test Subject',
        message_id      => '<test@example.com>',
        evidence_source => 'spamtrap',
        confidence      => 0.9,
        source_port     => 25,
        evidence        => [],
    };
    my $result = parse( $full, strict => 1 );
    is( scalar @{ $result->errors }, 0, 'no errors in strict mode with all recommended fields' );
};

subtest 'strict mode: report missing recommended fields has errors' => sub {
    my $result = parse( _spam_report(), strict => 1 );
    ok( scalar @{ $result->errors } > 0,
        'strict mode produces errors for missing recommended fields' );
};

subtest 'strict mode: unknown field becomes an error' => sub {
    # Use a fully recommended-field-complete report so schema errors don't interfere
    my $r = {
        _core(),
        category        => 'messaging',
        type            => 'spam',
        protocol        => 'smtp',
        smtp_from       => 'sender@example.com',
        smtp_to         => 'victim@example.org',
        subject         => 'Test Subject',
        message_id      => '<test@example.com>',
        evidence_source => 'spamtrap',
        confidence      => 0.9,
        source_port     => 25,
        evidence        => [],
        my_unknown_field => 'value',
    };
    my $result = parse( $r, strict => 1 );
    my @uf = grep { $_->field eq 'my_unknown_field' } @{ $result->errors };
    ok( scalar @uf > 0, 'unknown field is an error in strict mode' );
    is( scalar @{ $result->warnings }, 0, 'no warnings in strict mode (promoted to errors)' );
};

# ---------------------------------------------------------------------------
# Unknown field warnings (normal mode)
# ---------------------------------------------------------------------------

subtest 'normal mode: unknown field produces a warning, not an error' => sub {
    my $r = _spam_report();
    $r->{proprietary_extension} = 'data';
    my $result = parse($r);
    is( scalar @{ $result->errors }, 0, 'no errors for unknown field in normal mode' );
    my @uf = grep { $_->field eq 'proprietary_extension' } @{ $result->warnings };
    ok( scalar @uf > 0, 'unknown field triggers a warning' );
    ok( $uf[0]->isa('XARF::ValidationWarning'), 'warning is XARF::ValidationWarning' );
};

# ---------------------------------------------------------------------------
# show_missing_optional
# ---------------------------------------------------------------------------

subtest 'show_missing_optional: info is undef when not requested' => sub {
    my $result = parse( _spam_report() );
    ok( !defined $result->info, 'info is undef without show_missing_optional' );
};

subtest 'show_missing_optional: info is arrayref when requested' => sub {
    my $result = parse( _spam_report(), show_missing_optional => 1 );
    ok( defined $result->info,                  'info is defined' );
    ok( ref( $result->info ) eq 'ARRAY',        'info is arrayref' );
    ok( scalar @{ $result->info } > 0,          'at least one missing optional field listed' );
};

subtest 'show_missing_optional: info items have field and message keys' => sub {
    my $result = parse( _spam_report(), show_missing_optional => 1 );
    for my $item ( @{ $result->info } ) {
        ok( exists $item->{field},   'info item has field key' );
        ok( exists $item->{message}, 'info item has message key' );
        ok( $item->{message} =~ /^(RECOMMENDED|OPTIONAL):/,
            "message has correct prefix: $item->{message}" );
    }
};

subtest 'show_missing_optional: known recommended fields appear in info' => sub {
    my $result = parse( _spam_report(), show_missing_optional => 1 );
    my @fields = map { $_->{field} } @{ $result->info };
    ok( ( grep { $_ eq 'confidence' } @fields ),
        'confidence listed as missing optional' );
};

# ---------------------------------------------------------------------------
# Report field access
# ---------------------------------------------------------------------------

subtest 'parsed report exposes core fields as attributes' => sub {
    my $result = parse( _spam_report() );
    my $r      = $result->report;
    is( $r->xarf_version,      '4.2.0',                   'xarf_version' );
    is( $r->report_id,         '02eb480f-8172-431a-9276-c28ba90f694a', 'report_id' );
    is( $r->source_identifier, '192.168.1.100',            'source_identifier' );
    is( $r->category,          'messaging',                'category' );
    is( $r->type,              'spam',                     'type' );
    ok( ref( $r->reporter ) eq 'HASH', 'reporter is a hashref' );
    ok( ref( $r->sender )   eq 'HASH', 'sender is a hashref' );
};

subtest 'category-specific field accessible on typed report' => sub {
    my $result = parse( _spam_report() );
    ok( $result->report->can('protocol'), 'spam report has protocol attribute' );
    is( $result->report->protocol, 'sms', 'protocol value correct' );
};

done_testing;
