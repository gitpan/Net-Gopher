use strict;
use warnings;
use Test;

BEGIN { plan(tests => 545) }

use Net::Gopher;
use Net::Gopher::Constants qw(:item_types :request :response);
use Net::Gopher::Utility qw($CRLF);

require './tests/serverfunctions.pl';







run_server();

################################################################################
#
# These tests make the sure the extract items method can properly parse Gopher
# menus.
#

{
	my $ng = new Net::Gopher (WarnHandler => sub {});

	my $response = $ng->gopher(
		Host     => 'localhost',
		Selector => '/index'
	);

	ok($response->is_success); # 1

	my @items = $response->extract_items;



	ok($items[0]->item_type, INLINE_TEXT_TYPE);                # 2
	ok($items[0]->display, 'This is a Gopher menu.');          # 3
	ok($items[0]->selector, '');                               # 4
	ok($items[0]->host, '');                                   # 5
	ok($items[0]->port, '');                                   # 6
	ok(!defined $items[0]->gopher_plus);                       # 7
	ok($items[0]->as_string, "iThis is a Gopher menu.\t\t\t"); # 8
	ok($items[0]->as_url, "gopher://:/i");                     # 9

	{
		my $request = $items[0]->as_request;

		ok($request->as_string, "$CRLF");           # 10
		ok($request->as_url, 'gopher://:70/i');     # 11
		ok($request->request_type, GOPHER_REQUEST); # 12
		ok($request->host, '');                     # 13
		ok($request->port, 70);                     # 14
		ok($request->selector, '');                 # 15
		ok(!defined $request->search_words);        # 16
		ok(!defined $request->representation);      # 17
		ok(!defined $request->data_block);          # 18
		ok(!defined $request->attributes);          # 19
		ok($request->item_type, INLINE_TEXT_TYPE);  # 20
	}



	ok($items[1]->item_type, GOPHER_MENU_TYPE);                       # 21
	ok($items[1]->display, 'Item one');                               # 22
	ok($items[1]->selector, '/directory');                            # 23
	ok($items[1]->host, 'localhost');                                 # 24
	ok($items[1]->port, '70');                                        # 25
	ok(!defined $items[1]->gopher_plus);                              # 26
	ok($items[1]->as_string, "1Item one\t/directory\tlocalhost\t70"); # 27
	ok($items[1]->as_url, "gopher://localhost:70/1/directory");       # 28

	{
		my $request = $items[1]->as_request;

		ok($request->as_string, "/directory$CRLF");                # 29
		ok($request->as_url, 'gopher://localhost:70/1/directory'); # 30
		ok($request->request_type, GOPHER_REQUEST);                # 31
		ok($request->host, 'localhost');                           # 32
		ok($request->port, 70);                                    # 33
		ok($request->selector, '/directory');                      # 34
		ok(!defined $request->search_words);                       # 35
		ok(!defined $request->representation);                     # 36
		ok(!defined $request->data_block);                         # 37
		ok(!defined $request->attributes);                         # 38
		ok($request->item_type, GOPHER_MENU_TYPE);                 # 39
	}



	ok($items[2]->item_type, GOPHER_MENU_TYPE);              # 40
	ok($items[2]->display, 'Item two');                      # 41
	ok($items[2]->selector, '/another_directory');           # 42
	ok($items[2]->host, 'localhost');                        # 43
	ok($items[2]->port, '70');                               # 44
	ok(!defined $items[2]->gopher_plus);                     # 45
	ok($items[2]->as_string,
		"1Item two\t/another_directory\tlocalhost\t70"); # 46
	ok($items[2]->as_url,
		"gopher://localhost:70/1/another_directory");    # 47

	{
		my $request = $items[2]->as_request;

		ok($request->as_string, "/another_directory$CRLF");   # 48
		ok($request->as_url,
			'gopher://localhost:70/1/another_directory'); # 49
		ok($request->request_type, GOPHER_REQUEST);           # 50
		ok($request->host, 'localhost');                      # 51
		ok($request->port, 70);                               # 52
		ok($request->selector, '/another_directory');         # 53
		ok(!defined $request->search_words);                  # 54
		ok(!defined $request->representation);                # 55
		ok(!defined $request->data_block);                    # 56
		ok(!defined $request->attributes);                    # 57
		ok($request->item_type, GOPHER_MENU_TYPE);            # 58
	}



	ok($items[3]->item_type, TEXT_FILE_TYPE);                           # 59
	ok($items[3]->display, 'Item three');                               # 60
	ok($items[3]->selector, '/three.txt');                              # 61
	ok($items[3]->host, 'localhost');                                   # 62
	ok($items[3]->port, '70');                                          # 63
	ok(!defined $items[3]->gopher_plus);                                # 64
	ok($items[3]->as_string, "0Item three\t/three.txt\tlocalhost\t70"); # 65
	ok($items[3]->as_url, "gopher://localhost:70/0/three.txt");         # 66

	{
		my $request = $items[3]->as_request;

		ok($request->as_string, "/three.txt$CRLF");                # 67
		ok($request->as_url, 'gopher://localhost:70/0/three.txt'); # 68
		ok($request->request_type, GOPHER_REQUEST);                # 69
		ok($request->host, 'localhost');                           # 70
		ok($request->port, 70);                                    # 71
		ok($request->selector, '/three.txt');                      # 72
		ok(!defined $request->search_words);                       # 73
		ok(!defined $request->representation);                     # 74
		ok(!defined $request->data_block);                         # 75
		ok(!defined $request->attributes);                         # 76
		ok($request->item_type, TEXT_FILE_TYPE);                   # 77
	}



	ok($items[4]->item_type, GOPHER_MENU_TYPE);                # 78
	ok($items[4]->display, 'Item four');                       # 79
	ok($items[4]->selector, '/one_more_directory');            # 80
	ok($items[4]->host, 'localhost');                          # 81
	ok($items[4]->port, '70');                                 # 82
	ok(!defined $items[4]->gopher_plus);                       # 83
	ok($items[4]->as_string,
		"1Item four\t/one_more_directory\tlocalhost\t70"); # 84
	ok($items[4]->as_url,
		"gopher://localhost:70/1/one_more_directory");     # 85

	{
		my $request = $items[4]->as_request;

		ok($request->as_string, "/one_more_directory$CRLF");   # 86
		ok($request->as_url,
			'gopher://localhost:70/1/one_more_directory'); # 87
		ok($request->request_type, GOPHER_REQUEST);            # 88
		ok($request->host, 'localhost');                       # 89
		ok($request->port, 70);                                # 90
		ok($request->selector, '/one_more_directory');         # 91
		ok(!defined $request->search_words);                   # 92
		ok(!defined $request->representation);                 # 93
		ok(!defined $request->data_block);                     # 94
		ok(!defined $request->attributes);                     # 95
		ok($request->item_type, GOPHER_MENU_TYPE);             # 96
	}



	ok($items[5]->item_type, INLINE_TEXT_TYPE);        # 97
	ok($items[5]->display, 'Download this:');          # 98
	ok($items[5]->selector, '');                       # 99
	ok($items[5]->host, '');                           # 100
	ok($items[5]->port, '');                           # 101
	ok(!defined $items[5]->gopher_plus);               # 102
	ok($items[5]->as_string, "iDownload this:\t\t\t"); # 103
	ok($items[5]->as_url, "gopher://:/i");             # 104

	{
		my $request = $items[5]->as_request;

		ok($request->as_string, "$CRLF");           # 105
		ok($request->as_url,'gopher://:70/i');      # 106
		ok($request->request_type, GOPHER_REQUEST); # 107
		ok($request->host, '');                     # 108
		ok($request->port, 70);                     # 109
		ok($request->selector, '');                 # 110
		ok(!defined $request->search_words);        # 111
		ok(!defined $request->representation);      # 112
		ok(!defined $request->data_block);          # 113
		ok(!defined $request->attributes);          # 114
		ok($request->item_type, INLINE_TEXT_TYPE);  # 115
	}



	ok($items[6]->item_type, GIF_IMAGE_TYPE);                          # 116
	ok($items[6]->display, 'GIF image');                               # 117
	ok($items[6]->selector, '/image.gif');                             # 118
	ok($items[6]->host, 'localhost');                                  # 119
	ok($items[6]->port, 70);                                           # 120
	ok(!defined $items[6]->gopher_plus);                               # 121
	ok($items[6]->as_string, "gGIF image\t/image.gif\tlocalhost\t70"); # 122
	ok($items[6]->as_url, "gopher://localhost:70/g/image.gif");        # 123

	{
		my $request = $items[6]->as_request;

		ok($request->as_string, "/image.gif$CRLF");               # 124
		ok($request->as_url,'gopher://localhost:70/g/image.gif'); # 125
		ok($request->request_type, GOPHER_REQUEST);               # 126
		ok($request->host, 'localhost');                          # 127
		ok($request->port, 70);                                   # 128
		ok($request->selector, '/image.gif');                     # 129
		ok(!defined $request->search_words);                      # 130
		ok(!defined $request->representation);                    # 131
		ok(!defined $request->data_block);                        # 132
		ok(!defined $request->attributes);                        # 133
		ok($request->item_type, GIF_IMAGE_TYPE);                  # 134
	}



	ok($items[7]->item_type, TEXT_FILE_TYPE);                       # 135
	ok($items[7]->display, 'Item six');                             # 136
	ok($items[7]->selector, '/six.txt');                            # 137
	ok($items[7]->host, 'localhost');                               # 138
	ok($items[7]->port, 70);                                        # 139
	ok(!defined $items[7]->gopher_plus);                            # 140
	ok($items[7]->as_string, "0Item six\t/six.txt\tlocalhost\t70"); # 141
	ok($items[7]->as_url, "gopher://localhost:70/0/six.txt");       # 142

	{
		my $request = $items[7]->as_request;

		ok($request->as_string, "/six.txt$CRLF");               # 143
		ok($request->as_url,'gopher://localhost:70/0/six.txt'); # 144
		ok($request->request_type, GOPHER_REQUEST);             # 145
		ok($request->host, 'localhost');                        # 146
		ok($request->port, 70);                                 # 147
		ok($request->selector, '/six.txt');                     # 148
		ok(!defined $request->search_words);                    # 149
		ok(!defined $request->representation);                  # 150
		ok(!defined $request->data_block);                      # 151
		ok(!defined $request->attributes);                      # 152
		ok($request->item_type, TEXT_FILE_TYPE);                # 153
	}

	ok(scalar @items, 8); # 154





	{
		my @of_types = $response->extract_items(
			OfTypes => INLINE_TEXT_TYPE
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE);       # 155
		ok($of_types[0]->display, 'This is a Gopher menu.'); # 156
		ok($of_types[0]->selector, '');                      # 157
		ok($of_types[0]->host, '');                          # 158
		ok($of_types[0]->port, '');                          # 159
		ok(!defined $of_types[0]->gopher_plus);              # 160
		ok($of_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");            # 161
		ok($of_types[0]->as_url, "gopher://:/i");            # 162

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);        # 163
		ok($of_types[1]->display, 'Download this:');          # 164
		ok($of_types[1]->selector, '');                       # 165
		ok($of_types[1]->host, '');                           # 166
		ok($of_types[1]->port, '');                           # 167
		ok(!defined $of_types[1]->gopher_plus);               # 168
		ok($of_types[1]->as_string, "iDownload this:\t\t\t"); # 169
		ok($of_types[1]->as_url, "gopher://:/i");             # 170

		ok(scalar @of_types, 2); # 171
	}

	{
		my @of_types = $response->extract_items(
			OfTypes => [INLINE_TEXT_TYPE, TEXT_FILE_TYPE]
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE);       # 172
		ok($of_types[0]->display, 'This is a Gopher menu.'); # 173
		ok($of_types[0]->selector, '');                      # 174
		ok($of_types[0]->host, '');                          # 175
		ok($of_types[0]->port, '');                          # 176
		ok(!defined $of_types[0]->gopher_plus);              # 177
		ok($of_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");            # 178
		ok($of_types[0]->as_url, "gopher://:/i");            # 179

		ok($of_types[1]->item_type, TEXT_FILE_TYPE);       # 180
		ok($of_types[1]->display, 'Item three');           # 181
		ok($of_types[1]->selector, '/three.txt');          # 182
		ok($of_types[1]->host, 'localhost');               # 183
		ok($of_types[1]->port, '70');                      # 184
		ok(!defined $of_types[1]->gopher_plus);            # 185
		ok($of_types[1]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 186
		ok($of_types[1]->as_url,
			"gopher://localhost:70/0/three.txt");      # 187

		ok($of_types[2]->item_type, INLINE_TEXT_TYPE);        # 188
		ok($of_types[2]->display, 'Download this:');          # 189
		ok($of_types[2]->selector, '');                       # 190
		ok($of_types[2]->host, '');                           # 191
		ok($of_types[2]->port, '');                           # 192
		ok(!defined $of_types[2]->gopher_plus);               # 193
		ok($of_types[2]->as_string, "iDownload this:\t\t\t"); # 194
		ok($of_types[2]->as_url, "gopher://:/i");             # 195

		ok($of_types[3]->item_type, TEXT_FILE_TYPE);   # 196
		ok($of_types[3]->display, 'Item six');         # 197
		ok($of_types[3]->selector, '/six.txt');        # 198
		ok($of_types[3]->host, 'localhost');           # 199
		ok($of_types[3]->port, 70);                    # 200
		ok(!defined $of_types[3]->gopher_plus);        # 201
		ok($of_types[3]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70"); # 202
		ok($of_types[3]->as_url,
			"gopher://localhost:70/0/six.txt");    # 203

		ok(scalar @of_types, 4); # 204
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => GOPHER_MENU_TYPE
		);

		ok($except_types[0]->item_type, INLINE_TEXT_TYPE);       # 205
		ok($except_types[0]->display, 'This is a Gopher menu.'); # 206
		ok($except_types[0]->selector, '');                      # 207
		ok($except_types[0]->host, '');                          # 208
		ok($except_types[0]->port, '');                          # 209
		ok(!defined $except_types[0]->gopher_plus);              # 210
		ok($except_types[0]->as_string,
			"iThis is a Gopher menu.\t\t\t");                # 211
		ok($except_types[0]->as_url, "gopher://:/i");            # 212

		ok($except_types[1]->item_type, TEXT_FILE_TYPE);   # 213
		ok($except_types[1]->display, 'Item three');       # 214
		ok($except_types[1]->selector, '/three.txt');      # 215
		ok($except_types[1]->host, 'localhost');           # 216
		ok($except_types[1]->port, '70');                  # 217
		ok(!defined $except_types[1]->gopher_plus);        # 218
		ok($except_types[1]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 219
		ok($except_types[1]->as_url,
			"gopher://localhost:70/0/three.txt");      # 220

		ok($except_types[2]->item_type, INLINE_TEXT_TYPE);        # 221
		ok($except_types[2]->display, 'Download this:');          # 222
		ok($except_types[2]->selector, '');                       # 223
		ok($except_types[2]->host, '');                           # 224
		ok($except_types[2]->port, '');                           # 225
		ok(!defined $except_types[2]->gopher_plus);               # 226
		ok($except_types[2]->as_string, "iDownload this:\t\t\t"); # 227
		ok($except_types[2]->as_url, "gopher://:/i");             # 228

		ok($except_types[3]->item_type, GIF_IMAGE_TYPE);  # 229
		ok($except_types[3]->display, 'GIF image');       # 230
		ok($except_types[3]->selector, '/image.gif');     # 231
		ok($except_types[3]->host, 'localhost');          # 232
		ok($except_types[3]->port, 70);                   # 233
		ok(!defined $except_types[3]->gopher_plus);       # 234
		ok($except_types[3]->as_string,
			"gGIF image\t/image.gif\tlocalhost\t70"); # 235
		ok($except_types[3]->as_url,
			"gopher://localhost:70/g/image.gif");     # 236

		ok($except_types[4]->item_type, TEXT_FILE_TYPE); # 237
		ok($except_types[4]->display, 'Item six');       # 238
		ok($except_types[4]->selector, '/six.txt');      # 239
		ok($except_types[4]->host, 'localhost');         # 240
		ok($except_types[4]->port, 70);                  # 241
		ok(!defined $except_types[4]->gopher_plus);      # 242
		ok($except_types[4]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70");   # 243
		ok($except_types[4]->as_url,
			"gopher://localhost:70/0/six.txt");      # 244

		ok(scalar @except_types, 5); # 245
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => [GOPHER_MENU_TYPE, INLINE_TEXT_TYPE]
		);

		ok($except_types[0]->item_type, TEXT_FILE_TYPE);   # 246
		ok($except_types[0]->display, 'Item three');       # 247
		ok($except_types[0]->selector, '/three.txt');      # 248
		ok($except_types[0]->host, 'localhost');           # 249
		ok($except_types[0]->port, '70');                  # 250
		ok(!defined $except_types[0]->gopher_plus);        # 251
		ok($except_types[0]->as_string,
			"0Item three\t/three.txt\tlocalhost\t70"); # 252
		ok($except_types[0]->as_url,
			"gopher://localhost:70/0/three.txt");      # 253

		ok($except_types[1]->item_type, GIF_IMAGE_TYPE);  # 254
		ok($except_types[1]->display, 'GIF image');       # 255
		ok($except_types[1]->selector, '/image.gif');     # 256
		ok($except_types[1]->host, 'localhost');          # 257
		ok($except_types[1]->port, 70);                   # 258
		ok(!defined $except_types[1]->gopher_plus);       # 259
		ok($except_types[1]->as_string,
			"gGIF image\t/image.gif\tlocalhost\t70"); # 260
		ok($except_types[1]->as_url,
			"gopher://localhost:70/g/image.gif");     # 261

		ok($except_types[2]->item_type, TEXT_FILE_TYPE); # 262
		ok($except_types[2]->display, 'Item six');       # 263
		ok($except_types[2]->selector, '/six.txt');      # 264
		ok($except_types[2]->host, 'localhost');         # 265
		ok($except_types[2]->port, 70);                  # 266
		ok(!defined $except_types[2]->gopher_plus);      # 267
		ok($except_types[2]->as_string,
			"0Item six\t/six.txt\tlocalhost\t70");   # 268
		ok($except_types[2]->as_url,
			"gopher://localhost:70/0/six.txt");      # 269

		ok(scalar @except_types, 3); # 270
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => 'i10g'
		);

		ok(scalar @except_types, 0); # 271
	}
}










{
	my $ng = new Net::Gopher (WarnHandler => sub {});

	my $response = $ng->gopher_plus(
		Host     => 'localhost',
		Selector => '/gp_index'
	);

	ok($response->is_success); # 272

	my @items = $response->extract_items;



	ok($items[0]->item_type, INLINE_TEXT_TYPE); # 273
	ok($items[0]->display,
		'This is a Gopher+ style Gopher menu, where all of the '. 
		'items have a fifth field');        # 274
	ok($items[0]->selector, '');                # 275
	ok($items[0]->host, '');                    # 276
	ok($items[0]->port, '');                    # 277
	ok(!defined $items[0]->gopher_plus);        # 278
	ok($items[0]->as_string,
		"iThis is a Gopher+ style Gopher menu, where all of the " .
		"items have a fifth field\t\t\t");  # 279
	ok($items[0]->as_url, "gopher://:/i");      # 280

	{
		my $request = $items[0]->as_request;

		ok($request->as_string, "$CRLF");           # 281
		ok($request->as_url, 'gopher://:70/i');     # 282
		ok($request->request_type, GOPHER_REQUEST); # 283
		ok($request->host, '');                     # 284
		ok($request->port, 70);                     # 285
		ok($request->selector, '');                 # 286
		ok(!defined $request->search_words);        # 287
		ok(!defined $request->representation);      # 288
		ok(!defined $request->data_block);          # 289
		ok(!defined $request->attributes);          # 290
		ok($request->item_type, INLINE_TEXT_TYPE);  # 291
	}



	ok($items[1]->item_type, INLINE_TEXT_TYPE);                        # 292
	ok($items[1]->display, 'containing a + or ? character.');          # 293
	ok($items[1]->selector, '');                                       # 294
	ok($items[1]->host, '');                                           # 295
	ok($items[1]->port, '');                                           # 296
	ok(!defined $items[1]->gopher_plus);                               # 297
	ok($items[1]->as_string, "icontaining a + or ? character.\t\t\t"); # 298
	ok($items[1]->as_url, "gopher://:/i");                             # 299

	{
		my $request = $items[1]->as_request;

		ok($request->as_string, "$CRLF");           # 300
		ok($request->as_url, 'gopher://:70/i');     # 301
		ok($request->request_type, GOPHER_REQUEST); # 302
		ok($request->host, '');                     # 303
		ok($request->port, 70);                     # 304
		ok($request->selector, '');                 # 305
		ok(!defined $request->search_words);        # 306
		ok(!defined $request->representation);      # 307
		ok(!defined $request->data_block);          # 308
		ok(!defined $request->attributes);          # 309
		ok($request->item_type, INLINE_TEXT_TYPE);  # 310
	}



	ok($items[2]->item_type, GOPHER_MENU_TYPE);                       # 311
	ok($items[2]->display, 'Some directory');                         # 312
	ok($items[2]->selector, '/some_dir');                             # 313
	ok($items[2]->host, 'localhost');                                 # 314
	ok($items[2]->port, '70');                                        # 315
	ok($items[2]->gopher_plus, '+');                                  # 316
	ok($items[2]->as_string,
		"1Some directory\t/some_dir\tlocalhost\t70\t+");          # 317
	ok($items[2]->as_url, 'gopher://localhost:70/1/some_dir%09%09+'); # 318

	{
		my $request = $items[2]->as_request;

		ok($request->as_string, "/some_dir	+$CRLF");   # 319
		ok($request->as_url,
			'gopher://localhost:70/1/some_dir%09%09+'); # 320
		ok($request->request_type, GOPHER_PLUS_REQUEST);    # 321
		ok($request->host, 'localhost');                    # 322
		ok($request->port, 70);                             # 323
		ok($request->selector, '/some_dir');                # 324
		ok(!defined $request->search_words);                # 325
		ok(!defined $request->representation);              # 326
		ok(!defined $request->data_block);                  # 327
		ok(!defined $request->attributes);                  # 328
		ok($request->item_type, GOPHER_MENU_TYPE);          # 329
	}



	ok($items[3]->item_type, GOPHER_MENU_TYPE);                          # 330
	ok($items[3]->display, 'Some other directory');                      # 331
	ok($items[3]->selector, '/some_other_dir');                          # 332
	ok($items[3]->host, 'localhost');                                    # 333
	ok($items[3]->port, '70');                                           # 334
	ok($items[3]->gopher_plus, '+');                                     # 335
	ok($items[3]->as_string,
		"1Some other directory\t/some_other_dir\tlocalhost\t70\t+"); # 336
	ok($items[3]->as_url,
		'gopher://localhost:70/1/some_other_dir%09%09+');            # 337

	{
		my $request = $items[3]->as_request;

		ok($request->as_string, "/some_other_dir	+$CRLF"); # 338
		ok($request->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 339
		ok($request->request_type, GOPHER_PLUS_REQUEST);          # 340
		ok($request->host, 'localhost');                          # 341
		ok($request->port, 70);                                   # 342
		ok($request->selector, '/some_other_dir');                # 343
		ok(!defined $request->search_words);                      # 344
		ok(!defined $request->representation);                    # 345
		ok(!defined $request->data_block);                        # 346
		ok(!defined $request->attributes);                        # 347
		ok($request->item_type, GOPHER_MENU_TYPE);                # 348
	}



	ok($items[4]->item_type, GIF_IMAGE_TYPE);              # 349
	ok($items[4]->display, 'A GIF image');                 # 350
	ok($items[4]->selector, '/image.gif');                 # 351
	ok($items[4]->host, 'localhost');                      # 352
	ok($items[4]->port, '70');                             # 353
	ok($items[4]->gopher_plus, '+');                       # 354
	ok($items[4]->as_string,
		"gA GIF image\t/image.gif\tlocalhost\t70\t+"); # 355
	ok($items[4]->as_url,
		'gopher://localhost:70/g/image.gif%09%09+');   # 356

	{
		my $request = $items[4]->as_request;

		ok($request->as_string, "/image.gif	+$CRLF");    # 357
		ok($request->as_url,
			'gopher://localhost:70/g/image.gif%09%09+'); # 358
		ok($request->request_type, GOPHER_PLUS_REQUEST);     # 359
		ok($request->host, 'localhost');                     # 360
		ok($request->port, 70);                              # 361
		ok($request->selector, '/image.gif');                # 362
		ok(!defined $request->search_words);                 # 363
		ok(!defined $request->representation);               # 364
		ok(!defined $request->data_block);                   # 365
		ok(!defined $request->attributes);                   # 366
		ok($request->item_type, GIF_IMAGE_TYPE);             # 367
	}



	ok($items[5]->item_type, INLINE_TEXT_TYPE);             # 368
	ok($items[5]->display, 'Fill out this form:');          # 369
	ok($items[5]->selector, '');                            # 370
	ok($items[5]->host, '');                                # 371
	ok($items[5]->port, '');                                # 372
	ok(!defined $items[5]->gopher_plus);                    # 373
	ok($items[5]->as_string, "iFill out this form:\t\t\t"); # 374
	ok($items[5]->as_url, "gopher://:/i");                  # 375

	{
		my $request = $items[5]->as_request;

		ok($request->as_string, "$CRLF");           # 376
		ok($request->as_url,'gopher://:70/i');      # 377
		ok($request->request_type, GOPHER_REQUEST); # 378
		ok($request->host, '');                     # 379
		ok($request->port, 70);                     # 380
		ok($request->selector, '');                 # 381
		ok(!defined $request->search_words);        # 382
		ok(!defined $request->representation);      # 383
		ok(!defined $request->data_block);          # 384
		ok(!defined $request->attributes);          # 385
		ok($request->item_type, INLINE_TEXT_TYPE);  # 386
	}



	ok($items[6]->item_type, GOPHER_MENU_TYPE);             # 387
	ok($items[6]->display, 'Application');                  # 388
	ok($items[6]->selector, '/ask_script');                 # 389
	ok($items[6]->host, 'localhost');                       # 390
	ok($items[6]->port, '70');                              # 391
	ok($items[6]->gopher_plus, '?');                        # 392
	ok($items[6]->as_string,
		"1Application\t/ask_script\tlocalhost\t70\t?"); # 393
	ok($items[6]->as_url,
		'gopher://localhost:70/1/ask_script%09%09?');   # 394

	{
		my $request = $items[6]->as_request;

		ok($request->as_string, "/ask_script	+$CRLF");     # 395
		ok($request->as_url,
			'gopher://localhost:70/1/ask_script%09%09+'); # 396
		ok($request->request_type, GOPHER_PLUS_REQUEST);      # 397
		ok($request->host, 'localhost');                      # 398
		ok($request->port, 70);                               # 399
		ok($request->selector, '/ask_script');                # 400
		ok(!defined $request->search_words);                  # 401
		ok(!defined $request->representation);                # 402
		ok(!defined $request->data_block);                    # 403
		ok(!defined $request->attributes);                    # 404
		ok($request->item_type, GOPHER_MENU_TYPE);            # 405
	}

	ok(scalar @items, 7); # 406





	{
		my @of_types = $response->extract_items(
			OfTypes => [INLINE_TEXT_TYPE]
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE); # 407
		ok($of_types[0]->display,
			'This is a Gopher+ style Gopher menu, where all of ' .
			'the items have a fifth field');       # 408
		ok($of_types[0]->selector, '');                # 409
		ok($of_types[0]->host, '');                    # 410
		ok($of_types[0]->port, '');                    # 411
		ok(!defined $of_types[0]->gopher_plus);        # 412
		ok($of_types[0]->as_string,
			"iThis is a Gopher+ style Gopher menu, where all of " .
			"the items have a fifth field\t\t\t"); # 413
		ok($of_types[0]->as_url, "gopher://:/i");      # 414

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);    # 415
		ok($of_types[1]->display,
			'containing a + or ? character.');        # 416
		ok($of_types[1]->selector, '');                   # 417
		ok($of_types[1]->host, '');                       # 418
		ok($of_types[1]->port, '');                       # 419
		ok(!defined $of_types[1]->gopher_plus);           # 420
		ok($of_types[1]->as_string,
			"icontaining a + or ? character.\t\t\t"); # 421
		ok($of_types[1]->as_url, "gopher://:/i");         # 422

		ok($of_types[2]->item_type, INLINE_TEXT_TYPE);             # 423
		ok($of_types[2]->display, 'Fill out this form:');          # 424
		ok($of_types[2]->selector, '');                            # 425
		ok($of_types[2]->host, '');                                # 426
		ok($of_types[2]->port, '');                                # 427
		ok(!defined $of_types[2]->gopher_plus);                    # 428
		ok($of_types[2]->as_string, "iFill out this form:\t\t\t"); # 429
		ok($of_types[2]->as_url, "gopher://:/i");                  # 430

		ok(scalar @of_types, 3); # 431
	}

	{
		my @of_types = $response->extract_items(
			OfTypes => 'i1'
		);

		ok($of_types[0]->item_type, INLINE_TEXT_TYPE); # 432
		ok($of_types[0]->display,
			'This is a Gopher+ style Gopher menu, where all of ' .
			'the items have a fifth field');       # 433
		ok($of_types[0]->selector, '');                # 434
		ok($of_types[0]->host, '');                    # 435
		ok($of_types[0]->port, '');                    # 436
		ok(!defined $of_types[0]->gopher_plus);        # 437
		ok($of_types[0]->as_string,
			"iThis is a Gopher+ style Gopher menu, where all of " .
			"the items have a fifth field\t\t\t"); # 438
		ok($of_types[0]->as_url, "gopher://:/i");      # 439

		ok($of_types[1]->item_type, INLINE_TEXT_TYPE);    # 440
		ok($of_types[1]->display,
			'containing a + or ? character.');        # 441
		ok($of_types[1]->selector, '');                   # 442
		ok($of_types[1]->host, '');                       # 443
		ok($of_types[1]->port, '');                       # 444
		ok(!defined $of_types[1]->gopher_plus);           # 445
		ok($of_types[1]->as_string,
			"icontaining a + or ? character.\t\t\t"); # 446
		ok($of_types[1]->as_url, "gopher://:/i");         # 447

		ok($of_types[2]->item_type, GOPHER_MENU_TYPE);           # 448
		ok($of_types[2]->display, 'Some directory');             # 449
		ok($of_types[2]->selector, '/some_dir');                 # 450
		ok($of_types[2]->host, 'localhost');                     # 451
		ok($of_types[2]->port, '70');                            # 452
		ok($of_types[2]->gopher_plus, '+');                      # 453
		ok($of_types[2]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 454
		ok($of_types[2]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 455

		ok($of_types[3]->item_type, GOPHER_MENU_TYPE);            # 456
		ok($of_types[3]->display, 'Some other directory');        # 457
		ok($of_types[3]->selector, '/some_other_dir');            # 458
		ok($of_types[3]->host, 'localhost');                      # 459
		ok($of_types[3]->port, '70');                             # 460
		ok($of_types[3]->gopher_plus, '+');                       # 461
		ok($of_types[3]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 462
		ok($of_types[3]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 463

		ok($of_types[4]->item_type, INLINE_TEXT_TYPE);             # 464
		ok($of_types[4]->display, 'Fill out this form:');          # 465
		ok($of_types[4]->selector, '');                            # 466
		ok($of_types[4]->host, '');                                # 467
		ok($of_types[4]->port, '');                                # 468
		ok(!defined $of_types[4]->gopher_plus);                    # 469
		ok($of_types[4]->as_string, "iFill out this form:\t\t\t"); # 470
		ok($of_types[4]->as_url, "gopher://:/i");                  # 471

		ok($of_types[5]->item_type, GOPHER_MENU_TYPE);          # 472
		ok($of_types[5]->display, 'Application');               # 473
		ok($of_types[5]->selector, '/ask_script');              # 474
		ok($of_types[5]->host, 'localhost');                    # 475
		ok($of_types[5]->port, '70');                           # 476
		ok($of_types[5]->gopher_plus, '?');                     # 477
		ok($of_types[5]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 478
		ok($of_types[5]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 479

		ok(scalar @of_types, 6); # 480
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => [INLINE_TEXT_TYPE]
		);

		ok($except_types[0]->item_type, GOPHER_MENU_TYPE);       # 481
		ok($except_types[0]->display, 'Some directory');         # 482
		ok($except_types[0]->selector, '/some_dir');             # 483
		ok($except_types[0]->host, 'localhost');                 # 484
		ok($except_types[0]->port, '70');                        # 485
		ok($except_types[0]->gopher_plus, '+');                  # 486
		ok($except_types[0]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 487
		ok($except_types[0]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 488

		ok($except_types[1]->item_type, GOPHER_MENU_TYPE);        # 489
		ok($except_types[1]->display, 'Some other directory');    # 490
		ok($except_types[1]->selector, '/some_other_dir');        # 491
		ok($except_types[1]->host, 'localhost');                  # 492
		ok($except_types[1]->port, '70');                         # 493
		ok($except_types[1]->gopher_plus, '+');                   # 494
		ok($except_types[1]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 495
		ok($except_types[1]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 496

		ok($except_types[2]->item_type, GIF_IMAGE_TYPE);       # 497
		ok($except_types[2]->display, 'A GIF image');          # 498
		ok($except_types[2]->selector, '/image.gif');          # 499
		ok($except_types[2]->host, 'localhost');               # 500
		ok($except_types[2]->port, '70');                      # 501
		ok($except_types[2]->gopher_plus, '+');                # 502
		ok($except_types[2]->as_string,
			"gA GIF image\t/image.gif\tlocalhost\t70\t+"); # 503
		ok($except_types[2]->as_url,
			'gopher://localhost:70/g/image.gif%09%09+');   # 504

		ok($except_types[3]->item_type, GOPHER_MENU_TYPE);      # 505
		ok($except_types[3]->display, 'Application');           # 506
		ok($except_types[3]->selector, '/ask_script');          # 507
		ok($except_types[3]->host, 'localhost');                # 508
		ok($except_types[3]->port, '70');                       # 509
		ok($except_types[3]->gopher_plus, '?');                 # 510
		ok($except_types[3]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 511
		ok($except_types[3]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 512

		ok(scalar @except_types, 4); # 513
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => ['gi']
		);

		ok($except_types[0]->item_type, GOPHER_MENU_TYPE);       # 514
		ok($except_types[0]->display, 'Some directory');         # 515
		ok($except_types[0]->selector, '/some_dir');             # 516
		ok($except_types[0]->host, 'localhost');                 # 517
		ok($except_types[0]->port, '70');                        # 518
		ok($except_types[0]->gopher_plus, '+');                  # 519
		ok($except_types[0]->as_string,
			"1Some directory\t/some_dir\tlocalhost\t70\t+"); # 520
		ok($except_types[0]->as_url,
			'gopher://localhost:70/1/some_dir%09%09+');      # 521

		ok($except_types[1]->item_type, GOPHER_MENU_TYPE);        # 522
		ok($except_types[1]->display, 'Some other directory');    # 523
		ok($except_types[1]->selector, '/some_other_dir');        # 524
		ok($except_types[1]->host, 'localhost');                  # 525
		ok($except_types[1]->port, '70');                         # 526
		ok($except_types[1]->gopher_plus, '+');                   # 527
		ok($except_types[1]->as_string,
			"1Some other directory\t/some_other_dir" .
			"\tlocalhost\t70\t+");                            # 528
		ok($except_types[1]->as_url,
			'gopher://localhost:70/1/some_other_dir%09%09+'); # 529

		ok($except_types[2]->item_type, GOPHER_MENU_TYPE);      # 530
		ok($except_types[2]->display, 'Application');           # 531
		ok($except_types[2]->selector, '/ask_script');          # 532
		ok($except_types[2]->host, 'localhost');                # 533
		ok($except_types[2]->port, '70');                       # 534
		ok($except_types[2]->gopher_plus, '?');                 # 535
		ok($except_types[2]->as_string,
			"1Application\t/ask_script\tlocalhost\t70\t?"); # 536
		ok($except_types[2]->as_url,
			'gopher://localhost:70/1/ask_script%09%09?');   # 537

		ok(scalar @except_types, 3); # 538
	}

	{
		my @except_types = $response->extract_items(
			ExceptTypes => 'i1g'
		);

		ok(scalar @except_types, 0); # 539
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

		ok(scalar @warnings, 0);     # 540
		ok(scalar @fatal_errors, 1); # 541
		ok($fatal_errors[0],
			join(' ',
				'Menu item 2 lacks the following required',
				'fields: a selector string field, a host',
				'field, a port field. The response either',
				'does not contain a Gopher menu or contains',
				'a malformed Gopher menu.'
			)
		);                           # 542
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

		ok(scalar @warnings, 0);     # 543
		ok(scalar @fatal_errors, 1); # 544
		ok($fatal_errors[0],
			join(' ',
				'Menu item 1 lacks the following required',
				'fields: a selector string field, a host',
				'field, a port field. The response either',
				'does not contain a Gopher menu or contains',
				'a malformed Gopher menu.'
			)
		);                           # 545
	}
}





kill_server();
