#!/usr/bin/perl -w
use strict;
use Test::Harness;

unshift(@INC, qw(./blib/lib ./blib/arch));



runtests(
	qw(
		./tests/net_gopher_request.t
		./tests/net_gopher.t
		./tests/net_gopher_response.t
		./tests/menu_items.t
		./tests/live.t
	)
);
