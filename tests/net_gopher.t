use strict;
use warnings;
use Net::Gopher;
use Net::Gopher::Request qw(:all);
use Net::Gopher::Constants qw(:item_types);

print "1..9\n";

my $ng = new Net::Gopher;







################################################################################
#
# request() method tests:
#

{
	my $response = $ng->request(
		new Net::Gopher::Request ('Gopher',
			Host     => 'gopher.floodgap.com',
			Port     => 70,
			Selector => '/',
			ItemType => GOPHER_MENU_TYPE
		)
	);


	if ($response->is_success
		and $response->is_menu
		and $response->is_terminated)
	{
		print "ok 1\n";
	}
	else
	{
		print "not ok 1\n";
	}
}



{
	my $response = $ng->request(
		new Net::Gopher::Request ('GopherPlus',
			Host     => 'gopher.quux.org',
			Selector => '/About This Server.txt',
			ItemType => TEXT_FILE_TYPE
		),
		File => 'somefile.txt'
	);

	if ($response->is_success)
	{
		print "ok 2\n";
	}
	else
	{
		print "not ok 2\n";
	}

	if (-e 'somefile.txt')
	{
		unlink 'somefile.txt';
		print "ok 3\n";
	}
	else
	{
		print "not ok 3\n";
	}
}



{
	my ($count, $length);
	my $response = $ng->request(
		new Net::Gopher::Request ('Gopher',
			Host     => 'gopher.floodgap.com',
			Selector => '/gopher/proxy',
			ItemType => TEXT_FILE_TYPE
		),
		Callback => sub { process_content(@_, \$count, \$length) }
	);

	if ($response->is_success
		and $response->is_terminated
		and $count
		and $length > 64)
	{
		print "ok 4\n";
	}
	else
	{
		print "not ok 4\n";
	}
}

sub process_content
{
	my ($buffer, $request, $response, $count, $length) = @_;

	$$count++;
	$$length += length $buffer;
}





################################################################################
#
# Named request type method tests:
#

{
	my $response = $ng->gopher(Host => 'gopher.floodgap.com');

	if ($response->is_success
		and $response->is_menu
		and $response->is_terminated)
	{
		print "ok 5\n";
	}
	else
	{
		print "not ok 5\n";
	}
}



{
	my $response = $ng->gopher_plus(Host => 'gopher.quux.org');

	if ($response->is_success
		and $response->is_menu)
	{
		print "ok 6\n";
	}
	else
	{
		print "not ok 6\n";
	}
}



{
	my $response = $ng->item_attribute(Host => 'gopher.quux.org');

	if ($response->is_success
		and $response->is_blocks)
	{
		print "ok 7\n";
	}
	else
	{
		print "not ok 7\n";
	}
}



{
	my $response = $ng->directory_attribute(Host => 'gopher.quux.org');

	if ($response->is_success
		and $response->is_blocks)
	{
		print "ok 8\n";
	}
	else
	{
		print "not ok 8\n";
	}
}



{
	my $response = $ng->url('gopher.floodgap.com');

	if ($response->is_success
		and $response->is_terminated
		and $response->is_menu)
	{
		print "ok 9\n";
	}
	else
	{
		print "not ok 9\n";
	}
}
