use strict;
use warnings;
use Test;

BEGIN { plan(tests => 432) }

use Net::Gopher;
use Net::Gopher::Request qw(:all);
use Net::Gopher::Utility qw($CRLF size_in_bytes);
use Net::Gopher::Constants qw(:request :item_types);










################################################################################
#
# These tests check the integrity of Gopher-type request objects using the
# new() and Gopher() constructor methods and the accessor methods:
#

{
	my $request = new Net::Gopher::Request ('Gopher');

	ok($request->as_string, "$CRLF");           # 1
	ok($request->as_url, 'gopher://:70/1');     # 2
	ok($request->request_type, GOPHER_REQUEST); # 3
	ok(!defined $request->host);                # 4
	ok($request->port, 70);                     # 5
	ok(!defined $request->selector);            # 6
	ok(!defined $request->search_words);        # 7
	ok(!defined $request->representation);      # 8
	ok(!defined $request->data_block);          # 9
	ok(!defined $request->attributes);          # 10
	ok($request->item_type, GOPHER_MENU_TYPE);  # 11
}



{
	my $request = Gopher(Host => 'gopher.hole.foo');

	ok($request->as_string, "$CRLF");                      # 12
	ok($request->as_url, 'gopher://gopher.hole.foo:70/1'); # 13
	ok($request->request_type, GOPHER_REQUEST);            # 14
	ok($request->host, 'gopher.hole.foo');                 # 15
	ok($request->port, 70);                                # 16
	ok(!defined $request->selector);                       # 17
	ok(!defined $request->search_words);                   # 18
	ok(!defined $request->representation);                 # 19
	ok(!defined $request->data_block);                     # 20
	ok(!defined $request->attributes);                     # 21
	ok($request->item_type, GOPHER_MENU_TYPE);             # 22
}



{
	my $request = new Net::Gopher::Request ('GOPHER',
		Host     => 'gopher.hole.foo',
		SELECTOR => '/some_thing'
	);

	ok($request->as_string, "/some_thing$CRLF");                      # 23
	ok($request->as_url, 'gopher://gopher.hole.foo:70/1/some_thing'); # 24
	ok($request->request_type, GOPHER_REQUEST);                       # 25
	ok($request->host, 'gopher.hole.foo');                            # 26
	ok($request->port, 70);                                           # 27
	ok($request->selector, '/some_thing');                            # 28
	ok(!defined $request->search_words);                              # 29
	ok(!defined $request->representation);                            # 30
	ok(!defined $request->data_block);                                # 31
	ok(!defined $request->attributes);                                # 32
	ok($request->item_type, GOPHER_MENU_TYPE);                        # 33
}



{
	my $request = new Net::Gopher::Request (
		gopher => {
			Host          => 'gopher.hole.foo',
			PORT          => 7777,
			selector      => '/apps/a_search_engine',
			-SeARch_WoRDs => ['red', 'blue', 'green'],
			Item_Type     => INDEX_SEARCH_SERVER_TYPE
		}
	);

	ok($request->as_string, "/apps/a_search_engine	red blue green$CRLF");                # 34
	ok($request->as_url,
		'gopher://gopher.hole.foo:7777/7/apps/a_search_engine%09red%20blue%20green'); # 35
	ok($request->request_type, GOPHER_REQUEST);                                           # 36
	ok($request->host, 'gopher.hole.foo');                                                # 37
	ok($request->port, 7777);                                                             # 38
	ok($request->selector, '/apps/a_search_engine');                                      # 39
	ok($request->search_words, 'red blue green');                                         # 40
	ok(!defined $request->representation);                                                # 41
	ok(!defined $request->data_block);                                                    # 42
	ok(!defined $request->attributes);                                                    # 43
	ok($request->item_type, INDEX_SEARCH_SERVER_TYPE);                                    # 44
}



{
	my $request = new Net::Gopher::Request ('gOPhEr');

	$request->host('newhostname.foo');
	ok($request->host, 'newhostname.foo');           # 45

	$request->port(2600);
	ok($request->port, 2600);                        # 46

	$request->selector('/something');
	ok($request->selector, '/something');            # 47

	$request->search_words('some search words');
	ok($request->search_words, 'some search words'); # 48

	$request->search_words('some', 'more', 'words');
	ok($request->search_words, 'some more words');   # 49

	$request->search_words(['some', 'other', 'words']);
	ok($request->search_words, 'some other words');  # 50

	$request->search_words(['some final words']);
	ok($request->search_words, 'some final words');  # 51

#	$request->representation('shouldnt/work');
#	ok(!defined $request->representation);

#	$request->data_block('Shouldnt: work');
#	ok(!defined $request->data_block);

#	$request->attributes('+SHOULDNT+WORK');
#	ok(!defined $request->attributes);

	$request->item_type('g');
	ok($request->item_type, GIF_IMAGE_TYPE);         # 52
}










