print "1..3\n";
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

my @menu = $response->as_menu;

if (@menu)
{
	print "ok 3\n";
}
else
{
	print "not ok 3\n";
}
