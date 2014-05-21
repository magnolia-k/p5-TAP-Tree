package TAP::Tree;

use strict;
use warnings;
use v5.10.1;

our $VERSION = 'v0.0.1';

use Carp;
use autodie;

sub parse {
    my $pkg    = shift;
    my %params = @_;

    unless ( $params{tap_ref} && ref( $params{tap_ref} ) eq 'SCALAR' ) {
        croak "Parameter 'tap_ref' must be scalar reference.";
    }

    open my $fh, '<', $params{tap_ref};
    my $result = __PACKAGE__->_parse( $fh );
    close $fh;

    return $result;
}

sub parse_from_file {
    my $pkg    = shift;
    my %params = @_;

    unless ( $params{tap_file} && -e -f -r -T $params{tap_file} ) {
        croak "Invalid file:$params{tap_file}";
    }

    open my $fh, '<', $params{tap_file};
    my $result = __PACKAGE__->_parse( $fh );
    close $fh;

    return $fh;
}

sub _parse {
    my ( $pkg, $fh ) = @_;

    my $result = {
        version     => undef,
        plan        => undef,
        testline    => [],
        bailout     => undef,
    };

    my @subtest_lines;
    while ( my $line = <$fh> ) {
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

            if ( $1 ) {
                push @subtest_lines, $line;
            } else {
                if ( $result->{plan}{number} ) {
                    croak "Invalid TAP sequence. TAP plan is already specified.";
                }

                $result->{plan} = __PACKAGE__->_parse_plan( $line );
            }

            next;
        }

        # testline
        if ( $line =~ /^(\s*)(not )?ok/ ) {

            if ( $1 ) {
                push @subtest_lines, $line;
            } else {
                my $subtests = __PACKAGE__->_parse_subtest( \@subtest_lines );
                push @{ $result->{testline} },
                     __PACKAGE__->_parse_testline( $line, $subtests );
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
    my $pkg  = shift;
    my $line = shift;

    my $plan = {
        str         => $line,
        number      => undef,
        skip_all    => undef,
        directive   => undef,
    };

    if ( $line =~ /^1\.\.(\d+)\s*(# .*)?/ ) {

        $plan->{number} = $1;
        $plan->{skip_all}++ if ( $plan->{number} == 0 );

        if ( $2 ) {
            $plan->{directive} = $2;
            $plan->{directive} =~ s/^\s#\s+//;
        }

    } else {
        croak "Can't parse plan:$line";
    }

    return $plan;
}

sub _parse_testline {
    my $pkg      = shift;
    my $line     = shift;
    my $subtests = shift;

    my $testline = {
        str         => $line,
        result      => undef,       # 1 (ok) or 0 (not ok)
        test_number => undef,
        description => undef,
        directive   => undef,
        todo        => undef,       # is todo test?
        skip        => undef,       # is skipped?
        subtests    => $subtests,   # array reference of TAP
    };

    if ( $line =~ /(not )?ok\s*(\d+)?(.*)?/ ) {

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

    } else {
        croak "Can't parse testline:$line";
    }

    return $testline;
}

sub _parse_subtest {
    my $pkg         = shift;
    my $subtest_ref = shift;

    return unless $subtest_ref;
    return unless @{ $subtest_ref };

    my $str = pop @{ $subtest_ref };

    my ( $indent, $line );
    {
        $str =~ /^(\s+)(.*)/;
        $indent  = length( $1 );
        $line    = $2;
    }

    my $subtest_result = {
        plan        => undef,
        testline    => [],
        subtests    => undef,
    };

    __PACKAGE__->_parse_subtest_line( $line, $subtest_result );

    my @subtest_more;
    while( @{ $subtest_ref } ) {
        my $subtest_line = pop @{ $subtest_ref };

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

        __PACKAGE__->_parse_subtest_line( $sub_line, $subtest_result, \@subtest_more );
    }

    return $subtest_result;
}

sub _parse_subtest_line {
    my ( $pkg, $line, $subtest_result, $subtest_more_ref ) = @_;

    if ( $line =~ /^1\.\.\d+/ ) {
        $subtest_result->{plan} = __PACKAGE__->_parse_plan( $line );
    } elsif ( $line =~ /^(not )?ok/ ) {
        my $subtests = __PACKAGE__->_parse_subtest( $subtest_more_ref );
        push @{ $subtest_result->{testline} },
             __PACKAGE__->_parse_testline( $line, $subtests );
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

  my $tap = TAP::Tree->parse( tap_ref => \$tap );
  say $tap->{plan}{number};   # print 2
  say $tap->{testline}[0]{description}; # print test 1
  say $tap->{testline}[1]{description}; # print test 2

=cut
