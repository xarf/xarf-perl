use v5.40;
use Test2::V0;
use Scalar::Util qw(refaddr);

use XARF::SchemaValidator;
use XARF::ValidationError;

XARF::SchemaValidator->_reset_instance;

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# Standard contact block reused across fixtures
sub _contact {
    my ($org) = @_;
    return {
        org     => $org,
        contact => "abuse\@${\ lc($org =~ s/\s+/-/gr) }.example",
        domain  => "${\ lc($org =~ s/\s+/-/gr) }.example",
    };
}

# Minimal valid spam report — only fields required by the schema.
# Uses protocol=sms so the smtp_from conditional requirement does not apply.
sub _spam_required_only {
    return {
        xarf_version      => '4.2.0',
        report_id         => '02eb480f-8172-431a-9276-c28ba90f694a',
        timestamp         => '2025-01-11T10:59:45Z',
        reporter          => _contact('Test Service'),
        sender            => _contact('Test Service'),
        source_identifier => '192.168.1.100',
        category          => 'messaging',
        type              => 'spam',
        protocol          => 'sms',    # sms: no smtp_from conditional requirement
    };
}

# Full spam report — required fields PLUS all recommended fields.
# Used for strict-mode tests that must pass with strict => 1.
sub _spam_full {
    return {
        xarf_version      => '4.2.0',
        report_id         => '02eb480f-8172-431a-9276-c28ba90f694a',
        timestamp         => '2025-01-11T10:59:45Z',
        reporter          => _contact('Anti-Spam Service'),
        sender            => _contact('Anti-Spam Service'),
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

# Minimal valid DDoS report — all fields required by the type schema.
sub _ddos_report {
    return {
        xarf_version      => '4.2.0',
        report_id         => '9ac39cd1-85f3-4c31-ae87-a0a95f3ebc83',
        timestamp         => '2025-01-11T09:21:23Z',
        reporter          => _contact('DDoS Protection Service'),
        sender            => _contact('DDoS Protection Service'),
        source_identifier => '192.0.2.155',
        source_port       => 1,
        category          => 'connection',
        type              => 'ddos',
        evidence_source   => 'flow_analysis',
        first_seen        => '2025-01-11T08:45:00Z',                  # required by ddos type schema
        destination_ip    => '203.0.113.100',
        destination_port  => 80,
        protocol          => 'tcp',
        attack_vector     => 'syn_flood',
        peak_pps          => 250000,
        peak_bps          => 1_200_000_000,
    };
}

# Report missing many required core fields — used to trigger validation errors.
sub _incomplete_report {
    return {
        xarf_version => '4.2.0',
        category     => 'messaging',
        type         => 'spam',
    };
}

# Valid spam report with source_port set to a string instead of an integer.
sub _wrong_type_report {
    my $r = _spam_required_only();
    $r->{source_port} = 'not-a-number';
    return $r;
}

# ---------------------------------------------------------------------------
# Helper: shared reporter/sender/core fields
# ---------------------------------------------------------------------------

sub _core_fields {
    return (
        xarf_version      => '4.2.0',
        report_id         => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        timestamp         => '2025-01-11T10:00:00Z',
        reporter          => _contact('Test Reporter'),
        sender            => _contact('Test Reporter'),
        source_identifier => '198.51.100.5',
    );
}

# ---------------------------------------------------------------------------
# Singleton behaviour
# ---------------------------------------------------------------------------

subtest 'instance returns same object on repeated calls' => sub {
    my $v1 = XARF::SchemaValidator->instance;
    my $v2 = XARF::SchemaValidator->instance;
    ok( refaddr($v1) == refaddr($v2), 'same reference (identity) returned' );
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

subtest 'required-only spam report produces no errors' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _spam_required_only() );
    ok( ref($errors) eq 'ARRAY', 'returns arrayref' );
    is( scalar @$errors, 0, 'required-only report is valid in normal mode' );
};

subtest 'valid ddos report produces no errors' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _ddos_report() );
    is( scalar @$errors, 0, 'no errors for valid DDoS report' );
};

# ---------------------------------------------------------------------------
# Invalid reports produce structured errors
# ---------------------------------------------------------------------------

subtest 'incomplete report produces XARF::ValidationError instances' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _incomplete_report() );
    ok( scalar @$errors > 0, 'errors produced for incomplete report' );
    ok( ( grep { ref($_) eq 'XARF::ValidationError' } @$errors ) == scalar @$errors,
        'all errors are XARF::ValidationError instances',
    );
    ok( length( $_->message ) > 0, "error has non-empty message: " . $_->message )
        for @$errors;
};

