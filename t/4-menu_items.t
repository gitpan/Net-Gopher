use strict;
use warnings;
use Test;

BEGIN { plan(tests => 557) }

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

run_server();

{
	my $ng = new Net::Gopher (WarnHandler => sub {});

	my $response = $ng->gopher(
		Host     => 'localhost',
		Selector => '/index'
	);

	ok($response->is_success); # 13

	my @items = $response->extract_items;



	ok($items[0]->item_type, INLINE_TEXT_TYPE);                # 14
	ok($items[0]->display, 'This is a Gopher menu.');          # 15
	ok($items[0]->selector, '');                               # 16
	ok($items[0]->host, '');                                   # 17
	ok($items[0]->port, '');                                   # 18
	ok(!defined $items[0]->gopher_plus);                       # 19
	ok($items[0]->as_string, "iThis is a Gopher menu.\t\t\t"); # 20
	ok($items[0]->as_url, "gopher://:/i");                     # 21

	{
		my $request = $items[0]->as_request;

		ok($request->as_string, "$CRLF");           # 22
		ok($request->as_url, 'gopher://:70/i');     # 23
		ok($request->request_type, GOPHER_REQUEST); # 24
		ok($request->host, '');                     # 25
		ok($request->port, 70);                     # 26
		ok($request->selector, '');                 # 27
		ok(!defined $request->search_words);        # 28
		ok(!defined $request->representation);      # 29
		ok(!defined $request->data_block);          # 30
		ok(!defined $request->attributes);          # 31
		ok($request->item_type, INLINE_TEXT_TYPE);  # 32
	}



	ok($items[1]->item_type, GOPHER_MENU_TYPE);                       # 33
	ok($items[1]->display, 'Item one');                               # 34
	ok($items[1]->selector, '/directory');                            # 35
	ok($items[1]->host, 'localhost');                                 # 36
	ok($items[1]->port, '70');                                        # 37
	ok(!defined $items[1]->gopher_plus);                              # 38
	ok($items[1]->as_string, "1Item one\t/directory\tlocalhost\t70"); # 39
	ok($items[1]->as_url, "gopher://localhost:70/1/directory");       # 40

	{
		my $request = $items[1]->as_request;

		ok($request->as_string, "/directory$CRLF");                # 41
		ok($request->as_url, 'gopher://localhost:70/1/directory'); # 42
		ok($request->request_type, GOPHER_REQUEST);                # 43
		ok($request->host, 'localhost');                           # 44
		ok($request->port, 70);                                    # 45
		ok($request->selector, '/directory');                      # 46
		ok(!defined $request->search_words);                       # 47
		ok(!defined $request->representation);                     # 48
		ok(!defined $request->data_block);                         # 49
		ok(!defined $request->attributes);                         # 50
		ok($request->item_type, GOPHER_MENU_TYPE);                 # 51
	}



	ok($items[2]->item_type, GOPHER_MENU_TYPE);              # 52
	ok($items[2]->display, 'Item two');                      # 53
	ok($items[2]->selector, '/another_directory');           # 54
	ok($items[2]->host, 'localhost');                        # 55
	ok($items[2]->port, '70');                               # 56
	ok(!defined $items[2]->gopher_plus);                     # 57
	ok($items[2]->as_string,
		"1Item two\t/another_directory\tlocalhost\t70"); # 58
	ok($items[2]->as_url,
		"gopher://localhost:70/1/another_directory");    # 59

	{
		my $request = $items[2]->as_request;

		ok($request->as_string, "/another_directory$CRLF");   # 60
		ok($request->as_url,
			'gopher://localhost:70/1/another_directory'); # 61
		ok($request->request_type, GOPHER_REQUEST);           # 62
		ok($request->host, 'localhost');                      # 63
		ok($request->port, 70);                               # 64
		ok($request->selector, '/another_directory');         # 65
		ok(!defined $request->search_words);                  # 66
		ok(!defined $request->representation);                # 67
		ok(!defined $request->data_block);                    # 68
		ok(!defined $request->attributes);                    # 69
		ok($request->item_type, GOPHER_MENU_TYPE);            # 70
	}



	ok($items[3]->item_type, TEXT_FILE_TYPE);                           # 71
	ok($items[3]->display, 'Item three');                               # 72
	ok($items[3]->selector, '/three.txt');                              # 73
	ok($items[3]->host, 'localhost');                                   # 74
	ok($items[3]->port, '70');                                          # 75
	ok(!defined $items[3]->gopher_plus);                                # 76
	ok($items[3]->as_string, "0Item three\t/three.txt\tlocalhost\t70"); # 77
	ok($items[3]->as_url, "gopher://localhost:70/0/three.txt");         # 78

	{
		my $request = $items[3]->as_request;

		ok($request->as_string, "/three.txt$CRLF");                # 79
		ok($request->as_url, 'gopher://localhost:70/0/three.txt'); # 80
		ok($request->request_type, GOPHER_REQUEST);                # 81
		ok($request->host, 'localhost');                           # 82
		ok($request->port, 70);                                    # 83
		ok($request->selector, '/three.txt');                      # 84
		ok(!defined $request->search_words);                       # 85
		ok(!defined $request->representation);                     # 86
		ok(!defined $request->data_block);                         # 87
		ok(!defined $request->attributes);                         # 88
		ok($request->item_type, TEXT_FILE_TYPE);                   # 89
	}



	ok($items[4]->item_type, GOPHER_MENU_TYPE);                # 90
	ok($items[4]->display, 'Item four');                       # 91
	ok($items[4]->selector, '/one_more_directory');            # 92
	ok($items[4]->host, 'localhost');                          # 93
	ok($items[4]->port, '70');                                 # 94
	ok(!defined $items[4]->gopher_plus);                       # 95
	ok($items[4]->as_string,
		"1Item four\t/one_more_directory\tlocalhost\t70"); # 96
	ok($items[4]->as_url,
		"gopher://localhost:70/1/one_more_directory");     # 97

	{
		my $request = $items[4]->as_request;

		ok($request->as_string, "/one_more_directory$CRLF");   # 98
		ok($request->as_url,
			'gopher://localhost:70/1/one_more_directory'); # 99
		ok($request->request_type, GOPHER_REQUEST);            # 100
		ok($request->host, 'localhost');                       # 101
		ok($request->port, 70);                                # 102
		ok($request->selector, '/one_more_directory');         # 103
		ok(!defined $request->search_words);                   # 104
		ok(!defined $request->representation);                 # 105
		ok(!defined $request->data_block);                     # 106
		ok(!defined $request->attributes);                     # 107
		ok($request->item_type, GOPHER_MENU_TYPE);             # 108
	}



	ok($items[5]->item_type, INLINE_TEXT_TYPE);        # 109
	ok($items[5]->display, 'Download this:');          # 110
	ok($items[5]->selector, '');                       # 111
	ok($items[5]->host, '');                           # 112
	ok($items[5]->port, '');                           # 113
	ok(!defined $items[5]->gopher_plus);               # 114
	ok($items[5]->as_string, "iDownload this:\t\t\t"); # 115
	ok($items[5]->as_url, "gopher://:/i");             # 116

	{
		my $request = $items[5]->as_request;

		ok($request->as_string, "$CRLF");           # 117
		ok($request->as_url,'gopher://:70/i');      # 118
		ok($request->request_type, GOPHER_REQUEST); # 119
		ok($request->host, '');                     # 120
		ok($request->port, 70);                     # 121
		ok($request->selector, '');                 # 122
		ok(!defined $request->search_words);        # 123
		ok(!defined $request->representation);      # 124
		ok(!defined $request->data_block);          # 125
		ok(!defined $request->attributes);          # 126
		ok($request->item_type, INLINE_TEXT_TYPE);  # 127
	}



	ok($items[6]->item_type, GIF_IMAGE_TYPE);                          # 128
	ok($items[6]->display, 'GIF image');                               # 129
	ok($items[6]->selector, '/image.gif');                             # 130
	ok($items[6]->host, 'localhost');                                  # 131
	ok($items[6]->port, 70);                                           # 132
	ok(!defined $items[6]->gopher_plus);                               # 133
	ok($items[6]->as_string, "gGIF image\t/image.gif\tlocalhost\t70"); # 134
	ok($items[6]->as_url, "gopher://localhost:70/g/image.gif");        # 135

	{
		my $request = $items[6]->as_request;

		ok($request->as_string, "/image.gif$CRLF");               # 136
		ok($request->as_url,'gopher://localhost:70/g/image.gif'); # 137
		ok($request->request_type, GOPHER_REQUEST);               # 138
		ok($request->host, 'localhost');                          # 139
		ok($request->port, 70);                                   # 140
		ok($request->selector, '/image.gif');                     # 141
		ok(!defined $request->search_words);                      # 142
		ok(!defined $request->representation);                    # 143
		ok(!defined $request->data_block);                        # 144
		ok(!defined $request->attributes);                        # 145
		ok($request->item_type, GIF_IMAGE_TYPE);                  # 146
	}



	ok($items[7]->item_type, TEXT_FILE_TYPE);                       # 147
	ok($items[7]->display, 'Item six');                             # 148
	ok($items[7]->selector, '/six.txt');                            # 149
	ok($items[7]->host, 'localhost');                               # 150
	ok($items[7]->port, 70);                                        # 151
	ok(!defined $items[7]->gopher_plus);                            # 152
	ok($items[7]->as_string, "0Item six\t/six.txt\tlocalhost\t70"); # 153
	ok($items[7]->as_url, "gopher://localhost:70/0/six.txt");       # 154

	{
		my $request = $items[7]->as_request;

		ok($request->as_string, "/six.txt$CRLF");               # 155
		ok($request->as_url,'gopher://localhost:70/0/six.txt'); # 156
		ok($request->request_type, GOPHER_REQUEST);             # 157
		ok($request->host, 'localhost');                        # 158
		ok($request->port, 70);                                 # 159
		ok($request->selector, '/six.txt');                     # 160
		ok(!defined $request->search_words);                    # 161
		ok(!defined $request->representation);                  # 162
		ok(!defined $request->data_block);                      # 163
		ok(!defined $request->attributes);                      # 164
		ok($request->item_type, TEXT_FILE_TYPE);                # 165
	}

	ok(scalar @items, 8); # 166





	{
		my @of_types = $response->extract_items(
			OfTypes => INLINE_TEXT_TYPE
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE);       # 167
		ok($of_types[0]->display, 'This is a Gopher menu.'); # 168
		ok($of_types[0]->selector, '');                      # 169
		ok($of_types[0]->host, '');                          # 170
		ok($of_types[0]->port, '');                          # 171
		ok(!defined $of_types[0]->gopher_plus);              # 172
		ok($of_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");            # 173
		ok($of_types[0]->as_url, "gopher://:/i");            # 174

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);        # 175
		ok($of_types[1]->display, 'Download this:');          # 176
		ok($of_types[1]->selector, '');                       # 177
		ok($of_types[1]->host, '');                           # 178
		ok($of_types[1]->port, '');                           # 179
		ok(!defined $of_types[1]->gopher_plus);               # 180
		ok($of_types[1]->as_string, "iDownload this:\t\t\t"); # 181
		ok($of_types[1]->as_url, "gopher://:/i");             # 182

		ok(scalar @of_types, 2); # 183
	}

	{
		my @of_types = $response->extract_items(
			OfTypes => [INLINE_TEXT_TYPE, TEXT_FILE_TYPE]
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE);       # 184
		ok($of_types[0]->display, 'This is a Gopher menu.'); # 185
		ok($of_types[0]->selector, '');                      # 186
		ok($of_types[0]->host, '');                          # 187
		ok($of_types[0]->port, '');                          # 188
		ok(!defined $of_types[0]->gopher_plus);              # 189
		ok($of_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");            # 190
		ok($of_types[0]->as_url, "gopher://:/i");            # 191

		ok($of_types[1]->item_type, TEXT_FILE_TYPE);       # 192
		ok($of_types[1]->display, 'Item three');           # 193
		ok($of_types[1]->selector, '/three.txt');          # 194
		ok($of_types[1]->host, 'localhost');               # 195
		ok($of_types[1]->port, '70');                      # 196
		ok(!defined $of_types[1]->gopher_plus);            # 197
		ok($of_types[1]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 198
		ok($of_types[1]->as_url,
			"gopher://localhost:70/0/three.txt");      # 199

		ok($of_types[2]->item_type, INLINE_TEXT_TYPE);        # 200
		ok($of_types[2]->display, 'Download this:');          # 201
		ok($of_types[2]->selector, '');                       # 202
		ok($of_types[2]->host, '');                           # 203
		ok($of_types[2]->port, '');                           # 204
		ok(!defined $of_types[2]->gopher_plus);               # 205
		ok($of_types[2]->as_string, "iDownload this:\t\t\t"); # 206
		ok($of_types[2]->as_url, "gopher://:/i");             # 207

		ok($of_types[3]->item_type, TEXT_FILE_TYPE);   # 208
		ok($of_types[3]->display, 'Item six');         # 209
		ok($of_types[3]->selector, '/six.txt');        # 210
		ok($of_types[3]->host, 'localhost');           # 211
		ok($of_types[3]->port, 70);                    # 212
		ok(!defined $of_types[3]->gopher_plus);        # 213
		ok($of_types[3]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70"); # 214
		ok($of_types[3]->as_url,
			"gopher://localhost:70/0/six.txt");    # 215

		ok(scalar @of_types, 4); # 216
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => GOPHER_MENU_TYPE
		);

		ok($except_types[0]->item_type, INLINE_TEXT_TYPE);       # 217
		ok($except_types[0]->display, 'This is a Gopher menu.'); # 218
		ok($except_types[0]->selector, '');                      # 219
		ok($except_types[0]->host, '');                          # 220
		ok($except_types[0]->port, '');                          # 221
		ok(!defined $except_types[0]->gopher_plus);              # 222
		ok($except_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");                # 223
		ok($except_types[0]->as_url, "gopher://:/i");            # 224

		ok($except_types[1]->item_type, TEXT_FILE_TYPE);   # 225
		ok($except_types[1]->display, 'Item three');       # 226
		ok($except_types[1]->selector, '/three.txt');      # 227
		ok($except_types[1]->host, 'localhost');           # 228
		ok($except_types[1]->port, '70');                  # 229
		ok(!defined $except_types[1]->gopher_plus);        # 230
		ok($except_types[1]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 231
		ok($except_types[1]->as_url,
			"gopher://localhost:70/0/three.txt");      # 232

		ok($except_types[2]->item_type, INLINE_TEXT_TYPE);        # 233
		ok($except_types[2]->display, 'Download this:');          # 234
		ok($except_types[2]->selector, '');                       # 235
		ok($except_types[2]->host, '');                           # 236
		ok($except_types[2]->port, '');                           # 237
		ok(!defined $except_types[2]->gopher_plus);               # 238
		ok($except_types[2]->as_string, "iDownload this:\t\t\t"); # 239
		ok($except_types[2]->as_url, "gopher://:/i");             # 240

		ok($except_types[3]->item_type, GIF_IMAGE_TYPE);  # 241
		ok($except_types[3]->display, 'GIF image');       # 242
		ok($except_types[3]->selector, '/image.gif');     # 243
		ok($except_types[3]->host, 'localhost');          # 244
		ok($except_types[3]->port, 70);                   # 245
		ok(!defined $except_types[3]->gopher_plus);       # 246
		ok($except_types[3]->as_string,
			"gGIF image\t/image.gif\tlocalhost\t70"); # 247
		ok($except_types[3]->as_url,
			"gopher://localhost:70/g/image.gif");     # 248

		ok($except_types[4]->item_type, TEXT_FILE_TYPE); # 249
		ok($except_types[4]->display, 'Item six');       # 250
		ok($except_types[4]->selector, '/six.txt');      # 251
		ok($except_types[4]->host, 'localhost');         # 252
		ok($except_types[4]->port, 70);                  # 253
		ok(!defined $except_types[4]->gopher_plus);      # 254
		ok($except_types[4]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70");   # 255
		ok($except_types[4]->as_url,
			"gopher://localhost:70/0/six.txt");      # 256

		ok(scalar @except_types, 5); # 257
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => [GOPHER_MENU_TYPE, INLINE_TEXT_TYPE]
		);

		ok($except_types[0]->item_type, TEXT_FILE_TYPE);   # 258
		ok($except_types[0]->display, 'Item three');       # 259
		ok($except_types[0]->selector, '/three.txt');      # 260
		ok($except_types[0]->host, 'localhost');           # 261
		ok($except_types[0]->port, '70');                  # 262
		ok(!defined $except_types[0]->gopher_plus);        # 263
		ok($except_types[0]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 264
		ok($except_types[0]->as_url,
			"gopher://localhost:70/0/three.txt");      # 265

		ok($except_types[1]->item_type, GIF_IMAGE_TYPE);  # 266
		ok($except_types[1]->display, 'GIF image');       # 267
		ok($except_types[1]->selector, '/image.gif');     # 268
		ok($except_types[1]->host, 'localhost');          # 269
		ok($except_types[1]->port, 70);                   # 270
		ok(!defined $except_types[1]->gopher_plus);       # 271
		ok($except_types[1]->as_string,
			"gGIF image\t/image.gif\tlocalhost\t70"); # 272
		ok($except_types[1]->as_url,
			"gopher://localhost:70/g/image.gif");     # 273

		ok($except_types[2]->item_type, TEXT_FILE_TYPE); # 274
		ok($except_types[2]->display, 'Item six');       # 275
		ok($except_types[2]->selector, '/six.txt');      # 276
		ok($except_types[2]->host, 'localhost');         # 277
		ok($except_types[2]->port, 70);                  # 278
		ok(!defined $except_types[2]->gopher_plus);      # 279
		ok($except_types[2]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70");   # 280
		ok($except_types[2]->as_url,
			"gopher://localhost:70/0/six.txt");      # 281

		ok(scalar @except_types, 3); # 282
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => 'i10g'
		);

		ok(scalar @except_types, 0); # 283
	}
}










{
	my $ng = new Net::Gopher (WarnHandler => sub {});

	my $response = $ng->gopher_plus(
		Host     => 'localhost',
		Selector => '/gp_index'
	);

	ok($response->is_success); # 284

	my @items = $response->extract_items;



	ok($items[0]->item_type, INLINE_TEXT_TYPE); # 285
	ok($items[0]->display,
		'This is a Gopher+ style Gopher menu, where all of the '. 
		'items have a fifth field');        # 286
	ok($items[0]->selector, '');                # 287
	ok($items[0]->host, '');                    # 288
	ok($items[0]->port, '');                    # 289
	ok(!defined $items[0]->gopher_plus);        # 290
	ok($items[0]->as_string,
		"iThis is a Gopher+ style Gopher menu, where all of the " .
		"items have a fifth field\t\t\t");  # 291
	ok($items[0]->as_url, "gopher://:/i");      # 292

	{
		my $request = $items[0]->as_request;

		ok($request->as_string, "$CRLF");           # 293
		ok($request->as_url, 'gopher://:70/i');     # 294
		ok($request->request_type, GOPHER_REQUEST); # 295
		ok($request->host, '');                     # 296
		ok($request->port, 70);                     # 297
		ok($request->selector, '');                 # 298
		ok(!defined $request->search_words);        # 299
		ok(!defined $request->representation);      # 300
		ok(!defined $request->data_block);          # 301
		ok(!defined $request->attributes);          # 302
		ok($request->item_type, INLINE_TEXT_TYPE);  # 303
	}



	ok($items[1]->item_type, INLINE_TEXT_TYPE);                        # 304
	ok($items[1]->display, 'containing a + or ? character.');          # 305
	ok($items[1]->selector, '');                                       # 306
	ok($items[1]->host, '');                                           # 307
	ok($items[1]->port, '');                                           # 308
	ok(!defined $items[1]->gopher_plus);                               # 309
	ok($items[1]->as_string, "icontaining a + or ? character.\t\t\t"); # 310
	ok($items[1]->as_url, "gopher://:/i");                             # 311

	{
		my $request = $items[1]->as_request;

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



	ok($items[2]->item_type, GOPHER_MENU_TYPE);                       # 323
	ok($items[2]->display, 'Some directory');                         # 324
	ok($items[2]->selector, '/some_dir');                             # 325
	ok($items[2]->host, 'localhost');                                 # 326
	ok($items[2]->port, '70');                                        # 327
	ok($items[2]->gopher_plus, '+');                                  # 328
	ok($items[2]->as_string,
		"1Some directory\t/some_dir\tlocalhost\t70\t+");          # 329
	ok($items[2]->as_url, 'gopher://localhost:70/1/some_dir%09%09+'); # 330

	{
		my $request = $items[2]->as_request;

		ok($request->as_string, "/some_dir	+$CRLF");   # 331
		ok($request->as_url,
			'gopher://localhost:70/1/some_dir%09%09+'); # 332
		ok($request->request_type, GOPHER_PLUS_REQUEST);    # 333
		ok($request->host, 'localhost');                    # 334
		ok($request->port, 70);                             # 335
		ok($request->selector, '/some_dir');                # 336
		ok(!defined $request->search_words);                # 337
		ok(!defined $request->representation);              # 338
		ok(!defined $request->data_block);                  # 339
		ok(!defined $request->attributes);                  # 340
		ok($request->item_type, GOPHER_MENU_TYPE);          # 341
	}



	ok($items[3]->item_type, GOPHER_MENU_TYPE);                          # 342
	ok($items[3]->display, 'Some other directory');                      # 343
	ok($items[3]->selector, '/some_other_dir');                          # 344
	ok($items[3]->host, 'localhost');                                    # 345
	ok($items[3]->port, '70');                                           # 346
	ok($items[3]->gopher_plus, '+');                                     # 347
	ok($items[3]->as_string,
		"1Some other directory\t/some_other_dir\tlocalhost\t70\t+"); # 348
	ok($items[3]->as_url,
		'gopher://localhost:70/1/some_other_dir%09%09+');            # 349

	{
		my $request = $items[3]->as_request;

		ok($request->as_string, "/some_other_dir	+$CRLF"); # 350
		ok($request->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 351
		ok($request->request_type, GOPHER_PLUS_REQUEST);          # 352
		ok($request->host, 'localhost');                          # 353
		ok($request->port, 70);                                   # 354
		ok($request->selector, '/some_other_dir');                # 355
		ok(!defined $request->search_words);                      # 356
		ok(!defined $request->representation);                    # 357
		ok(!defined $request->data_block);                        # 358
		ok(!defined $request->attributes);                        # 359
		ok($request->item_type, GOPHER_MENU_TYPE);                # 360
	}



	ok($items[4]->item_type, GIF_IMAGE_TYPE);              # 361
	ok($items[4]->display, 'A GIF image');                 # 362
	ok($items[4]->selector, '/image.gif');                 # 363
	ok($items[4]->host, 'localhost');                      # 364
	ok($items[4]->port, '70');                             # 365
	ok($items[4]->gopher_plus, '+');                       # 366
	ok($items[4]->as_string,
		"gA GIF image\t/image.gif\tlocalhost\t70\t+"); # 367
	ok($items[4]->as_url,
		'gopher://localhost:70/g/image.gif%09%09+');   # 368

	{
		my $request = $items[4]->as_request;

		ok($request->as_string, "/image.gif	+$CRLF");    # 369
		ok($request->as_url,
			'gopher://localhost:70/g/image.gif%09%09+'); # 370
		ok($request->request_type, GOPHER_PLUS_REQUEST);     # 371
		ok($request->host, 'localhost');                     # 372
		ok($request->port, 70);                              # 373
		ok($request->selector, '/image.gif');                # 374
		ok(!defined $request->search_words);                 # 375
		ok(!defined $request->representation);               # 376
		ok(!defined $request->data_block);                   # 377
		ok(!defined $request->attributes);                   # 378
		ok($request->item_type, GIF_IMAGE_TYPE);             # 379
	}



	ok($items[5]->item_type, INLINE_TEXT_TYPE);             # 380
	ok($items[5]->display, 'Fill out this form:');          # 381
	ok($items[5]->selector, '');                            # 382
	ok($items[5]->host, '');                                # 383
	ok($items[5]->port, '');                                # 384
	ok(!defined $items[5]->gopher_plus);                    # 385
	ok($items[5]->as_string, "iFill out this form:\t\t\t"); # 386
	ok($items[5]->as_url, "gopher://:/i");                  # 387

	{
		my $request = $items[5]->as_request;

		ok($request->as_string, "$CRLF");           # 388
		ok($request->as_url,'gopher://:70/i');      # 389
		ok($request->request_type, GOPHER_REQUEST); # 390
		ok($request->host, '');                     # 391
		ok($request->port, 70);                     # 392
		ok($request->selector, '');                 # 393
		ok(!defined $request->search_words);        # 394
		ok(!defined $request->representation);      # 395
		ok(!defined $request->data_block);          # 396
		ok(!defined $request->attributes);          # 397
		ok($request->item_type, INLINE_TEXT_TYPE);  # 398
	}



	ok($items[6]->item_type, GOPHER_MENU_TYPE);             # 399
	ok($items[6]->display, 'Application');                  # 400
	ok($items[6]->selector, '/ask_script');                 # 401
	ok($items[6]->host, 'localhost');                       # 402
	ok($items[6]->port, '70');                              # 403
	ok($items[6]->gopher_plus, '?');                        # 404
	ok($items[6]->as_string,
		"1Application\t/ask_script\tlocalhost\t70\t?"); # 405
	ok($items[6]->as_url,
		'gopher://localhost:70/1/ask_script%09%09?');   # 406

	{
		my $request = $items[6]->as_request;

		ok($request->as_string, "/ask_script	+$CRLF");     # 407
		ok($request->as_url,
			'gopher://localhost:70/1/ask_script%09%09+'); # 408
		ok($request->request_type, GOPHER_PLUS_REQUEST);      # 409
		ok($request->host, 'localhost');                      # 410
		ok($request->port, 70);                               # 411
		ok($request->selector, '/ask_script');                # 412
		ok(!defined $request->search_words);                  # 413
		ok(!defined $request->representation);                # 414
		ok(!defined $request->data_block);                    # 415
		ok(!defined $request->attributes);                    # 416
		ok($request->item_type, GOPHER_MENU_TYPE);            # 417
	}

	ok(scalar @items, 7); # 418





	{
		my @of_types = $response->extract_items(
			OfTypes => [INLINE_TEXT_TYPE]
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE); # 419
		ok($of_types[0]->display,
			'This is a Gopher+ style Gopher menu, where all of ' .
			'the items have a fifth field');       # 420
		ok($of_types[0]->selector, '');                # 421
		ok($of_types[0]->host, '');                    # 422
		ok($of_types[0]->port, '');                    # 423
		ok(!defined $of_types[0]->gopher_plus);        # 424
		ok($of_types[0]->as_string,
			"iThis is a Gopher+ style Gopher menu, where all of " .
			"the items have a fifth field\t\t\t"); # 425
		ok($of_types[0]->as_url, "gopher://:/i");      # 426

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);    # 427
		ok($of_types[1]->display,
			'containing a + or ? character.');        # 428
		ok($of_types[1]->selector, '');                   # 429
		ok($of_types[1]->host, '');                       # 430
		ok($of_types[1]->port, '');                       # 431
		ok(!defined $of_types[1]->gopher_plus);           # 432
		ok($of_types[1]->as_string,
			"icontaining a + or ? character.\t\t\t"); # 433
		ok($of_types[1]->as_url, "gopher://:/i");         # 434

		ok($of_types[2]->item_type, INLINE_TEXT_TYPE);             # 435
		ok($of_types[2]->display, 'Fill out this form:');          # 436
		ok($of_types[2]->selector, '');                            # 437
		ok($of_types[2]->host, '');                                # 438
		ok($of_types[2]->port, '');                                # 439
		ok(!defined $of_types[2]->gopher_plus);                    # 440
		ok($of_types[2]->as_string, "iFill out this form:\t\t\t"); # 441
		ok($of_types[2]->as_url, "gopher://:/i");                  # 442

		ok(scalar @of_types, 3); # 443
	}

	{
		my @of_types = $response->extract_items(
			OfTypes => 'i1'
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE); # 444
		ok($of_types[0]->display,
			'This is a Gopher+ style Gopher menu, where all of ' .
			'the items have a fifth field');       # 445
		ok($of_types[0]->selector, '');                # 446
		ok($of_types[0]->host, '');                    # 447
		ok($of_types[0]->port, '');                    # 448
		ok(!defined $of_types[0]->gopher_plus);        # 449
		ok($of_types[0]->as_string,
			"iThis is a Gopher+ style Gopher menu, where all of " .
			"the items have a fifth field\t\t\t"); # 450
		ok($of_types[0]->as_url, "gopher://:/i");      # 451

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);    # 452
		ok($of_types[1]->display,
			'containing a + or ? character.');        # 453
		ok($of_types[1]->selector, '');                   # 454
		ok($of_types[1]->host, '');                       # 455
		ok($of_types[1]->port, '');                       # 456
		ok(!defined $of_types[1]->gopher_plus);           # 457
		ok($of_types[1]->as_string,
			"icontaining a + or ? character.\t\t\t"); # 458
		ok($of_types[1]->as_url, "gopher://:/i");         # 459

		ok($of_types[2]->item_type, GOPHER_MENU_TYPE);           # 460
		ok($of_types[2]->display, 'Some directory');             # 461
		ok($of_types[2]->selector, '/some_dir');                 # 462
		ok($of_types[2]->host, 'localhost');                     # 463
		ok($of_types[2]->port, '70');                            # 464
		ok($of_types[2]->gopher_plus, '+');                      # 465
		ok($of_types[2]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 466
		ok($of_types[2]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 467

		ok($of_types[3]->item_type, GOPHER_MENU_TYPE);            # 468
		ok($of_types[3]->display, 'Some other directory');        # 469
		ok($of_types[3]->selector, '/some_other_dir');            # 470
		ok($of_types[3]->host, 'localhost');                      # 471
		ok($of_types[3]->port, '70');                             # 472
		ok($of_types[3]->gopher_plus, '+');                       # 473
		ok($of_types[3]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 474
		ok($of_types[3]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 475

		ok($of_types[4]->item_type, INLINE_TEXT_TYPE);             # 476
		ok($of_types[4]->display, 'Fill out this form:');          # 477
		ok($of_types[4]->selector, '');                            # 478
		ok($of_types[4]->host, '');                                # 479
		ok($of_types[4]->port, '');                                # 480
		ok(!defined $of_types[4]->gopher_plus);                    # 481
		ok($of_types[4]->as_string, "iFill out this form:\t\t\t"); # 482
		ok($of_types[4]->as_url, "gopher://:/i");                  # 483

		ok($of_types[5]->item_type, GOPHER_MENU_TYPE);          # 484
		ok($of_types[5]->display, 'Application');               # 485
		ok($of_types[5]->selector, '/ask_script');              # 486
		ok($of_types[5]->host, 'localhost');                    # 487
		ok($of_types[5]->port, '70');                           # 488
		ok($of_types[5]->gopher_plus, '?');                     # 489
		ok($of_types[5]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 490
		ok($of_types[5]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 491

		ok(scalar @of_types, 6); # 492
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => [INLINE_TEXT_TYPE]
		);

		ok($except_types[0]->item_type, GOPHER_MENU_TYPE);       # 493
		ok($except_types[0]->display, 'Some directory');         # 494
		ok($except_types[0]->selector, '/some_dir');             # 495
		ok($except_types[0]->host, 'localhost');                 # 496
		ok($except_types[0]->port, '70');                        # 497
		ok($except_types[0]->gopher_plus, '+');                  # 498
		ok($except_types[0]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 499
		ok($except_types[0]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 500

		ok($except_types[1]->item_type, GOPHER_MENU_TYPE);        # 501
		ok($except_types[1]->display, 'Some other directory');    # 502
		ok($except_types[1]->selector, '/some_other_dir');        # 503
		ok($except_types[1]->host, 'localhost');                  # 504
		ok($except_types[1]->port, '70');                         # 505
		ok($except_types[1]->gopher_plus, '+');                   # 506
		ok($except_types[1]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 507
		ok($except_types[1]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 508

		ok($except_types[2]->item_type, GIF_IMAGE_TYPE);       # 509
		ok($except_types[2]->display, 'A GIF image');          # 510
		ok($except_types[2]->selector, '/image.gif');          # 511
		ok($except_types[2]->host, 'localhost');               # 512
		ok($except_types[2]->port, '70');                      # 513
		ok($except_types[2]->gopher_plus, '+');                # 514
		ok($except_types[2]->as_string,
			"gA GIF image\t/image.gif\tlocalhost\t70\t+"); # 515
		ok($except_types[2]->as_url,
			'gopher://localhost:70/g/image.gif%09%09+');   # 516

		ok($except_types[3]->item_type, GOPHER_MENU_TYPE);      # 517
		ok($except_types[3]->display, 'Application');           # 518
		ok($except_types[3]->selector, '/ask_script');          # 519
		ok($except_types[3]->host, 'localhost');                # 520
		ok($except_types[3]->port, '70');                       # 521
		ok($except_types[3]->gopher_plus, '?');                 # 522
		ok($except_types[3]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 523
		ok($except_types[3]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 524

		ok(scalar @except_types, 4); # 525
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => ['gi']
		);

		ok($except_types[0]->item_type, GOPHER_MENU_TYPE);       # 526
		ok($except_types[0]->display, 'Some directory');         # 527
		ok($except_types[0]->selector, '/some_dir');             # 528
		ok($except_types[0]->host, 'localhost');                 # 529
		ok($except_types[0]->port, '70');                        # 530
		ok($except_types[0]->gopher_plus, '+');                  # 531
		ok($except_types[0]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 532
		ok($except_types[0]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 533

		ok($except_types[1]->item_type, GOPHER_MENU_TYPE);        # 534
		ok($except_types[1]->display, 'Some other directory');    # 535
		ok($except_types[1]->selector, '/some_other_dir');        # 536
		ok($except_types[1]->host, 'localhost');                  # 537
		ok($except_types[1]->port, '70');                         # 538
		ok($except_types[1]->gopher_plus, '+');                   # 539
		ok($except_types[1]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 540
		ok($except_types[1]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 541

		ok($except_types[2]->item_type, GOPHER_MENU_TYPE);      # 542
		ok($except_types[2]->display, 'Application');           # 543
		ok($except_types[2]->selector, '/ask_script');          # 544
		ok($except_types[2]->host, 'localhost');                # 545
		ok($except_types[2]->port, '70');                       # 546
		ok($except_types[2]->gopher_plus, '?');                 # 547
		ok($except_types[2]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 548
		ok($except_types[2]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 549

		ok(scalar @except_types, 3); # 550
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => 'i1g'
		);

		ok(scalar @except_types, 0); # 551
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

		ok(scalar @warnings, 0);     # 552
		ok(scalar @fatal_errors, 1); # 553
		ok($fatal_errors[0],
			join(' ',
				'Menu item 2 lacks the following required',
				'fields: a selector string field, a host',
				'field, a port field. The response either',
				'does not contain a Gopher menu or contains',
				'a malformed Gopher menu.'
			)
		);                           # 554
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

		ok(scalar @warnings, 0);     # 555
		ok(scalar @fatal_errors, 1); # 556
		ok($fatal_errors[0],
			join(' ',
				'Menu item 1 lacks the following required',
				'fields: a selector string field, a host',
				'field, a port field. The response either',
				'does not contain a Gopher menu or contains',
				'a malformed Gopher menu.'
			)
		);                           # 557
	}
}





kill_server();
