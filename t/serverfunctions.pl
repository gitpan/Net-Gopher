use strict;
use warnings;
use vars qw($PERL $PATH $ITEM_SERVER_PID $ECHO_SERVER_PID);

use Config;
use Cwd;

# hack devised by Gisle Aas:
$PERL = $Config{'perlpath'};
$PERL = $^X if ($^O eq 'VMS' or -x $^X && $^X =~ m|^([a-z]:)?/|i);

$PATH = (cwd() =~ m|/t$|)
		? 'testserver.pl'
		: './t/testserver.pl';

$ITEM_SERVER_PID = undef;
$ECHO_SERVER_PID = undef;





sub launch_item_server
{
	my $pid = open(ITEM_SERVER, "$PERL $PATH |")
		or die "Couldn't launch the item server: $!.\n";

	my $line = <ITEM_SERVER>;

	(my $port) = $line =~ /(\d+)/;

	die "Server isn't listening."
		unless ($line =~ /^# Listening on port $port\.\.\./);

	$ITEM_SERVER_PID = $pid;

	return $port;
}

sub launch_echo_server
{
	my $pid = open(ECHO_SERVER, "$PERL $PATH -e |")
		or die "Couldn't launch the test server: $!.\n";

	my $line = <ECHO_SERVER>;

	(my $port) = $line =~ /(\d+)/;

	die "Server isn't listening."
		unless ($line =~ /^# Listening on port $port\.\.\./);

	$ECHO_SERVER_PID = $pid;

	return $port;
}

sub kill_servers
{
	return 1 unless ($ITEM_SERVER_PID || $ECHO_SERVER_PID);

	if ($ITEM_SERVER_PID)
	{
		kill(INT => $ITEM_SERVER_PID);
		waitpid($ITEM_SERVER_PID, 0);

		$ITEM_SERVER_PID = undef;

		close ITEM_SERVER;
	}

	if ($ECHO_SERVER_PID)
	{
		kill(INT => $ECHO_SERVER_PID);
		waitpid($ECHO_SERVER_PID, 0);

		$ECHO_SERVER_PID = undef;

		close ECHO_SERVER;
	}

	return 1;
}

1;
