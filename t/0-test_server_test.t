use warnings;
use strict;
use IO::Socket qw(SHUT_WR SOCK_STREAM);
use IO::Select;
use Test;

use constant BUFFER_SIZE => 4096;
use constant HOST        => 'localhost';
use constant PORT        => 70;
use constant TIMEOUT     => 30;

BEGIN { plan(tests => 11) }

require './t/serverfunctions.pl';




ok(run_echo_server()); # 1

my $socket = new IO::Socket::INET (
	PeerAddr => HOST,
	PeerPort => PORT,
	Type     => SOCK_STREAM,
	Proto    => 'tcp',
	Timeout  => TIMEOUT
);

ok($socket); # 2

eval {
	$socket->autoflush(1);
	$socket->blocking(0);
};

ok(!$@); # 3

my $select = new IO::Select ($socket);

ok($select->can_write(TIMEOUT)); # 4
ok($socket->send('test', 0), 4); # 5
ok($socket->shutdown(SHUT_WR));  # 6

ok($select->can_read(TIMEOUT));               # 7
my $response;
ok($socket->recv($response, BUFFER_SIZE, 0)); # 8
ok($response, 'test');                        # 9
ok($socket->close);                           # 10

ok(kill_server()); # 11
