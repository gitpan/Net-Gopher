use strict;
use warnings;
use Test;

BEGIN { plan(tests => 135) }

use Net::Gopher;
use Net::Gopher::Constants qw(:all);
use Net::Gopher::Request qw(:all);
use Net::Gopher::Utility qw(get_os_name $CRLF);
use vars qw(%ITEMS_RAW %ITEMS_CONTENT); # filled by BEGIN towards the bottom

require './t/serverfunctions.pl';






{
	run_server();



	#######################################################################
	# 
	# These tests are used to make sure each element of the response
	# object is correctly filled.
	# 

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher(
			Host     => 'localhost',
			Selector => '/index'
		);

		ok($response->raw_response, $ITEMS_RAW{'index'}); # 1
		ok($response->content, $ITEMS_CONTENT{'index'});  # 2
		ok(!defined $response->status_line);              # 3
		ok(!defined $response->status);                   # 4
		ok(!$response->is_error);                         # 5
		ok($response->is_success);                        # 6
		ok(!$response->is_blocks);                        # 7
		ok(!$response->is_gopher_plus);                   # 8
		ok($response->is_menu);                           # 9
		ok($response->is_terminated);                     # 10
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/gp_index'
		);

		ok($response->raw_response, $ITEMS_RAW{'gp_index'}); # 11
		ok($response->content, $ITEMS_CONTENT{'gp_index'});  # 12
		ok($response->status_line, "+322\015\012");          # 13
		ok($response->status, OK);                           # 14
		ok(!$response->is_error);                            # 15
		ok($response->is_success);                           # 16
		ok(!$response->is_blocks);                           # 17
		ok($response->is_gopher_plus);                       # 18
		ok($response->is_menu);                              # 19
		ok(!$response->is_terminated);                       # 20
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/gp_s_byte_term'
		);

		ok($response->raw_response, $ITEMS_RAW{'gp_s_byte_term'}); # 21
		ok($response->content, $ITEMS_CONTENT{'gp_s_byte_term'});  # 22
		ok($response->status_line, "+30\015\012");                 # 23
		ok($response->status, OK);                                 # 24
		ok(!$response->is_error);                                  # 25
		ok($response->is_success);                                 # 26
		ok(!$response->is_blocks);                                 # 27
		ok($response->is_gopher_plus);                             # 28
		ok(!$response->is_menu);                                   # 29
		ok(!$response->is_terminated);                             # 30
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/gp_s_period_term'
		);

		ok($response->raw_response, $ITEMS_RAW{'gp_s_period_term'}); # 31
		ok($response->content, $ITEMS_CONTENT{'gp_s_period_term'});  # 32
		ok($response->status_line, "+-1\015\012");                   # 33
		ok($response->status, OK);                                   # 34
		ok(!$response->is_error);                                    # 35
		ok($response->is_success);                                   # 36
		ok(!$response->is_blocks);                                   # 37
		ok($response->is_gopher_plus);                               # 38
		ok(!$response->is_menu);                                     # 39
		ok($response->is_terminated);                                # 40
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/gp_s_no_term'
		);

		ok($response->raw_response, $ITEMS_RAW{'gp_s_no_term'}); # 41
		ok($response->content, $ITEMS_CONTENT{'gp_s_no_term'});  # 42
		ok($response->status_line, "+-2\015\012");               # 43
		ok($response->status, OK);                               # 44
		ok(!$response->is_error);                                # 45
		ok($response->is_success);                               # 46
		ok(!$response->is_blocks);                               # 47
		ok($response->is_gopher_plus);                           # 48
		ok(!$response->is_menu);                                 # 49
		ok(!$response->is_terminated);                           # 50
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/gp_byte_term'
		);

		ok($response->raw_response, $ITEMS_RAW{'gp_byte_term'}); # 51
		ok($response->content, $ITEMS_CONTENT{'gp_byte_term'});  # 52
		ok($response->status_line, "+3483\015\012");             # 53
		ok($response->status, OK);                               # 54
		ok(!$response->is_error);                                # 55
		ok($response->is_success);                               # 56
		ok(!$response->is_blocks);                               # 57
		ok($response->is_gopher_plus);                           # 58
		ok(!$response->is_menu);                                 # 59
		ok(!$response->is_terminated);                           # 60
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/gp_period_term'
		);

		ok($response->raw_response, $ITEMS_RAW{'gp_period_term'}); # 61
		ok($response->content, $ITEMS_CONTENT{'gp_period_term'});  # 62
		ok($response->status_line, "+-1\015\012");                 # 63
		ok($response->status, OK);                                 # 64
		ok(!$response->is_error);                                  # 65
		ok($response->is_success);                                 # 66
		ok(!$response->is_blocks);                                 # 67
		ok($response->is_gopher_plus);                             # 68
		ok(!$response->is_menu);                                   # 69
		ok($response->is_terminated);                              # 70
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/gp_no_term'
		);

		ok($response->raw_response, $ITEMS_RAW{'gp_no_term'}); # 71
		ok($response->content, $ITEMS_CONTENT{'gp_no_term'});  # 72
		ok($response->status_line, "+-2\015\012");             # 73
		ok($response->status, OK);                             # 74
		ok(!$response->is_error);                              # 75
		ok($response->is_success);                             # 76
		ok(!$response->is_blocks);                             # 77
		ok($response->is_gopher_plus);                         # 78
		ok(!$response->is_menu);                               # 79
		ok(!$response->is_terminated);                         # 80
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/item_blocks'
		);

		ok($response->raw_response, $ITEMS_RAW{'item_blocks'}); # 81
		ok($response->content, $ITEMS_CONTENT{'item_blocks'});  # 82
		ok($response->status_line, "+-1\015\012");              # 83
		ok($response->status, OK);                              # 84
		ok(!$response->is_error);                               # 85
		ok($response->is_success);                              # 86
		ok($response->is_blocks);                               # 87
		ok($response->is_gopher_plus);                          # 88
		ok(!$response->is_menu);                                # 89
		ok($response->is_terminated);                           # 90
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/directory_blocks'
		);

		ok($response->raw_response,
			$ITEMS_RAW{'directory_blocks'});     # 91
		ok($response->content,
			$ITEMS_CONTENT{'directory_blocks'}); # 92
		ok($response->status_line, "+568\015\012");  # 93
		ok($response->status, OK);                   # 94
		ok(!$response->is_error);                    # 95
		ok($response->is_success);                   # 96
		ok($response->is_blocks);                    # 97
		ok($response->is_gopher_plus);               # 98
		ok(!$response->is_menu);                     # 99
		ok(!$response->is_terminated);               # 100
	}





	#######################################################################
	# 
	# These tests are used to make sure Gopher+ error messages are parsed
	# correctly:
	# 

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/error_not_found'
		);

		ok($response->error,
			"1 John Q. Phoney <jqphoney\@pobox.com>\n" .
			"The item does not exist.");                      # 101
		ok($response->error_code, 1);                             # 102

		my ($name, $email) = $response->error_admin;
		ok($name, 'John Q. Phoney');                              # 103
		ok($email, 'jqphoney@pobox.com');                         # 104
		ok($response->error_message, 'The item does not exist.'); # 105
		ok($response->status_line, "--1$CRLF");                   # 106
		ok($response->status, '-');                               # 107
		ok($response->is_error);                                  # 108
		ok(!$response->is_success);                               # 109
		ok(!$response->is_blocks);                                # 110
		ok($response->is_gopher_plus);                            # 111
		ok(!$response->is_menu);                                  # 112
		ok($response->is_terminated);                             # 113
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/error_multiline'
		);

		ok($response->error, join("\n",
			'7 Raymond A. Madeup <r_a_madeup@yahoo.com>',
			'Something very bad happened.',
			'Something very, very bad happened.',
			'Something very, very, very bad happened.')); # 114
		ok($response->error_code, 7);                         # 115

		my ($name, $email) = $response->error_admin;
		ok($name, 'Raymond A. Madeup');                       # 116
		ok($email, 'r_a_madeup@yahoo.com');                   # 117

		ok($response->error_message, join("\n",
			'Something very bad happened.',
			'Something very, very bad happened.',
			'Something very, very, very bad happened.')); # 118
		ok($response->status_line, "--1$CRLF");               # 119
		ok($response->status, '-');                           # 120
		ok($response->is_error);                              # 121
		ok(!$response->is_success);                           # 122
		ok(!$response->is_blocks);                            # 123
		ok($response->is_gopher_plus);                        # 124
		ok(!$response->is_menu);                              # 125
		ok($response->is_terminated);                         # 126
	}








	########################################################################
	# 
	# These tests make sure Net::Gopher::Response raises exceptions in the
	# proper places:
	#

	{
		my $ng = new Net::Gopher(
			UpwardCompatible => 0
		);

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/index'
		);

		ok($response->is_error);    # 127
		ok(!$response->is_success); # 128
		ok($response->error,
			'You sent a Gopher+ style request to a non-Gopher+ ' .
			'server'
		);                          # 129
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher(
			Host     => 'localhost',
			Selector => '/nothing'
		);

		ok($response->is_error);    # 130
		ok(!$response->is_success); # 131
		ok($response->error,
			'The server closed the connection without returning ' .
			'any response'
		);                          # 132
	}

	{
		my $ng = new Net::Gopher;

		my $response = $ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/nothing'
		);

		ok($response->is_error);    # 133
		ok(!$response->is_success); # 134
		ok($response->error,
			'The server closed the connection without ' .
			'returning any response'
		);                          # 135
	}




	kill_server();
}










