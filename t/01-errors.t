use v5.40;
use Test2::V0;

use XARF::Error;
use XARF::ParseError;
use XARF::SchemaError;

# ---------------------------------------------------------------------------
# XARF::Error — construction and stringification
# ---------------------------------------------------------------------------

subtest 'XARF::Error construction' => sub {
    my $err = XARF::Error->new( message => 'something went wrong' );
    is( $err->message, 'something went wrong', 'message attribute' );
};

subtest 'XARF::Error stringification' => sub {
    my $err = XARF::Error->new( message => 'oops' );
    is( "$err", 'oops', 'stringifies to message' );
};

subtest 'XARF::Error requires message' => sub {
    ok( dies { XARF::Error->new() }, 'dies without message' );
};

# ---------------------------------------------------------------------------
# XARF::ParseError — inheritance and own behaviour
# ---------------------------------------------------------------------------

subtest 'XARF::ParseError is-a XARF::Error' => sub {
    my $err = XARF::ParseError->new( message => 'bad json' );
    isa_ok( $err, 'XARF::Error' );
};

subtest 'XARF::ParseError stringification' => sub {
    my $err = XARF::ParseError->new( message => 'bad json' );
    is( "$err", 'bad json', 'stringifies via inherited overload' );
};

subtest 'XARF::ParseError requires message' => sub {
    ok( dies { XARF::ParseError->new() }, 'dies without message' );
};

# ---------------------------------------------------------------------------
# XARF::SchemaError — inheritance and own behaviour
# ---------------------------------------------------------------------------

subtest 'XARF::SchemaError is-a XARF::Error' => sub {
    my $err = XARF::SchemaError->new( message => 'missing schema' );
    isa_ok( $err, 'XARF::Error' );
};

subtest 'XARF::SchemaError stringification' => sub {
    my $err = XARF::SchemaError->new( message => 'missing schema' );
    is( "$err", 'missing schema', 'stringifies via inherited overload' );
};

subtest 'XARF::SchemaError requires message' => sub {
    ok( dies { XARF::SchemaError->new() }, 'dies without message' );
};

# ---------------------------------------------------------------------------
# Exception hierarchy — distinct types
# ---------------------------------------------------------------------------

subtest 'ParseError and SchemaError are distinct types' => sub {
    my $parse  = XARF::ParseError->new( message => 'a' );
    my $schema = XARF::SchemaError->new( message => 'b' );
    ok( !$parse->isa('XARF::SchemaError'),  'ParseError is not SchemaError' );
    ok( !$schema->isa('XARF::ParseError'), 'SchemaError is not ParseError' );
};

subtest 'die/eval round-trip' => sub {
    my $caught;
    eval { die XARF::ParseError->new( message => 'bad input' ) };
    $caught = $@;
    isa_ok( $caught, 'XARF::ParseError' );
    is( $caught->message, 'bad input', 'message survives die/eval' );
};

done_testing;
