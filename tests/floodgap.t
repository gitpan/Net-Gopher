# this file tests the Gopher support in Net::Gopher using gopher.floodgap.com

use strict;
use warnings;
use Net::Gopher;
use Net::Gopher::Request qw(:gopher);

print "1..10\n";

my $ng = new Net::Gopher;

{
	my $response = $ng->request(
		new Net::Gopher::Request(
			Gopher => {
				Host     => 'gopher.floodgap.com',
				Port     => 70,
				Selector => '/',
				ItemType => 1
			}
		)
	);

	if ($response->is_success and $response->is_menu and $response->is_terminated)
	{
		print "ok 1\n";
	}
	else
	{
		print "not ok 1\n";
	}

	my @menu = $response->as_menu;

	if (@menu and exists $menu[0]{'type'}   and exists $menu[0]{'display'}
		and exists $menu[0]{'selector'} and exists $menu[0]{'host'}
		and exists $menu[0]{'port'}     and exists $menu[0]{'gopher_plus'})
	{
		print "ok 2\n";
	}
	else
	{
		print "not ok 2\n";
	}
}

{
	my $response = $ng->request(
		Gopher(
			Host     => 'gopher.floodgap.com',
			Port     => 70,
			Selector => '/',
			ItemType => 1
		), File => 'somefile.txt'
	);

	if ($response->is_success)
	{
		print "ok 3\n";
	}
	else
	{
		print "not ok 3\n";
	}

	if (open(FILE, 'somefile.txt'))
	{
		print "ok 4\n";

		my $file = join('', <FILE>);
		close FILE;
		unlink 'somefile.txt';
		if ($file =~ /floodgap/i)
		{
			print "ok 5\n";
		}
		else
		{
			print "not ok 5\n";
		}
	}
	else
	{
		print "not ok 4\n";
	}
}


{
	my $response = $ng->gopher(
		Host     => 'gopher.floodgap.com',
		Port     => 70,
		Selector => '/',
		ItemType => 1
	);

	if ($response->is_success)
	{
		print "ok 6\n";
	}
	else
	{
		print "not ok 6\n";
	}
}





{
	my $length;
	my $response = $ng->request(
		new Net::Gopher::Request(URL => 'gopher.floodgap.com:70/1/'),
		Callback => sub { $length += length shift }
	);

	if ($response->is_success)
	{
		print "ok 7\n";

		if ($length > 1)
		{
			print "ok 8\n";
		}
		else
		{
			print "not ok 8\n";
		}
	}
	else
	{
		print "not ok 7\n";
	}
}

{
	my $response = $ng->request(
		URL('gopher.floodgap.com:70/1/')
	);

	if ($response->is_success and $response->is_menu)
	{
		print "ok 9\n";
	}
	else
	{
		print "not ok 9\n";
	}
}

{
	my $response = $ng->url('gopher.floodgap.com:70/1/');

	if ($response->is_success and $response->is_menu)
	{
		print "ok 10\n";
	}
	else
	{
		print "not ok 10\n";
	}
}
