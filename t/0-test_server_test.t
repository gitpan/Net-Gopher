use warnings;
use strict;
use Cwd;
use IO::Socket qw(SHUT_WR SOCK_STREAM);
use IO::Select;
use Test;

use constant BUFFER_SIZE => 4096;
use constant HOST        => 'localhost';
use constant TIMEOUT     => 30;

BEGIN { plan(tests => 12) }




if (-e './t/testserver.pl')
{
	ok(1); # 1
}
else
{
	die "Bad CWD: " . getcwd();
}
my $pid = open(PIPE, "perl ./t/testserver.pl -e |");
if ($pid)
{
	ok(1); # 2
}
else
{
	die "Couldn't fork: $!.";
}

chomp(my $line = <PIPE>);
(my $port) = $line =~ /(\d+)/;
ok($line, "# Listening on port $port..."); # 3


my $socket = new IO::Socket::INET (
	PeerAddr => HOST,
	PeerPort => $port,
	Type     => SOCK_STREAM,
	Proto    => 'tcp',
	Timeout  => TIMEOUT
);

ok($socket); # 4

eval {
	$socket->autoflush(1);
	$socket->blocking(0);
};

ok(!$@); # 5

my $select = new IO::Select ($socket);

ok($select->can_write(TIMEOUT)); # 6
ok($socket->send('test', 0), 4); # 7
ok($socket->shutdown(SHUT_WR));  # 8

ok($select->can_read(TIMEOUT));               # 9
my $response;
ok($socket->recv($response, BUFFER_SIZE, 0)); # 10
ok($response, 'test');                        # 11
ok($socket->close);                           # 12


kill(INT => $pid);
waitpid($pid, 0);

close PIPE;
