#!/usr/bin/perl -w
use strict;
use Net::Gopher;
use Net::Gopher::Constants qw(:item_types);

my $ng = new Net::Gopher;

my $response = $ng->gopher_plus(
	Host     => 'gopher.quux.org',
	Port     => 70,
	Selector => '/Software/Gopher/screenshots',
	ItemType => GOPHER_MENU_TYPE
);

die $response->error if ($response->is_error);



foreach my $item ($response->extract_items)
{
	(my $filename = $item->selector) =~ s{.*[:\\/]}{};
	$filename = './screenshots/' . $filename;

	print "Requesting \"$filename\"...\n";
	my $response = $ng->request($item->as_request, File => $filename);

	if ($response->is_error)
	{
		warn $response->error . "... Retry?\n";
		chomp(my $redo = <STDIN>);
		redo if ($redo =~ /^y/i);
	}

	print "Saved \"$filename\" to disk.\n\n";
}
