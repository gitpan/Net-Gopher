use strict;
use warnings;
use Net::Gopher;
use Net::Gopher::Request qw(:all);
use Net::Gopher::Utility qw($CRLF);
use Net::Gopher::Constants qw(:item_types);

print "1..26\n";







################################################################################
#
# Gopher request tests:
#

{
	my $request = Gopher(Host => 'gopher.hole.foo');

	if ($request->as_string eq "$CRLF"
		and $request->as_url eq 'gopher://gopher.hole.foo:70/1')
	{
		print "ok 1\n";
	}
	else
	{
		print "not ok 1\n";
	}
}



{
	my $request = new Net::Gopher::Request ('Gopher',
		Host     => 'gopher.hole.foo',
		Selector => '/some_thing'
	);

	if ($request->as_string eq "/some_thing$CRLF"
		and $request->as_url eq 'gopher://gopher.hole.foo:70/1/some_thing')
	{
		print "ok 2\n";
	}
	else
	{
		print "not ok 2\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		Gopher => {
			Host        => 'gopher.hole.foo',
			Port        => 7777,
			Selector    => '/apps/a_search_engine',
			SearchWords => ['red', 'blue', 'green'],
			ItemType    => INDEX_SEARCH_SERVER_TYPE
		}
	);

	if ($request->as_string eq "/apps/a_search_engine	red blue green$CRLF"
		and $request->as_url eq 'gopher://gopher.hole.foo:7777/7/apps/a_search_engine%09red%20blue%20green')
	{
		print "ok 3\n";
	}
	else
	{
		print "not ok 3\n";
	}
}





################################################################################
#
# Gopher+ request tests:
#

