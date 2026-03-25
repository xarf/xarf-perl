use v5.40;
use Test2::V0;

use XARF;

# ---------------------------------------------------------------------------
# Shared base data — overridden per test
# ---------------------------------------------------------------------------

my %BASE = (
    xarf_version      => '4.2.0',
    report_id         => 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    timestamp         => '2024-06-01T00:00:00Z',
    reporter          => { org => 'R', contact => 'r@r.example', domain => 'r.example' },
    sender            => { org => 'S', contact => 's@s.example', domain => 's.example' },
    source_identifier => '10.0.0.1',
);

# Helper: call from_hashref and check the result class
sub check_dispatch ( $category, $type, $extra_fields, $expected_class ) {
    my $data = {
        %BASE,
        category => $category,
        type     => $type,
        %{$extra_fields},
    };
    my $r = XARF::Report->from_hashref($data);
    ok( defined $r, "$category/$type returns defined" );
    isa_ok( $r, $expected_class );
    is( $r->category, $category, "$category/$type category attr" );
    is( $r->type,     $type,     "$category/$type type attr" );
}

# ---------------------------------------------------------------------------
# Messaging (2 types)
# ---------------------------------------------------------------------------

subtest 'dispatch messaging/spam' => sub {
    check_dispatch( 'messaging', 'spam', { protocol => 'smtp' },
        'XARF::Report::Messaging::Spam' );
};

subtest 'dispatch messaging/bulk_messaging' => sub {
    check_dispatch( 'messaging', 'bulk_messaging',
        { protocol => 'smtp', recipient_count => 1000 },
        'XARF::Report::Messaging::BulkMessaging' );
};

# ---------------------------------------------------------------------------
# Connection (8 types)
# ---------------------------------------------------------------------------

my %CONN_BASE = ( protocol => 'tcp', first_seen => '2024-01-01T00:00:00Z' );

subtest 'dispatch connection/login_attack' => sub {
    check_dispatch( 'connection', 'login_attack', \%CONN_BASE,
        'XARF::Report::Connection::LoginAttack' );
};

subtest 'dispatch connection/port_scan' => sub {
    check_dispatch( 'connection', 'port_scan', \%CONN_BASE,
        'XARF::Report::Connection::PortScan' );
};

subtest 'dispatch connection/ddos' => sub {
    check_dispatch( 'connection', 'ddos', \%CONN_BASE,
        'XARF::Report::Connection::DDoS' );
};

subtest 'dispatch connection/infected_host' => sub {
    check_dispatch( 'connection', 'infected_host',
        { %CONN_BASE, bot_type => 'mirai' },
        'XARF::Report::Connection::InfectedHost' );
};

subtest 'dispatch connection/reconnaissance' => sub {
    check_dispatch( 'connection', 'reconnaissance',
        { %CONN_BASE, probed_resources => ['/admin'] },
        'XARF::Report::Connection::Reconnaissance' );
};

subtest 'dispatch connection/scraping' => sub {
    check_dispatch( 'connection', 'scraping',
        { %CONN_BASE, total_requests => 5000 },
        'XARF::Report::Connection::Scraping' );
};

subtest 'dispatch connection/sql_injection' => sub {
    check_dispatch( 'connection', 'sql_injection', \%CONN_BASE,
        'XARF::Report::Connection::SqlInjection' );
};

subtest 'dispatch connection/vulnerability_scan' => sub {
    check_dispatch( 'connection', 'vulnerability_scan',
        { %CONN_BASE, scan_type => 'full' },
        'XARF::Report::Connection::VulnerabilityScan' );
};

# ---------------------------------------------------------------------------
# Content (9 types)
# ---------------------------------------------------------------------------

my %CONTENT_BASE = ( url => 'https://abuse.example.com/bad' );

subtest 'dispatch content/phishing' => sub {
    check_dispatch( 'content', 'phishing', \%CONTENT_BASE,
        'XARF::Report::Content::Phishing' );
};

subtest 'dispatch content/malware' => sub {
    check_dispatch( 'content', 'malware', \%CONTENT_BASE,
        'XARF::Report::Content::Malware' );
};

subtest 'dispatch content/csam' => sub {
    check_dispatch( 'content', 'csam',
        { %CONTENT_BASE, classification => 'A', detection_method => 'hash_match' },
        'XARF::Report::Content::Csam' );
};

subtest 'dispatch content/csem' => sub {
    check_dispatch( 'content', 'csem',
        { %CONTENT_BASE, detection_method => 'ai_detection', exploitation_type => 'grooming' },
        'XARF::Report::Content::Csem' );
};

subtest 'dispatch content/exposed_data' => sub {
    check_dispatch( 'content', 'exposed_data',
        { %CONTENT_BASE, data_types => ['email'], exposure_method => 'public_bucket' },
        'XARF::Report::Content::ExposedData' );
};

subtest 'dispatch content/brand_infringement' => sub {
    check_dispatch( 'content', 'brand_infringement',
        { %CONTENT_BASE, infringement_type => 'logo', legitimate_site => 'https://legit.example.com' },
        'XARF::Report::Content::BrandInfringement' );
};

