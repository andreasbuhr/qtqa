#!/usr/bin/env perl
#############################################################################
##
## Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies).
## All rights reserved.
## Contact: Nokia Corporation (qt-info@nokia.com)
##
## This file is part of the Quality Assurance module of the Qt Toolkit.
##
## $QT_BEGIN_LICENSE:LGPL$
## GNU Lesser General Public License Usage
## This file may be used under the terms of the GNU Lesser General Public
## License version 2.1 as published by the Free Software Foundation and
## appearing in the file LICENSE.LGPL included in the packaging of this
## file. Please review the following information to ensure the GNU Lesser
## General Public License version 2.1 requirements will be met:
## http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
##
## In addition, as a special exception, Nokia gives you certain additional
## rights. These rights are described in the Nokia Qt LGPL Exception
## version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
##
## GNU General Public License Usage
## Alternatively, this file may be used under the terms of the GNU General
## Public License version 3.0 as published by the Free Software Foundation
## and appearing in the file LICENSE.GPL included in the packaging of this
## file. Please review the following information to ensure the GNU General
## Public License version 3.0 requirements will be met:
## http://www.gnu.org/copyleft/gpl.html.
##
## Other Usage
## Alternatively, this file may be used in accordance with the terms and
## conditions contained in a signed written agreement between you and Nokia.
##
##
##
##
##
## $QT_END_LICENSE$
##
#############################################################################
use 5.010;
use strict;
use warnings;
use utf8;

=head1 NAME

30-parse_build_log.t - various tests for parse_build_log.pl

=head1 SYNOPSIS

  perl ./30-parse_build_log.t

Runs parse_build_log over all the testdata under the `data' directory.

  perl ./30-parse_build_log.t --update

Runs the test as usual, and updates the testdata such that the test
passes.  Use this with care for mass updating of multiple testdata.

=cut

use Getopt::Long qw( GetOptionsFromArray );
use Capture::Tiny qw( capture );
use English qw( -no_match_vars );
use File::Basename;
use File::Slurp;
use File::Spec::Functions;
use FindBin;
use Readonly;
use Test::More;
use Text::Diff;
use autodie;

Readonly my $DATADIR
    => catfile( $FindBin::Bin, 'data' );

Readonly my $PARSE_BUILD_LOG
    => catfile( $FindBin::Bin, '..', 'parse_build_log.pl' );

sub test_from_file
{
    my ($file, $update) = @_;

    my $testname = basename( $file );

    my @expected_lines = read_file( $file );

    # first line is special, it's the arguments to pass to parse_build_log;
    # the rest is the expected output of parse_build_log
    my $args_perl = shift @expected_lines;

    my $args_ref = eval $args_perl; ## no critic
    if ($EVAL_ERROR) {
        die "internal error: while eval'ing first line of $file, `$args_perl': $EVAL_ERROR";
    }
    if (ref($args_ref) ne 'ARRAY') {
        die "internal error: first line of $file, `$args_perl', did not eval to an arrayref";
    }

    my @command = ( $EXECUTABLE_NAME, $PARSE_BUILD_LOG, @{$args_ref} );

    my $status = -1;
    my ($stdout, $stderr) = capture {
        $status = system( @command );
    };

    # Basic checks that the command succeeded and didn't print any warnings

    is( $status, 0, "$testname - exit code 0" )
        || diag("stdout:\n$stdout\nstderr:\n$stderr");

    is( $stderr, q{}, "$testname - no standard error" );


    # Now check if the output was really what we expected.
    # To get the nicest looking failure messages, we use `diff', so the failure message
    # contains exactly the difference between what we wanted and what we got.
    my $diff = diff(
        \@expected_lines,
        \$stdout,
        {
            STYLE       =>  'Unified',
            FILENAME_A  =>  'expected',
            FILENAME_B  =>  'actual',
        },
    );

    # Normal mode: just test.
    if (!$update) {
        ok( !$diff, "$testname - actual matches expected" )
            || diag( $diff );

        return;
    }

    # Update mode: update the testdata if necessary.
    my $message = "$testname - actual matches expected";

    if ($diff) {
        open( my $fh, '>', $file );
        print $fh $args_perl.$stdout;
        close( $fh );
        $message .= " - UPDATED!";
    }

    pass( $message );

    return;
}

sub run
{
    my (@args) = @_;

    my $update;
    GetOptionsFromArray( \@args,
        update  =>  \$update,
    ) || die $!;

    foreach my $file (glob "$DATADIR/parsed-logs/*") {
        # README.txt is not testdata; treat all other files as testdata
        next if ( basename( $file ) eq 'README.txt' );
        next if ( ! -f $file );

        test_from_file( $file, $update );
    }

    done_testing;

    return;
}

run( @ARGV ) if (!caller);
1;

