use vars qw($TEST_SERVER_PID);

$TEST_SERVER_PID = undef;



sub run_server
{
	my $port = shift || 70;

	my $pid = open(SERVER, "| perl ./tests/testserver.pl -p $port")
		or die "Couldn't launch the test server: $!.\n";

	$TEST_SERVER_PID = $pid;
}

sub run_echo_server
{
	my $port = shift || 70;

	my $pid = open(SERVER, "| perl ./tests/testserver.pl -e -p $port")
		or die "Couldn't launch the test server: $!.\n";

	$TEST_SERVER_PID = $pid;
}

sub kill_server
{
	return unless ($TEST_SERVER_PID);

	kill(INT => $TEST_SERVER_PID);
	waitpid($TEST_SERVER_PID, 0);

	$TEST_SERVER_PID = undef;

	close SERVER;
}

BEGIN
{
	$SIG{__DIE__} = sub {
		kill_server();
	};
}

1;