################################################################################
#
# These tests check the integrity of Gopher+-type request objects using the
# new() and GopherPlus() constructor methods and the accessor methods:
#

{
	my $request = new Net::Gopher::Request ('GopherPlus');

	ok($request->as_string, "	+$CRLF");        # 53
	ok($request->as_url, 'gopher://:70/1%09%09+');   # 54
	ok($request->request_type, GOPHER_PLUS_REQUEST); # 55
	ok(!defined $request->host);                     # 56
	ok($request->port, 70);                          # 57
	ok(!defined $request->selector);                 # 58
	ok(!defined $request->search_words);             # 59
	ok(!defined $request->representation);           # 60
	ok(!defined $request->data_block);               # 61
	ok(!defined $request->attributes);               # 62
	ok($request->item_type, GOPHER_MENU_TYPE);       # 63
}

{
	my $request = GopherPlus(Host => 'gopher.hole.bar');

	ok($request->as_string, "	+$CRLF");                     # 64
	ok($request->as_url, 'gopher://gopher.hole.bar:70/1%09%09+'); # 65
	ok($request->request_type, GOPHER_PLUS_REQUEST);              # 66
	ok($request->host, 'gopher.hole.bar');                        # 67
	ok($request->port, 70);                                       # 68
	ok(!defined $request->selector);                              # 69
	ok(!defined $request->search_words);                          # 70
	ok(!defined $request->representation);                        # 71
	ok(!defined $request->data_block);                            # 72
	ok(!defined $request->attributes);                            # 73
	ok($request->item_type, GOPHER_MENU_TYPE);                    # 74
}



{
	my $request = new Net::Gopher::Request ('GOPHERPLUS',
		Host            => 'gopher.hole.bar',
		PORT            => 7000,
		selector        => '/some_pic.jpg',
		-RePReSEntATIon => 'image/jpeg',
		Item_Type       => IMAGE_FILE_TYPE
	);

	ok($request->as_string, "/some_pic.jpg	+image/jpeg$CRLF");               # 75
	ok($request->as_url,
		'gopher://gopher.hole.bar:7000/I/some_pic.jpg%09%09+image/jpeg'); # 76
	ok($request->request_type, GOPHER_PLUS_REQUEST);                          # 77
	ok($request->host, 'gopher.hole.bar');                                    # 78
	ok($request->port, 7000);                                                 # 79
	ok($request->selector, '/some_pic.jpg');                                  # 80
	ok(!defined $request->search_words);                                      # 81
	ok($request->representation, 'image/jpeg');                               # 82
	ok(!defined $request->data_block);                                        # 83
	ok(!defined $request->attributes);                                        # 84
	ok($request->item_type, IMAGE_FILE_TYPE);                                 # 85
}



{
	my $request = new Net::Gopher::Request (
		gopherplus => {
			Host          => 'gopher.hole.bar',
			SELECTOR      => '/search',
			-search_words => 'apple orange pear',
			-ITEmTyPE     => INDEX_SEARCH_SERVER_TYPE
		}
	);

	ok($request->as_string, "/search	apple orange pear	+$CRLF");    # 86
	ok($request->as_url,
		'gopher://gopher.hole.bar:70/7/search%09apple%20orange%20pear%09+'); # 87
	ok($request->request_type, GOPHER_PLUS_REQUEST);                             # 88
	ok($request->host, 'gopher.hole.bar');                                       # 89
	ok($request->port, 70);                                                      # 90
	ok($request->selector, '/search');                                           # 91
	ok($request->search_words, 'apple orange pear');                             # 92
	ok(!defined $request->representation);                                       # 93
	ok(!defined $request->data_block);                                           # 94
	ok(!defined $request->attributes);                                           # 95
	ok($request->item_type, INDEX_SEARCH_SERVER_TYPE);                           # 96
}



{
	my $request = new Net::Gopher::Request ('GoPHeRPlus',
		Host              => 'gopher.hole.bar',
		SELECTOR          => '/search',
		-_search_words    => ['aaa'],
		-_ReprESEntATIon  => 'application/gopher+-menu',
		_Item_Type        => INDEX_SEARCH_SERVER_TYPE
	);

	ok($request->as_string, "/search	aaa	+application/gopher+-menu$CRLF");  # 97
	ok($request->as_url,
		'gopher://gopher.hole.bar:70/7/search%09aaa%09+application/gopher+-menu'); # 98
	ok($request->request_type, GOPHER_PLUS_REQUEST);                                   # 99
	ok($request->host, 'gopher.hole.bar');                                             # 100
	ok($request->port, 70);                                                            # 101
	ok($request->selector, '/search');                                                 # 102
	ok($request->search_words, 'aaa');                                                 # 103
	ok($request->representation, 'application/gopher+-menu');                          # 104
	ok(!defined $request->data_block);                                                 # 105
	ok(!defined $request->attributes);                                                 # 106
	ok($request->item_type, INDEX_SEARCH_SERVER_TYPE);                                 # 107
}



