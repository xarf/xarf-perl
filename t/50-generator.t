use v5.40;
use Test2::V0;

use XARF qw(create_report create_evidence);
use XARF::Generator;
use XARF::Evidence;
use XARF::Result::CreateReport;
use XARF::SchemaValidator;
use XARF::ValidationError;
use XARF::ValidationWarning;

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

# Minimum fields shared by all report types
sub _base {
    return (
        source_identifier => '192.0.2.1',
        reporter          => _contact('Test ISP'),
        sender            => _contact('Bad Actor'),
    );
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# UUID v4 pattern: 8-4-4-4-12 hex digits, version nibble = 4, variant bits = 8/9/a/b
my $UUID_RE = qr/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i;

# ISO 8601 UTC timestamp (with or without sub-second precision)
my $TS_RE = qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\z/;

# ---------------------------------------------------------------------------
# Auto-metadata
# ---------------------------------------------------------------------------

subtest 'auto-fills xarf_version' => sub {
    my $r = create_report( _base(), category => 'messaging', type => 'spam', protocol => 'sms' );
    is $r->report->xarf_version, $XARF::SPEC_VERSION, 'xarf_version matches SPEC_VERSION';
};

subtest 'auto-generates UUID v4 report_id' => sub {
    my $r = create_report( _base(), category => 'messaging', type => 'spam', protocol => 'sms' );
    like $r->report->report_id, $UUID_RE, 'report_id is UUID v4';
};

subtest 'auto-generates ISO 8601 UTC timestamp' => sub {
    my $r = create_report( _base(), category => 'messaging', type => 'spam', protocol => 'sms' );
    like $r->report->timestamp, $TS_RE, 'timestamp is ISO 8601 UTC';
};

subtest 'caller can override report_id' => sub {
    my $custom_id = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
    my $r = create_report(
        _base(),
        category  => 'messaging',
        type      => 'spam',
        protocol  => 'sms',
        report_id => $custom_id,
    );
    is $r->report->report_id, $custom_id, 'report_id is caller-supplied value';
};

subtest 'caller can override timestamp' => sub {
    my $ts = '2024-06-01T12:00:00Z';
    my $r  = create_report(
        _base(),
        category  => 'messaging',
        type      => 'spam',
        protocol  => 'sms',
        timestamp => $ts,
    );
    is $r->report->timestamp, $ts, 'timestamp is caller-supplied value';
};

subtest 'each call generates a unique report_id' => sub {
    my $r1 = create_report( _base(), category => 'messaging', type => 'spam', protocol => 'sms' );
    my $r2 = create_report( _base(), category => 'messaging', type => 'spam', protocol => 'sms' );
    isnt $r1->report->report_id, $r2->report->report_id, 'consecutive calls get different UUIDs';
};

# ---------------------------------------------------------------------------
# Return type
# ---------------------------------------------------------------------------

subtest 'returns XARF::Result::CreateReport' => sub {
    my $r = create_report( _base(), category => 'messaging', type => 'spam', protocol => 'sms' );
    isa_ok $r, 'XARF::Result::CreateReport';
};

subtest 'successful create has empty errors' => sub {
    my $r = create_report( _base(), category => 'messaging', type => 'spam', protocol => 'sms' );
    is scalar @{ $r->errors }, 0, 'no errors on valid input';
};

# ---------------------------------------------------------------------------
# All 7 categories — one representative type each
# ---------------------------------------------------------------------------

subtest 'messaging/spam' => sub {
    my $r = create_report(
        _base(),
        category => 'messaging',
        type     => 'spam',
        protocol => 'sms',
    );
    ok !@{ $r->errors }, 'no errors'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };
    isa_ok $r->report, 'XARF::Report::Messaging::Spam';
};

subtest 'connection/ddos' => sub {
    my $r = create_report(
        _base(),
        category       => 'connection',
        type           => 'ddos',
        first_seen     => '2025-01-01T00:00:00Z',
        protocol       => 'tcp',
        destination_ip => '203.0.113.42',
        source_port    => 443,
    );
    ok !@{ $r->errors }, 'no errors'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };
    isa_ok $r->report, 'XARF::Report::Connection::DDoS';
};

subtest 'content/phishing' => sub {
    my $r = create_report(
        _base(),
        category => 'content',
        type     => 'phishing',
        url      => 'https://evil.example/steal',
    );
    ok !@{ $r->errors }, 'no errors'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };
    isa_ok $r->report, 'XARF::Report::Content::Phishing';
};

subtest 'infrastructure/botnet' => sub {
    my $r = create_report(
        _base(),
        category            => 'infrastructure',
        type                => 'botnet',
        compromise_evidence => 'cnc_traffic',
    );
    ok !@{ $r->errors }, 'no errors'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };
    isa_ok $r->report, 'XARF::Report::Infrastructure::Botnet';
};

subtest 'copyright/copyright' => sub {
    my $r = create_report(
        _base(),
        category       => 'copyright',
        type           => 'copyright',
        infringing_url => 'https://pirate.example/movie.mp4',
    );
    ok !@{ $r->errors }, 'no errors'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };
    isa_ok $r->report, 'XARF::Report::Copyright::Copyright';
};

