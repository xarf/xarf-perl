use v5.40;
use Test2::V0;
use Scalar::Util qw(refaddr);

use XARF::SchemaValidator;
use XARF::ValidationError;

XARF::SchemaValidator->_reset_instance;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Minimal valid spam report (all required + recommended fields present)
sub _spam_report {
    return {
        xarf_version => '4.2.0',
        report_id    => '02eb480f-8172-431a-9276-c28ba90f694a',
        timestamp    => '2025-01-11T10:59:45Z',
        reporter     => {
            org     => 'Example Anti-Spam Service',
            contact => 'reports@antispam-service.example',
            domain  => 'antispam-service.example',
        },
        sender => {
            org     => 'Example Anti-Spam Service',
            contact => 'reports@antispam-service.example',
            domain  => 'antispam-service.example',
        },
        source_identifier => '192.168.1.100',
        source_port       => 25,
        category          => 'messaging',
        type              => 'spam',
        evidence_source   => 'spamtrap',
        confidence        => 0.9,
        protocol          => 'smtp',
        smtp_from         => 'marketing@example.com',
        smtp_to           => 'victim@example.org',
        subject           => 'Urgent: Claim Your Prize Now!',
        message_id        => '<abc123@example.com>',
        evidence          => [
            {   content_type => 'message/rfc822',
                description  => 'Complete spam email with headers',
                payload      => 'UmVjZWl2ZWQ6IGZyb20gZXhhbXBsZS5jb20KU3ViamVjdDogVGVzdA==',
                hash => 'sha256:cee5863cbfe009a2560168a939bbced8d16eebafa97eb34d7b3b9d90f7bf1a17',
            },
        ],
    };
}

# Minimal valid DDoS report (all required + recommended fields)
sub _ddos_report {
    return {
        xarf_version => '4.2.0',
        report_id    => '9ac39cd1-85f3-4c31-ae87-a0a95f3ebc83',
        timestamp    => '2025-01-11T09:21:23Z',
        reporter     => {
            org     => 'DDoS Protection Service',
            contact => 'ddos@ddos-monitor.example',
            domain  => 'ddos-monitor.example',
        },
        sender => {
            org     => 'DDoS Protection Service',
            contact => 'ddos@ddos-monitor.example',
            domain  => 'ddos-monitor.example',
        },
        source_identifier => '192.0.2.155',
        source_port       => 1,
        category          => 'connection',
        type              => 'ddos',
        evidence_source   => 'flow_analysis',
        first_seen        => '2025-01-11T08:45:00Z',
        destination_ip    => '203.0.113.100',
        destination_port  => 80,
        protocol          => 'tcp',
        attack_vector     => 'syn_flood',
        peak_pps          => 250000,
        peak_bps          => 1_200_000_000,
    };
}

# Report missing required fields
sub _incomplete_report {
    return {
        xarf_version => '4.2.0',
        category     => 'messaging',
        type         => 'spam',
    };
}

# Report with wrong field types
sub _wrong_type_report {
    my $r = _spam_report();
    $r->{source_port} = 'not-a-number';
    return $r;
}

# Minimal report — all required fields but none of the recommended ones
# (source_port, evidence_source, evidence, confidence omitted)
sub _minimal_no_recommended {
    return {
        xarf_version => '4.2.0',
        report_id    => '02eb480f-8172-431a-9276-c28ba90f694a',
        timestamp    => '2025-01-11T10:59:45Z',
        reporter     => {
            org     => 'Example Anti-Spam Service',
            contact => 'reports@antispam-service.example',
            domain  => 'antispam-service.example',
        },
        sender => {
            org     => 'Example Anti-Spam Service',
            contact => 'reports@antispam-service.example',
            domain  => 'antispam-service.example',
        },
        source_identifier => '192.168.1.100',
        category          => 'messaging',
        type              => 'spam',
        protocol          => 'sms',             # sms does not trigger smtp_from requirement
    };
}

# ---------------------------------------------------------------------------
# Singleton behaviour
# ---------------------------------------------------------------------------