{
	my $request = new Net::Gopher::Request ('GoPHeRPlus',
		-Host           => 'gopher.hole.bar',
		-SELECTOR       => '/something.cgi',
		Data_Block      => "This is a single-line block",
		Item_Type       => GOPHER_MENU_TYPE
	);

	ok($request->as_string,
		"/something.cgi\t+\t1${CRLF}+27${CRLF}This is a single-line block"); # 108
	ok($request->as_url,
		'gopher://gopher.hole.bar:70/1/something.cgi%09%09+');               # 109
	ok($request->request_type, GOPHER_PLUS_REQUEST);                             # 110
	ok($request->host, 'gopher.hole.bar');                                       # 111
	ok($request->port, 70);                                                      # 112
	ok($request->selector, '/something.cgi');                                    # 113
	ok(!defined $request->search_words);                                         # 114
	ok(!defined $request->representation);                                       # 115
	ok($request->data_block, 'This is a single-line block');                     # 116
	ok(!defined $request->attributes);                                           # 117
	ok($request->item_type, GOPHER_MENU_TYPE);                                   # 118
}



{
	my $request = new Net::Gopher::Request ('GoPHeRPlus',
		Host      => 'gopher.hole.bar',
		SELECTOR  => '/something.cgi',
		DataBlock => 'This is a big single-line block ' x 2000,
		ItemType  => GOPHER_MENU_TYPE
	);

	ok($request->as_string,
		sprintf("/something.cgi\t+\t1${CRLF}+%s${CRLF}%s",
			size_in_bytes('This is a big single-line block ' x 2000),
			'This is a big single-line block ' x 2000
		)
	);                                                                   # 119
	ok($request->as_url,
		'gopher://gopher.hole.bar:70/1/something.cgi%09%09+');       # 120
	ok($request->request_type, GOPHER_PLUS_REQUEST);                     # 121
	ok($request->host, 'gopher.hole.bar');                               # 122
	ok($request->port, 70);                                              # 123
	ok($request->selector, '/something.cgi');                            # 124
	ok(!defined $request->search_words);                                 # 125
	ok(!defined $request->representation);                               # 126
	ok($request->data_block, 'This is a big single-line block ' x 2000); # 127
	ok(!defined $request->attributes);                                   # 128
	ok($request->item_type, GOPHER_MENU_TYPE);                           # 129
}



{
	my $request = new Net::Gopher::Request ('GoPHeRPlus',
		Host      => 'gopher.hole.bar',
		SELECTOR  => '/something.cgi',
		DataBlock => "This\015\012is\012a\015\012multi-line\012block",
		ItemType  => GOPHER_MENU_TYPE
	);

	ok($request->as_string,
		"/something.cgi\t+\t1${CRLF}+28${CRLF}" .
		"This\015\012is\012a\015\012multi-line\012block"
	);                                                                          # 130
	ok($request->as_url,
		'gopher://gopher.hole.bar:70/1/something.cgi%09%09+');              # 131
	ok($request->request_type, GOPHER_PLUS_REQUEST);                            # 132
	ok($request->host, 'gopher.hole.bar');                                      # 133
	ok($request->port, 70);                                                     # 134
	ok($request->selector, '/something.cgi');                                   # 135
	ok(!defined $request->search_words);                                        # 136
	ok(!defined $request->representation);                                      # 137
	ok($request->data_block, "This\015\012is\012a\015\012multi-line\012block"); # 138
	ok(!defined $request->attributes);                                          # 139
	ok($request->item_type, GOPHER_MENU_TYPE);                                  # 140
}



{
	my $request = new Net::Gopher::Request ('GoPHeRPlus', [
		Host       => 'gopher.hole.bar',
		SELECTOR   => '/something.cgi',
		Data_Block => "This\015\012is\012a\015\012multi-line\012block " x 2000,
		Item_Type  => GOPHER_MENU_TYPE
		]
	);

	ok($request->as_string,
		sprintf("/something.cgi\t+\t1${CRLF}+%s${CRLF}%s",
			29 * 2000,
			"This\015\012is\012a\015\012multi-line\012block " x 2000
		)
	);                                                                  # 141
	ok($request->as_url,
		'gopher://gopher.hole.bar:70/1/something.cgi%09%09+');     # 142
	ok($request->request_type, GOPHER_PLUS_REQUEST);                   # 143
	ok($request->host, 'gopher.hole.bar');                             # 144
	ok($request->port, 70);                                            # 145
	ok($request->selector, '/something.cgi');                          # 146
	ok(!defined $request->search_words);                               # 147
	ok(!defined $request->representation);                             # 148
	ok($request->data_block,
		"This\015\012is\012a\015\012multi-line\012block " x 2000); # 149
	ok(!defined $request->attributes);                                 # 150
	ok($request->item_type, GOPHER_MENU_TYPE);                         # 151
}



