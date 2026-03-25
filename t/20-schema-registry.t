use v5.40;
use Test2::V0;
use Scalar::Util qw(refaddr);

use XARF::SchemaRegistry;
use XARF::FieldMetadata;

# Reset the singleton once at file scope so any previous test run's instance
# does not bleed into this one.  Individual subtests share the same instance;
# that is fine because the registry is read-only after initialisation.
XARF::SchemaRegistry->_reset_instance;

# ---------------------------------------------------------------------------
# Singleton behaviour
# ---------------------------------------------------------------------------

subtest 'instance returns same object on repeated calls' => sub {
    my $r1 = XARF::SchemaRegistry->instance;
    my $r2 = XARF::SchemaRegistry->instance;
    is( $r1, $r2, 'same reference returned' );
};

subtest '_reset_instance forces re-initialisation' => sub {
    my $r1 = XARF::SchemaRegistry->instance;
    XARF::SchemaRegistry->_reset_instance;
    my $r2 = XARF::SchemaRegistry->instance;
    ok( refaddr($r1) != refaddr($r2), 'new object after reset' );
};

# ---------------------------------------------------------------------------
# is_loaded
# ---------------------------------------------------------------------------

subtest 'is_loaded returns 1 when core schema is present' => sub {
    my $r = XARF::SchemaRegistry->instance;
    is( $r->is_loaded, 1, 'is_loaded is true' );
};

# ---------------------------------------------------------------------------
# get_categories
# ---------------------------------------------------------------------------

subtest 'get_categories returns an arrayref' => sub {
    my $r    = XARF::SchemaRegistry->instance;
    my $cats = $r->get_categories;
    ok( ref($cats) eq 'ARRAY', 'get_categories returns arrayref' );
};

subtest 'get_categories contains the 7 expected categories' => sub {
    my $r    = XARF::SchemaRegistry->instance;
    my %cats = map { $_ => 1 } @{ $r->get_categories };
    ok( $cats{messaging},       'messaging present' );
    ok( $cats{connection},      'connection present' );
    ok( $cats{content},         'content present' );
    ok( $cats{infrastructure},  'infrastructure present' );
    ok( $cats{copyright},       'copyright present' );
    ok( $cats{vulnerability},   'vulnerability present' );
    ok( $cats{reputation},      'reputation present' );
    is( scalar keys %cats, 7, 'exactly 7 categories' );
};

# ---------------------------------------------------------------------------
# is_valid_category
# ---------------------------------------------------------------------------

subtest 'is_valid_category — known category' => sub {
    my $r = XARF::SchemaRegistry->instance;
    is( $r->is_valid_category('messaging'), 1, 'messaging is valid' );
};

subtest 'is_valid_category — unknown category' => sub {
    my $r = XARF::SchemaRegistry->instance;
    is( $r->is_valid_category('unicorn'), 0, 'unicorn is not valid' );
};

# ---------------------------------------------------------------------------
# get_types_for_category
# ---------------------------------------------------------------------------

subtest 'get_types_for_category returns arrayref for known category' => sub {
    my $r     = XARF::SchemaRegistry->instance;
    my $types = $r->get_types_for_category('messaging');
    ok( ref($types) eq 'ARRAY', 'types is arrayref' );
    ok( scalar @$types > 0, 'at least one messaging type' );
};

subtest 'get_types_for_category — messaging contains spam and bulk_messaging' => sub {
    my $r     = XARF::SchemaRegistry->instance;
    my %types = map { $_ => 1 } @{ $r->get_types_for_category('messaging') };
    ok( $types{spam},          'spam present' );
    ok( $types{bulk_messaging}, 'bulk_messaging present' );
};

subtest 'get_types_for_category — connection types' => sub {
    my $r     = XARF::SchemaRegistry->instance;
    my %types = map { $_ => 1 } @{ $r->get_types_for_category('connection') };
    ok( $types{ddos},               'ddos present' );
    ok( $types{login_attack},       'login_attack present' );
    ok( $types{port_scan},          'port_scan present' );
    ok( $types{infected_host},      'infected_host present' );
    ok( $types{reconnaissance},     'reconnaissance present' );
    ok( $types{scraping},           'scraping present' );
    ok( $types{sql_injection},      'sql_injection present' );
    ok( $types{vulnerability_scan}, 'vulnerability_scan present' );
};

