#!/usr/bin/perl -w
use strict;

my @tests = qw(
	./tests/net_gopher_request.t
	./tests/net_gopher.t
	./tests/net_gopher_response.t
	./tests/menu_items.t
	./tests/live.t
);

foreach my $test (@tests)
{
	my $rc = system("perl $test");

	die $! if ($rc != 0);

	warn $@ if ($@);
}