subtest 'dispatch content/fraud' => sub {
    check_dispatch( 'content', 'fraud',
        { %CONTENT_BASE, fraud_type => 'advance_fee' },
        'XARF::Report::Content::Fraud' );
};

subtest 'dispatch content/remote_compromise' => sub {
    check_dispatch( 'content', 'remote_compromise',
        { %CONTENT_BASE, compromise_type => 'webshell' },
        'XARF::Report::Content::RemoteCompromise' );
};

subtest 'dispatch content/suspicious_registration' => sub {
    check_dispatch( 'content', 'suspicious_registration',
        { %CONTENT_BASE, registration_date => '2024-01-01', suspicious_indicators => ['typosquat'] },
        'XARF::Report::Content::SuspiciousRegistration' );
};

# ---------------------------------------------------------------------------
# Copyright (6 types)
# ---------------------------------------------------------------------------

subtest 'dispatch copyright/copyright' => sub {
    check_dispatch( 'copyright', 'copyright',
        { infringing_url => 'https://infringe.example.com/file' },
        'XARF::Report::Copyright::Copyright' );
};

subtest 'dispatch copyright/p2p' => sub {
    check_dispatch( 'copyright', 'p2p',
        { p2p_protocol => 'bittorrent', swarm_info => { info_hash => 'abc' } },
        'XARF::Report::Copyright::P2P' );
};

subtest 'dispatch copyright/cyberlocker' => sub {
    check_dispatch( 'copyright', 'cyberlocker',
        { hosting_service => 'mega', infringing_url => 'https://mega.example.com/file' },
        'XARF::Report::Copyright::Cyberlocker' );
};

subtest 'dispatch copyright/ugc_platform' => sub {
    check_dispatch( 'copyright', 'ugc_platform',
        { infringing_url => 'https://ugc.example.com/video', platform_name => 'VideoSite' },
        'XARF::Report::Copyright::UgcPlatform' );
};

subtest 'dispatch copyright/link_site' => sub {
    check_dispatch( 'copyright', 'link_site',
        { infringing_url => 'https://links.example.com/page', site_name => 'LinkSite' },
        'XARF::Report::Copyright::LinkSite' );
};

subtest 'dispatch copyright/usenet' => sub {
    check_dispatch( 'copyright', 'usenet',
        { newsgroup => 'alt.binaries.movies', message_info => { message_id => '<123@nntp.example>' } },
        'XARF::Report::Copyright::Usenet' );
};

# ---------------------------------------------------------------------------
# Infrastructure (2 types)
# ---------------------------------------------------------------------------

subtest 'dispatch infrastructure/botnet' => sub {
    check_dispatch( 'infrastructure', 'botnet',
        { compromise_evidence => 'C2 traffic' },
        'XARF::Report::Infrastructure::Botnet' );
};

subtest 'dispatch infrastructure/compromised_server' => sub {
    check_dispatch( 'infrastructure', 'compromised_server',
        { compromise_method => 'brute_force' },
        'XARF::Report::Infrastructure::CompromisedServer' );
};

# ---------------------------------------------------------------------------
# Vulnerability (3 types)
# ---------------------------------------------------------------------------

subtest 'dispatch vulnerability/cve' => sub {
    check_dispatch( 'vulnerability', 'cve',
        { service => 'ssh', cve_id => 'CVE-2024-1234', service_port => 22 },
        'XARF::Report::Vulnerability::Cve' );
};

subtest 'dispatch vulnerability/open_service' => sub {
    check_dispatch( 'vulnerability', 'open_service',
        { service => 'rdp' },
        'XARF::Report::Vulnerability::OpenService' );
};

subtest 'dispatch vulnerability/misconfiguration' => sub {
    check_dispatch( 'vulnerability', 'misconfiguration',
        { service => 'smtp' },
        'XARF::Report::Vulnerability::Misconfiguration' );
};

# ---------------------------------------------------------------------------
# Reputation (2 types)
# ---------------------------------------------------------------------------

subtest 'dispatch reputation/blocklist' => sub {
    check_dispatch( 'reputation', 'blocklist',
        { threat_type => 'spam_source' },
        'XARF::Report::Reputation::Blocklist' );
};

subtest 'dispatch reputation/threat_intelligence' => sub {
    check_dispatch( 'reputation', 'threat_intelligence',
        { threat_type => 'c2_server' },
        'XARF::Report::Reputation::ThreatIntelligence' );
};

# ---------------------------------------------------------------------------
# Unknown type returns undef
# ---------------------------------------------------------------------------

subtest 'from_hashref returns undef for unknown type' => sub {
    my $r = XARF::Report->from_hashref( {
        %BASE,
        category => 'messaging',
        type     => 'nonexistent_type',
    } );
    is( $r, undef, 'unknown type returns undef' );
};

subtest 'from_hashref returns undef for unknown category' => sub {
    my $r = XARF::Report->from_hashref( {
        %BASE,
        category => 'unknown_category',
        type     => 'spam',
    } );
    is( $r, undef, 'unknown category returns undef' );
};

done_testing;
