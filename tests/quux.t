print "1..7\n";
use Net::Gopher;

my $gopher = new Net::Gopher;
if ($gopher->connect('gopher.quux.org', Port => 70))
{
	print "ok 1\n";
}
else
{
	print "not ok 1\n";
}

my $response = $gopher->request('	+');
$gopher->disconnect;

if ($response->is_success)
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



if ($gopher->connect('gopher.quux.org', Port => 70))
{
	print "ok 4\n";
}
else
{
	print "not ok 4\n";
}

$response = $gopher->request('	!');
if ($response->is_success)
{
	print "ok 5\n";
}
else
{
	print "not ok 5\n";
}

my $info = $response->as_block('INFO');

if (exists $info->{'type'} and exists $info->{'text'}
	and exists $info->{'selector'} and exists $info->{'host'}
	and exists $info->{'port'})
{
	print "ok 6\n";
}
else
{
	print "not ok 6\n";
}

my $admin = $response->as_block('ADMIN');

if (@{ $admin->{'Mod-Date'} } == 9)
{
	print "ok 7\n";
}
else
{
	print "not ok 7\n";
}
