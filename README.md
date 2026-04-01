# XARF Perl Library

![XARF Spec](https://img.shields.io/badge/XARF%20Spec-v4.2.0-blue)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Perl library for parsing, validating, and generating [XARF v4](https://xarf.org)
(eXtended Abuse Reporting Format) reports.

## Features

- **Parse** XARF reports from JSON strings or hashrefs with validation and typed results
- **Generate** XARF-compliant reports with auto-generated metadata (UUIDs, timestamps)
- **Validate** reports against the official JSON schemas with detailed errors and warnings
- **v3 backward compatibility** with automatic detection and conversion
- **Schema-driven** — validation rules derived from the official [xarf-spec](https://github.com/xarf/xarf-spec) schemas, not hardcoded

## Installation

```
cpanm XARF
```

Or from source:

```
perl Makefile.PL
make
make test
make install
```

## Quick Start

### Parsing a Report

```perl
use XARF qw(parse);

# Missing first_seen and source_port produce validation errors.
my $result = parse({
    xarf_version      => '4.2.0',
    report_id         => 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    timestamp         => '2024-01-15T10:30:00Z',
    # first_seen      => '2024-01-15T10:00:00Z',
    reporter => {
        org     => 'Security Team',
        contact => 'abuse@example.com',
        domain  => 'example.com',
    },
    sender => {
        org     => 'Security Team',
        contact => 'abuse@example.com',
        domain  => 'example.com',
    },
    source_identifier => '192.0.2.100',
    # source_port     => 1234,
    category          => 'connection',
    type              => 'ddos',
    evidence_source   => 'honeypot',
    destination_ip    => '203.0.113.10',
    protocol          => 'tcp',
});

if ( !@{ $result->errors } ) {
    say $result->report->category;   # 'connection'
} else {
    say $_->field, ': ', $_->message for @{ $result->errors };
}
```

### Creating a Report

```perl
use XARF qw(create_report create_evidence);

# Returns an XARF::Evidence object with base64-encoded payload,
# computed hash, and size.
my $evidence = create_evidence(
    content_type => 'message/rfc822',
    payload      => $raw_email,
    description  => 'Original spam email',
);

# xarf_version, report_id, and timestamp are auto-generated.
my $result = create_report(
    category          => 'messaging',
    type              => 'spam',
    source_identifier => '192.0.2.100',
    reporter => {
        org     => 'Example Security',
        contact => 'abuse@example.com',
        domain  => 'example.com',
    },
    sender => {
        org     => 'Example Security',
        contact => 'abuse@example.com',
        domain  => 'example.com',
    },
    evidence_source => 'spamtrap',
    description     => 'Spam email detected from source',
    protocol        => 'smtp',
    smtp_from       => 'spammer@evil.example.com',
    evidence        => [$evidence],
);

use JSON::MaybeXS qw(encode_json);
say encode_json( $result->report->TO_JSON ) unless @{ $result->errors };
```

## API Reference

### `parse( $json_data, %opts )`

Parse and validate a XARF report from JSON. Supports both v4 and v3 (legacy)
formats — v3 reports are automatically converted to v4 with deprecation warnings.

```perl
use XARF qw(parse);

my $result = parse( $json_string_or_hashref, %opts );
```

**Parameters:**

- `$json_data` — JSON string or already-decoded hashref containing a XARF report
- `strict => 0|1` — treat `x-recommended` fields as required and unknown fields as
  errors (default: `0`)
- `show_missing_optional => 0|1` — populate `$result->info` with missing optional and
  recommended fields (default: `0`)

Dies with `XARF::ParseError` if passed a string that is not valid JSON, or if an
auto-detected v3 report cannot be converted.

**Returns `XARF::Result::Parse`:**

- `$result->report` — `XARF::Report` subclass (e.g. `XARF::Report::Messaging::Spam`), or `undef` if the category/type could not be determined
- `$result->errors` — arrayref of `XARF::ValidationError` objects (empty if valid)
- `$result->warnings` — arrayref of `XARF::ValidationWarning` objects
- `$result->info` — arrayref of `{ field => $name, message => $text }` hashrefs, or `undef` (only populated when `show_missing_optional` is true)

### `create_report( %args )`

Create a validated XARF report with auto-generated metadata. Automatically fills
`xarf_version`, `report_id` (UUID v4), and `timestamp` (ISO 8601 UTC) if not provided.

```perl
use XARF qw(create_report);

my $result = create_report( %args );
```

**Required args:** `category`, `type`, `source_identifier`, `reporter`, `sender`

**Optional args:** `report_id`, `timestamp`, `strict`, `show_missing_optional`, plus
any category/type-specific fields defined by the spec.

**Returns `XARF::Result::CreateReport`** — same structure as `XARF::Result::Parse`.
The `report` attribute is always populated when the category and type are
recognisable; validation errors are informational, not fatal.

### `create_evidence( %args )`

Create an `XARF::Evidence` object with automatic base64 encoding, hashing, and
size calculation.

```perl
use XARF qw(create_evidence);

my $evidence = create_evidence(
    content_type   => 'message/rfc822',   # required
    payload        => $raw_bytes,          # required
    description    => 'Original email',    # optional
    hash_algorithm => 'sha256',            # optional; default 'sha256'
);
```

**`hash_algorithm`** accepts: `sha256` (default), `sha512`, `sha1`, `md5`.

**Returns `XARF::Evidence`** with attributes: `content_type`, `payload` (base64),
`hash`, `size`, `description`.

### `XARF::SchemaRegistry`

Access schema-derived validation rules and metadata without hardcoded lists.

```perl
use XARF::SchemaRegistry;

my $registry = XARF::SchemaRegistry->instance;

# All valid categories
$registry->get_categories;
# ['messaging', 'connection', 'content', 'infrastructure',
#  'copyright', 'vulnerability', 'reputation']

# Valid types for a category
$registry->get_types_for_category('connection');
# ['ddos', 'port_scan', 'login_attack', ...]

# Validity checks
$registry->is_valid_category('connection');       # 1
$registry->is_valid_type('connection', 'ddos');   # 1

# Field metadata from the schema
my $meta = $registry->get_field_metadata('confidence');
# XARF::FieldMetadata with ->description, ->required, ->recommended, ...
```

### Validation Details

Both `parse()` and `create_report()` run validation internally. Additional behaviours:

- **Unknown fields** trigger warnings (or errors in strict mode)
- **Missing optional fields** can be discovered with `show_missing_optional => 1`:

```perl
my $result = parse( $report, show_missing_optional => 1 );

for my $item ( @{ $result->info // [] } ) {
    say $item->{field}, ': ', $item->{message};
    # e.g. "description: OPTIONAL - Human-readable description of the abuse"
    # e.g. "confidence: RECOMMENDED - Confidence score between 0.0 and 1.0"
}
```

### Result Objects

`XARF::ValidationError` has:
- `->field` — the field name that failed validation
- `->message` — human-readable description of the failure
- `->value` — the offending value (may be `undef`)

`XARF::ValidationWarning` has:
- `->field` — the field name
- `->message` — description of the warning

### Report Objects

All report objects inherit from `XARF::Report` and expose every spec field as a
read-only accessor. Use `->category` and `->type` to identify the concrete report
type, or use `isa`:

```perl
my $report = $result->report;

say $report->category;   # 'messaging'
say $report->type;       # 'spam'

if ( $report->isa('XARF::Report::Messaging::Spam') ) {
    say $report->protocol;
}
```

Serialise back to a plain hashref for JSON encoding:

```perl
use JSON::MaybeXS qw(encode_json);

my $json = encode_json( $report->TO_JSON );
```

## v3 Backward Compatibility

The library automatically detects XARF v3 reports (identified by the `Version` field)
and converts them to v4 during parsing. Converted reports include `legacy_version: '3'`
and deprecation warnings.

```perl
use XARF qw(parse);

my $result = parse($v3_report);

say $result->report->xarf_version;    # '4.2.0'
say $result->report->category;        # mapped category, e.g. 'messaging'
say $result->report->legacy_version;  # '3'
# $result->warnings includes deprecation notice + conversion details
```

Low-level utilities are also available:

```perl
use XARF::V3Legacy qw(is_v3_report convert_v3_to_v4);

if ( is_v3_report($hashref) ) {
    my @warnings;
    my $v4 = convert_v3_to_v4( $hashref, \@warnings );
}
```

Unknown v3 report types cause a `XARF::ParseError` listing the supported types.

## Schema Management

This library validates against the official [xarf-spec](https://github.com/xarf/xarf-spec)
JSON schemas. Schemas are bundled inside the distribution as
[File::ShareDir](https://metacpan.org/pod/File::ShareDir) share files and work
offline after installation.

To fetch updated schemas (e.g. after a new spec release):

```
xarf-fetch-schemas
```

This installed CLI script downloads the schema tarball for the version declared in
`$XARF::SPEC_VERSION`, extracts `schemas/v4/` into the share directory, and records
the fetched version.

During library development, use the dev script instead:

```
perl script/fetch_schemas.pl
```

## Development

```bash
perl Makefile.PL && make          # build
prove -l t/                        # run tests
perlcritic --stern lib/            # lint
perltidy --check lib/**/*.pm       # formatting check
cover -test                        # coverage (requires Devel::Cover)
```

## Links

- [XARF Specification](https://xarf.org)
- [xarf-spec on GitHub](https://github.com/xarf/xarf-spec)
- [Issue Tracker](https://github.com/xarf/xarf-perl/issues)
- [License (MIT)](LICENSE)
