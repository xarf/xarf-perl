use v5.40;
use Test2::V0;

use Digest::MD5  ();
use Digest::SHA  ();
use Encode       ();
use MIME::Base64 qw(encode_base64 decode_base64);
use Scalar::Util qw(blessed);

use XARF qw(create_evidence);
use XARF::Evidence;
use XARF::Generator;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Verify a hex digest independently of the library
sub _sha256 { Digest::SHA::sha256_hex( $_[0] ) }
sub _sha512 { Digest::SHA::sha512_hex( $_[0] ) }
sub _sha1   { Digest::SHA::sha1_hex( $_[0] ) }
sub _md5    { Digest::MD5::md5_hex( $_[0] ) }

# ---------------------------------------------------------------------------
# Return type
# ---------------------------------------------------------------------------

subtest 'returns XARF::Evidence object' => sub {
    my $ev = create_evidence( content_type => 'text/plain', payload => 'hello' );
    isa_ok $ev, 'XARF::Evidence';
};

# ---------------------------------------------------------------------------
# Required attributes stored correctly
# ---------------------------------------------------------------------------

subtest 'content_type attribute' => sub {
    my $ev = create_evidence( content_type => 'message/rfc822', payload => 'data' );
    is $ev->content_type, 'message/rfc822', 'content_type stored';
};

# ---------------------------------------------------------------------------
# Payload: base64 encoding
# ---------------------------------------------------------------------------

subtest 'payload is base64-encoded' => sub {
    my $raw = 'Hello, World!';
    my $ev  = create_evidence( content_type => 'text/plain', payload => $raw );

    my $expected_b64 = encode_base64( $raw, '' );    # no line breaks
    is $ev->payload, $expected_b64, 'payload is base64-encoded raw bytes';
};

subtest 'payload base64 is decodeable back to original' => sub {
    my $raw = "Subject: test\r\nFrom: x\@example.com\r\n\r\nBody text";
    my $ev  = create_evidence( content_type => 'message/rfc822', payload => $raw );

    is decode_base64( $ev->payload ), $raw, 'decoded payload matches original';
};

subtest 'payload with no line breaks in base64' => sub {
    # Long payload to trigger line-break behaviour if encode_base64 default is used
    my $raw = 'A' x 200;
    my $ev  = create_evidence( content_type => 'text/plain', payload => $raw );
    ok index( $ev->payload, "\n" ) == -1, 'no newlines in base64 payload';
};

# ---------------------------------------------------------------------------
# Size
# ---------------------------------------------------------------------------

subtest 'size reflects byte count of original payload' => sub {
    my $raw = 'Hello';    # 5 bytes in ASCII / UTF-8
    my $ev  = create_evidence( content_type => 'text/plain', payload => $raw );
    is $ev->size, 5, 'size is 5';
};

subtest 'size for multibyte UTF-8 string' => sub {
    my $str = "\x{263A}";    # U+263A WHITE SMILING FACE — 3 bytes in UTF-8
    my $ev  = create_evidence( content_type => 'text/plain', payload => $str );
    my $expected_bytes = Encode::encode( 'UTF-8', $str );
    is $ev->size, length($expected_bytes), 'size counts UTF-8 bytes, not characters';
};

# ---------------------------------------------------------------------------
# Hash — all four algorithms
# ---------------------------------------------------------------------------

subtest 'default hash algorithm is sha256' => sub {
    my $raw = 'test payload';
    my $ev  = create_evidence( content_type => 'text/plain', payload => $raw );
    like $ev->hash, qr/\Asha256:/, 'hash starts with sha256:';
};

subtest 'sha256 hash correct' => sub {
    my $raw = 'test payload';
    my $ev  = create_evidence( content_type => 'text/plain', payload => $raw, hash_algorithm => 'sha256' );
    is $ev->hash, 'sha256:' . _sha256($raw), 'sha256 digest correct';
};

subtest 'sha512 hash correct' => sub {
    my $raw = 'test payload';
    my $ev  = create_evidence( content_type => 'text/plain', payload => $raw, hash_algorithm => 'sha512' );
    is $ev->hash, 'sha512:' . _sha512($raw), 'sha512 digest correct';
};

subtest 'sha1 hash correct' => sub {
    my $raw = 'test payload';
    my $ev  = create_evidence( content_type => 'text/plain', payload => $raw, hash_algorithm => 'sha1' );
    is $ev->hash, 'sha1:' . _sha1($raw), 'sha1 digest correct';
};

subtest 'md5 hash correct' => sub {
    my $raw = 'test payload';
    my $ev  = create_evidence( content_type => 'text/plain', payload => $raw, hash_algorithm => 'md5' );
    is $ev->hash, 'md5:' . _md5($raw), 'md5 digest correct';
};

