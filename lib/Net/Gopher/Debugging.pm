# Copyright 2003-2004 by William G. Davis.
#
# This library is free software released under the terms of the GNU Lesser
# General Public License (LGPL), the full terms of which can be found in the
# "COPYING" file that comes with the distribution.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.
#
# This class contains methods for generating and reporting diagnostic messages.
# You really don't need to be looking in here unless you plan on hacking
# Net::Gopher. See the POD for Net::Gopher new() and debug().

package Net::Gopher::Debugging;

use 5.005;
use strict;
use warnings;
use vars qw(@ISA $DEBUG $LOG $LOG_FILE $STARTED);
use Carp;
use Net::Gopher::Exception;

push(@ISA, 'Net::Gopher::Exception');



# is debugging turned on?
$DEBUG = 0;

# should the diagnostic messages be printed to a log file instead of to STDERR?
$LOG = 0;

# if logging is on, then this stores the name of the log file to use:
$LOG_FILE = undef;

# has the opening formatting for the debugging messages been printed yet?
$STARTED = 0;





################################################################################
#
#	Method
#		debug_print()
#
#	Purpose
#		This function prints out a formatted diagnostic message, either
#		to STDERR or to the log file specified by $LOG_FILENAME.
#
#	Parameters
#		None.
#

sub debug_print
{
	my $self = shift;

	return unless ($DEBUG);



	chomp(my $unformatted_message = shift);

	my $message;

	# make sure we print the opening message before anything else:
	if ($STARTED)
	{
		# separate this message from the last one:
		$message .= "\n";
	}
	else
	{
		# print the opening message:
		$message .= sprintf("[%s]\n%s\n",
			scalar localtime,
			'=' x 80
		);

		$STARTED++;
	}

	my ($filename, $line) = (caller(0))[1, 2];
	my $sub_name          = (caller(1))[3];
	$sub_name = '' unless (defined $sub_name);
	$filename =~ s{.*[\\/:]}{}; # remove the path name
	$sub_name =~ s{.*::}{};     # remove the package name

	$message .= sprintf("(In %s at line %d%s)\n%s\n",
		$filename,
		$line,
		($sub_name and $sub_name ne '__ANON__')
			? ", $sub_name() function."
			: '.',
		$unformatted_message
	);

	if ($LOG)
	{
		open(LOG, ">> $LOG_FILE")
			or return Net::Gopher::Exception->call_die(
				"Couldn't open debug log ($LOG_FILE): $!."
			);
		print LOG $message;
		close LOG;
	}
	else
	{
		print STDERR $message;
	}
}





sub debug
{
	my $self = shift;

	if (@_)
	{
		if (shift @_)
		{
			$DEBUG = 1;
		}
		else
		{
			$DEBUG = 0;
			$LOG   = 0;
		}
	}
	else
	{
		return $DEBUG;
	}
}





sub log_file
{
	my $self = shift;

	if (@_)
	{
		$LOG_FILE = shift;
		$LOG      = 1 if (defined $LOG_FILE);
	}
	else
	{
		return $LOG_FILE;
	}
}





END {
	return unless ($DEBUG and $STARTED);

	my $message = "\n". '=' x 80 . "\n\n";

	if ($LOG)
	{
		open(LOG, ">> $LOG_FILE")
			or return Net::Gopher::Exception->call_die(
				"Couldn't open debug log ($LOG_FILE): $!."
			);
		print LOG $message;
		close LOG;
	}
	else
	{
		print STDERR $message;
	}
}

1;