subtest 'type error on source_port produces error naming that field' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _wrong_type_report() );
    ok( scalar @$errors > 0, 'errors produced' );

    # instance_location /source_port is normalised to dot notation: "source_port"
    my @sp_errors = grep { $_->field eq 'source_port' } @$errors;
    ok( scalar @sp_errors > 0, 'at least one error specifically names source_port' );
    ok( ( grep { $_->message =~ /integer|number|string|type/i } @sp_errors ) > 0,
        'error message describes the type mismatch' );
};

subtest 'unknown category produces an error' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $report = _spam_required_only();
    $report->{category} = 'nonexistent';
    my $errors = $v->validate($report);
    ok( scalar @$errors > 0, 'error for unknown category' );
};

# ---------------------------------------------------------------------------
# Format validation
# ---------------------------------------------------------------------------

subtest 'invalid URI in url field is rejected' => sub {

    # Note: JSON::Schema::Modern email format validation requires Email::Address::XS
    # (not installed by default), so this test uses the url field (format: uri)
    # which is validated without extra dependencies.
    my $v = XARF::SchemaValidator->instance;
    my $r = {
        _core_fields(),
        category => 'content',
        type     => 'phishing',
        url      => 'not a valid uri !!',
    };
    my $errors = $v->validate($r);
    ok( scalar @$errors > 0, 'invalid URI format rejected' );
    my @uri_errors = grep { $_->field eq 'url' || $_->message =~ /uri|format/i } @$errors;
    ok( scalar @uri_errors > 0, 'error targets the url field' );
};

subtest 'invalid report_id UUID format is rejected' => sub {
    my $v = XARF::SchemaValidator->instance;
    my $r = _spam_required_only();
    $r->{report_id} = 'not-a-uuid';
    my $errors = $v->validate($r);
    ok( scalar @$errors > 0, 'non-UUID report_id rejected' );
    my @id_errors = grep { $_->field eq 'report_id' || $_->message =~ /uuid|format/i } @$errors;
    ok( scalar @id_errors > 0, 'error targets report_id' );
};

subtest 'invalid timestamp format is rejected' => sub {
    my $v = XARF::SchemaValidator->instance;
    my $r = _spam_required_only();
    $r->{timestamp} = '2025-01-11 10:59:45';    # space instead of T, missing Z
    my $errors = $v->validate($r);
    ok( scalar @$errors > 0, 'non-ISO-8601 timestamp rejected' );
    my @ts_errors
        = grep { $_->field eq 'timestamp' || $_->message =~ /date.time|format/i } @$errors;
    ok( scalar @ts_errors > 0, 'error targets timestamp' );
};

# ---------------------------------------------------------------------------
# Strict mode
# ---------------------------------------------------------------------------

subtest 'normal mode: required-only report passes' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _spam_required_only() );
    is( scalar @$errors, 0, 'required-only report passes in normal mode' );
};

subtest 'strict mode: report without recommended fields fails with specific field errors' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _spam_required_only(), strict => 1 );
    ok( scalar @$errors > 0, 'strict mode requires recommended fields' );

    # Known core recommended fields: source_port, evidence_source, evidence, confidence
    # JSON::Schema::Modern reports these as "object is missing property: X" at root level
    my $all_text = join "\n", map { $_->field . ' ' . $_->message } @$errors;
    ok( $all_text =~ /source_port/, 'strict errors mention source_port' );
    ok( $all_text =~ /evidence/,    'strict errors mention evidence (or evidence_source)' );
    ok( $all_text =~ /confidence/,  'strict errors mention confidence' );
};

subtest 'strict mode: full report with all recommended fields passes' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate( _spam_full(), strict => 1 );
    is( scalar @$errors, 0, 'strict mode passes when all recommended fields are present' );
};

# ---------------------------------------------------------------------------
# Error deduplication
# ---------------------------------------------------------------------------

subtest 'validate() deduplicates errors that JSM emits more than once' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $report = _incomplete_report();

    # Peek at the raw (undeduped) output directly from the JSON::Schema::Modern
    # instance. The master schema references xarf-core.json in allOf[0], and
    # the matched type schema also references xarf-core.json in its own allOf[0],
    # so core-required field errors appear at least twice in the raw output.
    my @raw_errors
        = $v->_jsm->evaluate( $report, 'https://xarf.org/schemas/v4/xarf-v4-master.json' )->errors;
    my %raw_seen;
    my @raw_dupes
        = grep { $raw_seen{ "" . $_->instance_location . "\0" . $_->error }++ } @raw_errors;
    ok( scalar @raw_dupes > 0, 'raw JSM output contains duplicate errors — dedup is needed' );

    my $deduped = $v->validate($report);
    ok( scalar @$deduped < scalar @raw_errors, 'validate() reduces error count via deduplication' );

    my %seen;
    my @dupes = grep { $seen{ $_->field . "\0" . $_->message }++ } @$deduped;
    is( scalar @dupes, 0, 'output has no duplicate (field, message) pairs' );
};