{
	my $request = new Net::Gopher::Request ('GopherPLUS');

	$request->host('newhostname.bar');
	ok($request->host, 'newhostname.bar');           # 152

	$request->port(2600);
	ok($request->port, 2600);                        # 153

	$request->selector('/something');
	ok($request->selector, '/something');            # 154

	$request->search_words('some search words');
	ok($request->search_words, 'some search words'); # 155

	$request->search_words('some', 'more', 'words');
	ok($request->search_words, 'some more words');   # 156

	$request->search_words(['some', 'other', 'words']);
	ok($request->search_words, 'some other words');  # 157

	$request->search_words(['some final words']);
	ok($request->search_words, 'some final words');  # 158

	$request->representation('text/plain');
	ok($request->representation, 'text/plain');      # 159

	$request->data_block('Question: answer');
	ok($request->data_block, 'Question: answer');    # 160

#	$request->attributes('+SHOULDNT+WORK');
#	ok(!defined $request->attributes);

	$request->item_type('2');
	ok($request->item_type, CCSO_NAMESERVER_TYPE);   # 161
}










################################################################################
#
# These tests check the integrity of item attribute information-type request
# objects using the new() and ItemAttribute() constructor methods and the
# accessor methods:
#

{
	my $request = new Net::Gopher::Request ('ItemAttribute');

	ok($request->as_string, "	!$CRLF");           # 162
	ok($request->as_url, 'gopher://:70/1%09%09!');      # 163
	ok($request->request_type, ITEM_ATTRIBUTE_REQUEST); # 164
	ok(!defined $request->host);                        # 165
	ok($request->port, 70);                             # 166
	ok(!defined $request->selector);                    # 167
	ok(!defined $request->search_words);                # 168
	ok(!defined $request->representation);              # 169
	ok(!defined $request->data_block);                  # 170
	ok(!defined $request->attributes);                  # 171
	ok(!defined $request->item_type);                   # 172
}

{
	my $request = ItemAttribute(Host => 'gopher.hole.blah');

	ok($request->as_string, "	!$CRLF");                      # 173
	ok($request->as_url, 'gopher://gopher.hole.blah:70/1%09%09!'); # 174
	ok($request->request_type, ITEM_ATTRIBUTE_REQUEST);            # 175
	ok($request->host, 'gopher.hole.blah');                        # 176
	ok($request->port, 70);                                        # 177
	ok(!defined $request->selector);                               # 178
	ok(!defined $request->search_words);                           # 179
	ok(!defined $request->representation);                         # 180
	ok(!defined $request->data_block);                             # 181
	ok(!defined $request->attributes);                             # 182
	ok(!defined $request->item_type);                              # 183
}



{
	my $request = new Net::Gopher::Request ('ITEMATTRIBUTE',
		Host     => 'gopher.hole.blah',
		SELECTOR => '/a_doc.txt',
	);

	ok($request->as_string, "/a_doc.txt	!$CRLF");           # 184
	ok($request->as_url,
		'gopher://gopher.hole.blah:70/1/a_doc.txt%09%09!'); # 185
	ok($request->request_type, ITEM_ATTRIBUTE_REQUEST);         # 186
	ok($request->host, 'gopher.hole.blah');                     # 187
	ok($request->port, 70);                                     # 188
	ok($request->selector, '/a_doc.txt');                       # 189
	ok(!defined $request->search_words);                        # 190
	ok(!defined $request->representation);                      # 191
	ok(!defined $request->data_block);                          # 192
	ok(!defined $request->attributes);                          # 193
	ok(!defined $request->item_type);                           # 194
}



{
	my $request = new Net::Gopher::Request (
		itemattribute => {
			Host       => 'gopher.hole.blah',
			PORT       => 1234,
			selector   => '/MIME_file.mime',
			AtTRibUtES => ['ADMIN', '+ABSTRACT']
		}
	);

	ok($request->as_string, "/MIME_file.mime	!+ADMIN+ABSTRACT$CRLF");          # 195
	ok($request->as_url,
		'gopher://gopher.hole.blah:1234/1/MIME_file.mime%09%09!+ADMIN+ABSTRACT'); # 196
	ok($request->request_type, ITEM_ATTRIBUTE_REQUEST);                               # 197
	ok($request->host, 'gopher.hole.blah');                                           # 198
	ok($request->port, 1234);                                                         # 199
	ok($request->selector, '/MIME_file.mime');                                        # 200
	ok(!defined $request->search_words);                                              # 201
	ok(!defined $request->representation);                                            # 202
	ok(!defined $request->data_block);                                                # 203
	ok($request->attributes, '+ADMIN+ABSTRACT');                                      # 204
	ok(!defined $request->item_type);                                                 # 205
}