BEGIN
{
	%ITEMS_RAW = (
		'index' => join('',
			"iThis is a Gopher menu.			\012",
			"1Item one	/directory	localhost	70\012",
			"1Item two	/another_directory	localhost	70\012",
			"0Item three	/three.txt	localhost	70\012",
			"1Item four	/one_more_directory	localhost	70\012",
			"iDownload this:			\012",
			"gGIF image	/image.gif	localhost	70\012",
			"0Item six	/six.txt	localhost	70\012",
			".\012"
		),
		gp_index => join('',
			"+322\015\012",
			"iThis is a Gopher+ style Gopher menu, where all of the items have a fifth field			\015\012",
			"icontaining a + or ? character.			\015\012",
			"1Some directory	/some_dir	localhost	70	+\015\012",
			"1Some other directory	/some_other_dir	localhost	70	+\015\012",
			"gA GIF image	/image.gif	localhost	70	+\015\012",
			"iFill out this form:			\015\012",
			"1Application	/ask_script	localhost	70	?\015\012"
		),
		gp_s_byte_term => join('',
			"+30\015\012",
			"2.3     Gopher+ data transfer.\015\012"
		),
		gp_s_period_term => join('',
			"+-1\015\012",
			"..Status of this Memo\015\012",
			".\015\012"
		),
		gp_s_no_term => join('',
			"+-2\015\012",
			"Gopher+"
		),
		gp_byte_term => join('',
			"+3483\015\012",
			"2.3     Gopher+ data transfer.\015",
			"\015",
			"If a client sends out a Gopher+ type request to a\015",
			"server (by  tagging on a tab and a \"+\" to the\015",
			"request):\015",
			"\015",
			"\015",
			"        bar selectorF+\015",
			"\015",
			"\015",
			"The server may return the response in one of three\015",
			"ways; examples  below:\015",
			"\015",
			"\015",
			"  +5340<CRLF><data>\015",
			"\015",
			"\015",
			"\015",
			"  +-1<CRLF><data><CRLF>.<CRLF>\015",
			"\015",
			"\015",
			"\015",
			"  +-2<CRLF><data>\015",
			"\015",
			"\015",
			"The first response means: I am going to send exactly\015",
			"5340 bytes at you and they will begin right after this\015",
			"line.  The second response means: I have no idea how\015",
			"many bytes I  have to send (or I am lazy), but I will\015",
			"send a period on a  line by itself when I am done.\015",
			"The  third means:  I really  have no idea how many\015",
			"bytes I have to send, and what\'s more,  they COULD\015",
			"contain the <CRLF>.<CRLF> pattern, so just read until\015",
			"I close  the connection.\015",
			"\015",
			"\015",
			"The first character of a response to a Gopher+ query\015",
			"denotes  success (+) or failure (-). Following that is\015",
			"a token to be  interpreted as a decimal number. If the\015",
			"number is >= 0, it  describes the length of the\015",
			"dataBlock. If = -1, it means the  data is period\015",
			"terminated. If = -2, it means the data ends  when the\015",
			"connection closes.\015",
			"\015",
			"\015",
			"The server may return an error also, as in:\015",
			"\015",
			"\015",
			"--1<CRLF><data><CRLF>.<CRLF>\015",
			"\015",
			"\015",
			"The (short!) error message will be in ASCII text in\015",
			"the data part.  The first token on the  first line of\015",
			"the error text (data) contains an error-code  (an\015",
			"integer).  It is recommended that the first line also\015",
			"contain  the e-mail address of the administrator of\015",
			"the  server (in angle brackets). Both the error-code\015",
			"and the email address may easily be  extracted by the\015",
			"client.  Subsequent lines contain a short  error\015",
			"message that may be displayed to the user. Basic error\015",
			"codes are:\015",
			"\015",
			"\015",
			"        1       Item is not available.\015",
			"\015",
			"        2       Try again later (\"eg.  My load is too high\015",
			"right now.\")\015",
			"\015",
			"        3       Item has moved.  Following the error-code is\015",
			"the  gopher descriptor\015",
			"\015",
			"                of where it now lives.\015",
			"\015",
			"\015",
			"More error codes may be defined as the need arises.\015",
			"\015",
			"\015",
			"\015",
			"This should be obvious: if the client sends out an\015",
			"\"old\"  Gopher kind of request:\015",
			"\015",
			"\015",
			"\015",
			"    bar selector\015",
			"\015",
			"\015",
			"\015",
			"the server will know that it is talking to an old\015",
			"client and  will respond in the old way. This means\015",
			"that old gopher  clients can still access information\015",
			"on Gopher+ servers.\015",
			"\015",
			"\015",
			"\015",
			"\015",
			"2.4     Gopher+ client requests.\015",
			"\015",
			"\015",
			"Clients can send requests to retrieve the contents of\015",
			"an item in this form:\015",
			"\015",
			"\015",
			"        \015",
			"selectorstringF+[representation][FdataFlag]<CRLF>[dat\015",
			"ablock]\015",
			"\015",
			"\015",
			"If dataFlag is \'0\', or nonexistent, then the client\015",
			"will not  send any data besides the selector string.\015",
			"If the dataFlag  is \'1\' then a block of data will\015",
			"follow in the same format as Section 2.3.  The  client\015",
			"can send a large amount of data to the server in the\015",
			"dataBlock.  Representations or alternative views of an\015",
			"item\'s contents may be discovered by interrogating the\015",
			"server about the item\'s attribute information; this is\015",
			"explained below.\015",
			"\015",
			"\015",
			"Note that in the original Gopher protocol, a query\015",
			"submitted to an index server might have a selector\015",
			"string followed by a TAB and the words for which the\015",
			"index server was being asked to search. In Gopher+,\015",
			"the extra TAB and Gopher+ information follow the words\015",
			"for which the server is being asked to search. Gopher+\015",
			"client have to be smart enough to know that in the\015",
			"case of a type 7 item (an index server) they append\015",
			"the Gopher+ information after the words being searched\015",
			"for."
		),
		gp_period_term => join('',
			"+-1\015\012",
			"Status of this Memo\015\012",
			"\015\012",
			"   This memo provides information for the Internet community.  It does\015\012",
			"   not specify an Internet standard.  Distribution of this memo is\015\012",
			"   unlimited.\015\012",
			"\015\012",
			"Abstract\015\012",
			"\015\012",
			"   The Internet Gopher protocol is designed for distributed document\015\012",
			"   search and retrieval.  This document describes the protocol, lists\015\012",
			"   some of the implementations currently available, and has an overview\015\012",
			"   of how to implement new client and server applications.  This\015\012",
			"   document is adapted from the basic Internet Gopher protocol document\015\012",
			"   first issued by the Microcomputer Center at the University of\015\012",
			"   Minnesota in 1991.\015\012",
			"\015\012",
			"Introduction\015\012",
			"\015\012",
			"   gopher  n.  1. Any of various short tailed, burrowing mammals of the\015\012",
			"   family Geomyidae, of North America.  2. (Amer. colloq.) Native or\015\012",
			"   inhabitant of Minnesota: the Gopher State.  3. (Amer. colloq.) One\015\012",
			"   who runs errands, does odd-jobs, fetches or delivers documents for\015\012",
			"   office staff.  4. (computer tech.) software following a simple\015\012",
			"   protocol for burrowing through a TCP/IP internet.\015\012",
			"\015\012",
			"   The Internet Gopher protocol and software follow a client-server\015\012",
			"   model.  This protocol assumes a reliable data stream; TCP is assumed.\015\012",
			"   Gopher servers should listen on port 70 (port 70 is assigned to\015\012",
			"   Internet Gopher by IANA).  Documents reside on many autonomous\015\012",
			"   servers on the Internet.  Users run client software on their desktop\015\012",
			"   systems, connecting to a server and sending the server a selector (a\015\012",
			"   line of text, which may be empty) via a TCP connection at a well-\015\012",
			"   known port.  The server responds with a block of text terminated by a\015\012",
			"   period on a line by itself and closes the connection.  No state is\015\012",
			"   retained by the server.\015\012",
			"\015\012",
			"\015\012",
			"\015\012",
			"Anklesari, McCahill, Lindner, Johnson, Torrey & Alberti         [Page 1]\015\012",
			"\015\012",
			"RFC 1436                         Gopher                       March 1993\015\012",
			"\015\012",
			"\015\012",
			"   While documents (and services) reside on many servers, Gopher client\015\012",
			"   software presents users with a hierarchy of items and directories\015\012",
			"   much like a file system.  The Gopher interface is designed to\015\012",
			"   resemble a file system since a file system is a good model for\015\012",
			"   organizing documents and services; the user sees what amounts to one\015\012",
			"   big networked information system containing primarily document items,\015\012",
			"   directory items, and search items (the latter allowing searches for\015\012",
			"   documents across subsets of the information base).\015\012",
			"\015\012",
			"   Servers return either directory lists or documents.  Each item in a\015\012",
			"   directory is identified by a type (the kind of object the item is),\015\012",
			"   user-visible name (used to browse and select from listings), an\015\012",
			"   opaque selector string (typically containing a pathname used by the\015\012",
			"   destination host to locate the desired object), a host name (which\015\012",
			"   host to contact to obtain this item), and an IP port number (the port\015\012",
			"   at which the server process listens for connections). The user only\015\012",
			"   sees the user-visible name.  The client software can locate and\015\012",
			"   retrieve any item by the trio of selector, hostname, and port.\015\012",
			"\015\012",
			"   To use a search item, the client submits a query to a special kind of\015\012",
			"   Gopher server: a search server.  In this case, the client sends the\015\012",
			"   selector string (if any) and the list of words to be matched. The\015\012",
			"   response yields \"virtual directory listings\" that contain items\015\012",
			"   matching the search criteria.\015\012",
			"\015\012",
			"   Gopher servers and clients exist for all popular platforms.  Because\015\012",
			"   the protocol is so sparse and simple, writing servers or clients is\015\012",
			"   quick and straightforward.\015\012",
			"\015\012",
			"1.  Introduction\015\012",
			"\015\012",
			"   The Internet Gopher protocol is designed primarily to act as a\015\012",
			"   distributed document delivery system.  While documents (and services)\015\012",
			"   reside on many servers, Gopher client software presents users with a\015\012",
			"   hierarchy of items and directories much like a file system.  In fact,\015\012",
			"   the Gopher interface is designed to resemble a file system since a\015\012",
			"   file system is a good model for locating documents and services.  Why\015\012",
			"   model a campus-wide information system after a file system?  Several\015\012",
			"   reasons:\015\012",
			"\015\012",
			"      (a) A hierarchical arrangement of information is familiar to many\015\012",
			"      users.  Hierarchical directories containing items (such as\015\012",
			"      documents, servers, and subdirectories) are widely used in\015\012",
			"      electronic bulletin boards and other campus-wide information\015\012",
			"      systems. People who access a campus-wide information server will\015\012",
			"      expect some sort of hierarchical organization to the information\015\012",
			"      presented.\015\012",
			"\015\012",
			"\015\012",
			"\015\012",
			"\015\012",
			"Anklesari, McCahill, Lindner, Johnson, Torrey & Alberti         [Page 2]\015\012",
			"\015\012",
			"RFC 1436                         Gopher                       March 1993\015\012",
			"\015\012",
			"\015\012",
			"      (b) A file-system style hierarchy can be expressed in a simple\015\012",
			"      syntax.  The syntax used for the internet Gopher protocol is\015\012",
			"      easily understandable, and was designed to make debugging servers\015\012",
			"      and clients easy.  You can use Telnet to simulate an internet\015\012",
			"      Gopher client\'s requests and observe the responses from a server.\015\012",
			"      Special purpose software tools are not required.  By keeping the\015\012",
			"      syntax of the pseudo-file system client/server protocol simple, we\015\012",
			"      can also achieve better performance for a very common user\015\012",
			"      activity: browsing through the directory hierarchy.\015\012",
			"\015\012",
			"      (c) Since Gopher originated in a University setting, one of the\015\012",
			"      goals was for departments to have the option of publishing\015\012",
			"      information from their inexpensive desktop machines, and since\015\012",
			"      much of the information can be presented as simple text files\015\012",
			"      arranged in directories, a protocol modeled after a file system\015\012",
			"      has immediate utility.  Because there can be a direct mapping from\015\012",
			"      the file system on the user\'s desktop machine to the directory\015\012",
			"      structure published via the Gopher protocol, the problem of\015\012",
			"      writing server software for slow desktop systems is minimized.\015\012",
			"\015\012",
			"      (d) A file system metaphor is extensible.  By giving a \"type\"\015\012",
			"      attribute to items in the pseudo-file system, it is possible to\015\012",
			"      accommodate documents other than simple text documents.  Complex\015\012",
			"      database services can be handled as a separate type of item.  A\015\012",
			"      file-system metaphor does not rule out search or database-style\015\012",
			"      queries for access to documents.  A search-server type is also\015\012",
			"      defined in this pseudo-file system.  Such servers return \"virtual\015\012",
			"      directories\" or list of documents matching user specified\015\012",
			"      criteria.\015\012",
			".\015\012"
		),
		gp_no_term => join('',
			"+-2\015\012",
			"Gopher+ upward compatible enhancements to\012",
			"the Internet Gopher protocol\012",
			"\012",
			"\012",
			"\012",
			"Farhad Anklesaria, Paul Lindner, Mark P.  McCahill,\012",
			"Daniel Torrey, David Johnson, Bob Alberti\012",
			"\012",
			"Microcomputer and Workstation  Networks Center /\012",
			"Computer and Information Systems\012",
			"University of Minnesota\012",
			"\012",
			"July 30, 1993\012",
			"\012",
			"\012",
			"\012",
			"gopher+  n.  1. Hardier strains of mammals of the\012",
			"family  Geomyidae.  2. (Amer. colloq.) Native or\012",
			"inhabitant of  Minnesota, the Gopher state, in full\012",
			"winter regalia (see  PARKA).  3. (Amer. colloq.)\012",
			"Executive secretary.  4.  (computer tech.) Software\012",
			"following a simple protocol for  burrowing through a\012",
			"TCP/IP internet, made more powerful by  simple\012",
			"enhancements (see CREEPING FEATURISM).\012",
			"\012",
			"\012",
			"Abstract\012",
			"\012",
			"The internet Gopher protocol was designed for\012",
			"distributed  document search and retrieval. The\012",
			"documents \"The internet  Gopher protocol: a\012",
			"distributed document search and retrieval protocol\"\012",
			"and internet RFC 1436 describe the basic  protocol and\012",
			"has an overview of how to implement new client  and\012",
			"server applications. This document describes a set of\012",
			"enhancements to the syntax, semantics and\012",
			"functionality of  the original Gopher protocol.\012",
			"\012",
			"\012",
			"Distribution of this document is unlimited.  Please\012",
			"send  comments to the Gopher development team:\012",
			"<gopher\@boombox.micro.umn.edu>.  Implementation of\012",
			"the  mechanisms described here is encouraged.\012",
			"\012",
			"\012",
			"\012",
			"1.      Introduction\012",
			"\012",
			"The Internet Gopher protocol was designed primarily to\012",
			"act as a distributed document  delivery system.  It\012",
			"has enjoyed increasing popularity, and  is being used\012",
			"for purposes that were not visualized when the\012",
			"protocol was first outlined.  The rest of this\012",
			"document  describes the Gopher+ enhancements in a non-\012",
			"rigorous but easily read and understood  way.  There\012",
			"is a short BNF-like section at the end for exact\012",
			"syntax descriptions.  Throughout the document, \"F\"\012",
			"stands  for the ASCII TAB character. There is an\012",
			"implicit carriage  return and linefeed at the ends of\012",
			"lines; these will only be explicitly  mentioned where\012",
			"necessary to avoid confusion. To understand  this\012",
			"document, you really must be familiar with the basic\012",
			"Gopher protocol.\012",
			"\012",
			"\012",
			"Servers and clients understanding the Gopher+\012",
			"extensions will transmit extra information at the ends\012",
			"of list and request lines.  Old, basic gopher clients\012",
			"ignore such information.  New  Gopher+ aware servers\012",
			"continue to work at their old level  with unenhanced\012",
			"clients.  The extra information that can be\012",
			"communicated by Gopher+ clients may be used to summon\012",
			"new capabilities to bridge  the most keenly felt\012",
			"shortcomings of the venerable old  Gopher.\012",
			"\012",
			"\012",
			"\012",
			"\012",
			"2.      How does Gopher+ work?\012",
			"\012",
			"Gopher+ enhancements rely on transmitting an \"extra\"\012",
			"tab  delimited fields beyond what regular (old) Gopher\012",
			"servers and clients now use.  If most existing (old)\012",
			"clients were to encounter extra stuff beyond the\012",
			"\"port\"  field in a list (directory), most would ignore\012",
			"it. Gopher+  servers will return item descriptions in\012",
			"this form:\012",
			"\012",
			"\012",
			"1Display stringFselector stringFhostFportFextra\012",
			"stuff<CRLF>\012",
			"\012",
			"\012",
			"If an existing (old) client has problems with\012",
			"additional  information beyond the port, it should not\012",
			"take much more  than a simple tweak to have it discard\012",
			"unneeded stuff.\012",
			"\012",
			"\012",
			"\012",
			"\012",
			"2.1     Advisory issued to client maintainers.\012",
			"\012",
			"If it does not do this already, your existing client\012",
			"should be modified  as soon as possible to ignore\012",
			"extra fields beyond what it  expects to find.  This\012",
			"will ensure thatyour clients does not break  when it\012",
			"encounters Gopher+ servers in gopherspace.\012",
			"\012",
			"\012",
			"All the regular Gopher protocol info remains intact\012",
			"except for:\012",
			"\012",
			"\012",
			"(1)  Instead of just a CRLF after the port field in\012",
			"any item  of a list (directory) there may be an\012",
			"optional TAB followed  by extra stuff as noted above\012",
			"(explanation to follow).\012",
			"\012",
			"\012",
			"\012",
			"(2) In the original Gopher protocol, there was\012",
			"provision for a date-time descriptor (sec 3.6) to be\012",
			"sent  after the selector (for use by autoindexer\012",
			"beasts).  As far  as we know, while the descriptor is\012",
			"implemented in the Mac  server, it is not in any other\012",
			"server and no clients or  daemons use it.  This is a\012",
			"good time to withdraw this feature. The basic gopher\012",
			"protocol has been revised for the final time and will\012",
			"be  frozen.\012",
			"\012",
			"\012",
			"\012",
			"\012",
			"\012",
			"\012",
			"2.2     Gopher+ item lists.\012",
			"\012",
			"Gopher servers that can utilize the Gopher+\012",
			"enhancements  will send some additional stuff\012",
			"(frequently the character \"+\") after the port field\012",
			"describing any list item.  eg:\012",
			"\012",
			"\012",
			"1Some old directoryFfoo selectorFhost1Fport1\012",
			"\012",
			"1Some new directoryFbar selectorFhost1Fport1F+\012",
			"\012",
			"0Some file or otherFmoo selectorFhost2Fport2F+\012",
			"\012",
			"\012",
			"The first line is the regular old gopher item\012",
			"description. The second line is new Gopher+  item\012",
			"description.  The third line is a Gopher+ description\012",
			"of a document. Old  gopher clients can request the\012",
			"latter two items using old  format gopher selector\012",
			"strings and retrieve the items. New,  Gopher+ savvy\012",
			"clients will notice the trailing + and know that they\012",
			"can do extra  things with these kinds of items.\012"
		),
		item_blocks => join('',
			"+-1\015\012",
			"+INFO 1Gopher+ Index	/gp_index	localhost	70	+\015",
			"+ADMIN:\015",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\015",
			" Mod-Date: <20030728173012>\015",
			" Creation-Date: <20030728170201>\015",
			" Expiration-Date: <20030909090001>\015",
			"+VIEWS:\015",
			" text/plain: <.40k>\015",
			" application/gopher+-menu En_US: <1200b>\015",
			" text/html: <.77KB>\015",
			"+ABSTRACT\015",
			" This is a short synopsis of the item.\015",
			" It spans\015",
			" multiple lines.\015",
			"+ASK\015",
			" Ask: What is your name?\015",
			" Ask: Where are you from?	Montana\015",
			" Choose: What is your favorite color?	red	green	blue\015",
			" Select: Contact using:	Email	Instant messages	IRC\015",
			".\015"
		),
		directory_blocks => join('',
			"+568\015\012",
			"+INFO: 1Gopher+ Index	/gp_index	localhost	70	+\012",
			"+ADMIN\012",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012",
			" Mod-Date: <20030728173012>\012",
			"+INFO: 0Byte terminated file	/gp_byte_term	localhost	70	+\012",
			"+ADMIN\012",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012",
			" Mod-Date: <20031201123000>\012",
			"+INFO: 0Period terminated file	/gp_period_term	localhost	70	+\012",
			"+ADMIN\012",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012",
			" Mod-Date: <20040101070206>\012",
			"+INFO: 0Non-terminated file	/gp_no_term	localhost	70	+\012",
			"+ADMIN\012",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012",
			" Mod-Date: <20040201182005>"
		),
	);





	%ITEMS_CONTENT = (
		'index' => join('',
			"iThis is a Gopher menu.			\n",
			"1Item one	/directory	localhost	70\n",
			"1Item two	/another_directory	localhost	70\n",
			"0Item three	/three.txt	localhost	70\n",
			"1Item four	/one_more_directory	localhost	70\n",
			"iDownload this:			\n",
			"gGIF image	/image.gif	localhost	70\n",
			"0Item six	/six.txt	localhost	70\n",
			".\n"
		),
		gp_index => join('',
			"iThis is a Gopher+ style Gopher menu, where all of the items have a fifth field			\n",
			"icontaining a + or ? character.			\n",
			"1Some directory	/some_dir	localhost	70	+\n",
			"1Some other directory	/some_other_dir	localhost	70	+\n",
			"gA GIF image	/image.gif	localhost	70	+\n",
			"iFill out this form:			\n",
			"1Application	/ask_script	localhost	70	?\n"
		),
		gp_s_byte_term => join('',
			"2.3     Gopher+ data transfer.\n"
		),
		gp_s_period_term => join('',
			".Status of this Memo\n",
			".\n"
		),
		gp_s_no_term => join('',
			"Gopher+"
		),
		gp_byte_term => join('',
			"2.3     Gopher+ data transfer.\n",
			"\n",
			"If a client sends out a Gopher+ type request to a\n",
			"server (by  tagging on a tab and a \"+\" to the\n",
			"request):\n",
			"\n",
			"\n",
			"        bar selectorF+\n",
			"\n",
			"\n",
			"The server may return the response in one of three\n",
			"ways; examples  below:\n",
			"\n",
			"\n",
			"  +5340<CRLF><data>\n",
			"\n",
			"\n",
			"\n",
			"  +-1<CRLF><data><CRLF>.<CRLF>\n",
			"\n",
			"\n",
			"\n",
			"  +-2<CRLF><data>\n",
			"\n",
			"\n",
			"The first response means: I am going to send exactly\n",
			"5340 bytes at you and they will begin right after this\n",
			"line.  The second response means: I have no idea how\n",
			"many bytes I  have to send (or I am lazy), but I will\n",
			"send a period on a  line by itself when I am done.\n",
			"The  third means:  I really  have no idea how many\n",
			"bytes I have to send, and what\'s more,  they COULD\n",
			"contain the <CRLF>.<CRLF> pattern, so just read until\n",
			"I close  the connection.\n",
			"\n",
			"\n",
			"The first character of a response to a Gopher+ query\n",
			"denotes  success (+) or failure (-). Following that is\n",
			"a token to be  interpreted as a decimal number. If the\n",
			"number is >= 0, it  describes the length of the\n",
			"dataBlock. If = -1, it means the  data is period\n",
			"terminated. If = -2, it means the data ends  when the\n",
			"connection closes.\n",
			"\n",
			"\n",
			"The server may return an error also, as in:\n",
			"\n",
			"\n",
			"--1<CRLF><data><CRLF>.<CRLF>\n",
			"\n",
			"\n",
			"The (short!) error message will be in ASCII text in\n",
			"the data part.  The first token on the  first line of\n",
			"the error text (data) contains an error-code  (an\n",
			"integer).  It is recommended that the first line also\n",
			"contain  the e-mail address of the administrator of\n",
			"the  server (in angle brackets). Both the error-code\n",
			"and the email address may easily be  extracted by the\n",
			"client.  Subsequent lines contain a short  error\n",
			"message that may be displayed to the user. Basic error\n",
			"codes are:\n",
			"\n",
			"\n",
			"        1       Item is not available.\n",
			"\n",
			"        2       Try again later (\"eg.  My load is too high\n",
			"right now.\")\n",
			"\n",
			"        3       Item has moved.  Following the error-code is\n",
			"the  gopher descriptor\n",
			"\n",
			"                of where it now lives.\n",
			"\n",
			"\n",
			"More error codes may be defined as the need arises.\n",
			"\n",
			"\n",
			"\n",
			"This should be obvious: if the client sends out an\n",
			"\"old\"  Gopher kind of request:\n",
			"\n",
			"\n",
			"\n",
			"    bar selector\n",
			"\n",
			"\n",
			"\n",
			"the server will know that it is talking to an old\n",
			"client and  will respond in the old way. This means\n",
			"that old gopher  clients can still access information\n",
			"on Gopher+ servers.\n",
			"\n",
			"\n",
			"\n",
			"\n",
			"2.4     Gopher+ client requests.\n",
			"\n",
			"\n",
			"Clients can send requests to retrieve the contents of\n",
			"an item in this form:\n",
			"\n",
			"\n",
			"        \n",
			"selectorstringF+[representation][FdataFlag]<CRLF>[dat\n",
			"ablock]\n",
			"\n",
			"\n",
			"If dataFlag is \'0\', or nonexistent, then the client\n",
			"will not  send any data besides the selector string.\n",
			"If the dataFlag  is \'1\' then a block of data will\n",
			"follow in the same format as Section 2.3.  The  client\n",
			"can send a large amount of data to the server in the\n",
			"dataBlock.  Representations or alternative views of an\n",
			"item\'s contents may be discovered by interrogating the\n",
			"server about the item\'s attribute information; this is\n",
			"explained below.\n",
			"\n",
			"\n",
			"Note that in the original Gopher protocol, a query\n",
			"submitted to an index server might have a selector\n",
			"string followed by a TAB and the words for which the\n",
			"index server was being asked to search. In Gopher+,\n",
			"the extra TAB and Gopher+ information follow the words\n",
			"for which the server is being asked to search. Gopher+\n",
			"client have to be smart enough to know that in the\n",
			"case of a type 7 item (an index server) they append\n",
			"the Gopher+ information after the words being searched\n",
			"for."
		),
		gp_period_term => join('',
			"Status of this Memo\n",
			"\n",
			"   This memo provides information for the Internet community.  It does\n",
			"   not specify an Internet standard.  Distribution of this memo is\n",
			"   unlimited.\n",
			"\n",
			"Abstract\n",
			"\n",
			"   The Internet Gopher protocol is designed for distributed document\n",
			"   search and retrieval.  This document describes the protocol, lists\n",
			"   some of the implementations currently available, and has an overview\n",
			"   of how to implement new client and server applications.  This\n",
			"   document is adapted from the basic Internet Gopher protocol document\n",
			"   first issued by the Microcomputer Center at the University of\n",
			"   Minnesota in 1991.\n",
			"\n",
			"Introduction\n",
			"\n",
			"   gopher  n.  1. Any of various short tailed, burrowing mammals of the\n",
			"   family Geomyidae, of North America.  2. (Amer. colloq.) Native or\n",
			"   inhabitant of Minnesota: the Gopher State.  3. (Amer. colloq.) One\n",
			"   who runs errands, does odd-jobs, fetches or delivers documents for\n",
			"   office staff.  4. (computer tech.) software following a simple\n",
			"   protocol for burrowing through a TCP/IP internet.\n",
			"\n",
			"   The Internet Gopher protocol and software follow a client-server\n",
			"   model.  This protocol assumes a reliable data stream; TCP is assumed.\n",
			"   Gopher servers should listen on port 70 (port 70 is assigned to\n",
			"   Internet Gopher by IANA).  Documents reside on many autonomous\n",
			"   servers on the Internet.  Users run client software on their desktop\n",
			"   systems, connecting to a server and sending the server a selector (a\n",
			"   line of text, which may be empty) via a TCP connection at a well-\n",
			"   known port.  The server responds with a block of text terminated by a\n",
			"   period on a line by itself and closes the connection.  No state is\n",
			"   retained by the server.\n",
			"\n",
			"\n",
			"\n",
			"Anklesari, McCahill, Lindner, Johnson, Torrey & Alberti         [Page 1]\n",
			"\n",
			"RFC 1436                         Gopher                       March 1993\n",
			"\n",
			"\n",
			"   While documents (and services) reside on many servers, Gopher client\n",
			"   software presents users with a hierarchy of items and directories\n",
			"   much like a file system.  The Gopher interface is designed to\n",
			"   resemble a file system since a file system is a good model for\n",
			"   organizing documents and services; the user sees what amounts to one\n",
			"   big networked information system containing primarily document items,\n",
			"   directory items, and search items (the latter allowing searches for\n",
			"   documents across subsets of the information base).\n",
			"\n",
			"   Servers return either directory lists or documents.  Each item in a\n",
			"   directory is identified by a type (the kind of object the item is),\n",
			"   user-visible name (used to browse and select from listings), an\n",
			"   opaque selector string (typically containing a pathname used by the\n",
			"   destination host to locate the desired object), a host name (which\n",
			"   host to contact to obtain this item), and an IP port number (the port\n",
			"   at which the server process listens for connections). The user only\n",
			"   sees the user-visible name.  The client software can locate and\n",
			"   retrieve any item by the trio of selector, hostname, and port.\n",
			"\n",
			"   To use a search item, the client submits a query to a special kind of\n",
			"   Gopher server: a search server.  In this case, the client sends the\n",
			"   selector string (if any) and the list of words to be matched. The\n",
			"   response yields \"virtual directory listings\" that contain items\n",
			"   matching the search criteria.\n",
			"\n",
			"   Gopher servers and clients exist for all popular platforms.  Because\n",
			"   the protocol is so sparse and simple, writing servers or clients is\n",
			"   quick and straightforward.\n",
			"\n",
			"1.  Introduction\n",
			"\n",
			"   The Internet Gopher protocol is designed primarily to act as a\n",
			"   distributed document delivery system.  While documents (and services)\n",
			"   reside on many servers, Gopher client software presents users with a\n",
			"   hierarchy of items and directories much like a file system.  In fact,\n",
			"   the Gopher interface is designed to resemble a file system since a\n",
			"   file system is a good model for locating documents and services.  Why\n",
			"   model a campus-wide information system after a file system?  Several\n",
			"   reasons:\n",
			"\n",
			"      (a) A hierarchical arrangement of information is familiar to many\n",
			"      users.  Hierarchical directories containing items (such as\n",
			"      documents, servers, and subdirectories) are widely used in\n",
			"      electronic bulletin boards and other campus-wide information\n",
			"      systems. People who access a campus-wide information server will\n",
			"      expect some sort of hierarchical organization to the information\n",
			"      presented.\n",
			"\n",
			"\n",
			"\n",
			"\n",
			"Anklesari, McCahill, Lindner, Johnson, Torrey & Alberti         [Page 2]\n",
			"\n",
			"RFC 1436                         Gopher                       March 1993\n",
			"\n",
			"\n",
			"      (b) A file-system style hierarchy can be expressed in a simple\n",
			"      syntax.  The syntax used for the internet Gopher protocol is\n",
			"      easily understandable, and was designed to make debugging servers\n",
			"      and clients easy.  You can use Telnet to simulate an internet\n",
			"      Gopher client\'s requests and observe the responses from a server.\n",
			"      Special purpose software tools are not required.  By keeping the\n",
			"      syntax of the pseudo-file system client/server protocol simple, we\n",
			"      can also achieve better performance for a very common user\n",
			"      activity: browsing through the directory hierarchy.\n",
			"\n",
			"      (c) Since Gopher originated in a University setting, one of the\n",
			"      goals was for departments to have the option of publishing\n",
			"      information from their inexpensive desktop machines, and since\n",
			"      much of the information can be presented as simple text files\n",
			"      arranged in directories, a protocol modeled after a file system\n",
			"      has immediate utility.  Because there can be a direct mapping from\n",
			"      the file system on the user\'s desktop machine to the directory\n",
			"      structure published via the Gopher protocol, the problem of\n",
			"      writing server software for slow desktop systems is minimized.\n",
			"\n",
			"      (d) A file system metaphor is extensible.  By giving a \"type\"\n",
			"      attribute to items in the pseudo-file system, it is possible to\n",
			"      accommodate documents other than simple text documents.  Complex\n",
			"      database services can be handled as a separate type of item.  A\n",
			"      file-system metaphor does not rule out search or database-style\n",
			"      queries for access to documents.  A search-server type is also\n",
			"      defined in this pseudo-file system.  Such servers return \"virtual\n",
			"      directories\" or list of documents matching user specified\n",
			"      criteria.\n",
			".\n"
		),
		gp_no_term => join('',
			"Gopher+ upward compatible enhancements to\n",
			"the Internet Gopher protocol\n",
			"\n",
			"\n",
			"\n",
			"Farhad Anklesaria, Paul Lindner, Mark P.  McCahill,\n",
			"Daniel Torrey, David Johnson, Bob Alberti\n",
			"\n",
			"Microcomputer and Workstation  Networks Center /\n",
			"Computer and Information Systems\n",
			"University of Minnesota\n",
			"\n",
			"July 30, 1993\n",
			"\n",
			"\n",
			"\n",
			"gopher+  n.  1. Hardier strains of mammals of the\n",
			"family  Geomyidae.  2. (Amer. colloq.) Native or\n",
			"inhabitant of  Minnesota, the Gopher state, in full\n",
			"winter regalia (see  PARKA).  3. (Amer. colloq.)\n",
			"Executive secretary.  4.  (computer tech.) Software\n",
			"following a simple protocol for  burrowing through a\n",
			"TCP/IP internet, made more powerful by  simple\n",
			"enhancements (see CREEPING FEATURISM).\n",
			"\n",
			"\n",
			"Abstract\n",
			"\n",
			"The internet Gopher protocol was designed for\n",
			"distributed  document search and retrieval. The\n",
			"documents \"The internet  Gopher protocol: a\n",
			"distributed document search and retrieval protocol\"\n",
			"and internet RFC 1436 describe the basic  protocol and\n",
			"has an overview of how to implement new client  and\n",
			"server applications. This document describes a set of\n",
			"enhancements to the syntax, semantics and\n",
			"functionality of  the original Gopher protocol.\n",
			"\n",
			"\n",
			"Distribution of this document is unlimited.  Please\n",
			"send  comments to the Gopher development team:\n",
			"<gopher\@boombox.micro.umn.edu>.  Implementation of\n",
			"the  mechanisms described here is encouraged.\n",
			"\n",
			"\n",
			"\n",
			"1.      Introduction\n",
			"\n",
			"The Internet Gopher protocol was designed primarily to\n",
			"act as a distributed document  delivery system.  It\n",
			"has enjoyed increasing popularity, and  is being used\n",
			"for purposes that were not visualized when the\n",
			"protocol was first outlined.  The rest of this\n",
			"document  describes the Gopher+ enhancements in a non-\n",
			"rigorous but easily read and understood  way.  There\n",
			"is a short BNF-like section at the end for exact\n",
			"syntax descriptions.  Throughout the document, \"F\"\n",
			"stands  for the ASCII TAB character. There is an\n",
			"implicit carriage  return and linefeed at the ends of\n",
			"lines; these will only be explicitly  mentioned where\n",
			"necessary to avoid confusion. To understand  this\n",
			"document, you really must be familiar with the basic\n",
			"Gopher protocol.\n",
			"\n",
			"\n",
			"Servers and clients understanding the Gopher+\n",
			"extensions will transmit extra information at the ends\n",
			"of list and request lines.  Old, basic gopher clients\n",
			"ignore such information.  New  Gopher+ aware servers\n",
			"continue to work at their old level  with unenhanced\n",
			"clients.  The extra information that can be\n",
			"communicated by Gopher+ clients may be used to summon\n",
			"new capabilities to bridge  the most keenly felt\n",
			"shortcomings of the venerable old  Gopher.\n",
			"\n",
			"\n",
			"\n",
			"\n",
			"2.      How does Gopher+ work?\n",
			"\n",
			"Gopher+ enhancements rely on transmitting an \"extra\"\n",
			"tab  delimited fields beyond what regular (old) Gopher\n",
			"servers and clients now use.  If most existing (old)\n",
			"clients were to encounter extra stuff beyond the\n",
			"\"port\"  field in a list (directory), most would ignore\n",
			"it. Gopher+  servers will return item descriptions in\n",
			"this form:\n",
			"\n",
			"\n",
			"1Display stringFselector stringFhostFportFextra\n",
			"stuff<CRLF>\n",
			"\n",
			"\n",
			"If an existing (old) client has problems with\n",
			"additional  information beyond the port, it should not\n",
			"take much more  than a simple tweak to have it discard\n",
			"unneeded stuff.\n",
			"\n",
			"\n",
			"\n",
			"\n",
			"2.1     Advisory issued to client maintainers.\n",
			"\n",
			"If it does not do this already, your existing client\n",
			"should be modified  as soon as possible to ignore\n",
			"extra fields beyond what it  expects to find.  This\n",
			"will ensure thatyour clients does not break  when it\n",
			"encounters Gopher+ servers in gopherspace.\n",
			"\n",
			"\n",
			"All the regular Gopher protocol info remains intact\n",
			"except for:\n",
			"\n",
			"\n",
			"(1)  Instead of just a CRLF after the port field in\n",
			"any item  of a list (directory) there may be an\n",
			"optional TAB followed  by extra stuff as noted above\n",
			"(explanation to follow).\n",
			"\n",
			"\n",
			"\n",
			"(2) In the original Gopher protocol, there was\n",
			"provision for a date-time descriptor (sec 3.6) to be\n",
			"sent  after the selector (for use by autoindexer\n",
			"beasts).  As far  as we know, while the descriptor is\n",
			"implemented in the Mac  server, it is not in any other\n",
			"server and no clients or  daemons use it.  This is a\n",
			"good time to withdraw this feature. The basic gopher\n",
			"protocol has been revised for the final time and will\n",
			"be  frozen.\n",
			"\n",
			"\n",
			"\n",
			"\n",
			"\n",
			"\n",
			"2.2     Gopher+ item lists.\n",
			"\n",
			"Gopher servers that can utilize the Gopher+\n",
			"enhancements  will send some additional stuff\n",
			"(frequently the character \"+\") after the port field\n",
			"describing any list item.  eg:\n",
			"\n",
			"\n",
			"1Some old directoryFfoo selectorFhost1Fport1\n",
			"\n",
			"1Some new directoryFbar selectorFhost1Fport1F+\n",
			"\n",
			"0Some file or otherFmoo selectorFhost2Fport2F+\n",
			"\n",
			"\n",
			"The first line is the regular old gopher item\n",
			"description. The second line is new Gopher+  item\n",
			"description.  The third line is a Gopher+ description\n",
			"of a document. Old  gopher clients can request the\n",
			"latter two items using old  format gopher selector\n",
			"strings and retrieve the items. New,  Gopher+ savvy\n",
			"clients will notice the trailing + and know that they\n",
			"can do extra  things with these kinds of items.\n"
		),
		item_blocks => join('',
			"+INFO 1Gopher+ Index	/gp_index	localhost	70	+\n",
			"+ADMIN:\n",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n",
			" Mod-Date: <20030728173012>\n",
			" Creation-Date: <20030728170201>\n",
			" Expiration-Date: <20030909090001>\n",
			"+VIEWS:\n",
			" text/plain: <.40k>\n",
			" application/gopher+-menu En_US: <1200b>\n",
			" text/html: <.77KB>\n",
			"+ABSTRACT\n",
			" This is a short synopsis of the item.\n",
			" It spans\n",
			" multiple lines.\n",
			"+ASK\n",
			" Ask: What is your name?\n",
			" Ask: Where are you from?	Montana\n",
			" Choose: What is your favorite color?	red	green	blue\n",
			" Select: Contact using:	Email	Instant messages	IRC\n",
			".\n"
		),
		directory_blocks => join('',
			"+INFO: 1Gopher+ Index	/gp_index	localhost	70	+\n",
			"+ADMIN\n",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n",
			" Mod-Date: <20030728173012>\n",
			"+INFO: 0Byte terminated file	/gp_byte_term	localhost	70	+\n",
			"+ADMIN\n",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n",
			" Mod-Date: <20031201123000>\n",
			"+INFO: 0Period terminated file	/gp_period_term	localhost	70	+\n",
			"+ADMIN\n",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n",
			" Mod-Date: <20040101070206>\n",
			"+INFO: 0Non-terminated file	/gp_no_term	localhost	70	+\n",
			"+ADMIN\n",
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n",
			" Mod-Date: <20040201182005>"
		),
	);
}
