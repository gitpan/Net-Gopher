# this file tests the Gopher+ support in Net::Gopher using gopher.quux.org

print "1..18\n";
use strict;
use warnings;
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

my $response = $gopher->request('	+', Type => 1);
$gopher->disconnect;

if ($response->is_success)
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

if (@menu)
{
	print "ok 4\n";
}
else
{
	print "not ok 4\n";
}



if ($gopher->connect('gopher.quux.org', Port => 70))
{
	print "ok 5\n";
}
else
{
	print "not ok 5\n";
}

$response = $gopher->request('	!');
if ($response->is_success)
{
	print "ok 6\n";
}
else
{
	print "not ok 6\n";
}

if ($response->is_blocks)
{
	print "ok 7\n";
}
else
{
	print "not ok 7\n";
}

my $info = $response->item_blocks('INFO');

if (exists $info->{'type'} and exists $info->{'text'}
	and exists $info->{'selector'} and exists $info->{'host'}
	and exists $info->{'port'})
{
	print "ok 8\n";
}
else
{
	print "not ok 8\n";
}

my $admin = $response->item_blocks('ADMIN');

if (@{ $admin->{'Mod-Date'} } == 9)
{
	print "ok 9\n";
}
else
{
	print "not ok 9\n";
}

if (scalar @{ $admin->{'Admin'} } == 2)
{
	print "ok 10\n";
}
else
{
	print "not ok 10\n";
}

my %blocks = $response->as_blocks;

if (exists $blocks{'INFO'}{'type'} and exists $blocks{'INFO'}{'text'}
	and exists $blocks{'INFO'}{'selector'} and exists $blocks{'INFO'}{'host'}
	and exists $blocks{'INFO'}{'port'})
{
	print "ok 11\n";
}
else
{
	print "not ok 11\n";
}

if (@{ $blocks{'ADMIN'}{'Mod-Date'} } == 9)
{
	print "ok 12\n";
}
else
{
	print "not ok 12\n";
}

if (@{ $blocks{'ADMIN'}{'Admin'} } == 2)
{
	print "ok 13\n";
}
else
{
	print "not ok 13\n";
}

if ($gopher->connect('gopher.quux.org', Port => 70))
{
	print "ok 14\n";
}
else
{
	print "not ok 14\n";
}

$response = $gopher->request(
	'/Software/Gopher/screenshots/lynx.gif	+',
	Type => 'g'
);
if ($response->is_success)
{
	print "ok 15\n";
}
else
{
	print "not ok 15\n";
}

$response = $gopher->request_url("gopher://gopher.quux.org/0/		\$+INFO");

if ($response->is_success and $response->is_blocks)
{
	print "ok 16\n";
}
else
{
	print "not ok 16\n";
}

$response = $gopher->request_url('gopher.quux.org/0/About This Server.txt		!');

if ($response->is_success and $response->is_blocks)
{
	print "ok 17\n";
}
else
{
	print "not ok 17\n";
}

$response = $gopher->request_url("gopher.quux.org/0/		+text/plain");

if ($response->is_success)
{
	print "ok 18\n";
}
else
{
	print "not ok 18\n";
}