# ---------------------------------------------------------------------------
# get_supported_types
# ---------------------------------------------------------------------------

subtest 'get_supported_types returns arrayref of category/type strings' => sub {
    my $v     = XARF::SchemaValidator->instance;
    my $types = $v->get_supported_types;
    ok( ref($types) eq 'ARRAY', 'returns arrayref' );
    for my $t (@$types) {
        ok( $t =~ m{^[a-z0-9_]+/[a-z0-9_]+$}, "entry '$t' matches category/type format" );
    }
};

subtest 'get_supported_types includes one type from each of the 7 categories' => sub {
    my $v   = XARF::SchemaValidator->instance;
    my %set = map { $_ => 1 } @{ $v->get_supported_types };
    is( $set{'messaging/spam'},        1, 'messaging/spam present' );
    is( $set{'connection/ddos'},       1, 'connection/ddos present' );
    is( $set{'content/phishing'},      1, 'content/phishing present' );
    is( $set{'infrastructure/botnet'}, 1, 'infrastructure/botnet present' );
    is( $set{'copyright/copyright'},   1, 'copyright/copyright present' );
    is( $set{'vulnerability/cve'},     1, 'vulnerability/cve present' );
    is( $set{'reputation/blocklist'},  1, 'reputation/blocklist present' );
};

subtest 'get_supported_types returns exactly 32 types' => sub {
    my $v     = XARF::SchemaValidator->instance;
    my $types = $v->get_supported_types;
    is( scalar @$types, 32, '32 supported types' );
};

# ---------------------------------------------------------------------------
# has_type_schema
# ---------------------------------------------------------------------------

subtest 'has_type_schema returns 1 for one known type per category' => sub {
    my $v = XARF::SchemaValidator->instance;
    is( $v->has_type_schema( 'messaging',      'spam' ),      1, 'messaging/spam' );
    is( $v->has_type_schema( 'connection',     'ddos' ),      1, 'connection/ddos' );
    is( $v->has_type_schema( 'content',        'phishing' ),  1, 'content/phishing' );
    is( $v->has_type_schema( 'infrastructure', 'botnet' ),    1, 'infrastructure/botnet' );
    is( $v->has_type_schema( 'copyright',      'copyright' ), 1, 'copyright/copyright' );
    is( $v->has_type_schema( 'vulnerability',  'cve' ),       1, 'vulnerability/cve' );
    is( $v->has_type_schema( 'reputation',     'blocklist' ), 1, 'reputation/blocklist' );
};

subtest 'has_type_schema returns 0 for unknown types' => sub {
    my $v = XARF::SchemaValidator->instance;
    is( $v->has_type_schema( 'messaging',   'nonexistent' ), 0, 'unknown type' );
    is( $v->has_type_schema( 'nonexistent', 'spam' ),        0, 'unknown category' );
    is( $v->has_type_schema( '',            '' ),            0, 'empty strings' );
};

# ---------------------------------------------------------------------------
# Smoke tests — one valid report per category
# ---------------------------------------------------------------------------

subtest 'content/phishing report validates' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate(
        {   _core_fields(),
            category => 'content',
            type     => 'phishing',
            url      => 'https://evil.example/login',
        }
    );
    is( scalar @$errors, 0, 'content/phishing passes' );
};

subtest 'infrastructure/botnet report validates' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate(
        {   _core_fields(),
            category            => 'infrastructure',
            type                => 'botnet',
            compromise_evidence => 'cnc_traffic',
        }
    );
    is( scalar @$errors, 0, 'infrastructure/botnet passes' );
};

subtest 'copyright/copyright report validates' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate(
        {   _core_fields(),
            category       => 'copyright',
            type           => 'copyright',
            infringing_url => 'https://pirate.example/movie.mp4',
        }
    );
    is( scalar @$errors, 0, 'copyright/copyright passes' );
};

subtest 'vulnerability/cve report validates' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate(
        {   _core_fields(),
            category     => 'vulnerability',
            type         => 'cve',
            service      => 'http',
            service_port => 80,
            cve_id       => 'CVE-2024-1234',
        }
    );
    is( scalar @$errors, 0, 'vulnerability/cve passes' );
};

subtest 'reputation/blocklist report validates' => sub {
    my $v      = XARF::SchemaValidator->instance;
    my $errors = $v->validate(
        {   _core_fields(),
            category    => 'reputation',
            type        => 'blocklist',
            threat_type => 'spam_source',
        }
    );
    is( scalar @$errors, 0, 'reputation/blocklist passes' );
};

done_testing;
