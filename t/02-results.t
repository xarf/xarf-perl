use v5.40;
use Test2::V0;

use XARF::ValidationError;
use XARF::ValidationWarning;
use XARF::Result::Parse;
use XARF::Result::CreateReport;

# ---------------------------------------------------------------------------
# XARF::ValidationError
# ---------------------------------------------------------------------------

subtest 'ValidationError — required message' => sub {
    ok( dies { XARF::ValidationError->new() }, 'dies without message' );
};

subtest 'ValidationError — basic construction' => sub {
    my $err = XARF::ValidationError->new(
        field   => 'source_identifier',
        message => 'must be an IP address',
        value   => 'not-an-ip',
    );
    is( $err->field,   'source_identifier',    'field attribute' );
    is( $err->message, 'must be an IP address', 'message attribute' );
    is( $err->value,   'not-an-ip',             'value attribute' );
};

subtest 'ValidationError — field defaults to empty string' => sub {
    my $err = XARF::ValidationError->new( message => 'general error' );
    is( $err->field, '', 'field defaults to empty string' );
};

subtest 'ValidationError — value defaults to undef' => sub {
    my $err = XARF::ValidationError->new( message => 'no value' );
    is( $err->value, undef, 'value defaults to undef' );
};

# ---------------------------------------------------------------------------
# XARF::ValidationWarning
# ---------------------------------------------------------------------------

subtest 'ValidationWarning — required message' => sub {
    ok( dies { XARF::ValidationWarning->new() }, 'dies without message' );
};

subtest 'ValidationWarning — basic construction' => sub {
    my $warn = XARF::ValidationWarning->new(
        field   => 'confidence',
        message => 'recommended field is missing',
    );
    is( $warn->field,   'confidence',                'field attribute' );
    is( $warn->message, 'recommended field is missing', 'message attribute' );
};

subtest 'ValidationWarning — field defaults to empty string' => sub {
    my $warn = XARF::ValidationWarning->new( message => 'general warning' );
    is( $warn->field, '', 'field defaults to empty string' );
};

# ---------------------------------------------------------------------------
# XARF::Result::Parse
# ---------------------------------------------------------------------------

subtest 'Result::Parse — defaults' => sub {
    my $result = XARF::Result::Parse->new();
    is( $result->report,   undef, 'report defaults to undef' );
    is( $result->errors,   [],    'errors defaults to empty arrayref' );
    is( $result->warnings, [],    'warnings defaults to empty arrayref' );
    is( $result->info,     undef, 'info defaults to undef' );
};

subtest 'Result::Parse — with errors' => sub {
    my $err = XARF::ValidationError->new( message => 'bad field' );
    my $result = XARF::Result::Parse->new( errors => [$err] );
    is( scalar @{ $result->errors }, 1,     'one error stored' );
    is( $result->errors->[0]->message, 'bad field', 'error message preserved' );
};

subtest 'Result::Parse — with warnings' => sub {
    my $warn = XARF::ValidationWarning->new( message => 'missing recommended' );
    my $result = XARF::Result::Parse->new( warnings => [$warn] );
    is( scalar @{ $result->warnings }, 1, 'one warning stored' );
    is( $result->warnings->[0]->message, 'missing recommended', 'warning message preserved' );
};

subtest 'Result::Parse — with info' => sub {
    my $result = XARF::Result::Parse->new( info => { missing => ['confidence'] } );
    is( $result->info->{missing}, ['confidence'], 'info hashref stored' );
};

# ---------------------------------------------------------------------------
# XARF::Result::CreateReport
# ---------------------------------------------------------------------------

subtest 'Result::CreateReport — defaults' => sub {
    my $result = XARF::Result::CreateReport->new();
    is( $result->report,   undef, 'report defaults to undef' );
    is( $result->errors,   [],    'errors defaults to empty arrayref' );
    is( $result->warnings, [],    'warnings defaults to empty arrayref' );
    is( $result->info,     undef, 'info defaults to undef' );
};

subtest 'Result::CreateReport — with info' => sub {
    my $result = XARF::Result::CreateReport->new( info => [ { field => 'confidence', message => 'OPTIONAL: ...' } ] );
    ref_ok( $result->info, 'ARRAY', 'info is arrayref' );
    is( $result->info->[0]{field}, 'confidence', 'info entry stored' );
};

subtest 'Result::CreateReport — with errors' => sub {
    my $err = XARF::ValidationError->new( message => 'missing category' );
    my $result = XARF::Result::CreateReport->new( errors => [$err] );
    is( scalar @{ $result->errors }, 1, 'one error stored' );
    is( $result->errors->[0]->message, 'missing category', 'error message preserved' );
};

subtest 'Result::CreateReport — with warnings' => sub {
    my $warn = XARF::ValidationWarning->new( message => 'no evidence provided' );
    my $result = XARF::Result::CreateReport->new( warnings => [$warn] );
    is( scalar @{ $result->warnings }, 1, 'one warning stored' );
};

done_testing;