subtest 'instance returns same object on repeated calls' => sub {
    my $v1 = XARF::SchemaValidator->instance;
    my $v2 = XARF::SchemaValidator->instance;
    is( $v1, $v2, 'same reference returned' );
};

subtest '_reset_instance forces re-initialisation' => sub {
    my $v1 = XARF::SchemaValidator->instance;
    XARF::SchemaValidator->_reset_instance;
    my $v2 = XARF::SchemaValidator->instance;
    ok( refaddr($v1) != refaddr($v2), 'new object after reset' );
    XARF::SchemaValidator->_reset_instance;
};

# ---------------------------------------------------------------------------
# Valid reports pass without errors
# ---------------------------------------------------------------------------

subtest 'valid spam report produces no errors' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _spam_report() );
    ok( ref($errors) eq 'ARRAY', 'returns arrayref' );
    is( scalar @$errors, 0, 'no errors for valid report' );
};

subtest 'valid ddos report produces no errors' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _ddos_report() );
    is( scalar @$errors, 0, 'no errors for valid DDoS report' );
};

# ---------------------------------------------------------------------------
# Invalid reports produce structured errors
# ---------------------------------------------------------------------------

subtest 'incomplete report produces validation errors' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _incomplete_report() );
    ok( scalar @$errors > 0, 'errors produced for incomplete report' );
    ok( ( grep { ref($_) eq 'XARF::ValidationError' } @$errors ) == scalar @$errors,
        'all errors are XARF::ValidationError instances',
    );
};

subtest 'errors have non-empty message' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _incomplete_report() );
    ok( scalar @$errors > 0, 'got errors' );
    for my $err (@$errors) {
        ok( length( $err->message ) > 0, 'error has non-empty message' );
    }
};

subtest 'wrong field type produces errors' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _wrong_type_report() );
    ok( scalar @$errors > 0, 'errors for wrong field type' );
};

subtest 'errors have field path for field-level failures' => sub {
    my $v          = XARF::SchemaValidator->instance;
    my $errors     = $v->validate( _wrong_type_report() );
    my @with_field = grep { length( $_->field ) > 0 } @$errors;
    ok( scalar @with_field > 0, 'at least one error has a field path' );
};

subtest 'unknown category produces an error' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $report = _spam_report();
    $report->{category} = 'nonexistent';
    my $errors = $v->validate($report);
    ok( scalar @$errors > 0, 'error for unknown category' );
};

# ---------------------------------------------------------------------------
# Strict mode
# ---------------------------------------------------------------------------

subtest 'normal mode: report without recommended fields passes' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _minimal_no_recommended() );
    is( scalar @$errors, 0, 'passes without recommended fields in normal mode' );
};

subtest 'strict mode: report without recommended fields fails' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _minimal_no_recommended(), strict => 1 );
    ok( scalar @$errors > 0, 'strict mode requires recommended fields' );
};

subtest 'strict mode: report with recommended fields passes' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _spam_report(), strict => 1 );
    is( scalar @$errors, 0, 'strict mode passes when recommended fields present' );
};

# ---------------------------------------------------------------------------
# Error deduplication
# ---------------------------------------------------------------------------

subtest 'duplicate errors are removed' => sub {
    my $v = XARF::SchemaValidator->instance;

    # A report with several missing required fields will produce errors from
    # both the core schema ref and the master schema allOf — deduplicate.
    my $errors = $v->validate( _incomplete_report() );
    my %seen;
    my @dupes = grep { $seen{ $_->field . "\0" . $_->message }++ } @$errors;
    is( scalar @dupes, 0, 'no duplicate (field, message) pairs' );
};

# ---------------------------------------------------------------------------
# get_supported_types
# ---------------------------------------------------------------------------

subtest 'get_supported_types returns arrayref of strings' => sub {
    my $v     = XARF::SchemaValidator->instance;
    my $types = $v->get_supported_types;
    ok( ref($types) eq 'ARRAY', 'returns arrayref' );
    ok( scalar @$types > 0,     'at least one type returned' );
};

