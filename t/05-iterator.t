use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 3;

require_ok( 'TAP::Tree::Iterator' );

require TAP::Tree;

subtest 'no subtest' => sub {
    my $tap = <<'END';
1..2
ok
not ok
END

    my $taptree  = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $iterator = $taptree->create_tap_tree_iterator;

    my $next1 = $iterator->next;
    is( $next1->{testline}{result}, 1, 'ok' );
    is( $next1->{test}{plan}{number}, 2, 'plan test 1' );

    my $next2 = $iterator->next;
    is( $next2->{testline}{result}, 0, 'not ok' );
    is( $next2->{test}{plan}{number}, 2, 'plan test 2' );

    my $next3 = $iterator->next;
    is( $next3, undef, 'no test' );
};

subtest 'subtest' => sub {
    my $tap = <<'END';
1..3
ok 1 - first test
    ok 1 - first sub test
        ok 1 - sub sub test
        1..1
    ok 2 - second sub test
    1..2
ok 2 - second test
ok 3 - third test
END

    my $taptree  = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $iterator = $taptree->create_tap_tree_iterator( subtest => 1 );

    my $next1 = $iterator->next;
    is( $next1->{testline}{description}, 'first test', 'first test' );
    is( $next1->{indent}, 0, 'indent - first test' );

    my $next2 = $iterator->next;
    is( $next2->{testline}{description}, 'second test', 'second test' );
    is( $next2->{indent}, 0, 'indent - second test' );

    my $next3 = $iterator->next;
    is( $next3->{testline}{description}, 'first sub test', 'first sub test' );
    is( $next3->{indent}, 1, 'indent - first sub test' );

    my $next4 = $iterator->next;
    is( $next4->{testline}{description}, 'second sub test', 'second sub test' );
    is( $next4->{indent}, 1, 'indent - second sub test' );

    my $next5 = $iterator->next;
    is( $next5->{testline}{description}, 'sub sub test', 'desc. - sub sub test' );
    is( $next5->{indent}, 2, 'indent - sub sub test' );

    my $next6 = $iterator->next;
    is( $next6->{testline}{description}, 'third test', 'desc. - third test' );
    is( $next6->{indent}, 0, 'indent - third sub test' );

    my $next7 = $iterator->next;
    is( $next7, undef, 'finish iterate' );
};
