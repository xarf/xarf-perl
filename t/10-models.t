use v5.40;
use Test2::V0;

use XARF;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

my %BASE = (
    xarf_version      => '4.2.0',
    report_id         => '123e4567-e89b-12d3-a456-426614174000',
    timestamp         => '2024-01-15T14:30:25Z',
    reporter          => { org => 'Test Org', contact => 'abuse@test.example', domain => 'test.example' },
    sender            => { org => 'Test Org', contact => 'abuse@test.example', domain => 'test.example' },
    source_identifier => '192.0.2.1',
    category          => 'messaging',
    type              => 'spam',
);

# ---------------------------------------------------------------------------
# XARF::Report — base required fields
# ---------------------------------------------------------------------------

subtest 'XARF::Report construction with required fields' => sub {
    my $r = XARF::Report->new(%BASE);
    is( $r->xarf_version,      '4.2.0',                              'xarf_version' );
    is( $r->report_id,         '123e4567-e89b-12d3-a456-426614174000', 'report_id' );
    is( $r->timestamp,         '2024-01-15T14:30:25Z',               'timestamp' );
    is( $r->source_identifier, '192.0.2.1',                          'source_identifier' );
    is( $r->category,          'messaging',                          'category' );
    is( $r->type,              'spam',                               'type' );
    isa_ok( $r, 'XARF::Report' );
};

subtest 'XARF::Report optional fields default to undef' => sub {
    my $r = XARF::Report->new(%BASE);
    is( $r->evidence_source, undef, 'evidence_source undef' );
    is( $r->source_port,     undef, 'source_port undef' );
    is( $r->description,     undef, 'description undef' );
    is( $r->legacy_version,  undef, 'legacy_version undef' );
    is( $r->evidence,        undef, 'evidence undef' );
    is( $r->tags,            undef, 'tags undef' );
    is( $r->confidence,      undef, 'confidence undef' );
    is( $r->_internal,       undef, '_internal undef' );
};

subtest 'XARF::Report optional fields set correctly' => sub {
    my $r = XARF::Report->new(
        %BASE,
        evidence_source => 'spamtrap',
        source_port     => 25,
        description     => 'test',
        tags            => [ 'a', 'b' ],
        confidence      => 0.9,
        _internal       => { key => 'val' },
    );
    is( $r->evidence_source, 'spamtrap', 'evidence_source' );
    is( $r->source_port,     25,         'source_port' );
    is( $r->description,     'test',     'description' );
    is( $r->confidence,      0.9,        'confidence' );
    is( $r->tags, [ 'a', 'b' ], 'tags' );
    is( $r->_internal, { key => 'val' }, '_internal' );
};

subtest 'XARF::Report missing required field dies' => sub {
    ok( dies { XARF::Report->new( %BASE, xarf_version => undef ) },
        'dies when required field is undef' );
};

subtest 'XARF::Report _extra captures unknown fields' => sub {
    my $r = XARF::Report->new( %BASE, unknown_field => 'secret', another => 42 );
    is( $r->_extra, { unknown_field => 'secret', another => 42 }, '_extra populated' );
};

