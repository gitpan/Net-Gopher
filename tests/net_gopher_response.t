use strict;
use warnings;
use Net::Gopher;
use Net::Gopher::Request qw(:all);
use Net::Gopher::Constants qw(:item_types);

print "1..7\n";

my $ng = new Net::Gopher;







################################################################################
#
# menu tests:
#

{
	my $response = $ng->gopher(Host => 'gopher.floodgap.com');

	if ($response->is_success
		and $response->is_menu
		and $response->is_terminated)
	{
		my @menu_items = $response->extract_menu_items(IgnoreTypes => 'i');

		my $inline_text;
		foreach my $item (@menu_items)
		{
			$inline_text++ if ($item->item_type eq INLINE_TEXT_TYPE);
		}

		if ($inline_text)
		{
			print "not ok 1\n";
		}
		else
		{
			print "ok 1\n";
		}



		@menu_items = $response->extract_menu_items(GetTypes => ['1']);

		my $not_menu;
		foreach my $item (@menu_items)
		{
			$not_menu++ if ($item->item_type ne GOPHER_MENU_TYPE);
		}

		if ($not_menu)
		{
			print "not ok 2\n";
		}
		else
		{
			print "ok 2\n";
		}

		if ($response->as_xml(File => 'menu.xml') and -e 'menu.xml')
		{
			unlink 'menu.xml';
			print "ok 3\n";

			my $request = shift(@menu_items)->as_request;

			$response = $ng->request($request);

			if ($response->is_success and $response->is_terminated)
			{
				print "ok 4\n";
			}
			else
			{
				print "not ok 4\n";
			}
		}
		else
		{
			print "not ok 3\n";
			print "not ok 4\n";
		}
	}
	else
	{
		print "not ok 1\n";
		print "not ok 2\n";
		print "not ok 3\n";
		print "not ok 4\n";
	}
}



################################################################################
#
# item attribute tests:
#

{
	my $response = $ng->item_attribute(Host => 'gopher.quux.org');

	if ($response->is_success and $response->is_blocks)
	{
		my %seen;
		my $not_ok;
		foreach my $item ($response->get_blocks)
		{
			if ($item->name and !$seen{$item->name}
				and $item->value
				and $item->raw_value)
			{
				$seen{$item->name}++;
			}
			else
			{
				$not_ok++;
				last;
			}
		}

		if (%seen and !$not_ok)
		{
			print "ok 5\n";
		}
		else
		{
			print "not ok 5\n";
		}



		my $admin = $response->get_blocks(Blocks => '+ADMIN');

		my ($name, $email) = $admin->extract_administrator;

		if ($name eq 'John Goerzen' and $email eq 'jgoerzen@complete.org')
		{
			print "ok 6\n";
		}
		else
		{
			print "not ok 6\n";
		}

		if (localtime $admin->extract_date_modified)
		{
			print "ok 7\n";
		}
		else
		{
			print "not ok 7\n";
		}
	}
	else
	{
		print "not ok 5\n";
		print "not ok 6\n";
		print "not ok 7\n";
	}
}