{
	my $request = GopherPlus(Host => 'gopher.host.foo');

	if ($request->as_string eq "	+$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1%09%09+')
	{
		print "ok 4\n";
	}
	else
	{
		print "not ok 4\n";
	}
}



{
	my $request = new Net::Gopher::Request ('GopherPlus',
		Host           => 'gopher.host.foo',
		Port           => 7000,
		Selector       => '/some_pic.jpg',
		Representation => 'image/jpeg',
		ItemType       => IMAGE_FILE_TYPE
	);

	if ($request->as_string eq "/some_pic.jpg	+image/jpeg$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:7000/I/some_pic.jpg%09%09+image/jpeg')
	{
		print "ok 5\n";
	}
	else
	{
		print "not ok 5\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		GopherPlus => {
			Host        => 'gopher.host.foo',
			Selector    => '/search',
			SearchWords => 'apple orange pear',
			ItemType    => INDEX_SEARCH_SERVER_TYPE
		}
	);

	if ($request->as_string eq "/search	apple orange pear	+$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/7/search%09apple%20orange%20pear%09+')
	{
		print "ok 6\n";
	}
	else
	{
		print "not ok 6\n";
	}
}



{
	my $request = new Net::Gopher::Request ('GopherPlus',
		Host           => 'gopher.host.foo',
		Selector       => '/search',
		SearchWords    => ['apple orange pear'],
		Representation => 'application/gopher+-menu',
		ItemType       => INDEX_SEARCH_SERVER_TYPE
	);

	if ($request->as_string eq "/search	apple orange pear	+application/gopher+-menu$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/7/search%09apple%20orange%20pear%09+application/gopher+-menu')
	{
		print "ok 7\n";
	}
	else
	{
		print "not ok 7\n";
	}
}





################################################################################
#
# Item attribute information request tests:
#

{
	my $request = ItemAttribute(Host => 'gopher.host.foo');

	if ($request->as_string eq "	!$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1%09%09!')
	{
		print "ok 8\n";
	}
	else
	{
		print "not ok 8\n";
	}
}



{
	my $request = new Net::Gopher::Request ('ItemAttribute',
		Host     => 'gopher.host.foo',
		Selector => '/a_doc.txt',
	);

	if ($request->as_string eq "/a_doc.txt	!$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1/a_doc.txt%09%09!')
	{
		print "ok 9\n";
	}
	else
	{
		print "not ok 9\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		ItemAttribute => {
			Host       => 'gopher.host.foo',
			Port       => 1234,
			Selector   => '/MIME_file.mime',
			Attributes => ['ADMIN', 'ABSTRACT']
		}
	);

	if ($request->as_string eq "/MIME_file.mime	!+ADMIN+ABSTRACT$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:1234/1/MIME_file.mime%09%09!+ADMIN+ABSTRACT')
	{
		print "ok 10\n";
	}
	else
	{
		print "not ok 10\n";
	}
}





################################################################################
#
# Directory attribute information request tests:
#

{
	my $request = DirectoryAttribute(Host => 'gopher.host.foo');

	if ($request->as_string eq "	\$$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1%09%09$')
	{
		print "ok 11\n";
	}
	else
	{
		print "not ok 11\n";
	}
}



{
	my $request = new Net::Gopher::Request ('DirectoryAttribute',
		Host       => 'gopher.host.foo',
		Selector   => '/directory',
		Attributes => '+INFO+VIEWS'
	);

	if ($request->as_string eq "/directory	\$+INFO+VIEWS$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1/directory%09%09$+INFO+VIEWS')
	{
		print "ok 12\n";
	}
	else
	{
		print "not ok 12\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		DirectoryAttribute => {
			Host       => 'gopher.host.foo',
			Port       => 2600,
			Selector   => '/more/directory',
			Attributes => ['+INFO', '+ADMIN']
		}
	);

	if ($request->as_string eq "/more/directory	\$+INFO+ADMIN$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:2600/1/more/directory%09%09$+INFO+ADMIN')
	{
		print "ok 13\n";
	}
	else
	{
		print "not ok 13\n";
	}
}










################################################################################
#
# URL request tests:
#

{
	my $request = URL('gopher://gopher.hole.foo:70/1');

	if ($request->as_string eq "$CRLF"
		and $request->as_url eq 'gopher://gopher.hole.foo:70/1')
	{
		print "ok 14\n";
	}
	else
	{
		print "not ok 14\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		URL => 'gopher://gopher.hole.foo:70/1/some_thing'
	);

	if ($request->as_string eq "/some_thing$CRLF"
		and $request->as_url eq 'gopher://gopher.hole.foo:70/1/some_thing')
	{
		print "ok 15\n";
	}
	else
	{
		print "not ok 15\n";
	}
}



{
	my $request = URL('gopher://gopher.hole.foo:7777/7/apps/a_search_engine%09red%20blue%20green');

	if ($request->as_string eq "/apps/a_search_engine	red blue green$CRLF"
		and $request->as_url eq 'gopher://gopher.hole.foo:7777/7/apps/a_search_engine%09red%20blue%20green')
	{
		print "ok 16\n";
	}
	else
	{
		print "not ok 16\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		URL => 'gopher://gopher.host.foo:70/1%09%09+'
	);

	if ($request->as_string eq "	+$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1%09%09+')
	{
		print "ok 17\n";
	}
	else
	{
		print "not ok 17\n";
	}
}



{
	my $request = URL('gopher://gopher.host.foo:7000/I/some_pic.jpg%09%09+image/jpeg');

	if ($request->as_string eq "/some_pic.jpg	+image/jpeg$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:7000/I/some_pic.jpg%09%09+image/jpeg')
	{
		print "ok 18\n";
	}
	else
	{
		print "not ok 18\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		URL => 'gopher://gopher.host.foo:70/7/search%09apple%20orange%20pear%09+'
	);

	if ($request->as_string eq "/search	apple orange pear	+$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/7/search%09apple%20orange%20pear%09+')
	{
		print "ok 19\n";
	}
	else
	{
		print "not ok 19\n";
	}
}



{
	my $request = URL('gopher://gopher.host.foo:70/7/search%09apple%20orange%20pear%09+application/gopher+-menu');

	if ($request->as_string eq "/search	apple orange pear	+application/gopher+-menu$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/7/search%09apple%20orange%20pear%09+application/gopher+-menu')
	{
		print "ok 20\n";
	}
	else
	{
		print "not ok 20\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		URL => 'gopher://gopher.host.foo:70/1%09%09!'
	);

	if ($request->as_string eq "	!$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1%09%09!')
	{
		print "ok 21\n";
	}
	else
	{
		print "not ok 21\n";
	}
}



{
	my $request = URL('gopher://gopher.host.foo:70/1/a_doc.txt%09%09!');

	if ($request->as_string eq "/a_doc.txt	!$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1/a_doc.txt%09%09!')
	{
		print "ok 22\n";
	}
	else
	{
		print "not ok 22\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		URL => 'gopher://gopher.host.foo:1234/1/MIME_file.mime%09%09!+ADMIN+ABSTRACT'
	);

	if ($request->as_string eq "/MIME_file.mime	!+ADMIN+ABSTRACT$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:1234/1/MIME_file.mime%09%09!+ADMIN+ABSTRACT')
	{
		print "ok 23\n";
	}
	else
	{
		print "not ok 23\n";
	}
}



{
	my $request = URL('gopher://gopher.host.foo:70/1%09%09$');

	if ($request->as_string eq "	\$$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1%09%09$')
	{
		print "ok 24\n";
	}
	else
	{
		print "not ok 24\n";
	}
}



{
	my $request = new Net::Gopher::Request (
		URL => 'gopher://gopher.host.foo:70/1/directory%09%09$+INFO+VIEWS'
	);

	if ($request->as_string eq "/directory	\$+INFO+VIEWS$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:70/1/directory%09%09$+INFO+VIEWS')
	{
		print "ok 25\n";
	}
	else
	{
		print "not ok 15\n";
	}
}



{
	my $request = URL('gopher://gopher.host.foo:2600/1/more/directory%09%09$+INFO+ADMIN');

	if ($request->as_string eq "/more/directory	\$+INFO+ADMIN$CRLF"
		and $request->as_url eq 'gopher://gopher.host.foo:2600/1/more/directory%09%09$+INFO+ADMIN')
	{
		print "ok 26\n";
	}
	else
	{
		print "not ok 26\n";
	}
}
