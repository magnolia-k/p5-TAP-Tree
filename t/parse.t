use strict;
use warnings;

use v5.10.1;

use Carp;
use FindBin qw[$Bin];
use File::Spec;

use Test::More tests => 16;

require_ok( 'TAP::Tree' );

subtest '01-success.t' => sub {
    my $tree = execute_test_script( '01-success.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 5;

    is( $plan->{number}, 2, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[0]->{description}, 'first test', 'description - first test' );
    is( $testlines->[0]->{test_number}, 1, 'test number - first test' );

    is( $testlines->[1]->{result}, 1, 'result - second test' );
};

subtest '02-failure.t' => sub {
    my $tree = execute_test_script( '02-failure.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $plan->{number}, 2, 'number' );

    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[1]->{result}, 0, 'result - second test' );
};

subtest '03-skip.t' => sub {
    my $tree = execute_test_script( '03-skip.t' );
    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 5;

    is( $plan->{number}, 3, 'number' );

    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[0]->{skip}, undef, 'is skipped? - first test' );
    is( $testlines->[1]->{result}, 1, 'result - second test' );
    ok( $testlines->[1]->{skip}, 'is skipped? - second test' );
};

subtest '04-todo.t' => sub {
    my $tree = execute_test_script( '04-todo.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 5;

    is( $plan->{number}, 3, 'number' );

    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[0]->{todo}, undef, 'is todo? - first test' );
    is( $testlines->[1]->{result}, 0, 'result - second test' );
    ok( $testlines->[1]->{todo}, 'is todo? - second test' );
};

subtest '05-bailout.t' => sub {
    my $tree = execute_test_script( '05-bailout.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $plan->{number}, 2, 'number' );

    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( @{ $testlines }, 1, 'number of taps' );
};

subtest '06-die.t' => sub {
    my $tree = execute_test_script( '06-die.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $plan->{number}, 2, 'number' );

    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( @{ $testlines }, 1, 'number of taps' );
};

subtest '07-donetesting.t' => sub {
    my $tree = execute_test_script( '07-donetesting.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 1;

    is( $plan->{number}, 2, 'number' );
};

subtest '08-subtest.t' => sub {
    my $tree = execute_test_script( '08-subtest.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 2;

    is( $plan->{number}, 3, 'number' );
    is( @{ $testlines }, 3, 'number of taps' );
};

subtest '09-unmatch.t' => sub {
    my $tree = execute_test_script( '09-unmatch.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 2;

    is( $plan->{number}, 3, 'number' );
    is( @{ $testlines }, 2, 'number of taps' );
};

subtest '10-todo_skip.t' => sub {
    my $tree = execute_test_script( '10-todo_skip.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $testlines->[1]->{result}, 0, 'result - second test' );
    ok( $testlines->[1]->{todo}, 'is todo? - second test' );
    ok( $testlines->[1]->{skip}, 'is skipped? - second test' );
};

subtest '11-fail_subtest.t' => sub {
    my $tree = execute_test_script( '11-fail_subtest.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $plan->{number}, 3, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[1]->{result}, 0, 'result - second test' );
};

subtest '12-todo_subtest.t' => sub {
    my $tree = execute_test_script( '12-todo_subtest.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 3;

    is( $plan->{number}, 2, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
    is( $testlines->[1]->{todo}, undef, 'is todo - second test' );
};

subtest '13-bailout_subtest_donetesting.t' => sub {
    my $tree = execute_test_script( '13-bailout_subtest_donetesting.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 2;

    is( $plan->{number}, undef, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
};

subtest '14-skipall.t' => sub {
    my $tree = execute_test_script( '14-skipall.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 1;

    is( $plan->{number}, 0, 'number' );
};

subtest '15-skipall_aftertest.t' => sub {
    my $tree = execute_test_script( '15-skipall_aftertest.t' );

    my $plan      = $tree->{plan};
    my $testlines = $tree->{testline};

    plan tests => 2;

    is( $plan->{number}, 0, 'number' );
    is( $testlines->[0]->{result}, 1, 'result - first test' );
};

sub execute_test_script {
    my $test_script = shift;
    my $path  = File::Spec->catfile( $Bin, 'test_stuff', $test_script );

    if ( ! -e $path ) {
        croak "Can't find $path";
    }

    my $tap_output = `$^X $path 2>&1`;
    my $tree = TAP::Tree->new( tap_ref => \$tap_output )->parse;

    return $tree;
}
