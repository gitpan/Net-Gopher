use warnings;
use strict;
use IO::Socket 'SOCK_STREAM';
use Test;

# make sure that we are connected to the net:
BEGIN
{
	my $socket = new IO::Socket::INET (
		Type     => SOCK_STREAM,
		Proto    => 'tcp',
		PeerAddr => 'gopher.floodgap.com',
		PeerPort => 70,
		Timeout  => 60
	);

	if ($socket)
	{
		close $socket;

		plan(tests => 24);
	}
	else
	{
		plan(tests => 0);
		exit;
	}
}





use Net::Gopher;

{
	my $ng = new Net::Gopher;

	my $response = $ng->gopher(Host => 'gopher.floodgap.com');

	if ($response->is_success)
	{
		ok(1);                  # 1
	}
	else
	{
		warn $response->error;
	}
	ok(!$response->is_error);       # 2
	ok(!$response->is_blocks);      # 3
	ok(!$response->is_gopher_plus); # 4
	ok($response->is_menu);         # 5
	ok($response->is_terminated);   # 6
}

{
	my $ng = new Net::Gopher;

	my $response = $ng->gopher_plus(Host => 'gopher.quux.org');

	if ($response->is_success)
	{
		ok(1);                 # 7
	}
	else
	{
		warn $response->error;
	}
	ok(!$response->is_error);      # 8
	ok(!$response->is_blocks);     # 9
	ok($response->is_gopher_plus); # 10
	ok($response->is_menu);        # 11
	ok(!$response->is_terminated); # 12
}

{
	my $ng = new Net::Gopher;

	my $response = $ng->item_attribute(Host => 'gopher.quux.org');

	if ($response->is_success)
	{
		ok(1);                 # 13
	}
	else
	{
		warn $response->error;
	}
	ok(!$response->is_error);      # 14
	ok($response->is_blocks);      # 15
	ok($response->is_gopher_plus); # 16
	ok(!$response->is_menu);       # 17
	ok(!$response->is_terminated); # 18
}

{
	my $ng = new Net::Gopher;

	my $response = $ng->directory_attribute(Host => 'gopher.quux.org');

	if ($response->is_success)
	{
		ok(1);                 # 19
	}
	else
	{
		warn $response->error;
	}
	ok(!$response->is_error);      # 20
	ok($response->is_blocks);      # 21
	ok($response->is_gopher_plus); # 22
	ok(!$response->is_menu);       # 23
	ok(!$response->is_terminated); # 24
}
