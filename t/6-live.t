use strict;
use warnings;
use IO::Socket 'SOCK_STREAM';
use Test;

use constant TIMEOUT => 120;

# make sure that we are connected to the net:
{
	my $floodgap = new IO::Socket::INET (
		Type     => SOCK_STREAM,
		Proto    => 'tcp',
		PeerAddr => 'gopher.floodgap.com',
		PeerPort => 70,
		Timeout  => TIMEOUT
	);

	my $quux = new IO::Socket::INET (
		Type     => SOCK_STREAM,
		Proto    => 'tcp',
		PeerAddr => 'gopher.quux.org',
		PeerPort => 70,
		Timeout  => TIMEOUT
	);

	if ($floodgap and $quux)
	{
		close $floodgap;
		close $quux;

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
	my $ng = new Net::Gopher (Timeout => TIMEOUT);

	my $response = $ng->gopher(Host => 'gopher.floodgap.com');

	if ($response->is_success)
	{
		ok(1);                  # 1
	}
	else
	{
		ok(0);
		warn $response->error;
	}
	ok(!$response->is_error);       # 2
	ok(!$response->is_blocks);      # 3
	ok(!$response->is_gopher_plus); # 4
	ok($response->is_menu);         # 5
	ok($response->is_terminated);   # 6
}

{
	my $ng = new Net::Gopher (Timeout => TIMEOUT);

	my $response = $ng->gopher_plus(Host => 'gopher.quux.org');

	if ($response->is_success)
	{
		ok(1);                 # 7
	}
	else
	{
		ok(0);
		warn $response->error;
	}
	ok(!$response->is_error);      # 8
	ok(!$response->is_blocks);     # 9
	ok($response->is_gopher_plus); # 10
	ok($response->is_menu);        # 11
	ok(!$response->is_terminated); # 12
}

{
	my $ng = new Net::Gopher (Timeout => TIMEOUT);

	my $response = $ng->item_attribute(Host => 'gopher.quux.org');

	if ($response->is_success)
	{
		ok(1);                 # 13
	}
	else
	{
		ok(0);
		warn $response->error;
	}
	ok(!$response->is_error);      # 14
	ok($response->is_blocks);      # 15
	ok($response->is_gopher_plus); # 16
	ok(!$response->is_menu);       # 17
	ok(!$response->is_terminated); # 18
}

{
	my $ng = new Net::Gopher (Timeout => TIMEOUT);

	my $response = $ng->directory_attribute(Host => 'gopher.quux.org');

	if ($response->is_success)
	{
		ok(1);                 # 19
	}
	else
	{
		ok(0);
		warn $response->error;
	}
	ok(!$response->is_error);      # 20
	ok($response->is_blocks);      # 21
	ok($response->is_gopher_plus); # 22
	ok(!$response->is_menu);       # 23
	ok(!$response->is_terminated); # 24
}
