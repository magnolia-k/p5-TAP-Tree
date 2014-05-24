use strict;
use warnings;

use Test::More tests => 4;

require TAP::Tree;

subtest 'pass' => sub {

    my $tap = <<'END';
1..2
ok 1 - first test
ok 2 - second test
END

    my $taptree = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $summary = $taptree->summary;

    is( $summary->{plan}{number}, 2, 'plan number' );
    is( $summary->{fail}, 0, 'fail tests' );
};

subtest 'fail' => sub {

    my $tap = <<'END';
1..2
ok 1 - first test
not ok 2 - second test
END

    my $taptree = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $summary = $taptree->summary;

    is( $summary->{plan}{number}, 2, 'plan number' );
    is( $summary->{fail}, 1, 'fail tests' );
};

subtest 'bailout' => sub {

    my $tap = <<'END';
1..2
ok 1 - first test
Bail out!  stop test!
END

    my $taptree = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $summary = $taptree->summary;

    is( $summary->{plan}{number}, 2, 'plan number' );
    is( $summary->{bailout}{message}, 'stop test!', 'bailout' );
    is( $summary->{fail}, 0, 'fail tests' );
};

subtest 'todo' => sub {

    my $tap = <<'END';
1..2
ok 1 - first test
not ok 2 - second test # TODO
END

    my $taptree = TAP::Tree->new( tap_ref => \$tap );
    $taptree->parse;
    my $summary = $taptree->summary;

    is( $summary->{plan}{number}, 2, 'plan number' );
    is( $summary->{fail}, 0, 'fail tests' );
};