{
	my $request = new Net::Gopher::Request ('iTeMAtTriBUTe');

	$request->host('newhostname.blah');
	ok($request->host, 'newhostname.blah');     # 206

	$request->port(2600);
	ok($request->port, 2600);                   # 207

	$request->selector('/something_else');
	ok($request->selector, '/something_else');  # 208

#	$request->search_words('should not work');
#	ok(!defined $request->search_words);

#	$request->representation('shouldnt/work');
#	ok(!defined $request->representation);

#	$request->data_block('Shouldnt: work');
#	ok(!defined $request->data_block);

	$request->attributes('+INFO');
	ok($request->attributes, '+INFO');          # 209

	$request->attributes('+INFO+ABSTRACT');
	ok($request->attributes, '+INFO+ABSTRACT'); # 210

	$request->attributes('+INFO', '+ADMIN');
	ok($request->attributes, '+INFO+ADMIN');    # 211

	$request->attributes('INFO', 'VIEWS');
	ok($request->attributes, '+INFO+VIEWS');    # 212

	$request->attributes(['+INFO', '+ADMIN']);
	ok($request->attributes, '+INFO+ADMIN');    # 213

	$request->attributes(['+INFO+ADMIN']);
	ok($request->attributes, '+INFO+ADMIN');    # 214

	$request->item_type('1');
	ok($request->item_type, GOPHER_MENU_TYPE);  # 215
}










################################################################################
#
# These tests check the integrity of directory attribute information-type
# request objects using the new() and DirectoryAttribute() constructor methods
# and the accessor methods:
#

{
	my $request = DirectoryAttribute(Host => 'gopher.hole.baz');

	ok($request->as_string, "	\$$CRLF");                    # 216
	ok($request->as_url, 'gopher://gopher.hole.baz:70/1%09%09$'); # 217
	ok($request->request_type, DIRECTORY_ATTRIBUTE_REQUEST);      # 218
	ok($request->host, 'gopher.hole.baz');                        # 219
	ok($request->port, 70);                                       # 220
	ok(!defined $request->selector);                              # 221
	ok(!defined $request->search_words);                          # 222
	ok(!defined $request->representation);                        # 223
	ok(!defined $request->data_block);                            # 224
	ok(!defined $request->attributes);                            # 225
	ok(!defined $request->item_type);                             # 226
}



{
	my $request = new Net::Gopher::Request ('DIRECTORYATTRIBUTE',
		Host       => 'gopher.hole.baz',
		SELECTOR   => '/directory',
		attributes => '+INFO+VIEWS'
	);

	ok($request->as_string, "/directory	\$+INFO+VIEWS$CRLF");         # 227
	ok($request->as_url,
		'gopher://gopher.hole.baz:70/1/directory%09%09$+INFO+VIEWS'); # 228
	ok($request->request_type, DIRECTORY_ATTRIBUTE_REQUEST);              # 229
	ok($request->host, 'gopher.hole.baz');                                # 230
	ok($request->port, 70);                                               # 231
	ok($request->selector, '/directory');                                 # 232
	ok(!defined $request->search_words);                                  # 233
	ok(!defined $request->representation);                                # 234
	ok(!defined $request->data_block);                                    # 235
	ok($request->attributes, '+INFO+VIEWS');                              # 236
	ok(!defined $request->item_type);                                     # 237
}



{
	my $request = new Net::Gopher::Request (
		directoryattribute => {
			Host       => 'gopher.hole.baz',
			Port       => 2600,
			Selector   => '/more/directory',
			Attributes => ['INFO', '+ADMIN']
		}
	);

	ok($request->as_string, "/more/directory	\$+INFO+ADMIN$CRLF");        # 238
	ok($request->as_url,
		'gopher://gopher.hole.baz:2600/1/more/directory%09%09$+INFO+ADMIN'); # 239
	ok($request->request_type, DIRECTORY_ATTRIBUTE_REQUEST);                     # 240
	ok($request->host, 'gopher.hole.baz');                                       # 241
	ok($request->port, 2600);                                                    # 242
	ok($request->selector, '/more/directory');                                   # 243
	ok(!defined $request->search_words);                                         # 244
	ok(!defined $request->representation);                                       # 245
	ok(!defined $request->data_block);                                           # 246
	ok($request->attributes, '+INFO+ADMIN');                                     # 247
	ok(!defined $request->item_type);                                            # 248
}










{
	my $request = new Net::Gopher::Request ('dIreCTorYatTRibUTE');

	$request->host('newhostname.blah');
	ok($request->host, 'newhostname.blah');     # 249

	$request->port(2600);
	ok($request->port, 2600);                   # 250

	$request->selector('/something_else');
	ok($request->selector, '/something_else');  # 251

#	$request->search_words('should not work');
#	ok(!defined $request->search_words);

#	$request->representation('text/plain');
#	ok(!defined $request->representation);

#	$request->data_block('shouldnt/work');
#	ok(!defined $request->data_block);

	$request->attributes('+INFO');
	ok($request->attributes, '+INFO');          # 252

	$request->attributes('+INFO+ABSTRACT');
	ok($request->attributes, '+INFO+ABSTRACT'); # 253

	$request->attributes('+INFO', '+ADMIN');
	ok($request->attributes, '+INFO+ADMIN');    # 254

	$request->attributes(['INFO', 'VIEWS']);
	ok($request->attributes, '+INFO+VIEWS');    # 255

	$request->attributes(['+INFO+ADMIN']);
	ok($request->attributes, '+INFO+ADMIN');    # 256

	$request->attributes(['+INFO']);
	ok($request->attributes, '+INFO');          # 257

	$request->item_type('1');
	ok($request->item_type, GOPHER_MENU_TYPE);  # 258
}