subtest 'get_types_for_category — unknown category returns empty arrayref' => sub {
    my $r     = XARF::SchemaRegistry->instance;
    my $types = $r->get_types_for_category('unicorn');
    ok( ref($types) eq 'ARRAY', 'arrayref' );
    is( scalar @$types, 0, 'empty' );
};

subtest 'get_types_for_category result is sorted' => sub {
    my $r     = XARF::SchemaRegistry->instance;
    my $types = $r->get_types_for_category('connection');
    my @sorted = sort @$types;
    is( $types, \@sorted, 'types are sorted alphabetically' );
};

# ---------------------------------------------------------------------------
# get_all_types
# ---------------------------------------------------------------------------

subtest 'get_all_types returns hashref of all categories' => sub {
    my $r   = XARF::SchemaRegistry->instance;
    my $all = $r->get_all_types;
    ok( ref($all) eq 'HASH', 'get_all_types returns hashref' );
    ok( exists $all->{messaging},      'messaging key present' );
    ok( exists $all->{connection},     'connection key present' );
    ok( exists $all->{content},        'content key present' );
    ok( exists $all->{infrastructure}, 'infrastructure key present' );
    ok( exists $all->{copyright},      'copyright key present' );
    ok( exists $all->{vulnerability},  'vulnerability key present' );
    ok( exists $all->{reputation},     'reputation key present' );
};

# ---------------------------------------------------------------------------
# is_valid_type
# ---------------------------------------------------------------------------

subtest 'is_valid_type — known pair' => sub {
    my $r = XARF::SchemaRegistry->instance;
    is( $r->is_valid_type( 'messaging', 'spam' ), 1, 'messaging/spam is valid' );
};

subtest 'is_valid_type — unknown type in known category' => sub {
    my $r = XARF::SchemaRegistry->instance;
    is( $r->is_valid_type( 'messaging', 'carrier_pigeon' ), 0, 'not valid' );
};

subtest 'is_valid_type — unknown category' => sub {
    my $r = XARF::SchemaRegistry->instance;
    is( $r->is_valid_type( 'unicorn', 'spam' ), 0, 'not valid' );
};

subtest 'is_valid_type — all 32 known types are valid' => sub {
    my $r = XARF::SchemaRegistry->instance;
    my @pairs = (
        [ messaging      => 'spam' ],
        [ messaging      => 'bulk_messaging' ],
        [ connection     => 'ddos' ],
        [ connection     => 'login_attack' ],
        [ connection     => 'port_scan' ],
        [ connection     => 'infected_host' ],
        [ connection     => 'reconnaissance' ],
        [ connection     => 'scraping' ],
        [ connection     => 'sql_injection' ],
        [ connection     => 'vulnerability_scan' ],
        [ content        => 'phishing' ],
        [ content        => 'malware' ],
        [ content        => 'csam' ],
        [ content        => 'csem' ],
        [ content        => 'exposed_data' ],
        [ content        => 'brand_infringement' ],
        [ content        => 'fraud' ],
        [ content        => 'remote_compromise' ],
        [ content        => 'suspicious_registration' ],
        [ copyright      => 'copyright' ],
        [ copyright      => 'p2p' ],
        [ copyright      => 'cyberlocker' ],
        [ copyright      => 'ugc_platform' ],
        [ copyright      => 'link_site' ],
        [ copyright      => 'usenet' ],
        [ infrastructure => 'botnet' ],
        [ infrastructure => 'compromised_server' ],
        [ vulnerability  => 'cve' ],
        [ vulnerability  => 'open_service' ],
        [ vulnerability  => 'misconfiguration' ],
        [ reputation     => 'blocklist' ],
        [ reputation     => 'threat_intelligence' ],
    );
    for my $pair (@pairs) {
        my ( $cat, $type ) = @$pair;
        is( $r->is_valid_type( $cat, $type ), 1, "$cat/$type is valid" );
    }
};

