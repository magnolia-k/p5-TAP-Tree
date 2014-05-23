use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

require_ok( 'TAP::Tree' );

my $tap = <<'END';
1..2
# comment first
ok 1 - first test
ok 2 - second test
# comment second
END

my $taptree = TAP::Tree->new( tap_ref => \$tap );

throws_ok { $taptree->summary } qr[not parsed], 'not parsed';

my $parsed = $taptree->parse;

my $re_taptree = TAP::Tree->new( tap_tree => $parsed );
my $re_parsed = $re_taptree->tap_tree;

is( $re_parsed->{testline}[0]{result}, 1, 'first test' );
