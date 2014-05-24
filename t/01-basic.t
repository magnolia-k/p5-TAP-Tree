use strict;
use warnings;

use Test::More tests => 3;

my $tap = <<'END';
1..3
ok 1 - first test
    # Subtest: second test
    ok 1 - first sub test
        # Subtest: second sub test
        ok 1 - sub sub test
        1..1
    ok 2 - second sub test
    ok 3 - third sub test
    1..3
ok 2 - second test
ok 3 - third test
END

require TAP::Tree;
my $taptree = TAP::Tree->new( tap_ref => \$tap );
my $tree    = $taptree->parse;

subtest 'summary' => sub {
    plan tests => 3;

    my $summary = $taptree->summary;

    is( $summary->{plan}{number}, 3, 'summary - test number' );
    is( $summary->{fail}, 0,         'summary - fail number' );
    is( $summary->{bailout}, undef,  'summary - not bailout' );
};

subtest 'tree' => sub {
    plan tests => 2;

    is( $tree->{testline}[0]{description}, 'first test', 'test description' );
    is( $tree->{testline}[1]{subtest}{testline}[1]{subtest}{testline}[0]{description}, 'sub sub test', 'subtest description' );
};

subtest 'iterator' => sub {
    plan tests => 7;
    
    my $iterator = $taptree->create_tap_tree_iterator( subtest => 1 );

    my @descriptions = ( 'first test', 'second test', 'first sub test', 'second sub test', 'sub sub test', 'third sub test', 'third test' );

    for my $description ( @descriptions ) {
        my $result = $iterator->next;
        is( $result->{testline}{description}, $description, $description );
    }
};
