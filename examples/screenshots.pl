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

	printf("Requesting \"%s\" from %s...\n",
		$filename,
		$item->host
	);

	my $response = $ng->request($item->as_request,
		File => './screenshots/' . $filename
	);

	if ($response->is_error)
	{
		warn $response->error . "... Retry?\n";
		chomp(my $redo = <STDIN>);
		redo if ($redo =~ /^y(?:es)?$/i);
	}

	print "Saved \"$filename\" to disk.\n\n";
}

print "Now go look in ./screenshots for your images.\n";
