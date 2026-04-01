use v5.40;
use Test::Pod::Coverage 1.08;

# BUILDARGS is a Moo construction hook, not a public API method.
all_pod_coverage_ok( { trustme => [qr/^BUILDARGS$/] } );