subtest 'vulnerability/cve' => sub {
    my $r = create_report(
        _base(),
        category     => 'vulnerability',
        type         => 'cve',
        service      => 'http',
        service_port => 80,
        cve_id       => 'CVE-2024-1234',
    );
    ok !@{ $r->errors }, 'no errors'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };
    isa_ok $r->report, 'XARF::Report::Vulnerability::Cve';
};

subtest 'reputation/blocklist' => sub {
    my $r = create_report(
        _base(),
        category    => 'reputation',
        type        => 'blocklist',
        threat_type => 'spam_source',
    );
    ok !@{ $r->errors }, 'no errors'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };
    isa_ok $r->report, 'XARF::Report::Reputation::Blocklist';
};

# ---------------------------------------------------------------------------
# report always returned (JS alignment: errors are informational)
# ---------------------------------------------------------------------------

subtest 'report populated even when there are validation errors' => sub {
    # An unknown field in strict mode produces a validation error, but all Moo-required
    # attributes are present so the typed report object is still constructed.
    # This mirrors JS createReport() which always returns the report alongside errors.
    my $r = create_report(
        _base(),
        category          => 'messaging',
        type              => 'spam',
        protocol          => 'sms',
        unknown_xyz_field => 'value',
        strict            => 1,
    );
    ok @{ $r->errors }, 'has validation errors';
    ok defined $r->report, 'report is still defined';
    isa_ok $r->report, 'XARF::Report::Messaging::Spam';
};

# ---------------------------------------------------------------------------
# Validation errors for missing required fields
# ---------------------------------------------------------------------------

subtest 'missing required field produces ValidationError' => sub {
    # Omit source_identifier
    my $r = create_report(
        reporter => _contact('Test ISP'),
        sender   => _contact('Bad Actor'),
        category => 'messaging',
        type     => 'spam',
        protocol => 'sms',
    );
    ok @{ $r->errors }, 'has errors';
    my @msgs = map { $_->message } @{ $r->errors };
    ok scalar( grep { /source_identifier/ } @msgs ), 'error message references the missing field';
};

# ---------------------------------------------------------------------------
# strict mode
# ---------------------------------------------------------------------------

subtest 'strict mode converts unknown field to error' => sub {
    my $r = create_report(
        _base(),
        category          => 'messaging',
        type              => 'spam',
        protocol          => 'sms',
        unknown_field_xyz => 'some value',
        strict            => 1,
    );
    ok @{ $r->errors }, 'has errors in strict mode';
    my @msgs = map { $_->message } @{ $r->errors };
    ok scalar( grep { /unknown_field_xyz/ } @msgs ), 'error mentions unknown field';
};

subtest 'non-strict mode: unknown field is warning not error' => sub {
    my $r = create_report(
        _base(),
        category          => 'messaging',
        type              => 'spam',
        protocol          => 'sms',
        unknown_field_xyz => 'some value',
    );
    ok !@{ $r->errors },   'no errors in non-strict mode';
    ok @{ $r->warnings }, 'has warnings';
    my @msgs = map { $_->message } @{ $r->warnings };
    ok scalar( grep { /unknown_field_xyz/ } @msgs ), 'warning mentions unknown field';
};

# ---------------------------------------------------------------------------
# show_missing_optional
# ---------------------------------------------------------------------------

subtest 'show_missing_optional populates info' => sub {
    my $r = create_report(
        _base(),
        category              => 'messaging',
        type                  => 'spam',
        protocol              => 'sms',
        show_missing_optional => 1,
    );
    ok defined $r->info, 'info is defined';
    ref_ok $r->info, 'ARRAY', 'info is arrayref';
    ok @{ $r->info } > 0, 'info contains entries';

    my $first = $r->info->[0];
    ok exists $first->{field},   'each entry has field key';
    ok exists $first->{message}, 'each entry has message key';
};

subtest 'info is undef when show_missing_optional not set' => sub {
    my $r = create_report(
        _base(),
        category => 'messaging',
        type     => 'spam',
        protocol => 'sms',
    );
    ok !defined $r->info, 'info is undef when show_missing_optional is off';
};

# ---------------------------------------------------------------------------
# Evidence objects are serialised automatically
# ---------------------------------------------------------------------------

subtest 'XARF::Evidence objects in evidence list are serialised to hashrefs' => sub {
    my $ev = create_evidence(
        content_type => 'text/plain',
        payload      => 'spam content',
    );
    isa_ok $ev, 'XARF::Evidence';

    my $r = create_report(
        _base(),
        category => 'messaging',
        type     => 'spam',
        protocol => 'sms',
        evidence => [$ev],
    );
    ok !@{ $r->errors }, 'no errors with Evidence object in evidence list'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };

    my $stored = $r->report->evidence;
    ref_ok $stored, 'ARRAY', 'evidence is arrayref on report';
    is scalar(@$stored), 1, 'one evidence item';
    ref_ok $stored->[0], 'HASH', 'evidence item is plain hashref on report';
};

subtest 'plain hashref evidence also works' => sub {
    my $r = create_report(
        _base(),
        category => 'messaging',
        type     => 'spam',
        protocol => 'sms',
        evidence => [ { content_type => 'text/plain', payload => 'aGVsbG8=' } ],
    );
    ok !@{ $r->errors }, 'no errors with plain hashref evidence'
        or note join ', ', map { $_->field . ': ' . $_->message } @{ $r->errors };
};

done_testing;
