use warnings;
use strict;
use Cwd;
use IO::Socket qw(SHUT_WR SOCK_STREAM);
use IO::Select;
use Test;

use constant BUFFER_SIZE => 4096;
use constant HOST        => 'localhost';
use constant PORT        => 70;
use constant TIMEOUT     => 30;

BEGIN { plan(tests => 11) }




if (-e './t/testserver.pl')
{
	ok(1); # 1
}
else
{
	die "Bad CWD: " . getcwd();
}
my $pid = open(PIPE, "perl ./t/testserver.pl -ep 70 |")
	or die "Couldn't fork: $!.";

ok($pid); # 2

my $socket = new IO::Socket::INET (
	PeerAddr => HOST,
	PeerPort => PORT,
	Type     => SOCK_STREAM,
	Proto    => 'tcp',
	Timeout  => TIMEOUT
);

ok($socket); # 3

eval {
	$socket->autoflush(1);
	$socket->blocking(0);
};

ok(!$@); # 4

my $select = new IO::Select ($socket);

ok($select->can_write(TIMEOUT)); # 5
ok($socket->send('test', 0), 4); # 6
ok($socket->shutdown(SHUT_WR));  # 7

ok($select->can_read(TIMEOUT));               # 8
my $response;
ok($socket->recv($response, BUFFER_SIZE, 0)); # 9
ok($response, 'test');                        # 10
ok($socket->close);                           # 11


kill(INT => $pid);
waitpid($pid, 0);

close PIPE;