subtest 'XARF::Report _extra is empty when no unknown fields' => sub {
    my $r = XARF::Report->new(%BASE);
    is( $r->_extra, {}, '_extra empty' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Messaging::Spam
# ---------------------------------------------------------------------------

subtest 'Spam construction' => sub {
    my $r = XARF::Report::Messaging::Spam->new(
        %BASE,
        category => 'messaging',
        type     => 'spam',
        protocol => 'smtp',
    );
    isa_ok( $r, 'XARF::Report::Messaging::Spam' );
    isa_ok( $r, 'XARF::Report::Messaging' );
    isa_ok( $r, 'XARF::Report' );
    is( $r->protocol, 'smtp', 'protocol' );
};

subtest 'Spam optional fields' => sub {
    my $r = XARF::Report::Messaging::Spam->new(
        %BASE,
        category        => 'messaging',
        type            => 'spam',
        protocol        => 'smtp',
        language        => 'en',
        message_id      => '<abc@example.com>',
        recipient_count => 100,
        smtp_to         => 'victim@example.org',
        spam_indicators => { commercial_content => 1 },
        user_agent      => 'Outlook',
    );
    is( $r->language,        'en',                     'language' );
    is( $r->message_id,      '<abc@example.com>',      'message_id' );
    is( $r->recipient_count, 100,                      'recipient_count' );
    is( $r->smtp_to,         'victim@example.org',     'smtp_to' );
    is( $r->user_agent,      'Outlook',                'user_agent' );
    is( $r->spam_indicators, { commercial_content => 1 }, 'spam_indicators' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Messaging::BulkMessaging
# ---------------------------------------------------------------------------

subtest 'BulkMessaging construction' => sub {
    my $r = XARF::Report::Messaging::BulkMessaging->new(
        %BASE,
        category         => 'messaging',
        type             => 'bulk_messaging',
        protocol         => 'smtp',
        recipient_count  => 50000,
    );
    isa_ok( $r, 'XARF::Report::Messaging::BulkMessaging' );
    is( $r->recipient_count, 50000, 'recipient_count' );
};

subtest 'BulkMessaging missing recipient_count dies' => sub {
    ok( dies {
        XARF::Report::Messaging::BulkMessaging->new(
            %BASE,
            category => 'messaging',
            type     => 'bulk_messaging',
            protocol => 'smtp',
        )
    }, 'dies without recipient_count' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Connection::DDoS
# ---------------------------------------------------------------------------

subtest 'DDoS construction' => sub {
    my $r = XARF::Report::Connection::DDoS->new(
        %BASE,
        category   => 'connection',
        type       => 'ddos',
        protocol   => 'tcp',
        first_seen => '2024-01-15T14:00:00Z',
    );
    isa_ok( $r, 'XARF::Report::Connection::DDoS' );
    isa_ok( $r, 'XARF::Report::Connection' );
    is( $r->first_seen, '2024-01-15T14:00:00Z', 'first_seen' );
};

subtest 'DDoS optional fields' => sub {
    my $r = XARF::Report::Connection::DDoS->new(
        %BASE,
        category           => 'connection',
        type               => 'ddos',
        protocol           => 'udp',
        first_seen         => '2024-01-15T14:00:00Z',
        attack_vector      => 'syn_flood',
        peak_pps           => 250000,
        peak_bps           => 1_200_000_000,
        duration_seconds   => 2700,
        mitigation_applied => 1,
        service_impact     => 'degraded',
    );
    is( $r->attack_vector,      'syn_flood',     'attack_vector' );
    is( $r->peak_pps,           250000,          'peak_pps' );
    is( $r->mitigation_applied, 1,               'mitigation_applied' );
    is( $r->service_impact,     'degraded',      'service_impact' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Connection::LoginAttack (no extra fields)
# ---------------------------------------------------------------------------

subtest 'LoginAttack construction' => sub {
    my $r = XARF::Report::Connection::LoginAttack->new(
        %BASE,
        category   => 'connection',
        type       => 'login_attack',
        protocol   => 'ssh',
        first_seen => '2024-01-15T14:00:00Z',
    );
    isa_ok( $r, 'XARF::Report::Connection::LoginAttack' );
    isa_ok( $r, 'XARF::Report::Connection' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Connection::InfectedHost
# ---------------------------------------------------------------------------

subtest 'InfectedHost construction' => sub {
    my $r = XARF::Report::Connection::InfectedHost->new(
        %BASE,
        category   => 'connection',
        type       => 'infected_host',
        protocol   => 'tcp',
        first_seen => '2024-01-15T14:00:00Z',
        bot_type   => 'mirai',
    );
    isa_ok( $r, 'XARF::Report::Connection::InfectedHost' );
    is( $r->bot_type, 'mirai', 'bot_type' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Content::Phishing
# ---------------------------------------------------------------------------

subtest 'Phishing construction' => sub {
    my $r = XARF::Report::Content::Phishing->new(
        %BASE,
        category => 'content',
        type     => 'phishing',
        url      => 'https://phish.example.com/login',
    );
    isa_ok( $r, 'XARF::Report::Content::Phishing' );
    isa_ok( $r, 'XARF::Report::Content' );
    is( $r->url, 'https://phish.example.com/login', 'url' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Content::Csam
# ---------------------------------------------------------------------------

subtest 'Csam required fields' => sub {
    my $r = XARF::Report::Content::Csam->new(
        %BASE,
        category          => 'content',
        type              => 'csam',
        url               => 'https://example.com/illegal',
        classification    => 'A',
        detection_method  => 'hash_match',
    );
    is( $r->classification,   'A',          'classification' );
    is( $r->detection_method, 'hash_match', 'detection_method' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Copyright::P2P
# ---------------------------------------------------------------------------

subtest 'P2P construction' => sub {
    my $r = XARF::Report::Copyright::P2P->new(
        %BASE,
        category     => 'copyright',
        type         => 'p2p',
        p2p_protocol => 'bittorrent',
        swarm_info   => { info_hash => 'abc123', torrent_name => 'Test Movie' },
    );
    isa_ok( $r, 'XARF::Report::Copyright::P2P' );
    isa_ok( $r, 'XARF::Report::Copyright' );
    is( $r->p2p_protocol, 'bittorrent', 'p2p_protocol' );
    is( $r->swarm_info, { info_hash => 'abc123', torrent_name => 'Test Movie' }, 'swarm_info' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Infrastructure::Botnet
# ---------------------------------------------------------------------------

subtest 'Botnet construction' => sub {
    my $r = XARF::Report::Infrastructure::Botnet->new(
        %BASE,
        category            => 'infrastructure',
        type                => 'botnet',
        compromise_evidence => 'C2 traffic observed',
    );
    isa_ok( $r, 'XARF::Report::Infrastructure::Botnet' );
    is( $r->compromise_evidence, 'C2 traffic observed', 'compromise_evidence' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Vulnerability::Cve
# ---------------------------------------------------------------------------

subtest 'Cve construction' => sub {
    my $r = XARF::Report::Vulnerability::Cve->new(
        %BASE,
        category     => 'vulnerability',
        type         => 'cve',
        service      => 'ssh',
        cve_id       => 'CVE-2024-1234',
        service_port => 22,
    );
    isa_ok( $r, 'XARF::Report::Vulnerability::Cve' );
    isa_ok( $r, 'XARF::Report::Vulnerability' );
    is( $r->cve_id,       'CVE-2024-1234', 'cve_id' );
    is( $r->service_port, 22,              'service_port' );
};

# ---------------------------------------------------------------------------
# XARF::Report::Reputation::Blocklist
# ---------------------------------------------------------------------------

subtest 'Blocklist construction' => sub {
    my $r = XARF::Report::Reputation::Blocklist->new(
        %BASE,
        category     => 'reputation',
        type         => 'blocklist',
        threat_type  => 'spam_source',
    );
    isa_ok( $r, 'XARF::Report::Reputation::Blocklist' );
    isa_ok( $r, 'XARF::Report::Reputation' );
    is( $r->threat_type, 'spam_source', 'threat_type' );
};

done_testing;