# ---------------------------------------------------------------------------
# get_required_fields
# ---------------------------------------------------------------------------

subtest 'get_required_fields returns an arrayref' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $fields = $r->get_required_fields;
    ok( ref($fields) eq 'ARRAY', 'get_required_fields returns arrayref' );
};

subtest 'get_required_fields includes the 8 core required fields' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my %fields = map { $_ => 1 } @{ $r->get_required_fields };
    ok( $fields{xarf_version},      'xarf_version required' );
    ok( $fields{report_id},         'report_id required' );
    ok( $fields{timestamp},         'timestamp required' );
    ok( $fields{reporter},          'reporter required' );
    ok( $fields{sender},            'sender required' );
    ok( $fields{source_identifier}, 'source_identifier required' );
    ok( $fields{category},          'category required' );
    ok( $fields{type},              'type required' );
};

# ---------------------------------------------------------------------------
# get_contact_required_fields
# ---------------------------------------------------------------------------

subtest 'get_contact_required_fields returns an arrayref' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $fields = $r->get_contact_required_fields;
    ok( ref($fields) eq 'ARRAY', 'get_contact_required_fields returns arrayref' );
};

subtest 'get_contact_required_fields includes org, contact, domain' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my %fields = map { $_ => 1 } @{ $r->get_contact_required_fields };
    ok( $fields{org},     'org required' );
    ok( $fields{contact}, 'contact required' );
    ok( $fields{domain},  'domain required' );
};

# ---------------------------------------------------------------------------
# get_type_schema
# ---------------------------------------------------------------------------

subtest 'get_type_schema — known type returns hashref' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $schema = $r->get_type_schema( 'messaging', 'spam' );
    ok( defined $schema,           'schema defined' );
    ok( ref($schema) eq 'HASH',   'schema is hashref' );
};

subtest 'get_type_schema — unknown type returns undef' => sub {
    my $r = XARF::SchemaRegistry->instance;
    is( $r->get_type_schema( 'messaging', 'nonexistent' ), undef, 'undef for unknown type' );
};

subtest 'get_type_schema — spam schema has allOf' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $schema = $r->get_type_schema( 'messaging', 'spam' );
    ok( exists $schema->{allOf}, 'allOf present in spam schema' );
};

# ---------------------------------------------------------------------------
# get_field_metadata
# ---------------------------------------------------------------------------

subtest 'get_field_metadata — known required field' => sub {
    my $r    = XARF::SchemaRegistry->instance;
    my $meta = $r->get_field_metadata('source_identifier');
    ok( defined $meta,                          'meta defined' );
    isa_ok( $meta, 'XARF::FieldMetadata' );
    is( $meta->required,    1, 'required is 1' );
    is( $meta->recommended, 0, 'recommended is 0' );
    ok( length $meta->description, 'description non-empty' );
};

subtest 'get_field_metadata — recommended field' => sub {
    my $r    = XARF::SchemaRegistry->instance;
    my $meta = $r->get_field_metadata('source_port');
    ok( defined $meta,          'meta defined' );
    is( $meta->recommended, 1, 'source_port is recommended' );
    is( $meta->required,    0, 'source_port is not required' );
    is( $meta->type, 'integer', 'type is integer' );
    is( $meta->minimum, 1,     'minimum is 1' );
    is( $meta->maximum, 65535, 'maximum is 65535' );
};

subtest 'get_field_metadata — enum field (category)' => sub {
    my $r    = XARF::SchemaRegistry->instance;
    my $meta = $r->get_field_metadata('category');
    ok( defined $meta,                        'meta defined' );
    ok( ref( $meta->enum ) eq 'ARRAY',        'enum is arrayref' );
    ok( scalar @{ $meta->enum } == 7,         '7 enum values' );
};

