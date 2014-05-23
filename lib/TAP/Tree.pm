package TAP::Tree;

use strict;
use warnings;
use v5.10.1;

our $VERSION = 'v0.0.1';

use Carp;
use autodie;
use Encode qw[decode];

sub new {
    my $class  = shift;
    my %params = @_;

    my $self = {
        tap_file    => $params{tap_file},
        tap_ref     => $params{tap_ref},
        tap_tree    => $params{tap_tree},

        utf8        => $params{utf8},

        is_parsed   => undef,

        result      => {
            version     => undef,
            plan        => undef,
            testline    => [],
            bailout     => undef,
        },
    };

    bless $self, $class;

    $self->_validate;
    $self->_initialize;

    return $self;
}

sub is_utf8     { return $_[0]->{utf8}      }
sub is_parsed   { return $_[0]->{is_parsed} }

sub _check_for_parsed { croak "not parsed" unless $_[0]->is_parsed }

sub summary {
    my $self = shift;

    $self->_check_for_parsed;

    my $fail = 0;
    for my $testline ( @{ $self->{result}{testline} } ) {
        $fail++ if ( $testline->{result} == 0 && ! $testline->{todo} );
    }

    my $summary = {
        version     => $self->{result}{version},
        bailout     => $self->{result}{bailout},
        plan        => $self->{result}{plan},
        fail        => $fail,
    };

    return $summary;
}

sub tap_tree {
    my $self = shift;

    $self->_check_for_parsed;

    return $self->{result};
}

sub create_tap_tree_iterator {
    my $self   = shift;
    my %params = @_;

    require TAP::Tree::Iterator;
    my $iterator = TAP::Tree::Iterator->new( tap_tree => $self->tap_tree, %params );

    return $iterator;
}

sub _validate {
    my $self = shift;

    if ( $self->{tap_ref} ) {
        if ( $self->{tap_file} or $self->{tap_tree} ) {
            croak "Excessive parameter";
        }

        if ( ref( $self->{tap_ref} ) ne 'SCALAR' ) {
            croak "Parameter 'tap_ref' is not scalar reference";
        }

        return $self;
    }

    if ( $self->{tap_file} ) {
        if ( $self->{tap_ref} or $self->{tap_tree} ) {
            croak "Excessive parameter";
        }

        if ( ! -e -f -r -T $self->{tap_file} ) {
            croak "Paramter 'tap_file' is invalid:$self->{tap_file}";
        }

        return $self;
    }

    if ( $self->{tap_tree} ) {
        if ( $self->{tap_file} or $self->{tap_ref} ) {
            croak "Excessive parameter";
        }

        if ( ref( $self->{tap_tree} ) ne 'HASH' ) {
            croak "Parameter 'tap_tree' is not hash reference";
        }

        my @keys = qw[version plan testline];
        for my $key ( @keys ) {
            if ( ! defined $self->{tap_tree}{$key} ) {
                croak "Parameter 'tap_tree' is invalid tap tree:$key";
            }
        }

        return $self;
    }

    croak "No required parameter ( tap_ref or tap_file ot tap_tree )";
}

sub _initialize {
    my $self = shift;

    if ( $self->{tap_tree} ) {
        $self->{result} = $self->{tap_tree};    # Not deep copy.
        $self->{is_parsed}++;

        return $self;
    }

}

sub parse {
    my $self   = shift;

    if ( $self->{is_parsed} ) {
        croak "TAP is already parsed.";
    }

    my $path = ( $self->{tap_file} ) ? $self->{tap_file} : $self->{tap_ref};

    open my $fh, '<', $path;
    $self->{result} = $self->_parse( $fh );
    close $fh;

    $self->{is_parsed}++;

    return $self->{result};
}

