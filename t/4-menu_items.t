use strict;
use warnings;
use Test;

BEGIN { plan(tests => 577) }

use Net::Gopher;
use Net::Gopher::Constants qw(:item_types :request :response);
use Net::Gopher::Utility qw($CRLF);

require './t/serverfunctions.pl';







################################################################################
#
# These tests make the sure the get/set accessor methods work correctly:
#

my $item = new Net::Gopher::Response::MenuItem;

ok($item->item_type('x'));                   # 1
ok($item->item_type, 'x');                   # 2
ok($item->display('A display string'));      # 3
ok($item->display, 'A display string');      # 4
ok($item->selector('A selector string.'));   # 5
ok($item->selector, 'A selector string.');   # 6
ok($item->host('some.host.name'));           # 7
ok($item->host, 'some.host.name');           # 8
ok($item->port('7070'));                     # 9
ok($item->port, '7070');                     # 10
ok($item->gopher_plus('A Gopher+ string.')); # 11
ok($item->gopher_plus, 'A Gopher+ string.'); # 12





################################################################################
#
# These tests make the sure the extract items method can properly parse Gopher
# menus.
#

my $port = launch_item_server();
ok($port); # 13

{
	my $ng = new Net::Gopher (WarnHandler => sub {});

	my $response = $ng->gopher(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/index'
	);

	if ($response->is_success)
	{
		ok(1); # 14
	}
	else
	{
		ok(0);
		warn $response->error;
	}

	my @items = $response->extract_items;



	ok($items[0]->item_type, INLINE_TEXT_TYPE);                # 15
	ok($items[0]->display, 'This is a Gopher menu.');          # 16
	ok($items[0]->selector, '');                               # 17
	ok($items[0]->host, '');                                   # 18
	ok($items[0]->port, '');                                   # 19
	ok(!defined $items[0]->gopher_plus);                       # 20
	ok($items[0]->as_string, "iThis is a Gopher menu.\t\t\t"); # 21
	ok($items[0]->as_url, "gopher://:/i");                     # 22

	{
		my $request = $items[0]->as_request;

		ok($request->as_string, "$CRLF");           # 23
		ok($request->as_url, 'gopher://:70/i');     # 24
		ok($request->request_type, GOPHER_REQUEST); # 25
		ok($request->host, '');                     # 26
		ok($request->port, 70);                     # 27
		ok($request->selector, '');                 # 28
		ok(!defined $request->search_words);        # 29
		ok(!defined $request->representation);      # 30
		ok(!defined $request->data_block);          # 31
		ok(!defined $request->attributes);          # 32
		ok($request->item_type, INLINE_TEXT_TYPE);  # 33
	}



	ok($items[1]->item_type, GOPHER_MENU_TYPE);                       # 34
	ok($items[1]->display, 'Item one');                               # 35
	ok($items[1]->selector, '/directory');                            # 36
	ok($items[1]->host, 'localhost');                                 # 37
	ok($items[1]->port, '70');                                        # 38
	ok(!defined $items[1]->gopher_plus);                              # 39
	ok($items[1]->as_string, "1Item one\t/directory\tlocalhost\t70"); # 40
	ok($items[1]->as_url, "gopher://localhost:70/1/directory");       # 41

	{
		my $request = $items[1]->as_request;

		ok($request->as_string, "/directory$CRLF");                # 42
		ok($request->as_url, 'gopher://localhost:70/1/directory'); # 43
		ok($request->request_type, GOPHER_REQUEST);                # 44
		ok($request->host, 'localhost');                           # 45
		ok($request->port, 70);                                    # 46
		ok($request->selector, '/directory');                      # 47
		ok(!defined $request->search_words);                       # 48
		ok(!defined $request->representation);                     # 49
		ok(!defined $request->data_block);                         # 50
		ok(!defined $request->attributes);                         # 51
		ok($request->item_type, GOPHER_MENU_TYPE);                 # 52
	}



	ok($items[2]->item_type, GOPHER_MENU_TYPE);              # 53
	ok($items[2]->display, 'Item two');                      # 54
	ok($items[2]->selector, '/another_directory');           # 55
	ok($items[2]->host, 'localhost');                        # 56
	ok($items[2]->port, '70');                               # 57
	ok(!defined $items[2]->gopher_plus);                     # 58
	ok($items[2]->as_string,
		"1Item two\t/another_directory\tlocalhost\t70"); # 59
	ok($items[2]->as_url,
		"gopher://localhost:70/1/another_directory");    # 60

	{
		my $request = $items[2]->as_request;

		ok($request->as_string, "/another_directory$CRLF");   # 61
		ok($request->as_url,
			'gopher://localhost:70/1/another_directory'); # 62
		ok($request->request_type, GOPHER_REQUEST);           # 63
		ok($request->host, 'localhost');                      # 64
		ok($request->port, 70);                               # 65
		ok($request->selector, '/another_directory');         # 66
		ok(!defined $request->search_words);                  # 67
		ok(!defined $request->representation);                # 68
		ok(!defined $request->data_block);                    # 69
		ok(!defined $request->attributes);                    # 70
		ok($request->item_type, GOPHER_MENU_TYPE);            # 71
	}



	ok($items[3]->item_type, TEXT_FILE_TYPE);                           # 72
	ok($items[3]->display, 'Item three');                               # 73
	ok($items[3]->selector, '/three.txt');                              # 74
	ok($items[3]->host, 'localhost');                                   # 75
	ok($items[3]->port, '70');                                          # 76
	ok(!defined $items[3]->gopher_plus);                                # 77
	ok($items[3]->as_string, "0Item three\t/three.txt\tlocalhost\t70"); # 78
	ok($items[3]->as_url, "gopher://localhost:70/0/three.txt");         # 79

	{
		my $request = $items[3]->as_request;

		ok($request->as_string, "/three.txt$CRLF");                # 80
		ok($request->as_url, 'gopher://localhost:70/0/three.txt'); # 81
		ok($request->request_type, GOPHER_REQUEST);                # 82
		ok($request->host, 'localhost');                           # 83
		ok($request->port, 70);                                    # 84
		ok($request->selector, '/three.txt');                      # 85
		ok(!defined $request->search_words);                       # 86
		ok(!defined $request->representation);                     # 87
		ok(!defined $request->data_block);                         # 88
		ok(!defined $request->attributes);                         # 89
		ok($request->item_type, TEXT_FILE_TYPE);                   # 90
	}



	ok($items[4]->item_type, GOPHER_MENU_TYPE);                # 91
	ok($items[4]->display, 'Item four');                       # 92
	ok($items[4]->selector, '/one_more_directory');            # 93
	ok($items[4]->host, 'localhost');                          # 94
	ok($items[4]->port, '70');                                 # 95
	ok(!defined $items[4]->gopher_plus);                       # 96
	ok($items[4]->as_string,
		"1Item four\t/one_more_directory\tlocalhost\t70"); # 97
	ok($items[4]->as_url,
		"gopher://localhost:70/1/one_more_directory");     # 98

	{
		my $request = $items[4]->as_request;

		ok($request->as_string, "/one_more_directory$CRLF");   # 99
		ok($request->as_url,
			'gopher://localhost:70/1/one_more_directory'); # 100
		ok($request->request_type, GOPHER_REQUEST);            # 101
		ok($request->host, 'localhost');                       # 102
		ok($request->port, 70);                                # 103
		ok($request->selector, '/one_more_directory');         # 104
		ok(!defined $request->search_words);                   # 105
		ok(!defined $request->representation);                 # 106
		ok(!defined $request->data_block);                     # 107
		ok(!defined $request->attributes);                     # 108
		ok($request->item_type, GOPHER_MENU_TYPE);             # 109
	}



	ok($items[5]->item_type, INLINE_TEXT_TYPE);        # 110
	ok($items[5]->display, 'Download this:');          # 111
	ok($items[5]->selector, '');                       # 112
	ok($items[5]->host, '');                           # 113
	ok($items[5]->port, '');                           # 114
	ok(!defined $items[5]->gopher_plus);               # 115
	ok($items[5]->as_string, "iDownload this:\t\t\t"); # 116
	ok($items[5]->as_url, "gopher://:/i");             # 117

	{
		my $request = $items[5]->as_request;

		ok($request->as_string, "$CRLF");           # 118
		ok($request->as_url,'gopher://:70/i');      # 119
		ok($request->request_type, GOPHER_REQUEST); # 120
		ok($request->host, '');                     # 121
		ok($request->port, 70);                     # 122
		ok($request->selector, '');                 # 123
		ok(!defined $request->search_words);        # 124
		ok(!defined $request->representation);      # 125
		ok(!defined $request->data_block);          # 126
		ok(!defined $request->attributes);          # 127
		ok($request->item_type, INLINE_TEXT_TYPE);  # 128
	}



	ok($items[6]->item_type, GIF_IMAGE_TYPE);                          # 129
	ok($items[6]->display, 'GIF image');                               # 130
	ok($items[6]->selector, '/image.gif');                             # 131
	ok($items[6]->host, 'localhost');                                  # 132
	ok($items[6]->port, 70);                                           # 133
	ok(!defined $items[6]->gopher_plus);                               # 134
	ok($items[6]->as_string, "gGIF image\t/image.gif\tlocalhost\t70"); # 135
	ok($items[6]->as_url, "gopher://localhost:70/g/image.gif");        # 136

	{
		my $request = $items[6]->as_request;

		ok($request->as_string, "/image.gif$CRLF");               # 137
		ok($request->as_url,'gopher://localhost:70/g/image.gif'); # 138
		ok($request->request_type, GOPHER_REQUEST);               # 139
		ok($request->host, 'localhost');                          # 140
		ok($request->port, 70);                                   # 141
		ok($request->selector, '/image.gif');                     # 142
		ok(!defined $request->search_words);                      # 143
		ok(!defined $request->representation);                    # 144
		ok(!defined $request->data_block);                        # 145
		ok(!defined $request->attributes);                        # 146
		ok($request->item_type, GIF_IMAGE_TYPE);                  # 147
	}



	ok($items[7]->item_type, TEXT_FILE_TYPE);                       # 148
	ok($items[7]->display, 'Item six');                             # 149
	ok($items[7]->selector, '/six.txt');                            # 150
	ok($items[7]->host, 'localhost');                               # 151
	ok($items[7]->port, 70);                                        # 152
	ok(!defined $items[7]->gopher_plus);                            # 153
	ok($items[7]->as_string, "0Item six\t/six.txt\tlocalhost\t70"); # 154
	ok($items[7]->as_url, "gopher://localhost:70/0/six.txt");       # 155

	{
		my $request = $items[7]->as_request;

		ok($request->as_string, "/six.txt$CRLF");               # 156
		ok($request->as_url,'gopher://localhost:70/0/six.txt'); # 157
		ok($request->request_type, GOPHER_REQUEST);             # 158
		ok($request->host, 'localhost');                        # 159
		ok($request->port, 70);                                 # 160
		ok($request->selector, '/six.txt');                     # 161
		ok(!defined $request->search_words);                    # 162
		ok(!defined $request->representation);                  # 163
		ok(!defined $request->data_block);                      # 164
		ok(!defined $request->attributes);                      # 165
		ok($request->item_type, TEXT_FILE_TYPE);                # 166
	}

	ok(scalar @items, 8); # 167





	########################################################################
	#
	# These tests test the OfTypes and ExceptTypes block filters:
	#
	{
		my @of_types = $response->extract_items(
			OfTypes => INLINE_TEXT_TYPE
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE);       # 168
		ok($of_types[0]->display, 'This is a Gopher menu.'); # 169
		ok($of_types[0]->selector, '');                      # 170
		ok($of_types[0]->host, '');                          # 171
		ok($of_types[0]->port, '');                          # 172
		ok(!defined $of_types[0]->gopher_plus);              # 173
		ok($of_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");            # 174
		ok($of_types[0]->as_url, "gopher://:/i");            # 175

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);        # 176
		ok($of_types[1]->display, 'Download this:');          # 177
		ok($of_types[1]->selector, '');                       # 178
		ok($of_types[1]->host, '');                           # 179
		ok($of_types[1]->port, '');                           # 180
		ok(!defined $of_types[1]->gopher_plus);               # 181
		ok($of_types[1]->as_string, "iDownload this:\t\t\t"); # 182
		ok($of_types[1]->as_url, "gopher://:/i");             # 183

		ok(scalar @of_types, 2); # 184
	}

	{
		my @of_types = $response->extract_items(
			OfTypes => [INLINE_TEXT_TYPE, TEXT_FILE_TYPE]
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE);       # 185
		ok($of_types[0]->display, 'This is a Gopher menu.'); # 186
		ok($of_types[0]->selector, '');                      # 187
		ok($of_types[0]->host, '');                          # 188
		ok($of_types[0]->port, '');                          # 189
		ok(!defined $of_types[0]->gopher_plus);              # 190
		ok($of_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");            # 191
		ok($of_types[0]->as_url, "gopher://:/i");            # 192

		ok($of_types[1]->item_type, TEXT_FILE_TYPE);       # 193
		ok($of_types[1]->display, 'Item three');           # 194
		ok($of_types[1]->selector, '/three.txt');          # 195
		ok($of_types[1]->host, 'localhost');               # 196
		ok($of_types[1]->port, '70');                      # 197
		ok(!defined $of_types[1]->gopher_plus);            # 198
		ok($of_types[1]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 199
		ok($of_types[1]->as_url,
			"gopher://localhost:70/0/three.txt");      # 200

		ok($of_types[2]->item_type, INLINE_TEXT_TYPE);        # 201
		ok($of_types[2]->display, 'Download this:');          # 202
		ok($of_types[2]->selector, '');                       # 203
		ok($of_types[2]->host, '');                           # 204
		ok($of_types[2]->port, '');                           # 205
		ok(!defined $of_types[2]->gopher_plus);               # 206
		ok($of_types[2]->as_string, "iDownload this:\t\t\t"); # 207
		ok($of_types[2]->as_url, "gopher://:/i");             # 208

		ok($of_types[3]->item_type, TEXT_FILE_TYPE);   # 209
		ok($of_types[3]->display, 'Item six');         # 210
		ok($of_types[3]->selector, '/six.txt');        # 211
		ok($of_types[3]->host, 'localhost');           # 212
		ok($of_types[3]->port, 70);                    # 213
		ok(!defined $of_types[3]->gopher_plus);        # 214
		ok($of_types[3]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70"); # 215
		ok($of_types[3]->as_url,
			"gopher://localhost:70/0/six.txt");    # 216

		ok(scalar @of_types, 4); # 217
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => GOPHER_MENU_TYPE
		);

		ok($except_types[0]->item_type, INLINE_TEXT_TYPE);       # 218
		ok($except_types[0]->display, 'This is a Gopher menu.'); # 219
		ok($except_types[0]->selector, '');                      # 220
		ok($except_types[0]->host, '');                          # 221
		ok($except_types[0]->port, '');                          # 222
		ok(!defined $except_types[0]->gopher_plus);              # 223
		ok($except_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");                # 224
		ok($except_types[0]->as_url, "gopher://:/i");            # 225

		ok($except_types[1]->item_type, TEXT_FILE_TYPE);   # 226
		ok($except_types[1]->display, 'Item three');       # 227
		ok($except_types[1]->selector, '/three.txt');      # 228
		ok($except_types[1]->host, 'localhost');           # 229
		ok($except_types[1]->port, '70');                  # 230
		ok(!defined $except_types[1]->gopher_plus);        # 231
		ok($except_types[1]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 232
		ok($except_types[1]->as_url,
			"gopher://localhost:70/0/three.txt");      # 233

		ok($except_types[2]->item_type, INLINE_TEXT_TYPE);        # 234
		ok($except_types[2]->display, 'Download this:');          # 235
		ok($except_types[2]->selector, '');                       # 236
		ok($except_types[2]->host, '');                           # 237
		ok($except_types[2]->port, '');                           # 238
		ok(!defined $except_types[2]->gopher_plus);               # 239
		ok($except_types[2]->as_string, "iDownload this:\t\t\t"); # 240
		ok($except_types[2]->as_url, "gopher://:/i");             # 241

		ok($except_types[3]->item_type, GIF_IMAGE_TYPE);  # 242
		ok($except_types[3]->display, 'GIF image');       # 243
		ok($except_types[3]->selector, '/image.gif');     # 244
		ok($except_types[3]->host, 'localhost');          # 245
		ok($except_types[3]->port, 70);                   # 246
		ok(!defined $except_types[3]->gopher_plus);       # 247
		ok($except_types[3]->as_string,
			"gGIF image\t/image.gif\tlocalhost\t70"); # 248
		ok($except_types[3]->as_url,
			"gopher://localhost:70/g/image.gif");     # 249

		ok($except_types[4]->item_type, TEXT_FILE_TYPE); # 250
		ok($except_types[4]->display, 'Item six');       # 251
		ok($except_types[4]->selector, '/six.txt');      # 252
		ok($except_types[4]->host, 'localhost');         # 253
		ok($except_types[4]->port, 70);                  # 254
		ok(!defined $except_types[4]->gopher_plus);      # 255
		ok($except_types[4]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70");   # 256
		ok($except_types[4]->as_url,
			"gopher://localhost:70/0/six.txt");      # 257

		ok(scalar @except_types, 5); # 258
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => [GOPHER_MENU_TYPE, INLINE_TEXT_TYPE]
		);

		ok($except_types[0]->item_type, TEXT_FILE_TYPE);   # 259
		ok($except_types[0]->display, 'Item three');       # 260
		ok($except_types[0]->selector, '/three.txt');      # 261
		ok($except_types[0]->host, 'localhost');           # 262
		ok($except_types[0]->port, '70');                  # 263
		ok(!defined $except_types[0]->gopher_plus);        # 264
		ok($except_types[0]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 265
		ok($except_types[0]->as_url,
			"gopher://localhost:70/0/three.txt");      # 266

		ok($except_types[1]->item_type, GIF_IMAGE_TYPE);  # 267
		ok($except_types[1]->display, 'GIF image');       # 268
		ok($except_types[1]->selector, '/image.gif');     # 269
		ok($except_types[1]->host, 'localhost');          # 270
		ok($except_types[1]->port, 70);                   # 271
		ok(!defined $except_types[1]->gopher_plus);       # 272
		ok($except_types[1]->as_string,
			"gGIF image\t/image.gif\tlocalhost\t70"); # 273
		ok($except_types[1]->as_url,
			"gopher://localhost:70/g/image.gif");     # 274

		ok($except_types[2]->item_type, TEXT_FILE_TYPE); # 275
		ok($except_types[2]->display, 'Item six');       # 276
		ok($except_types[2]->selector, '/six.txt');      # 277
		ok($except_types[2]->host, 'localhost');         # 278
		ok($except_types[2]->port, 70);                  # 279
		ok(!defined $except_types[2]->gopher_plus);      # 280
		ok($except_types[2]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70");   # 281
		ok($except_types[2]->as_url,
			"gopher://localhost:70/0/six.txt");      # 282

		ok(scalar @except_types, 3); # 283
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => 'i10g'
		);

		ok(scalar @except_types, 0); # 284
	}





	########################################################################
	#
	# These tests test block handlers:
	#

	{
		my @items;
		my $invocations;
		my @rv = $response->extract_items(
			Handler => sub {
				push(@items, shift);

				$invocations++;

				# stop after two items:
				return if ($invocations >= 2);

				return 1;
			}
		);

		ok($items[0]->item_type, INLINE_TEXT_TYPE);                # 285
		ok($items[0]->display, 'This is a Gopher menu.');          # 286
		ok($items[0]->selector, '');                               # 287
		ok($items[0]->host, '');                                   # 288
		ok($items[0]->port, '');                                   # 289
		ok(!defined $items[0]->gopher_plus);                       # 290
		ok($items[0]->as_string, "iThis is a Gopher menu.\t\t\t"); # 291
		ok($items[0]->as_url, "gopher://:/i");                     # 292

		ok($items[1]->item_type, GOPHER_MENU_TYPE);      # 293
		ok($items[1]->display, 'Item one');              # 294
		ok($items[1]->selector, '/directory');           # 295
		ok($items[1]->host, 'localhost');                # 296
		ok($items[1]->port, '70');                       # 297
		ok(!defined $items[1]->gopher_plus);             # 298
		ok($items[1]->as_string,
			"1Item one\t/directory\tlocalhost\t70"); # 299
		ok($items[1]->as_url,
			"gopher://localhost:70/1/directory");    # 300

		ok(scalar @rv, 0);   # 301
		ok($invocations, 2); # 302
	}
}










{
	my $ng = new Net::Gopher (WarnHandler => sub {});

	my $response = $ng->gopher_plus(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/gp_index'
	);

	if ($response->is_success)
	{
		ok(1); # 303
	}
	else
	{
		ok(0);
		warn $response->error;
	}

	my @items = $response->extract_items;



	ok($items[0]->item_type, INLINE_TEXT_TYPE); # 304
	ok($items[0]->display,
		'This is a Gopher+ style Gopher menu, where all of the '. 
		'items have a fifth field');        # 305
	ok($items[0]->selector, '');                # 306
	ok($items[0]->host, '');                    # 307
	ok($items[0]->port, '');                    # 308
	ok(!defined $items[0]->gopher_plus);        # 309
	ok($items[0]->as_string,
		"iThis is a Gopher+ style Gopher menu, where all of the " .
		"items have a fifth field\t\t\t");  # 310
	ok($items[0]->as_url, "gopher://:/i");      # 311

	{
		my $request = $items[0]->as_request;

		ok($request->as_string, "$CRLF");           # 312
		ok($request->as_url, 'gopher://:70/i');     # 313
		ok($request->request_type, GOPHER_REQUEST); # 314
		ok($request->host, '');                     # 315
		ok($request->port, 70);                     # 316
		ok($request->selector, '');                 # 317
		ok(!defined $request->search_words);        # 318
		ok(!defined $request->representation);      # 319
		ok(!defined $request->data_block);          # 320
		ok(!defined $request->attributes);          # 321
		ok($request->item_type, INLINE_TEXT_TYPE);  # 322
	}



	ok($items[1]->item_type, INLINE_TEXT_TYPE);                        # 323
	ok($items[1]->display, 'containing a + or ? character.');          # 324
	ok($items[1]->selector, '');                                       # 325
	ok($items[1]->host, '');                                           # 326
	ok($items[1]->port, '');                                           # 327
	ok(!defined $items[1]->gopher_plus);                               # 328
	ok($items[1]->as_string, "icontaining a + or ? character.\t\t\t"); # 329
	ok($items[1]->as_url, "gopher://:/i");                             # 330

	{
		my $request = $items[1]->as_request;

		ok($request->as_string, "$CRLF");           # 331
		ok($request->as_url, 'gopher://:70/i');     # 332
		ok($request->request_type, GOPHER_REQUEST); # 333
		ok($request->host, '');                     # 334
		ok($request->port, 70);                     # 335
		ok($request->selector, '');                 # 336
		ok(!defined $request->search_words);        # 337
		ok(!defined $request->representation);      # 338
		ok(!defined $request->data_block);          # 339
		ok(!defined $request->attributes);          # 340
		ok($request->item_type, INLINE_TEXT_TYPE);  # 341
	}



	ok($items[2]->item_type, GOPHER_MENU_TYPE);                       # 342
	ok($items[2]->display, 'Some directory');                         # 343
	ok($items[2]->selector, '/some_dir');                             # 344
	ok($items[2]->host, 'localhost');                                 # 345
	ok($items[2]->port, '70');                                        # 346
	ok($items[2]->gopher_plus, '+');                                  # 347
	ok($items[2]->as_string,
		"1Some directory\t/some_dir\tlocalhost\t70\t+");          # 348
	ok($items[2]->as_url, 'gopher://localhost:70/1/some_dir%09%09+'); # 349

	{
		my $request = $items[2]->as_request;

		ok($request->as_string, "/some_dir	+$CRLF");   # 350
		ok($request->as_url,
			'gopher://localhost:70/1/some_dir%09%09+'); # 351
		ok($request->request_type, GOPHER_PLUS_REQUEST);    # 352
		ok($request->host, 'localhost');                    # 353
		ok($request->port, 70);                             # 354
		ok($request->selector, '/some_dir');                # 355
		ok(!defined $request->search_words);                # 356
		ok(!defined $request->representation);              # 357
		ok(!defined $request->data_block);                  # 358
		ok(!defined $request->attributes);                  # 359
		ok($request->item_type, GOPHER_MENU_TYPE);          # 360
	}



	ok($items[3]->item_type, GOPHER_MENU_TYPE);                          # 361
	ok($items[3]->display, 'Some other directory');                      # 362
	ok($items[3]->selector, '/some_other_dir');                          # 363
	ok($items[3]->host, 'localhost');                                    # 364
	ok($items[3]->port, '70');                                           # 365
	ok($items[3]->gopher_plus, '+');                                     # 366
	ok($items[3]->as_string,
		"1Some other directory\t/some_other_dir\tlocalhost\t70\t+"); # 367
	ok($items[3]->as_url,
		'gopher://localhost:70/1/some_other_dir%09%09+');            # 368

	{
		my $request = $items[3]->as_request;

		ok($request->as_string, "/some_other_dir	+$CRLF"); # 369
		ok($request->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 370
		ok($request->request_type, GOPHER_PLUS_REQUEST);          # 371
		ok($request->host, 'localhost');                          # 372
		ok($request->port, 70);                                   # 373
		ok($request->selector, '/some_other_dir');                # 374
		ok(!defined $request->search_words);                      # 375
		ok(!defined $request->representation);                    # 376
		ok(!defined $request->data_block);                        # 377
		ok(!defined $request->attributes);                        # 378
		ok($request->item_type, GOPHER_MENU_TYPE);                # 379
	}



	ok($items[4]->item_type, GIF_IMAGE_TYPE);              # 380
	ok($items[4]->display, 'A GIF image');                 # 381
	ok($items[4]->selector, '/image.gif');                 # 382
	ok($items[4]->host, 'localhost');                      # 383
	ok($items[4]->port, '70');                             # 384
	ok($items[4]->gopher_plus, '+');                       # 385
	ok($items[4]->as_string,
		"gA GIF image\t/image.gif\tlocalhost\t70\t+"); # 386
	ok($items[4]->as_url,
		'gopher://localhost:70/g/image.gif%09%09+');   # 387

	{
		my $request = $items[4]->as_request;

		ok($request->as_string, "/image.gif	+$CRLF");    # 388
		ok($request->as_url,
			'gopher://localhost:70/g/image.gif%09%09+'); # 389
		ok($request->request_type, GOPHER_PLUS_REQUEST);     # 390
		ok($request->host, 'localhost');                     # 391
		ok($request->port, 70);                              # 392
		ok($request->selector, '/image.gif');                # 393
		ok(!defined $request->search_words);                 # 394
		ok(!defined $request->representation);               # 395
		ok(!defined $request->data_block);                   # 396
		ok(!defined $request->attributes);                   # 397
		ok($request->item_type, GIF_IMAGE_TYPE);             # 398
	}



	ok($items[5]->item_type, INLINE_TEXT_TYPE);             # 399
	ok($items[5]->display, 'Fill out this form:');          # 400
	ok($items[5]->selector, '');                            # 401
	ok($items[5]->host, '');                                # 402
	ok($items[5]->port, '');                                # 403
	ok(!defined $items[5]->gopher_plus);                    # 404
	ok($items[5]->as_string, "iFill out this form:\t\t\t"); # 405
	ok($items[5]->as_url, "gopher://:/i");                  # 406

	{
		my $request = $items[5]->as_request;

		ok($request->as_string, "$CRLF");           # 407
		ok($request->as_url,'gopher://:70/i');      # 408
		ok($request->request_type, GOPHER_REQUEST); # 409
		ok($request->host, '');                     # 410
		ok($request->port, 70);                     # 411
		ok($request->selector, '');                 # 412
		ok(!defined $request->search_words);        # 413
		ok(!defined $request->representation);      # 414
		ok(!defined $request->data_block);          # 415
		ok(!defined $request->attributes);          # 416
		ok($request->item_type, INLINE_TEXT_TYPE);  # 417
	}



	ok($items[6]->item_type, GOPHER_MENU_TYPE);             # 418
	ok($items[6]->display, 'Application');                  # 419
	ok($items[6]->selector, '/ask_script');                 # 420
	ok($items[6]->host, 'localhost');                       # 421
	ok($items[6]->port, '70');                              # 422
	ok($items[6]->gopher_plus, '?');                        # 423
	ok($items[6]->as_string,
		"1Application\t/ask_script\tlocalhost\t70\t?"); # 424
	ok($items[6]->as_url,
		'gopher://localhost:70/1/ask_script%09%09?');   # 425

	{
		my $request = $items[6]->as_request;

		ok($request->as_string, "/ask_script	+$CRLF");     # 426
		ok($request->as_url,
			'gopher://localhost:70/1/ask_script%09%09+'); # 427
		ok($request->request_type, GOPHER_PLUS_REQUEST);      # 428
		ok($request->host, 'localhost');                      # 429
		ok($request->port, 70);                               # 430
		ok($request->selector, '/ask_script');                # 431
		ok(!defined $request->search_words);                  # 432
		ok(!defined $request->representation);                # 433
		ok(!defined $request->data_block);                    # 434
		ok(!defined $request->attributes);                    # 435
		ok($request->item_type, GOPHER_MENU_TYPE);            # 436
	}

	ok(scalar @items, 7); # 437





	{
		my @of_types = $response->extract_items(
			OfTypes => [INLINE_TEXT_TYPE]
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE); # 438
		ok($of_types[0]->display,
			'This is a Gopher+ style Gopher menu, where all of ' .
			'the items have a fifth field');       # 439
		ok($of_types[0]->selector, '');                # 440
		ok($of_types[0]->host, '');                    # 441
		ok($of_types[0]->port, '');                    # 442
		ok(!defined $of_types[0]->gopher_plus);        # 443
		ok($of_types[0]->as_string,
			"iThis is a Gopher+ style Gopher menu, where all of " .
			"the items have a fifth field\t\t\t"); # 444
		ok($of_types[0]->as_url, "gopher://:/i");      # 445

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);    # 446
		ok($of_types[1]->display,
			'containing a + or ? character.');        # 447
		ok($of_types[1]->selector, '');                   # 448
		ok($of_types[1]->host, '');                       # 449
		ok($of_types[1]->port, '');                       # 450
		ok(!defined $of_types[1]->gopher_plus);           # 451
		ok($of_types[1]->as_string,
			"icontaining a + or ? character.\t\t\t"); # 452
		ok($of_types[1]->as_url, "gopher://:/i");         # 453

		ok($of_types[2]->item_type, INLINE_TEXT_TYPE);             # 454
		ok($of_types[2]->display, 'Fill out this form:');          # 455
		ok($of_types[2]->selector, '');                            # 456
		ok($of_types[2]->host, '');                                # 457
		ok($of_types[2]->port, '');                                # 458
		ok(!defined $of_types[2]->gopher_plus);                    # 459
		ok($of_types[2]->as_string, "iFill out this form:\t\t\t"); # 460
		ok($of_types[2]->as_url, "gopher://:/i");                  # 461

		ok(scalar @of_types, 3); # 462
	}

	{
		my @of_types = $response->extract_items(
			OfTypes => 'i1'
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE); # 463
		ok($of_types[0]->display,
			'This is a Gopher+ style Gopher menu, where all of ' .
			'the items have a fifth field');       # 464
		ok($of_types[0]->selector, '');                # 465
		ok($of_types[0]->host, '');                    # 466
		ok($of_types[0]->port, '');                    # 467
		ok(!defined $of_types[0]->gopher_plus);        # 468
		ok($of_types[0]->as_string,
			"iThis is a Gopher+ style Gopher menu, where all of " .
			"the items have a fifth field\t\t\t"); # 469
		ok($of_types[0]->as_url, "gopher://:/i");      # 470

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);    # 471
		ok($of_types[1]->display,
			'containing a + or ? character.');        # 472
		ok($of_types[1]->selector, '');                   # 473
		ok($of_types[1]->host, '');                       # 474
		ok($of_types[1]->port, '');                       # 475
		ok(!defined $of_types[1]->gopher_plus);           # 476
		ok($of_types[1]->as_string,
			"icontaining a + or ? character.\t\t\t"); # 477
		ok($of_types[1]->as_url, "gopher://:/i");         # 478

		ok($of_types[2]->item_type, GOPHER_MENU_TYPE);           # 479
		ok($of_types[2]->display, 'Some directory');             # 480
		ok($of_types[2]->selector, '/some_dir');                 # 481
		ok($of_types[2]->host, 'localhost');                     # 482
		ok($of_types[2]->port, '70');                            # 483
		ok($of_types[2]->gopher_plus, '+');                      # 484
		ok($of_types[2]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 485
		ok($of_types[2]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 486

		ok($of_types[3]->item_type, GOPHER_MENU_TYPE);            # 487
		ok($of_types[3]->display, 'Some other directory');        # 488
		ok($of_types[3]->selector, '/some_other_dir');            # 489
		ok($of_types[3]->host, 'localhost');                      # 490
		ok($of_types[3]->port, '70');                             # 491
		ok($of_types[3]->gopher_plus, '+');                       # 492
		ok($of_types[3]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 493
		ok($of_types[3]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 494

		ok($of_types[4]->item_type, INLINE_TEXT_TYPE);             # 495
		ok($of_types[4]->display, 'Fill out this form:');          # 496
		ok($of_types[4]->selector, '');                            # 497
		ok($of_types[4]->host, '');                                # 498
		ok($of_types[4]->port, '');                                # 499
		ok(!defined $of_types[4]->gopher_plus);                    # 500
		ok($of_types[4]->as_string, "iFill out this form:\t\t\t"); # 501
		ok($of_types[4]->as_url, "gopher://:/i");                  # 502

		ok($of_types[5]->item_type, GOPHER_MENU_TYPE);          # 503
		ok($of_types[5]->display, 'Application');               # 504
		ok($of_types[5]->selector, '/ask_script');              # 505
		ok($of_types[5]->host, 'localhost');                    # 506
		ok($of_types[5]->port, '70');                           # 507
		ok($of_types[5]->gopher_plus, '?');                     # 508
		ok($of_types[5]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 509
		ok($of_types[5]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 510

		ok(scalar @of_types, 6); # 511
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => [INLINE_TEXT_TYPE]
		);

		ok($except_types[0]->item_type, GOPHER_MENU_TYPE);       # 512
		ok($except_types[0]->display, 'Some directory');         # 513
		ok($except_types[0]->selector, '/some_dir');             # 514
		ok($except_types[0]->host, 'localhost');                 # 515
		ok($except_types[0]->port, '70');                        # 516
		ok($except_types[0]->gopher_plus, '+');                  # 517
		ok($except_types[0]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 518
		ok($except_types[0]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 519

		ok($except_types[1]->item_type, GOPHER_MENU_TYPE);        # 520
		ok($except_types[1]->display, 'Some other directory');    # 521
		ok($except_types[1]->selector, '/some_other_dir');        # 522
		ok($except_types[1]->host, 'localhost');                  # 523
		ok($except_types[1]->port, '70');                         # 524
		ok($except_types[1]->gopher_plus, '+');                   # 525
		ok($except_types[1]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 526
		ok($except_types[1]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 527

		ok($except_types[2]->item_type, GIF_IMAGE_TYPE);       # 528
		ok($except_types[2]->display, 'A GIF image');          # 529
		ok($except_types[2]->selector, '/image.gif');          # 530
		ok($except_types[2]->host, 'localhost');               # 531
		ok($except_types[2]->port, '70');                      # 532
		ok($except_types[2]->gopher_plus, '+');                # 533
		ok($except_types[2]->as_string,
			"gA GIF image\t/image.gif\tlocalhost\t70\t+"); # 534
		ok($except_types[2]->as_url,
			'gopher://localhost:70/g/image.gif%09%09+');   # 535

		ok($except_types[3]->item_type, GOPHER_MENU_TYPE);      # 536
		ok($except_types[3]->display, 'Application');           # 537
		ok($except_types[3]->selector, '/ask_script');          # 538
		ok($except_types[3]->host, 'localhost');                # 539
		ok($except_types[3]->port, '70');                       # 540
		ok($except_types[3]->gopher_plus, '?');                 # 541
		ok($except_types[3]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 542
		ok($except_types[3]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 543

		ok(scalar @except_types, 4); # 544
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => ['gi']
		);

		ok($except_types[0]->item_type, GOPHER_MENU_TYPE);       # 545
		ok($except_types[0]->display, 'Some directory');         # 546
		ok($except_types[0]->selector, '/some_dir');             # 547
		ok($except_types[0]->host, 'localhost');                 # 548
		ok($except_types[0]->port, '70');                        # 549
		ok($except_types[0]->gopher_plus, '+');                  # 550
		ok($except_types[0]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 551
		ok($except_types[0]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 552

		ok($except_types[1]->item_type, GOPHER_MENU_TYPE);        # 553
		ok($except_types[1]->display, 'Some other directory');    # 554
		ok($except_types[1]->selector, '/some_other_dir');        # 555
		ok($except_types[1]->host, 'localhost');                  # 556
		ok($except_types[1]->port, '70');                         # 557
		ok($except_types[1]->gopher_plus, '+');                   # 558
		ok($except_types[1]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 559
		ok($except_types[1]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 560

		ok($except_types[2]->item_type, GOPHER_MENU_TYPE);      # 561
		ok($except_types[2]->display, 'Application');           # 562
		ok($except_types[2]->selector, '/ask_script');          # 563
		ok($except_types[2]->host, 'localhost');                # 564
		ok($except_types[2]->port, '70');                       # 565
		ok($except_types[2]->gopher_plus, '?');                 # 566
		ok($except_types[2]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 567
		ok($except_types[2]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 568

		ok(scalar @except_types, 3); # 569
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => 'i1g'
		);

		ok(scalar @except_types, 0); # 570
	}





	{
		my (@warnings, @fatal_errors);

		my $ng = new Net::Gopher(
			WarnHandler => sub { push(@warnings, @_) },
			DieHandler  => sub { push(@fatal_errors, @_) }
		);

		$ng->gopher(
			Host     => 'localhost',
			Port     => $port,
			Selector => '/malformed_menu'
		)->extract_items;

		ok(scalar @warnings, 0);     # 571
		ok(scalar @fatal_errors, 1); # 572
		ok($fatal_errors[0],
			join(' ',
				'Menu item 2 lacks the following required',
				'fields: a selector string field; a host',
				'field; a port field. The response either',
				'does not contain a Gopher menu or contains',
				'a malformed Gopher menu.'
			)
		);                           # 573
	}

	{
		my (@warnings, @fatal_errors);

		my $ng = new Net::Gopher(
			WarnHandler => sub { push(@warnings, @_) },
			DieHandler  => sub { push(@fatal_errors, @_) }
		);

		$ng->gopher_plus(
			Host     => 'localhost',
			Port     => $port,
			Selector => '/gp_s_no_term'
		)->extract_items;

		ok(scalar @warnings, 0);     # 574
		ok(scalar @fatal_errors, 1); # 575
		ok($fatal_errors[0],
			join(' ',
				'Menu item 1 lacks the following required',
				'fields: a selector string field; a host',
				'field; a port field. The response either',
				'does not contain a Gopher menu or contains',
				'a malformed Gopher menu.'
			)
		);                           # 576
	}
}





ok(kill_servers()); # 577
