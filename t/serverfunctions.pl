#!/usr/bin/perl -w
use strict;
use vars qw($PERL $PATH $TEST_SERVER_PID);

use Config;
use Cwd;

use constant DEFAULT_PORT => 70;

# hack devised by Gisle Aas:
$PERL = $Config{'perlpath'};
$PERL = $^X if ($^O eq 'VMS' or -x $^X && $^X =~ m|^([a-z]:)?/|i);

$PATH = (cwd() =~ m|/t$|)
		? 'testserver.pl'
		: './t/testserver.pl';

$TEST_SERVER_PID = undef;





sub run_server
{
	my $port = shift || DEFAULT_PORT;

	my $pid = open(SERVER, "$PERL $PATH -p $port |")
		or die "Couldn't launch the test server: $!.\n";

	return $TEST_SERVER_PID = $pid;
}

sub run_echo_server
{
	my $port = shift || DEFAULT_PORT;

	my $pid = open(SERVER, "$PERL $PATH -ep $port |")
		or die "Couldn't launch the test server: $!.\n";

	return $TEST_SERVER_PID = $pid;
}

sub kill_server
{
	return unless ($TEST_SERVER_PID);

	kill(INT => $TEST_SERVER_PID);
	waitpid($TEST_SERVER_PID, 0);

	$TEST_SERVER_PID = undef;

	close SERVER;

	return 1;
}

1;