################################################################################
#
# These tests check the same things as the ones above, only they do so using
# URLs:
#

{
	my $request = new Net::Gopher::Request ('URL');

	ok($request->as_string, "$CRLF");           # 259
	ok($request->as_url, 'gopher://:70/1');     # 260
	ok($request->request_type, GOPHER_REQUEST); # 261
	ok(!defined $request->host);                # 262
	ok($request->port, 70);                     # 263
	ok(!defined $request->selector);            # 264
	ok(!defined $request->search_words);        # 265
	ok(!defined $request->representation);      # 266
	ok(!defined $request->data_block);          # 267
	ok(!defined $request->attributes);          # 268
	ok($request->item_type, GOPHER_MENU_TYPE);  # 269
}



{
	my $request = new Net::Gopher::Request ('URL', 'localhost');

	ok($request->as_string, "$CRLF");                # 270
	ok($request->as_url, 'gopher://localhost:70/1'); # 271
	ok($request->request_type, GOPHER_REQUEST);      # 272
	ok($request->host, 'localhost');                 # 273
	ok($request->port, 70);                          # 274
	ok(!defined $request->selector);                 # 275
	ok(!defined $request->search_words);             # 276
	ok(!defined $request->representation);           # 277
	ok(!defined $request->data_block);               # 278
	ok(!defined $request->attributes);               # 279
	ok($request->item_type, GOPHER_MENU_TYPE);       # 280
}



{
	my $request = URL('gopher://gopher.hole.url:70/1');

	ok($request->as_string, "$CRLF");                      # 281
	ok($request->as_url, 'gopher://gopher.hole.url:70/1'); # 282
	ok($request->request_type, GOPHER_REQUEST);            # 283
	ok($request->host, 'gopher.hole.url');                 # 284
	ok($request->port, 70);                                # 285
	ok(!defined $request->selector);                       # 286
	ok(!defined $request->search_words);                   # 287
	ok(!defined $request->representation);                 # 288
	ok(!defined $request->data_block);                     # 289
	ok(!defined $request->attributes);                     # 290
	ok($request->item_type, GOPHER_MENU_TYPE);             # 291
}



{
	my $request = new Net::Gopher::Request (
		url => 'gopher://gopher.hole.url:70/1/some_thing'
	);

	ok($request->as_string, "/some_thing$CRLF");                      # 292
	ok($request->as_url, 'gopher://gopher.hole.url:70/1/some_thing'); # 293
	ok($request->request_type, GOPHER_REQUEST);                       # 294
	ok($request->host, 'gopher.hole.url');                            # 295
	ok($request->port, 70);                                           # 296
	ok($request->selector, '/some_thing');                            # 297
	ok(!defined $request->search_words);                              # 298
	ok(!defined $request->representation);                            # 299
	ok(!defined $request->data_block);                                # 300
	ok(!defined $request->attributes);                                # 301
	ok($request->item_type, GOPHER_MENU_TYPE);                        # 302
}



{
	my $request = URL(
		'gopher://gopher.hole.url:7777/7/apps/a_search_engine%09red%20blue%20green'
	);

	ok($request->as_string, "/apps/a_search_engine	red blue green$CRLF");                # 303
	ok($request->as_url,
		'gopher://gopher.hole.url:7777/7/apps/a_search_engine%09red%20blue%20green'); # 304
	ok($request->request_type, GOPHER_REQUEST);                                           # 305
	ok($request->host, 'gopher.hole.url');                                                # 306
	ok($request->port, 7777);                                                             # 307
	ok($request->selector, '/apps/a_search_engine');                                      # 308
	ok($request->search_words, 'red blue green');                                         # 309
	ok(!defined $request->representation);                                                # 310
	ok(!defined $request->data_block);                                                    # 311
	ok(!defined $request->attributes);                                                    # 312
	ok($request->item_type, INDEX_SEARCH_SERVER_TYPE);                                    # 313
}





{
	my $request = new Net::Gopher::Request (
		UrL => 'gopher://gopher.hole.url:70/1%09%09+'
	);

	ok($request->as_string, "	+$CRLF");                     # 314
	ok($request->as_url, 'gopher://gopher.hole.url:70/1%09%09+'); # 315
	ok($request->request_type, GOPHER_PLUS_REQUEST);              # 316
	ok($request->host, 'gopher.hole.url');                        # 317
	ok($request->port, 70);                                       # 318
	ok(!defined $request->selector);                              # 319
	ok(!defined $request->search_words);                          # 320
	ok(!defined $request->representation);                        # 321
	ok(!defined $request->data_block);                            # 322
	ok(!defined $request->attributes);                            # 323
	ok($request->item_type, GOPHER_MENU_TYPE);                    # 324
}



