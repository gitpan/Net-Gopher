#!/usr/bin/perl -w
# 
# alternatestyle.pl - This script just demonstrates an alternate style of
#                     coding Net::Gopher scripts.
# 
use strict;
use Net::Gopher;
use Net::Gopher::Constants ':item_types';

my $ng = new Net::Gopher;

my $request = new Net::Gopher::Request (
	Gopher => {
		host      => 'gopher.floodgap.com',
		port      => 70,
		selector  => '/',
		item_type => GOPHER_MENU_TYPE
	}
);

my $response = $ng->request($request);

die $response->error if ($response->is_error);

print $response->content;
