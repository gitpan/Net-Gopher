#!/usr/bin/perl -w
use strict;
use Test::Harness;

unshift(@INC, qw(./blib/lib ./blib/arch));



# first, make sure the line endings in the test items are correct:
my %files_and_newlines = (
	'index'          => 'LF',
	gp_index         => 'CRLF',
	gp_s_byte_term   => 'CRLF',
	gp_s_period_term => 'CRLF',
	gp_s_no_term     => 'CRLF',
	gp_byte_term     => 'CR',
	gp_period_term   => 'CRLF',
	gp_no_term       => 'LF',
	item_blocks      => 'CR',
	directory_blocks => 'LF',
	error_not_found  => 'CRLF',
	error_multiline  => 'CR',
	malformed_menu   => 'LF'
);

while (my ($file, $nl) = each %files_and_newlines)
{
	my $rc = system("perl ./tests/newlines.pl -n $nl ./tests/items/$file");
	die "Couldn't fix line endings in test item ($file) via newlines.pl: $!"
		if ($rc);
}

runtests(
	qw(
		./tests/net_gopher_request.t
		./tests/net_gopher.t
		./tests/net_gopher_response.t
		./tests/menu_items.t
		./tests/information_blocks.t
		./tests/live.t
	)
);

