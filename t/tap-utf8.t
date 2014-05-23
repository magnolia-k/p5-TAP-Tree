use strict;
use warnings;

use utf8;

use FindBin qw[$Bin];
use File::Spec;
use autodie;

use Test::More tests => 6;

my $path = File::Spec->catfile( $Bin, 'test_stuff', 'tap_utf8.txt' );

require TAP::Tree;
{
    my $taptree = TAP::Tree->new( tap_file => $path, utf8 => 1 );
    my $tree = $taptree->parse;

    is( $tree->{testline}[0]{description}, 'テスト', 'not latin1' );
    is( $tree->{testline}[1]{description}, 'test', 'latin1' );

    ok( $taptree->is_utf8, 'utf8 mode' );
}

{
    my $taptree = TAP::Tree->new( tap_file => $path );
    my $tree = $taptree->parse;

    isnt( $tree->{testline}[0]{description}, 'テスト', 'not latin1' );
    is( $tree->{testline}[1]{description}, 'test', 'latin1' );

    is( $taptree->is_utf8, undef, 'not utf8 mode' );
}
