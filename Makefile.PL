#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

# don't prompt the user if we're not being called interactively (e.g., if we're
# being called from cron or some such program instead of directly by the user):
# don't prompt the user if we're not being called interactively (e.g., if we're
# being called from cron or some such program instead of directly by the user):
my $interactive = 1;
$interactive = 1 if (-t STDIN and -t STDOUT);

# first, make sure the line endings in the test items are correct:
my %files_and_newlines = (
	'index'             => 'LF',
	gp_index            => 'CRLF',
	gp_s_byte_term      => 'LF',
	gp_s_period_term    => 'CRLF',
	gp_s_no_term        => 'CRLF',
	gp_byte_term        => 'CR',
	gp_period_term      => 'CRLF',
	gp_no_term          => 'LF',
	gp_partial_response => 'LF',
	item_blocks         => 'CR',
	directory_blocks    => 'LF',
	error_not_found     => 'CRLF',
	error_multiline     => 'CR',
	malformed_menu      => 'LF',
	bad_blocks          => 'LF'
);

print "Converting the line endings in the test items...\n" if ($interactive);
while (my ($file, $nl) = each %files_and_newlines)
{
	my $rc = system("perl ./t/newlines.pl -n $nl ./t/items/$file");
	die "Couldn't fix line endings in test item ($file) via newlines.pl: $!"
		if ($rc);
}
print "Done.\n\n" if ($interactive);

print <<END_OF_MESSAGE if ($interactive);

Some of the tests I'm going to run employ the services of a test server that
listens on what ever ports the OS will let it, and serves up some test items to
the *.t test scripts. If some big, port blocking scheme enabled, then these
tests will inexplicably fail.

The final test script, live.t, contains tests that employ real-world
Gopherspaces (like gopher.floodgap.com). These live tests are not crucial and
will be skipped if you're not connected to the Internet. If you want them to
run, then connect to the Internet before continuing.

Press <Return> to continue.
END_OF_MESSAGE

<STDIN> if ($interactive);





# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME            => 'Net::Gopher',
	VERSION_FROM    => 'lib/Net/Gopher.pm',
	PL_FILES        => {},
	PREREQ_PM       => {
		'IO::String'       => 1.0,
		'IO::Socket'       => 1.26,
		'IO::Socket::INET' => 1.25,
		'URI'              => 1.27
	},
	($] >= 5.005
		? (ABSTRACT_FROM => 'lib/Net/Gopher.pm',
		   AUTHOR        => 'William G. Davis ' .
		                    '<william_g_davis@users.sourceforge.net>')
		: ()
	),
);