{
	my $request = URL('gopher://gopher.hole.url:7000/I/some_pic.jpg		+image/jpeg');

	ok($request->as_string, "/some_pic.jpg	+image/jpeg$CRLF");               # 325
	ok($request->as_url,
		'gopher://gopher.hole.url:7000/I/some_pic.jpg%09%09+image/jpeg'); # 326
	ok($request->request_type, GOPHER_PLUS_REQUEST);                          # 327
	ok($request->host, 'gopher.hole.url');                                    # 328
	ok($request->port, 7000);                                                 # 329
	ok($request->selector, '/some_pic.jpg');                                  # 330
	ok(!defined $request->search_words);                                      # 331
	ok($request->representation, 'image/jpeg');                               # 332
	ok(!defined $request->data_block);                                        # 333
	ok(!defined $request->attributes);                                        # 334
	ok($request->item_type, IMAGE_FILE_TYPE);                                 # 335
}



{
	my $request = new Net::Gopher::Request (
		uRl => 'gopher://gopher.hole.url:70/7/search	pear banana	+'
	);

	ok($request->as_string, "/search	pear banana	+$CRLF");    # 336
	ok($request->as_url,
		'gopher://gopher.hole.url:70/7/search%09pear%20banana%09+'); # 337
	ok($request->request_type, GOPHER_PLUS_REQUEST);                     # 338
	ok($request->host, 'gopher.hole.url');                               # 339
	ok($request->port, 70);                                              # 340
	ok($request->selector, '/search');                                   # 341
	ok($request->search_words, 'pear banana');                           # 342
	ok(!defined $request->representation);                               # 343
	ok(!defined $request->data_block);                                   # 344
	ok(!defined $request->attributes);                                   # 345
	ok($request->item_type, INDEX_SEARCH_SERVER_TYPE);                   # 346
}



{
	my $request = URL('gopher://gopher.hole.url:70/7/search%09aaa%09+application/gopher+-menu');

	ok($request->as_string, "/search	aaa	+application/gopher+-menu$CRLF");  # 347
	ok($request->as_url,
		'gopher://gopher.hole.url:70/7/search%09aaa%09+application/gopher+-menu'); # 348
	ok($request->request_type, GOPHER_PLUS_REQUEST);                                   # 349
	ok($request->host, 'gopher.hole.url');                                             # 350
	ok($request->port, 70);                                                            # 351
	ok($request->selector, '/search');                                                 # 352
	ok($request->search_words, 'aaa');                                                 # 353
	ok($request->representation, 'application/gopher+-menu');                          # 354
	ok(!defined $request->data_block);                                                 # 355
	ok(!defined $request->attributes);                                                 # 356
	ok($request->item_type, INDEX_SEARCH_SERVER_TYPE);                                 # 357
}





{
	my $request = new Net::Gopher::Request (
		UrL => 'gopher://gopher.hole.url:70/1%09%09!'
	);

	ok($request->as_string, "	!$CRLF");                     # 358
	ok($request->as_url, 'gopher://gopher.hole.url:70/1%09%09!'); # 359
	ok($request->request_type, ITEM_ATTRIBUTE_REQUEST);           # 360
	ok($request->host, 'gopher.hole.url');                        # 361
	ok($request->port, 70);                                       # 362
	ok(!defined $request->selector);                              # 363
	ok(!defined $request->search_words);                          # 364
	ok(!defined $request->representation);                        # 365
	ok(!defined $request->data_block);                            # 366
	ok(!defined $request->attributes);                            # 367
	ok(!defined $request->item_type);                             # 368
}



{
	my $request = URL('gopher://gopher.hole.url:70/1/a_doc.txt%09%09!');

	ok($request->as_string, "/a_doc.txt	!$CRLF");          # 369
	ok($request->as_url,
		'gopher://gopher.hole.url:70/1/a_doc.txt%09%09!'); # 370
	ok($request->request_type, ITEM_ATTRIBUTE_REQUEST);        # 371
	ok($request->host, 'gopher.hole.url');                     # 372
	ok($request->port, 70);                                    # 373
	ok($request->selector, '/a_doc.txt');                      # 374
	ok(!defined $request->search_words);                       # 375
	ok(!defined $request->representation);                     # 376
	ok(!defined $request->data_block);                         # 377
	ok(!defined $request->attributes);                         # 378
	ok(!defined $request->item_type);                          # 379
}



