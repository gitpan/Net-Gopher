print "1..12\n";
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

if ($response->is_blocks)
{
	print "ok 6\n";
}
else
{
	print "not ok 6\n";
}

my $info = $response->item_blocks('INFO');

if (exists $info->{'type'} and exists $info->{'text'}
	and exists $info->{'selector'} and exists $info->{'host'}
	and exists $info->{'port'})
{
	print "ok 7\n";
}
else
{
	print "not ok 7\n";
}

my $admin = $response->item_blocks('ADMIN');

if (@{ $admin->{'Mod-Date'} } == 9)
{
	print "ok 8\n";
}
else
{
	print "not ok 8\n";
}

if (scalar @{ $admin->{'Admin'} } == 2)
{
	print "ok 9\n";
}
else
{
	print "not ok 9\n";
}

my %blocks = $response->as_blocks;

if (exists $blocks{'INFO'}{'type'} and exists $blocks{'INFO'}{'text'}
	and exists $blocks{'INFO'}{'selector'} and exists $blocks{'INFO'}{'host'}
	and exists $blocks{'INFO'}{'port'})
{
	print "ok 10\n";
}
else
{
	print "not ok 10\n";
}

if (@{ $blocks{'ADMIN'}{'Mod-Date'} } == 9)
{
	print "ok 11\n";
}
else
{
	print "not ok 11\n";
}

if (@{ $blocks{'ADMIN'}{'Admin'} } == 2)
{
	print "ok 12\n";
}
else
{
	print "not ok 12\n";
}
