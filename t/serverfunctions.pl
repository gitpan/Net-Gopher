#!/usr/bin/perl -w
use strict;
use vars qw($TEST_SERVER_PID);

use constant DEFAULT_PORT => 70;

$TEST_SERVER_PID = undef;





sub run_server
{
	my $port = shift || DEFAULT_PORT;

	my $pid = open(SERVER, "| perl ./t/testserver.pl -p $port")
		or die "Couldn't launch the test server: $!.\n";

	return $TEST_SERVER_PID = $pid;
}

sub run_echo_server
{
	my $port = shift || DEFAULT_PORT;

	my $pid = open(SERVER, "| perl ./t/testserver.pl -e -p $port")
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





BEGIN
{
	$SIG{'__DIE__'} = sub { kill_server() };
	$SIG{'INT'}     = sub { kill_server() };

}

1;
