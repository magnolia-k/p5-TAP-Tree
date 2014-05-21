use strict;
use warnings;

use Test::More tests => 3;

ok( 1, 'first test' );

subtest 'second test' => sub {
    ok( 1, 'first sub test' );

    subtest 'more sub test' => sub {
        ok( 1, 'second sub test' );
    };

    ok( 1, 'third sub test' );
};

ok( 1, 'third test' );