subtest 'get_supported_types entries are "category/type" strings' => sub {
    my $v     = XARF::SchemaValidator->instance;
    my $types = $v->get_supported_types;
    for my $t (@$types) {
        ok( $t =~ m{^[a-z0-9_]+/[a-z0-9_]+$}, "entry '$t' matches category/type format" );
    }
};

subtest 'get_supported_types includes expected types' => sub {
    my $v     = XARF::SchemaValidator->instance;
    my $types = $v->get_supported_types;
    my %set   = map { $_ => 1 } @$types;
    ok( $set{'messaging/spam'},        'includes messaging/spam' );
    ok( $set{'connection/ddos'},       'includes connection/ddos' );
    ok( $set{'content/phishing'},      'includes content/phishing' );
    ok( $set{'infrastructure/botnet'}, 'includes infrastructure/botnet' );
    ok( $set{'copyright/copyright'},   'includes copyright/copyright' );
    ok( $set{'vulnerability/cve'},     'includes vulnerability/cve' );
    ok( $set{'reputation/blocklist'},  'includes reputation/blocklist' );
};

subtest 'get_supported_types covers all 32 report types' => sub {
    my $v     = XARF::SchemaValidator->instance;
    my $types = $v->get_supported_types;
    is( scalar @$types, 32, '32 supported types' );
};

# ---------------------------------------------------------------------------
# has_type_schema
# ---------------------------------------------------------------------------

subtest 'has_type_schema returns 1 for known types' => sub {
    my $v = XARF::SchemaValidator->instance;
    is( $v->has_type_schema( 'messaging',  'spam' ),     1, 'messaging/spam known' );
    is( $v->has_type_schema( 'connection', 'ddos' ),     1, 'connection/ddos known' );
    is( $v->has_type_schema( 'content',    'phishing' ), 1, 'content/phishing known' );
};

subtest 'has_type_schema returns 0 for unknown types' => sub {
    my $v = XARF::SchemaValidator->instance;
    is( $v->has_type_schema( 'messaging',   'nonexistent' ), 0, 'unknown type' );
    is( $v->has_type_schema( 'nonexistent', 'spam' ),        0, 'unknown category' );
    is( $v->has_type_schema( '',            '' ),            0, 'empty strings' );
};

# ---------------------------------------------------------------------------
# Multiple categories smoke-test
# ---------------------------------------------------------------------------

subtest 'content/phishing report validates' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $report = {
        xarf_version => '4.2.0',
        report_id    => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        timestamp    => '2025-01-11T10:00:00Z',
        reporter     => {
            org     => 'Phish Hunters',
            contact => 'abuse@phishhunters.example',
            domain  => 'phishhunters.example',
        },
        sender => {
            org     => 'Phish Hunters',
            contact => 'abuse@phishhunters.example',
            domain  => 'phishhunters.example',
        },
        source_identifier => '198.51.100.5',
        source_port       => 80,
        category          => 'content',
        type              => 'phishing',
        evidence_source   => 'user_report',
        url               => 'https://evil.example/login',
    };
    my $errors = $v->validate($report);
    is( scalar @$errors, 0, 'content/phishing passes validation' );
};

subtest 'reputation/blocklist report validates' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $report = {
        xarf_version => '4.2.0',
        report_id    => 'aaaaaaaa-bbbb-cccc-dddd-ffffffffffff',
        timestamp    => '2025-01-11T10:00:00Z',
        reporter     => {
            org     => 'Blocklist Service',
            contact => 'bl@example.example',
            domain  => 'example.example',
        },
        sender => {
            org     => 'Blocklist Service',
            contact => 'bl@example.example',
            domain  => 'example.example',
        },
        source_identifier => '198.51.100.99',
        source_port       => 25,
        category          => 'reputation',
        type              => 'blocklist',
        evidence_source   => 'automated',
        threat_type       => 'spam_source',
    };
    my $errors = $v->validate($report);
    is( scalar @$errors, 0, 'reputation/blocklist passes validation' );
};

done_testing;