sub _parse {
    my ( $self, $fh ) = @_;

    my $result = {
        version     => undef,
        plan        => undef,
        testline    => [],
        bailout     => undef,
    };

    my @subtest_lines;
    while ( my $line_raw = <$fh> ) {

        my $line = ( $self->{utf8} ) ? decode( 'UTF-8', $line_raw ) : $line_raw;

        chomp $line;

        next if ( $line =~ /!\s*#/ );   # skip all comments.

        # Bail Out!
        if ( $line =~ /^Bail Out!\s{2}(.*)/ ) {
            $result->{bailout} = {
                str     => $line,
                message => $1,
            };

            last;
        }

        # tap version
        if ( $line =~ /^TAP version (\d+)$/ ) {

            if ( $result->{version}{number} ) {
                croak "Invalid TAP sequence. TAP version is already specified.";
            }

            $result->{version} = {
                str     => $line,
                number  => $1,
            };

            next;
        }

        # plan
        if ( $line =~ /^(\s*)1\.\.\d+(\s#.*)?$/ ) {

            if ( $1 ) { # subtest
                push @subtest_lines, $line;
            } else {
                if ( $result->{plan}{number} ) {
                    croak "Invalid TAP sequence. Plan is already specified.";
                }

                $result->{plan} = $self->_parse_plan( $line );
            }

            next;
        }

        # testline
        if ( $line =~ /^(\s*)(not )?ok/ ) {

            if ( $1 ) { # subtest
                push @subtest_lines, $line;
            } else {
                my $subtest = $self->_parse_subtest( \@subtest_lines );
                push @{ $result->{testline} },
                     $self->_parse_testline( $line, $subtest );
            }

            next;
        }

    }

    if ( ! $result->{version} ) {
        $result->{version}{number} = 12;    # Default tap version is '12'.
    }

    return $result;
}

sub _parse_plan {
    my $self = shift;
    my $line = shift;

    my $plan = {
        str         => $line,
        number      => undef,
        skip_all    => undef,
        directive   => undef,
    };

    {
        $line =~ /^1\.\.(\d+)\s*(# .*)?/;

        $plan->{number} = $1;
        $plan->{skip_all}++ if ( $plan->{number} == 0 );

        if ( $2 ) {
            $plan->{directive} = $2;
            $plan->{directive} =~ s/^\s#\s+//;
        }
    }

    return $plan;
}

sub _parse_testline {
    my $self    = shift;
    my $line    = shift;
    my $subtest = shift;

    my $testline = {
        str         => $line,
        result      => undef,       # 1 (ok) or 0 (not ok)
        test_number => undef,
        description => undef,
        directive   => undef,
        todo        => undef,       # is todo test?
        skip        => undef,       # is skipped?
        subtest     => $subtest,
    };

    {
        $line =~ /(not )?ok\s*(\d+)?(.*)?/;

        $testline->{result} = $1 ? 0 : 1;
        $testline->{test_number} = $2 if $2;    # test number is optional

        my $msg = $3;

        if ( $msg && $msg =~ /^\s?(-\s.+?)?\s*(#\s.+?)?\s*$/ ) {
            if ( $1 ) { # matched description
                $testline->{description} = $1;
                $testline->{description} =~ s/^-\s//;
            }

            if ( $2 ) { # matched directive
                $testline->{directive} = $2;
                $testline->{directive} =~ s/^#\s//;
                $testline->{todo}++ if ( $testline->{directive} =~ /TODO/i );
                $testline->{skip}++ if ( $testline->{directive} =~ /skip/i );
            }
        }
    }

    return $testline;
}

sub _parse_subtest {
    my $self        = shift;
    my $subtest_ref = shift;

    return unless $subtest_ref;
    return unless @{ $subtest_ref };

    my $str = shift @{ $subtest_ref };

    my ( $indent, $line );
    {
        $str =~ /^(\s+)(.*)/;
        $indent  = length( $1 );
        $line    = $2;
    }

    my $subtest_result = {
        plan        => undef,
        testline    => [],
        subtest     => undef,
    };

    $self->_parse_subtest_line( $line, $subtest_result );

    my @subtest_more;
    while( @{ $subtest_ref } ) {
        my $subtest_line = shift @{ $subtest_ref };

        my ( $sub_indent, $sub_line );
        {
            $subtest_line =~ /^(\s+)(.*)/;
            $sub_indent = length( $1 );
            $sub_line   = $2;
        }

        if ( $sub_indent > $indent ) {
            unshift @subtest_more, $subtest_line;
            next;
        }

        $self->_parse_subtest_line( $sub_line, $subtest_result, \@subtest_more );
    }

    return $subtest_result;
}

sub _parse_subtest_line {
    my ( $self, $line, $subtest_result, $subtest_more_ref ) = @_;

    if ( $line =~ /^1\.\.\d+/ ) {
        $subtest_result->{plan} = $self->_parse_plan( $line );
    } elsif ( $line =~ /^(not )?ok/ ) {
        my $subtest = $self->_parse_subtest( $subtest_more_ref );
        push @{ $subtest_result->{testline} },
             $self->_parse_testline( $line, $subtest );
    }
}

1;

__END__

=pod

=head1 NAME

TAP::Tree - Simple TAP (Test Anything Protocol) parser

=head1 SYNOPSIS

  use v5.10.1;
  require TAP::Tree;
  my $tap = <<'END';
  ok 1 - test 1
  ok 2 - test 2
  1..2
  END

  my $tap  = TAP::Tree->new( tap_ref => \$tap );
  my $tree = $tap->parse;
  say $tree->{plan}{number};   # print 2
  say $tree->{testline}[0]{description}; # print test 1
  say $tree->{testline}[1]{description}; # print test 2

=cut
