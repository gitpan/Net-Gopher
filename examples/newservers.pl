#!/usr/bin/perl -w
# 
# newservers.pl - Requests a list a new Gopher servers since 1999 from 
#                 gopher.floodgap.com, prints it out to the console, and saves
#                 the list to a file it creates named newservers.xml.
# 

use strict;
use Net::Gopher;
use Net::Gopher::Constants qw(:item_types);





my $ng = new Net::Gopher;

print "Downloading list of new servers from floodgap.com...\n";

my $response = $ng->gopher(
	Host     => 'gopher.floodgap.com',
	Selector => '/new',
	ItemType => GOPHER_MENU_TYPE
);

die "Couldn't get list of new servers: " . $response->error
	if ($response->is_error);

my @items = $response->extract_items(ExceptTypes => INLINE_TEXT_TYPE);
$response->as_xml(File => './newservers/newservers.xml');

print "\n...Saved to ./newservers/newservers.xml\n";
