#!/usr/bin/perl -w
# 
# newservers.pl - Requests a list a new Gopher servers since 1999 from 
#                 gopher.floodgap.com and saves the list as XML to a file it
#                 creates named newservers.xml.
# 

use strict;
use Net::Gopher;
use Net::Gopher::Constants qw(:item_types);



print "Downloading list of new servers from floodgap.com...\n";

my $ng = new Net::Gopher;

my $response = $ng->gopher(
	Host     => 'gopher.floodgap.com',
	Selector => '/new',
	ItemType => GOPHER_MENU_TYPE
);

die "Couldn't get list of new servers: " . $response->error
	if ($response->is_error);

$response->as_xml(File => './newservers/newservers.xml');

print "\n...Saved to ./newservers/newservers.xml\n";
