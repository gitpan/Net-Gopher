print "1..4\n";
use strict;
use warnings;
use Net::Gopher;

my $gopher = new Net::Gopher;
if ($gopher->connect('gopher.floodgap.com', Port => 70))
{
	print "ok 1\n";
}
else
{
	print "not ok 1\n";
}

my $response = $gopher->request('', Type => 1);

if ($response->is_success and $response->is_terminated)
{
	print "ok 2\n";
}
else
{
	print "not ok 2\n";
}

if ($response->is_menu)
{
	print "ok 3\n";
}
else
{
	print "not ok 3\n";
}

my @menu = $response->as_menu;

if (@menu and exists $menu[0]{'type'}   and exists $menu[0]{'text'}
	and exists $menu[0]{'selector'} and exists $menu[0]{'host'}
	and exists $menu[0]{'port'}     and exists $menu[0]{'gopher+'})
{
	print "ok 4\n";
}
else
{
	print "not ok 4\n";
}
