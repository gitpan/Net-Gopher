# this file tests the Gopher+ support in Net::Gopher using gopher.quux.org

use strict;
use warnings;
use Net::Gopher;
use Net::Gopher::Request qw(:gopher_plus);

print "1..16\n";

my $ng = new Net::Gopher;





##############################################################################
# 
# Gopher+ request tests:
# 

{
	my $response = $ng->request(
		new Net::Gopher::Request(
			GopherPlus => {
				Host     => 'gopher.quux.org',
				Selector => '/',
				ItemType => 1
			}
		)
	);

	if ($response->is_success and $response->is_menu and $response->is_gopher_plus)
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
		GopherPlus(
			Host     => 'gopher.quux.org',
			Port     => 70,
			Selector => '/',
			ItemType => 1
		), File => 'someotherfile.txt'
	);

	if ($response->is_success)
	{
		print "ok 3\n";
	}
	else
	{
		print "not ok 3\n";
	}

	if (open(FILE, 'someotherfile.txt'))
	{
		print "ok 4\n";

		my $file = join('', <FILE>);
		close FILE;
		unlink 'someotherfile.txt';
		if ($file =~ /quux/i)
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
	my $response = $ng->gopher_plus(
		Host     => 'gopher.quux.org',
		Port     => 70,
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





##############################################################################
# 
# Item attribute information request tests:
# 

{
	my $response = $ng->request(
		new Net::Gopher::Request(
			ItemAttribute => {
				Host     => 'gopher.quux.org',
				Selector => '/',
			}
		)
	);

	if ($response->is_success and $response->is_blocks)
	{
		print "ok 7\n";
	}
	else
	{
		print "not ok 7\n";
	}



	my %info = $response->as_info;

	if (exists $info{'type'} and exists $info{'display'}
		and exists $info{'selector'} and exists $info{'host'}
		and exists $info{'port'})
	{
		print "ok 8\n";
	}
	else
	{
		print "not ok 8\n";
	}


	my %admin = $response->as_admin;

	if (@{ $admin{'Mod-Date'} } == 9)
	{
		print "ok 9\n";
	}
	else
	{
		print "not ok 9\n";
	}

	if (scalar @{ $admin{'Admin'} } == 2)
	{
		print "ok 10\n";
	}
	else
	{
		print "not ok 10\n";
	}



	my %blocks = $response->as_blocks;

	my $info = $blocks{'INFO'}->as_info;

	if (exists $info->{'type'} and exists $info->{'display'}
		and exists $info->{'selector'} and exists $info->{'host'}
		and exists $info->{'port'})
	{
		print "ok 11\n";
	}
	else
	{
		print "not ok 11\n";
	}

	my $admin = $blocks{'ADMIN'}->as_admin;

	if (@{ $admin->{'Mod-Date'} } == 9)
	{
		print "ok 12\n";
	}
	else
	{
		print "not ok 12\n";
	}

	if (@{ $admin->{'Admin'} } == 2)
	{
		print "ok 13\n";
	}
	else
	{
		print "not ok 13\n";
	}
}

{
	my $response = $ng->request(
		ItemAttribute(
			Host     => 'gopher.quux.org',
			Port     => 70,
			Selector => '/About This Server.txt'
		)
	);

	if ($response->is_success and $response->is_blocks)
	{
		print "ok 14\n";
	}
	else
	{
		print "not ok 14\n";
	}
}

{
	my $response = $ng->item(
		Host     => 'gopher.quux.org',
		Port     => 70,
		Selector => '/'
	);

	if ($response->is_success and $response->is_blocks)
	{
		print "ok 15\n";
	}
	else
	{
		print "not ok 15\n";
	}
}





##############################################################################
# 
# URL request tests:
# 

{
	my $response = $ng->request(
		new Net::Gopher::Request(
			URL => 'gopher.quux.org/g/Software/Gopher/screenshots/lynx.gif		+'
		)
	);

	if ($response->is_success)
	{
		print "ok 16\n";
	}
	else
	{
		print "not ok 16\n";
	}
}