subtest 'get_field_metadata — format field (report_id)' => sub {
    my $r    = XARF::SchemaRegistry->instance;
    my $meta = $r->get_field_metadata('report_id');
    ok( defined $meta,        'meta defined' );
    is( $meta->format, 'uuid', 'format is uuid' );
};

subtest 'get_field_metadata — unknown field returns undef' => sub {
    my $r = XARF::SchemaRegistry->instance;
    is( $r->get_field_metadata('no_such_field'), undef, 'undef for unknown field' );
};

# ---------------------------------------------------------------------------
# get_core_property_names
# ---------------------------------------------------------------------------

subtest 'get_core_property_names returns an arrayref' => sub {
    my $r     = XARF::SchemaRegistry->instance;
    my $names = $r->get_core_property_names;
    ok( ref($names) eq 'ARRAY', 'returns arrayref' );
    ok( scalar @$names > 0,     'non-empty' );
};

subtest 'get_core_property_names includes known core fields' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my %names  = map { $_ => 1 } @{ $r->get_core_property_names };
    ok( $names{xarf_version},      'xarf_version' );
    ok( $names{report_id},         'report_id' );
    ok( $names{category},          'category' );
    ok( $names{source_identifier}, 'source_identifier' );
};

subtest 'get_core_property_names result is sorted' => sub {
    my $r     = XARF::SchemaRegistry->instance;
    my $names = $r->get_core_property_names;
    my @sorted = sort @$names;
    is( $names, \@sorted, 'sorted alphabetically' );
};

# ---------------------------------------------------------------------------
# get_category_fields
# ---------------------------------------------------------------------------

subtest 'get_category_fields — messaging/spam returns type-specific fields' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $fields = $r->get_category_fields( 'messaging', 'spam' );
    ok( ref($fields) eq 'ARRAY', 'returns arrayref' );
    my %f = map { $_ => 1 } @$fields;
    ok( $f{protocol},   'protocol present' );
    ok( $f{smtp_from},  'smtp_from present' );
    ok( $f{smtp_to},    'smtp_to present' );
    ok( $f{subject},    'subject present' );
};

subtest 'get_category_fields — does not include core fields' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my %core   = map { $_ => 1 } @{ $r->get_core_property_names };
    my $fields = $r->get_category_fields( 'messaging', 'spam' );
    for my $f (@$fields) {
        ok( !$core{$f}, "category field '$f' is not a core field" );
    }
};

subtest 'get_category_fields — content/phishing includes fields from content-base' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $fields = $r->get_category_fields( 'content', 'phishing' );
    my %f      = map { $_ => 1 } @$fields;
    ok( $f{url},               'url (from content-base) present' );
    ok( $f{credential_fields}, 'credential_fields (phishing-specific) present' );
};

subtest 'get_category_fields — unknown type returns empty arrayref' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $fields = $r->get_category_fields( 'messaging', 'nonexistent' );
    ok( ref($fields) eq 'ARRAY', 'returns arrayref' );
    is( scalar @$fields, 0, 'empty' );
};

# ---------------------------------------------------------------------------
# get_all_fields_for_category
# ---------------------------------------------------------------------------

subtest 'get_all_fields_for_category — messaging has fields from all types' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $fields = $r->get_all_fields_for_category('messaging');
    ok( ref($fields) eq 'ARRAY', 'returns arrayref' );
    my %f = map { $_ => 1 } @$fields;
    ok( $f{protocol}, 'protocol present (from spam)' );
};

subtest 'get_all_fields_for_category — unknown category returns empty arrayref' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $fields = $r->get_all_fields_for_category('unicorn');
    ok( ref($fields) eq 'ARRAY', 'returns arrayref' );
    is( scalar @$fields, 0, 'empty' );
};

subtest 'get_all_fields_for_category — no duplicates' => sub {
    my $r      = XARF::SchemaRegistry->instance;
    my $fields = $r->get_all_fields_for_category('connection');
    my %seen;
    for my $f (@$fields) {
        ok( !$seen{$f}, "no duplicate: $f" );
        $seen{$f} = 1;
    }
};

done_testing;
