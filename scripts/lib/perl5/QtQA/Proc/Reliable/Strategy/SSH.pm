#############################################################################
##
## Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
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

package QtQA::Proc::Reliable::Strategy::SSH;
use strict;
use warnings;

use base qw( QtQA::Proc::Reliable::Strategy::GenericRegex );

use Readonly;

# Pattern matching all formatted errno strings (in English) which
# may be considered possibly junk
Readonly my $JUNK_ERRNO_STRING => qr{

      \QNo route to host\E          # network outage
    | \QNetwork is unreachable\E    # network outage
    | \QConnection timed out\E      # network outage
    | \QConnection refused\E        # ssh service outage (e.g. host is rebooting)

}xmsi;

Readonly my @JUNK_STDERR_PATTERNS => (

    # Unknown host, could be temporary DNS outage:
    #
    #   $ ssh ignore_me@foo.bar.quux
    #   ssh: Could not resolve hostname foo.bar.quux: Name or service not known
    #
    qr{^ssh: Could not resolve hostname}msi,

    # Various types of possibly temporary outages:
    #
    #   $ ssh ignore_me@128.0.0.1
    #   ssh: connect to host 128.0.0.1 port 22: No route to host
    #
    #   $ ssh -p 9999 ignore_me@127.0.0.1
    #   ssh: connect to host 127.0.0.1 port 9999: Connection refused
    #
    #   $ ssh ignore_me@example.com
    #   ssh: connect to host example.com port 22: Network is unreachable
    #
    #   $ ssh ignore_me@nokia.com
    #   ssh: connect to host nokia.com port 22: Connection timed out
    #
    qr{^ssh: connect to host.*: $JUNK_ERRNO_STRING$}msi,

);

sub new
{
    my ($class) = @_;

    my $self = $class->SUPER::new( );
    $self->push_stderr_patterns( @JUNK_STDERR_PATTERNS );

    return bless $self, $class;
}

=head1 NAME

QtQA::Proc::Reliable::Strategy::SSH - reliable strategy for ssh command

=head1 DESCRIPTION

Attempts to recover from various forms of network issues when performing
ssh commands.

=head1 SEE ALSO

L<QtQA::Proc::Reliable::Strategy>

=cut

1;