{
	my $request = new Net::Gopher::Request (
		URL => 'gopher://gopher.hole.url:1234/1/MIME_file.mime%09%09!+ADMIN+ABSTRACT'
	);

	ok($request->as_string, "/MIME_file.mime	!+ADMIN+ABSTRACT$CRLF");         # 380
	ok($request->as_url,
		'gopher://gopher.hole.url:1234/1/MIME_file.mime%09%09!+ADMIN+ABSTRACT'); # 381
	ok($request->request_type, ITEM_ATTRIBUTE_REQUEST);                              # 382
	ok($request->host, 'gopher.hole.url');                                           # 383
	ok($request->port, 1234);                                                        # 384
	ok($request->selector, '/MIME_file.mime');                                       # 385
	ok(!defined $request->search_words);                                             # 386
	ok(!defined $request->representation);                                           # 387
	ok(!defined $request->data_block);                                               # 388
	ok($request->attributes, '+ADMIN+ABSTRACT');                                     # 389
	ok(!defined $request->item_type);                                                # 390
}





{
	my $request = URL('gopher://gopher.hole.url:70/1%09%09$');

	ok($request->as_string, "	\$$CRLF");                    # 391
	ok($request->as_url, 'gopher://gopher.hole.url:70/1%09%09$'); # 392
	ok($request->request_type, DIRECTORY_ATTRIBUTE_REQUEST);      # 393
	ok($request->host, 'gopher.hole.url');                        # 394
	ok($request->port, 70);                                       # 395
	ok(!defined $request->selector);                              # 396
	ok(!defined $request->search_words);                          # 397
	ok(!defined $request->representation);                        # 398
	ok(!defined $request->data_block);                            # 399
	ok(!defined $request->attributes);                            # 400
	ok(!defined $request->item_type);                             # 401
}



{
	my $request = new Net::Gopher::Request (
		url => 'gopher://gopher.hole.url:70/1/directory%09%09$+INFO'
	);

	ok($request->as_string, "/directory	\$+INFO$CRLF");         # 402
	ok($request->as_url,
		'gopher://gopher.hole.url:70/1/directory%09%09$+INFO'); # 403
	ok($request->request_type, DIRECTORY_ATTRIBUTE_REQUEST);        # 404
	ok($request->host, 'gopher.hole.url');                          # 405
	ok($request->port, 70);                                         # 406
	ok($request->selector, '/directory');                           # 407
	ok(!defined $request->search_words);                            # 408
	ok(!defined $request->representation);                          # 409
	ok(!defined $request->data_block);                              # 410
	ok($request->attributes, '+INFO');                              # 411
	ok(!defined $request->item_type);                               # 412
}



{
	my $request = URL('gopher://gopher.hole.url:2600/1/more/directory%09%09$+INFO+ADMIN');

	ok($request->as_string, "/more/directory	\$+INFO+ADMIN$CRLF");        # 413
	ok($request->as_url,
		'gopher://gopher.hole.url:2600/1/more/directory%09%09$+INFO+ADMIN'); # 414
	ok($request->request_type, DIRECTORY_ATTRIBUTE_REQUEST);                     # 415
	ok($request->host, 'gopher.hole.url');                                       # 416
	ok($request->port, 2600);                                                    # 417
	ok($request->selector, '/more/directory');                                   # 418
	ok(!defined $request->search_words);                                         # 419
	ok(!defined $request->representation);                                       # 420
	ok(!defined $request->data_block);                                           # 421
	ok($request->attributes, '+INFO+ADMIN');                                     # 422
	ok(!defined $request->item_type);                                            # 423
}










########################################################################
# 
# These tests make sure Net::Gopher::Request raises exceptions in the
# proper places:
#

{
	my (@warnings, @fatal_errors);

	my $ng = new Net::Gopher(
		WarnHandler => sub { push(@warnings, @_) },
		DieHandler  => sub { push(@fatal_errors, @_) }
	);

	my $request = new Net::Gopher::Request;

	ok(@warnings, 0);                                 # 424
	ok(@fatal_errors, 1);                             # 425
	ok($fatal_errors[0], 'No request type specified.'); # 426
}



{
	my (@warnings, @fatal_errors);

	my $ng = new Net::Gopher(
		WarnHandler => sub { push(@warnings, @_) },
		DieHandler  => sub { push(@fatal_errors, @_) }
	);

	my $request = new Net::Gopher::Request('made-up-type');

	ok(@warnings, 0);     # 427
	ok(@fatal_errors, 1); # 428
	ok($fatal_errors[0],
		join(' ',
			'Type "made-up-type" is not a valid request type. ' .
			'Supply either "Gopher", "GopherPlus", ' .
			'"ItemAttribute", "DirectoryAttribute", or "URL" ' .
			'instead.'
		)
	);                    # 429
}



{
	my (@warnings, @fatal_errors);

	my $ng = new Net::Gopher(
		WarnHandler => sub { push(@warnings, @_) },
		DieHandler  => sub { push(@fatal_errors, @_) }
	);

	my $request = new Net::Gopher::Request(URL => 'http://search.cpan.org');

	ok(@warnings, 0);                                          # 430
	ok(@fatal_errors, 1);                                      # 431
	ok($fatal_errors[0], 'Protocol "http" is not supported.'); # 432
}