subtest 'hash is computed over original bytes, not the base64 payload' => sub {
    my $raw    = 'some content';
    my $ev     = create_evidence( content_type => 'text/plain', payload => $raw );
    my $digest = ( split /:/, $ev->hash, 2 )[1];
    is   $digest, _sha256($raw),       'hash matches sha256 of original bytes';
    isnt $digest, _sha256($ev->payload), 'hash does NOT match sha256 of the base64 string';
};

subtest 'unsupported algorithm dies' => sub {
    ok dies { create_evidence( content_type => 'text/plain', payload => 'x', hash_algorithm => 'blake2' ) },
        'unsupported algorithm causes die';
};

# ---------------------------------------------------------------------------
# UTF-8 string vs raw bytes
# ---------------------------------------------------------------------------

subtest 'UTF-8 string payload encoded to UTF-8 bytes' => sub {
    my $str   = "caf\x{e9}";    # "café" — 5 UTF-8 bytes
    my $bytes = Encode::encode( 'UTF-8', $str );

    my $ev = create_evidence( content_type => 'text/plain', payload => $str );

    is $ev->size,   length($bytes), 'size is byte count';
    is $ev->hash,   'sha256:' . _sha256($bytes), 'hash over UTF-8 bytes';
    is $ev->payload, encode_base64( $bytes, '' ), 'payload is base64 of UTF-8 bytes';
};

subtest 'byte string without UTF-8 flag: treated as Latin-1 and encoded to UTF-8' => sub {
    # A byte string without the UTF-8 flag: characters are treated as Latin-1 code
    # points and encoded to UTF-8 bytes (mirrors JS Buffer.from(payload, 'utf8')).
    # 0xE9 is U+00E9 (é) in Latin-1 → two UTF-8 bytes 0xC3 0xA9.
    my $latin1 = pack 'C*', 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0xE9;    # "helloé" as Latin-1
    ok !Encode::is_utf8($latin1), 'precondition: no UTF-8 flag';

    my $expected_bytes = Encode::encode( 'UTF-8', $latin1 );    # 7 UTF-8 bytes
    my $ev = create_evidence( content_type => 'application/octet-stream', payload => $latin1 );

    is $ev->size,    length($expected_bytes),             'size is UTF-8 byte count (7, not 6)';
    is $ev->payload, encode_base64( $expected_bytes, '' ), 'payload is base64 of UTF-8 encoded bytes';
};

# ---------------------------------------------------------------------------
# Optional description
# ---------------------------------------------------------------------------

subtest 'description stored when provided' => sub {
    my $ev = create_evidence(
        content_type => 'text/plain',
        payload      => 'data',
        description  => 'A sample evidence item',
    );
    is $ev->description, 'A sample evidence item', 'description stored';
};

subtest 'description undef when not provided' => sub {
    my $ev = create_evidence( content_type => 'text/plain', payload => 'data' );
    ok !defined $ev->description, 'description is undef';
};

# ---------------------------------------------------------------------------
# to_hashref
# ---------------------------------------------------------------------------

subtest 'to_hashref includes content_type and payload' => sub {
    my $ev   = create_evidence( content_type => 'text/plain', payload => 'hi' );
    my $href = $ev->to_hashref;
    ok exists $href->{content_type}, 'content_type present';
    ok exists $href->{payload},      'payload present';
};

subtest 'to_hashref includes hash and size' => sub {
    my $ev   = create_evidence( content_type => 'text/plain', payload => 'hi' );
    my $href = $ev->to_hashref;
    ok exists $href->{hash}, 'hash present';
    ok exists $href->{size}, 'size present';
};

subtest 'to_hashref includes description when set' => sub {
    my $ev   = create_evidence( content_type => 'text/plain', payload => 'hi', description => 'desc' );
    my $href = $ev->to_hashref;
    is $href->{description}, 'desc', 'description present';
};

subtest 'to_hashref omits description when not set' => sub {
    my $ev   = create_evidence( content_type => 'text/plain', payload => 'hi' );
    my $href = $ev->to_hashref;
    ok !exists $href->{description}, 'description absent from hashref';
};

subtest 'to_hashref returns a plain unblessed hashref' => sub {
    my $ev   = create_evidence( content_type => 'text/plain', payload => 'hello' );
    my $href = $ev->to_hashref;
    ref_ok $href, 'HASH', 'is a hashref';
    ok !blessed($href), 'is not a blessed object';
};

# ---------------------------------------------------------------------------
# Required argument validation
# ---------------------------------------------------------------------------

subtest 'missing content_type dies' => sub {
    ok dies { create_evidence( payload => 'data' ) }, 'dies without content_type';
};

subtest 'missing payload dies' => sub {
    ok dies { create_evidence( content_type => 'text/plain' ) }, 'dies without payload';
};

done_testing;
