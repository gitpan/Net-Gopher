use strict;
use warnings;
use Test;

BEGIN { plan(tests => 559) }

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

ok(run_server()); # 13

{
	my $ng = new Net::Gopher (WarnHandler => sub {});

	my $response = $ng->gopher(
		Host     => 'localhost',
		Selector => '/index'
	);

	ok($response->is_success); # 14

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
}










{
	my $ng = new Net::Gopher (WarnHandler => sub {});

	my $response = $ng->gopher_plus(
		Host     => 'localhost',
		Selector => '/gp_index'
	);

	ok($response->is_success); # 285

	my @items = $response->extract_items;



	ok($items[0]->item_type, INLINE_TEXT_TYPE); # 286
	ok($items[0]->display,
		'This is a Gopher+ style Gopher menu, where all of the '. 
		'items have a fifth field');        # 287
	ok($items[0]->selector, '');                # 288
	ok($items[0]->host, '');                    # 289
	ok($items[0]->port, '');                    # 290
	ok(!defined $items[0]->gopher_plus);        # 291
	ok($items[0]->as_string,
		"iThis is a Gopher+ style Gopher menu, where all of the " .
		"items have a fifth field\t\t\t");  # 292
	ok($items[0]->as_url, "gopher://:/i");      # 293

	{
		my $request = $items[0]->as_request;

		ok($request->as_string, "$CRLF");           # 294
		ok($request->as_url, 'gopher://:70/i');     # 295
		ok($request->request_type, GOPHER_REQUEST); # 296
		ok($request->host, '');                     # 297
		ok($request->port, 70);                     # 298
		ok($request->selector, '');                 # 299
		ok(!defined $request->search_words);        # 300
		ok(!defined $request->representation);      # 301
		ok(!defined $request->data_block);          # 302
		ok(!defined $request->attributes);          # 303
		ok($request->item_type, INLINE_TEXT_TYPE);  # 304
	}



	ok($items[1]->item_type, INLINE_TEXT_TYPE);                        # 305
	ok($items[1]->display, 'containing a + or ? character.');          # 306
	ok($items[1]->selector, '');                                       # 307
	ok($items[1]->host, '');                                           # 308
	ok($items[1]->port, '');                                           # 309
	ok(!defined $items[1]->gopher_plus);                               # 310
	ok($items[1]->as_string, "icontaining a + or ? character.\t\t\t"); # 311
	ok($items[1]->as_url, "gopher://:/i");                             # 312

	{
		my $request = $items[1]->as_request;

		ok($request->as_string, "$CRLF");           # 313
		ok($request->as_url, 'gopher://:70/i');     # 314
		ok($request->request_type, GOPHER_REQUEST); # 315
		ok($request->host, '');                     # 316
		ok($request->port, 70);                     # 317
		ok($request->selector, '');                 # 318
		ok(!defined $request->search_words);        # 319
		ok(!defined $request->representation);      # 320
		ok(!defined $request->data_block);          # 321
		ok(!defined $request->attributes);          # 322
		ok($request->item_type, INLINE_TEXT_TYPE);  # 323
	}



	ok($items[2]->item_type, GOPHER_MENU_TYPE);                       # 324
	ok($items[2]->display, 'Some directory');                         # 325
	ok($items[2]->selector, '/some_dir');                             # 326
	ok($items[2]->host, 'localhost');                                 # 327
	ok($items[2]->port, '70');                                        # 328
	ok($items[2]->gopher_plus, '+');                                  # 329
	ok($items[2]->as_string,
		"1Some directory\t/some_dir\tlocalhost\t70\t+");          # 330
	ok($items[2]->as_url, 'gopher://localhost:70/1/some_dir%09%09+'); # 331

	{
		my $request = $items[2]->as_request;

		ok($request->as_string, "/some_dir	+$CRLF");   # 332
		ok($request->as_url,
			'gopher://localhost:70/1/some_dir%09%09+'); # 333
		ok($request->request_type, GOPHER_PLUS_REQUEST);    # 334
		ok($request->host, 'localhost');                    # 335
		ok($request->port, 70);                             # 336
		ok($request->selector, '/some_dir');                # 337
		ok(!defined $request->search_words);                # 338
		ok(!defined $request->representation);              # 339
		ok(!defined $request->data_block);                  # 340
		ok(!defined $request->attributes);                  # 341
		ok($request->item_type, GOPHER_MENU_TYPE);          # 342
	}



	ok($items[3]->item_type, GOPHER_MENU_TYPE);                          # 343
	ok($items[3]->display, 'Some other directory');                      # 344
	ok($items[3]->selector, '/some_other_dir');                          # 345
	ok($items[3]->host, 'localhost');                                    # 346
	ok($items[3]->port, '70');                                           # 347
	ok($items[3]->gopher_plus, '+');                                     # 348
	ok($items[3]->as_string,
		"1Some other directory\t/some_other_dir\tlocalhost\t70\t+"); # 349
	ok($items[3]->as_url,
		'gopher://localhost:70/1/some_other_dir%09%09+');            # 350

	{
		my $request = $items[3]->as_request;

		ok($request->as_string, "/some_other_dir	+$CRLF"); # 351
		ok($request->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 352
		ok($request->request_type, GOPHER_PLUS_REQUEST);          # 353
		ok($request->host, 'localhost');                          # 354
		ok($request->port, 70);                                   # 355
		ok($request->selector, '/some_other_dir');                # 356
		ok(!defined $request->search_words);                      # 357
		ok(!defined $request->representation);                    # 358
		ok(!defined $request->data_block);                        # 359
		ok(!defined $request->attributes);                        # 360
		ok($request->item_type, GOPHER_MENU_TYPE);                # 361
	}



	ok($items[4]->item_type, GIF_IMAGE_TYPE);              # 362
	ok($items[4]->display, 'A GIF image');                 # 363
	ok($items[4]->selector, '/image.gif');                 # 364
	ok($items[4]->host, 'localhost');                      # 365
	ok($items[4]->port, '70');                             # 366
	ok($items[4]->gopher_plus, '+');                       # 367
	ok($items[4]->as_string,
		"gA GIF image\t/image.gif\tlocalhost\t70\t+"); # 368
	ok($items[4]->as_url,
		'gopher://localhost:70/g/image.gif%09%09+');   # 369

	{
		my $request = $items[4]->as_request;

		ok($request->as_string, "/image.gif	+$CRLF");    # 370
		ok($request->as_url,
			'gopher://localhost:70/g/image.gif%09%09+'); # 371
		ok($request->request_type, GOPHER_PLUS_REQUEST);     # 372
		ok($request->host, 'localhost');                     # 373
		ok($request->port, 70);                              # 374
		ok($request->selector, '/image.gif');                # 375
		ok(!defined $request->search_words);                 # 376
		ok(!defined $request->representation);               # 377
		ok(!defined $request->data_block);                   # 378
		ok(!defined $request->attributes);                   # 379
		ok($request->item_type, GIF_IMAGE_TYPE);             # 380
	}



	ok($items[5]->item_type, INLINE_TEXT_TYPE);             # 381
	ok($items[5]->display, 'Fill out this form:');          # 382
	ok($items[5]->selector, '');                            # 383
	ok($items[5]->host, '');                                # 384
	ok($items[5]->port, '');                                # 385
	ok(!defined $items[5]->gopher_plus);                    # 386
	ok($items[5]->as_string, "iFill out this form:\t\t\t"); # 387
	ok($items[5]->as_url, "gopher://:/i");                  # 388

	{
		my $request = $items[5]->as_request;

		ok($request->as_string, "$CRLF");           # 389
		ok($request->as_url,'gopher://:70/i');      # 390
		ok($request->request_type, GOPHER_REQUEST); # 391
		ok($request->host, '');                     # 392
		ok($request->port, 70);                     # 393
		ok($request->selector, '');                 # 394
		ok(!defined $request->search_words);        # 395
		ok(!defined $request->representation);      # 396
		ok(!defined $request->data_block);          # 397
		ok(!defined $request->attributes);          # 398
		ok($request->item_type, INLINE_TEXT_TYPE);  # 399
	}



	ok($items[6]->item_type, GOPHER_MENU_TYPE);             # 400
	ok($items[6]->display, 'Application');                  # 401
	ok($items[6]->selector, '/ask_script');                 # 402
	ok($items[6]->host, 'localhost');                       # 403
	ok($items[6]->port, '70');                              # 404
	ok($items[6]->gopher_plus, '?');                        # 405
	ok($items[6]->as_string,
		"1Application\t/ask_script\tlocalhost\t70\t?"); # 406
	ok($items[6]->as_url,
		'gopher://localhost:70/1/ask_script%09%09?');   # 407

	{
		my $request = $items[6]->as_request;

		ok($request->as_string, "/ask_script	+$CRLF");     # 408
		ok($request->as_url,
			'gopher://localhost:70/1/ask_script%09%09+'); # 409
		ok($request->request_type, GOPHER_PLUS_REQUEST);      # 410
		ok($request->host, 'localhost');                      # 411
		ok($request->port, 70);                               # 412
		ok($request->selector, '/ask_script');                # 413
		ok(!defined $request->search_words);                  # 414
		ok(!defined $request->representation);                # 415
		ok(!defined $request->data_block);                    # 416
		ok(!defined $request->attributes);                    # 417
		ok($request->item_type, GOPHER_MENU_TYPE);            # 418
	}

	ok(scalar @items, 7); # 419





	{
		my @of_types = $response->extract_items(
			OfTypes => [INLINE_TEXT_TYPE]
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE); # 420
		ok($of_types[0]->display,
			'This is a Gopher+ style Gopher menu, where all of ' .
			'the items have a fifth field');       # 421
		ok($of_types[0]->selector, '');                # 422
		ok($of_types[0]->host, '');                    # 423
		ok($of_types[0]->port, '');                    # 424
		ok(!defined $of_types[0]->gopher_plus);        # 425
		ok($of_types[0]->as_string,
			"iThis is a Gopher+ style Gopher menu, where all of " .
			"the items have a fifth field\t\t\t"); # 426
		ok($of_types[0]->as_url, "gopher://:/i");      # 427

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);    # 428
		ok($of_types[1]->display,
			'containing a + or ? character.');        # 429
		ok($of_types[1]->selector, '');                   # 430
		ok($of_types[1]->host, '');                       # 431
		ok($of_types[1]->port, '');                       # 432
		ok(!defined $of_types[1]->gopher_plus);           # 433
		ok($of_types[1]->as_string,
			"icontaining a + or ? character.\t\t\t"); # 434
		ok($of_types[1]->as_url, "gopher://:/i");         # 435

		ok($of_types[2]->item_type, INLINE_TEXT_TYPE);             # 436
		ok($of_types[2]->display, 'Fill out this form:');          # 437
		ok($of_types[2]->selector, '');                            # 438
		ok($of_types[2]->host, '');                                # 439
		ok($of_types[2]->port, '');                                # 440
		ok(!defined $of_types[2]->gopher_plus);                    # 441
		ok($of_types[2]->as_string, "iFill out this form:\t\t\t"); # 442
		ok($of_types[2]->as_url, "gopher://:/i");                  # 443

		ok(scalar @of_types, 3); # 444
	}

	{
		my @of_types = $response->extract_items(
			OfTypes => 'i1'
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE); # 445
		ok($of_types[0]->display,
			'This is a Gopher+ style Gopher menu, where all of ' .
			'the items have a fifth field');       # 446
		ok($of_types[0]->selector, '');                # 447
		ok($of_types[0]->host, '');                    # 448
		ok($of_types[0]->port, '');                    # 449
		ok(!defined $of_types[0]->gopher_plus);        # 450
		ok($of_types[0]->as_string,
			"iThis is a Gopher+ style Gopher menu, where all of " .
			"the items have a fifth field\t\t\t"); # 451
		ok($of_types[0]->as_url, "gopher://:/i");      # 452

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);    # 453
		ok($of_types[1]->display,
			'containing a + or ? character.');        # 454
		ok($of_types[1]->selector, '');                   # 455
		ok($of_types[1]->host, '');                       # 456
		ok($of_types[1]->port, '');                       # 457
		ok(!defined $of_types[1]->gopher_plus);           # 458
		ok($of_types[1]->as_string,
			"icontaining a + or ? character.\t\t\t"); # 459
		ok($of_types[1]->as_url, "gopher://:/i");         # 460

		ok($of_types[2]->item_type, GOPHER_MENU_TYPE);           # 461
		ok($of_types[2]->display, 'Some directory');             # 462
		ok($of_types[2]->selector, '/some_dir');                 # 463
		ok($of_types[2]->host, 'localhost');                     # 464
		ok($of_types[2]->port, '70');                            # 465
		ok($of_types[2]->gopher_plus, '+');                      # 466
		ok($of_types[2]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 467
		ok($of_types[2]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 468

		ok($of_types[3]->item_type, GOPHER_MENU_TYPE);            # 469
		ok($of_types[3]->display, 'Some other directory');        # 470
		ok($of_types[3]->selector, '/some_other_dir');            # 471
		ok($of_types[3]->host, 'localhost');                      # 472
		ok($of_types[3]->port, '70');                             # 473
		ok($of_types[3]->gopher_plus, '+');                       # 474
		ok($of_types[3]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 475
		ok($of_types[3]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 476

		ok($of_types[4]->item_type, INLINE_TEXT_TYPE);             # 477
		ok($of_types[4]->display, 'Fill out this form:');          # 478
		ok($of_types[4]->selector, '');                            # 479
		ok($of_types[4]->host, '');                                # 480
		ok($of_types[4]->port, '');                                # 481
		ok(!defined $of_types[4]->gopher_plus);                    # 482
		ok($of_types[4]->as_string, "iFill out this form:\t\t\t"); # 483
		ok($of_types[4]->as_url, "gopher://:/i");                  # 484

		ok($of_types[5]->item_type, GOPHER_MENU_TYPE);          # 485
		ok($of_types[5]->display, 'Application');               # 486
		ok($of_types[5]->selector, '/ask_script');              # 487
		ok($of_types[5]->host, 'localhost');                    # 488
		ok($of_types[5]->port, '70');                           # 489
		ok($of_types[5]->gopher_plus, '?');                     # 490
		ok($of_types[5]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 491
		ok($of_types[5]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 492

		ok(scalar @of_types, 6); # 493
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => [INLINE_TEXT_TYPE]
		);

		ok($except_types[0]->item_type, GOPHER_MENU_TYPE);       # 494
		ok($except_types[0]->display, 'Some directory');         # 495
		ok($except_types[0]->selector, '/some_dir');             # 496
		ok($except_types[0]->host, 'localhost');                 # 497
		ok($except_types[0]->port, '70');                        # 498
		ok($except_types[0]->gopher_plus, '+');                  # 499
		ok($except_types[0]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 500
		ok($except_types[0]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 501

		ok($except_types[1]->item_type, GOPHER_MENU_TYPE);        # 502
		ok($except_types[1]->display, 'Some other directory');    # 503
		ok($except_types[1]->selector, '/some_other_dir');        # 504
		ok($except_types[1]->host, 'localhost');                  # 505
		ok($except_types[1]->port, '70');                         # 506
		ok($except_types[1]->gopher_plus, '+');                   # 507
		ok($except_types[1]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 508
		ok($except_types[1]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 509

		ok($except_types[2]->item_type, GIF_IMAGE_TYPE);       # 510
		ok($except_types[2]->display, 'A GIF image');          # 511
		ok($except_types[2]->selector, '/image.gif');          # 512
		ok($except_types[2]->host, 'localhost');               # 513
		ok($except_types[2]->port, '70');                      # 514
		ok($except_types[2]->gopher_plus, '+');                # 515
		ok($except_types[2]->as_string,
			"gA GIF image\t/image.gif\tlocalhost\t70\t+"); # 516
		ok($except_types[2]->as_url,
			'gopher://localhost:70/g/image.gif%09%09+');   # 517

		ok($except_types[3]->item_type, GOPHER_MENU_TYPE);      # 518
		ok($except_types[3]->display, 'Application');           # 519
		ok($except_types[3]->selector, '/ask_script');          # 520
		ok($except_types[3]->host, 'localhost');                # 521
		ok($except_types[3]->port, '70');                       # 522
		ok($except_types[3]->gopher_plus, '?');                 # 523
		ok($except_types[3]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 524
		ok($except_types[3]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 525

		ok(scalar @except_types, 4); # 526
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => ['gi']
		);

		ok($except_types[0]->item_type, GOPHER_MENU_TYPE);       # 527
		ok($except_types[0]->display, 'Some directory');         # 528
		ok($except_types[0]->selector, '/some_dir');             # 529
		ok($except_types[0]->host, 'localhost');                 # 530
		ok($except_types[0]->port, '70');                        # 531
		ok($except_types[0]->gopher_plus, '+');                  # 532
		ok($except_types[0]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 533
		ok($except_types[0]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 534

		ok($except_types[1]->item_type, GOPHER_MENU_TYPE);        # 535
		ok($except_types[1]->display, 'Some other directory');    # 536
		ok($except_types[1]->selector, '/some_other_dir');        # 537
		ok($except_types[1]->host, 'localhost');                  # 538
		ok($except_types[1]->port, '70');                         # 539
		ok($except_types[1]->gopher_plus, '+');                   # 540
		ok($except_types[1]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 541
		ok($except_types[1]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 542

		ok($except_types[2]->item_type, GOPHER_MENU_TYPE);      # 543
		ok($except_types[2]->display, 'Application');           # 544
		ok($except_types[2]->selector, '/ask_script');          # 545
		ok($except_types[2]->host, 'localhost');                # 546
		ok($except_types[2]->port, '70');                       # 547
		ok($except_types[2]->gopher_plus, '?');                 # 548
		ok($except_types[2]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 549
		ok($except_types[2]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 550

		ok(scalar @except_types, 3); # 551
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => 'i1g'
		);

		ok(scalar @except_types, 0); # 552
	}





	{
		my (@warnings, @fatal_errors);

		my $ng = new Net::Gopher(
			WarnHandler => sub { push(@warnings, @_) },
			DieHandler  => sub { push(@fatal_errors, @_) }
		);

		$ng->gopher(
			Host     => 'localhost',
			Selector => '/malformed_menu'
		)->extract_items;

		ok(scalar @warnings, 0);     # 553
		ok(scalar @fatal_errors, 1); # 554
		ok($fatal_errors[0],
			join(' ',
				'Menu item 2 lacks the following required',
				'fields: a selector string field, a host',
				'field, a port field. The response either',
				'does not contain a Gopher menu or contains',
				'a malformed Gopher menu.'
			)
		);                           # 555
	}

	{
		my (@warnings, @fatal_errors);

		my $ng = new Net::Gopher(
			WarnHandler => sub { push(@warnings, @_) },
			DieHandler  => sub { push(@fatal_errors, @_) }
		);

		$ng->gopher_plus(
			Host     => 'localhost',
			Selector => '/gp_s_no_term'
		)->extract_items;

		ok(scalar @warnings, 0);     # 556
		ok(scalar @fatal_errors, 1); # 557
		ok($fatal_errors[0],
			join(' ',
				'Menu item 1 lacks the following required',
				'fields: a selector string field, a host',
				'field, a port field. The response either',
				'does not contain a Gopher menu or contains',
				'a malformed Gopher menu.'
			)
		);                           # 558
	}
}





ok(kill_server()); # 559
