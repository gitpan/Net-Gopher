#!/usr/bin/perl -w
use strict;
use Test::Harness;

runtests(
	'./tests/net_gopher_request.t',
	'./tests/net_gopher.t',
	'./tests/net_gopher_response.t'
);
