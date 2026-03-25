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
# Basic TO_JSON round-trip
# ---------------------------------------------------------------------------

subtest 'TO_JSON contains all set required fields' => sub {
    my $r   = XARF::Report->new(%BASE);
    my $out = $r->TO_JSON;

    is( ref $out, 'HASH', 'returns a hashref' );
    is( $out->{xarf_version},      '4.2.0',    'xarf_version present' );
    is( $out->{report_id},         $BASE{report_id}, 'report_id present' );
    is( $out->{category},          'messaging', 'category present' );
    is( $out->{type},              'spam',      'type present' );
    is( $out->{source_identifier}, '192.0.2.1', 'source_identifier present' );
    is( $out->{reporter}, $BASE{reporter}, 'reporter present' );
    is( $out->{sender},   $BASE{sender},   'sender present' );
};

subtest 'TO_JSON omits undef optional fields' => sub {
    my $r   = XARF::Report->new(%BASE);
    my $out = $r->TO_JSON;

    ok( !exists $out->{evidence_source}, 'evidence_source absent' );
    ok( !exists $out->{source_port},     'source_port absent' );
    ok( !exists $out->{description},     'description absent' );
    ok( !exists $out->{evidence},        'evidence absent' );
    ok( !exists $out->{tags},            'tags absent' );
    ok( !exists $out->{confidence},      'confidence absent' );
    ok( !exists $out->{_internal},       '_internal absent' );
    ok( !exists $out->{_extra},          '_extra not in output' );
};

subtest 'TO_JSON includes set optional fields' => sub {
    my $r = XARF::Report->new(
        %BASE,
        evidence_source => 'spamtrap',
        source_port     => 25,
        description     => 'spam campaign',
        tags            => [ 'tag1', 'tag2' ],
        confidence      => 0.95,
    );
    my $out = $r->TO_JSON;

    is( $out->{evidence_source}, 'spamtrap',       'evidence_source' );
    is( $out->{source_port},     25,                'source_port' );
    is( $out->{description},     'spam campaign',   'description' );
    is( $out->{confidence},      0.95,              'confidence' );
    is( $out->{tags}, [ 'tag1', 'tag2' ], 'tags' );
};

# ---------------------------------------------------------------------------
# _extra round-trip — unknown fields are preserved
# ---------------------------------------------------------------------------

subtest 'TO_JSON merges _extra fields into output' => sub {
    my $r   = XARF::Report->new( %BASE, custom_extension => 'my_value', x_org_field => 99 );
    my $out = $r->TO_JSON;

    is( $out->{custom_extension}, 'my_value', 'custom_extension preserved' );
    is( $out->{x_org_field},      99,          'x_org_field preserved' );
    ok( !exists $out->{_extra},  '_extra key not leaked' );
};

subtest '_extra does not shadow known fields' => sub {
    # If somehow _extra had a key that matched a known field, the known field wins.
    # We test that known fields come through correctly when extra fields also exist.
    my $r   = XARF::Report->new( %BASE, extra_1 => 'a', extra_2 => 'b' );
    my $out = $r->TO_JSON;

    is( $out->{category}, 'messaging', 'category not shadowed' );
    is( $out->{extra_1},  'a',         'extra_1 present' );
    is( $out->{extra_2},  'b',         'extra_2 present' );
};

# ---------------------------------------------------------------------------
# Subclass TO_JSON includes category-specific fields
# ---------------------------------------------------------------------------

subtest 'Spam TO_JSON includes messaging fields' => sub {
    my $r = XARF::Report::Messaging::Spam->new(
        %BASE,
        category   => 'messaging',
        type       => 'spam',
        protocol   => 'smtp',
        smtp_from  => 'spammer@evil.example',
        language   => 'en',
    );
    my $out = $r->TO_JSON;

    is( $out->{protocol},  'smtp',                 'protocol' );
    is( $out->{smtp_from}, 'spammer@evil.example', 'smtp_from' );
    is( $out->{language},  'en',                   'language' );
};

subtest 'DDoS TO_JSON includes connection and ddos-specific fields' => sub {
    my $r = XARF::Report::Connection::DDoS->new(
        %BASE,
        category       => 'connection',
        type           => 'ddos',
        protocol       => 'udp',
        first_seen     => '2024-01-15T14:00:00Z',
        peak_pps       => 500000,
        attack_vector  => 'udp_flood',
    );
    my $out = $r->TO_JSON;

    is( $out->{protocol},     'udp',       'protocol' );
    is( $out->{first_seen},   '2024-01-15T14:00:00Z', 'first_seen' );
    is( $out->{peak_pps},     500000,      'peak_pps' );
    is( $out->{attack_vector},'udp_flood', 'attack_vector' );
    ok( !exists $out->{amplification_factor}, 'absent optional not present' );
};

# ---------------------------------------------------------------------------
# from_hashref → TO_JSON round-trip preserves all data
# ---------------------------------------------------------------------------

subtest 'from_hashref then TO_JSON is a round-trip' => sub {
    my %data = (
        %BASE,
        category        => 'messaging',
        type            => 'spam',
        protocol        => 'smtp',
        smtp_from       => 'bad@evil.example',
        subject         => 'Win a prize!',
        evidence_source => 'spamtrap',
        source_port     => 25,
        evidence        => [ { content_type => 'message/rfc822', payload => 'dGVzdA==' } ],
        tags            => [ 'spam:commercial' ],
        confidence      => 0.9,
        custom_field    => 'preserved',
    );

    my $report = XARF::Report->from_hashref( \%data );
    my $out    = $report->TO_JSON;

    is( $out->{protocol},        'smtp',              'protocol' );
    is( $out->{smtp_from},       'bad@evil.example',  'smtp_from' );
    is( $out->{subject},         'Win a prize!',      'subject' );
    is( $out->{evidence_source}, 'spamtrap',          'evidence_source' );
    is( $out->{source_port},     25,                  'source_port' );
    is( $out->{confidence},      0.9,                 'confidence' );
    is( $out->{custom_field},    'preserved',         'custom_field (extra)' );
    is( $out->{tags},     [ 'spam:commercial' ], 'tags' );
    is( $out->{evidence}, [ { content_type => 'message/rfc822', payload => 'dGVzdA==' } ],
        'evidence' );
};

subtest 'Vulnerability Cve round-trip' => sub {
    my %data = (
        %BASE,
        category     => 'vulnerability',
        type         => 'cve',
        service      => 'ssh',
        cve_id       => 'CVE-2024-9999',
        service_port => 22,
        cvss_score   => 9.8,
        patch_available => 0,
    );
    my $report = XARF::Report->from_hashref( \%data );
    isa_ok( $report, 'XARF::Report::Vulnerability::Cve' );
    my $out = $report->TO_JSON;
    is( $out->{cve_id},       'CVE-2024-9999', 'cve_id' );
    is( $out->{service_port}, 22,              'service_port' );
    is( $out->{cvss_score},   9.8,             'cvss_score' );
    # patch_available => 0 is defined (false but not undef), should be present
    ok( exists $out->{patch_available}, 'patch_available 0 is present in output' );
};

done_testing;
