use strict;
use warnings;
use Test;

BEGIN { plan(tests => 279) }

use Net::Gopher;
use Net::Gopher::Constants qw(:item_types :request);
use Net::Gopher::Utility '$CRLF';

require './t/serverfunctions.pl';





ok(launch_item_server()); # 1

{
	my $ng = new Net::Gopher;

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Selector => '/item_blocks'
	);

	if ($response->is_success)
	{
		ok(1); # 2
	}
	else
	{
		warn $response->error;
	}

	{
		ok($response->has_block('INFO')); # 3

		my $block = $response->get_block('+INFO');

		ok($block->name, '+INFO');                              # 4
		ok($block->value,
			"1Gopher+ Index\t/gp_index\tlocalhost\t70\t+"); # 5
		ok($block->raw_value,
			"1Gopher+ Index\t/gp_index\tlocalhost\t70\t+"); # 6
		ok(!$block->is_attributes);                             # 7

		my ($type, $display, $selector, $host, $port, $gp) =
			$block->extract_description;

		ok($type, GOPHER_MENU_TYPE);                        # 8
		ok($display, 'Gopher+ Index');                      # 9
		ok($selector, '/gp_index');                         # 10
		ok($host, 'localhost');                             # 11
		ok($port, 70);                                      # 12
		ok($gp, '+');                                       # 13
		ok($block->as_url,
			"gopher://localhost:70/1/gp_index%09%09+"); # 14

		{
			my $request = $block->as_request;

			ok($request->as_string, "/gp_index\t+$CRLF");       # 15
			ok($request->as_url,
				'gopher://localhost:70/1/gp_index%09%09+'); # 16
			ok($request->request_type, GOPHER_PLUS_REQUEST);    # 17
			ok($request->host, 'localhost');                    # 18
			ok($request->port, 70);                             # 19
			ok($request->selector, '/gp_index');                # 20
			ok(!defined $request->search_words);                # 21
			ok(!defined $request->representation);              # 22
			ok(!defined $request->data_block);                  # 23
			ok(!defined $request->attributes);                  # 24
			ok($request->item_type, GOPHER_MENU_TYPE);          # 25
		}
	}

	{
		ok($response->has_block('ADMIN')); # 26

		my $block = $response->get_block('+ADMIN');

		ok($block->name, '+ADMIN');                         # 27
		ok($block->value,
			join('',
				"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n",
				"Mod-Date: <20030728173012>\n",
				"Creation-Date: <20030728170201>\n",
				"Expiration-Date: <20030909090001>"
			));                                         # 28
		ok($block->raw_value,
			join('',
				" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\015",
				" Mod-Date: <20030728173012>\015",
				" Creation-Date: <20030728170201>\015",
				" Expiration-Date: <20030909090001>"
			));                                         # 29
		ok($block->is_attributes);                          # 30
		ok($block->has_attribute('Admin'));                 # 31
		ok($block->get_attribute('Admin'),
			'John Q. Sixpack <j_q_sixpack@yahoo.com>'); # 32
		ok($block->has_attribute('Mod-Date'));              # 33
		ok($block->get_attribute('Mod-Date'),
			'<20030728173012>');                        # 34
		ok($block->has_attribute('Creation-Date'));         # 35
		ok($block->get_attribute('Creation-Date'),
			'<20030728170201>');                        # 36
		ok($block->has_attribute('Expiration-Date'));       # 37
		ok($block->get_attribute('Expiration-Date'),
			'<20030909090001>');                        # 38



		my %attributes = $block->get_attributes;
		ok($attributes{'Admin'},
			'John Q. Sixpack <j_q_sixpack@yahoo.com>');    # 39
		ok($attributes{'Mod-Date'}, '<20030728173012>');       # 40
		ok($attributes{'Creation-Date'}, '<20030728170201>');  # 41
		ok($attributes{'Expiration-Date'},'<20030909090001>'); # 42



		my $attributes = $block->get_attributes;
		ok($attributes->{'Admin'},
			'John Q. Sixpack <j_q_sixpack@yahoo.com>');      # 43
		ok($attributes->{'Mod-Date'}, '<20030728173012>');       # 44
		ok($attributes->{'Creation-Date'}, '<20030728170201>');  # 45
		ok($attributes->{'Expiration-Date'},'<20030909090001>'); # 46



		my ($admin_name, $admin_email) = $block->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 47
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 48

		{
			my @gmtime = gmtime $block->extract_date_modified;
			
			ok(scalar @gmtime, 9); # 49

			ok($gmtime[0], 12);  # 50
			ok($gmtime[1], 30);  # 51
			ok($gmtime[2], 17);  # 52
			ok($gmtime[3], 28);  # 53
			ok($gmtime[4], 6);   # 54
			ok($gmtime[5], 103); # 55
			ok($gmtime[6], 1);   # 56
			ok($gmtime[7], 208); # 57
			ok($gmtime[8], 0);   # 58
		}

		{
			my @gmtime = gmtime $block->extract_date_created;

			ok(scalar @gmtime, 9); # 59

			ok($gmtime[0], 1);   # 60
			ok($gmtime[1], 2);   # 61
			ok($gmtime[2], 17);  # 62
			ok($gmtime[3], 28);  # 63
			ok($gmtime[4], 6);   # 64
			ok($gmtime[5], 103); # 65
			ok($gmtime[6], 1);   # 66
			ok($gmtime[7], 208); # 67
			ok($gmtime[8], 0);   # 68
		}

		{
			my @gmtime = gmtime $block->extract_date_expires;

			ok(scalar @gmtime, 9); # 69

			ok($gmtime[0], 1);   # 70
			ok($gmtime[1], 0);   # 71
			ok($gmtime[2], 9);  # 72
			ok($gmtime[3], 9);   # 73
			ok($gmtime[4], 8);   # 74
			ok($gmtime[5], 103); # 75
			ok($gmtime[6], 2);   # 76
			ok($gmtime[7], 251); # 77
			ok($gmtime[8], 0);   # 78
		}
	}

	{
		ok($response->has_block('+VIEWS')); # 79

		my $block = $response->get_block('VIEWS');

		ok($block->name, '+VIEWS'); # 80
		ok($block->value,
			join('',
				"text/plain: <.40k>\n",
				"application/gopher+-menu En_US: <1200b>\n",
				"text/html: <.77KB>"
			));                 # 81
		ok($block->raw_value,
			join('',
				" text/plain: <.40k>\015",
				" application/gopher+-menu En_US: <1200b>\015",
				" text/html: <.77KB>"
			));                 # 82
		ok($block->is_attributes);  # 83



		my @views = $block->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 84
		ok(!defined $views[0]->{'language'});  # 85
		ok(!defined $views[0]->{'country'});   # 86
		ok($views[0]->{'size'}, 410);          # 87

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 88
		ok($views[1]->{'language'}, 'En');                   # 89
		ok($views[1]->{'country'}, 'US');                    # 90
		ok($views[1]->{'size'}, 1200);                       # 91

		ok($views[2]->{'type'}, 'text/html'); # 92
		ok(!defined $views[2]->{'language'}); # 93
		ok(!defined $views[2]->{'country'});  # 94
		ok($views[2]->{'size'}, 789);         # 95

		ok(scalar @views, 3); # 96
	}

	{
	
		ok($response->has_block('ASK')); # 97

		my $block = $response->get_block('ASK');

		ok($block->name, '+ASK');  # 98
		ok($block->value,
			join('',
				"Ask: What is your name?\n",
				"Ask: Where are you from?\tMontana\n",
				"Choose: What is your favorite color?\tred\tgreen\tblue\n",
				"Select: Contact using Email:\t1\n",
				"Select: Contact using Instant Messenger:\t1\n",
				"Select: Contact using IRC:\t0"
			));                # 99
		ok($block->raw_value,
			join('',
				" Ask: What is your name?\015",
				" Ask: Where are you from?\tMontana\015",
				" Choose: What is your favorite color?\tred\tgreen\tblue\015",
				" Select: Contact using Email:\t1\015",
				" Select: Contact using Instant Messenger:\t1\015",
				" Select: Contact using IRC:\t0"
			));                # 100
		ok($block->is_attributes); # 101



		my @queries = $block->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 102
		ok($queries[0]->{'question'}, 'What is your name?'); # 103
		ok(!defined $queries[0]->{'value'});                 # 104
		ok(!exists $queries[0]->{'choices'});                # 105

		ok($queries[1]->{'type'}, 'Ask');                     # 106
		ok($queries[1]->{'question'}, 'Where are you from?'); # 107
		ok($queries[1]->{'value'}, 'Montana');                # 108
		ok(!exists $queries[1]->{'choices'});                 # 109

		ok($queries[2]->{'type'}, 'Choose');         # 110
		ok($queries[2]->{'question'},
			'What is your favorite color?');     # 111
		ok(!exists $queries[2]->{'value'});          # 112
		ok(ref $queries[2]->{'choices'}, 'ARRAY');   # 113
		ok($queries[2]->{'choices'}->[0], 'red');    # 114
		ok($queries[2]->{'choices'}->[1], 'green');  # 115
		ok($queries[2]->{'choices'}->[2], 'blue');   # 116
		ok(scalar @{ $queries[2]->{'choices'} }, 3); # 117

		ok($queries[3]->{'type'}, 'Select');                   # 118
		ok($queries[3]->{'question'}, 'Contact using Email:'); # 119
		ok($queries[3]->{'value'}, '1');                       # 120
		ok(!exists $queries[3]->{'choices'});                  # 121

		ok($queries[4]->{'type'}, 'Select');                               # 122
		ok($queries[4]->{'question'}, 'Contact using Instant Messenger:'); # 123
		ok($queries[4]->{'value'}, '1');                                   # 124
		ok(!exists $queries[4]->{'choices'});                              # 125

		ok($queries[5]->{'type'}, 'Select');                 # 126
		ok($queries[5]->{'question'}, 'Contact using IRC:'); # 127
		ok($queries[5]->{'value'}, '0');                     # 128
		ok(!exists $queries[5]->{'choices'});                # 129

		ok(scalar @queries, 6); # 130
	}





	{
		my ($type, $display, $selector, $host, $port, $gp) =
			$response->extract_description;

		ok($type, GOPHER_MENU_TYPE);                        # 131
		ok($display, 'Gopher+ Index');                      # 132
		ok($selector, '/gp_index');                         # 133
		ok($host, 'localhost');                             # 134
		ok($port, 70);                                      # 135
		ok($gp, '+');                                       # 136
	}

	{
		my ($admin_name, $admin_email) = $response->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 137
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 138

		{
			my @gmtime = gmtime $response->extract_date_modified;
			
			ok(scalar @gmtime, 9); # 139

			ok($gmtime[0], 12);  # 140
			ok($gmtime[1], 30);  # 141
			ok($gmtime[2], 17);  # 142
			ok($gmtime[3], 28);  # 143
			ok($gmtime[4], 6);   # 144
			ok($gmtime[5], 103); # 145
			ok($gmtime[6], 1);   # 146
			ok($gmtime[7], 208); # 147
			ok($gmtime[8], 0);   # 148
		}

		{
			my @gmtime = gmtime $response->extract_date_created;

			ok(scalar @gmtime, 9); # 149

			ok($gmtime[0], 1);   # 150
			ok($gmtime[1], 2);   # 151
			ok($gmtime[2], 17);  # 152
			ok($gmtime[3], 28);  # 153
			ok($gmtime[4], 6);   # 154
			ok($gmtime[5], 103); # 155
			ok($gmtime[6], 1);   # 156
			ok($gmtime[7], 208); # 157
			ok($gmtime[8], 0);   # 158
		}

		{
			my @gmtime = gmtime $response->extract_date_expires;

			ok(scalar @gmtime, 9); # 159

			ok($gmtime[0], 1);   # 160
			ok($gmtime[1], 0);   # 161
			ok($gmtime[2], 9);  # 162
			ok($gmtime[3], 9);   # 163
			ok($gmtime[4], 8);   # 164
			ok($gmtime[5], 103); # 165
			ok($gmtime[6], 2);   # 166
			ok($gmtime[7], 251); # 167
			ok($gmtime[8], 0);   # 168
		}
	}

	{
		my @views = $response->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 169
		ok(!defined $views[0]->{'language'});  # 170
		ok(!defined $views[0]->{'country'});   # 171
		ok($views[0]->{'size'}, 410);          # 172

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 173
		ok($views[1]->{'language'}, 'En');                   # 174
		ok($views[1]->{'country'}, 'US');                    # 175
		ok($views[1]->{'size'}, 1200);                       # 176

		ok($views[2]->{'type'}, 'text/html'); # 177
		ok(!defined $views[2]->{'language'}); # 178
		ok(!defined $views[2]->{'country'});  # 179
		ok($views[2]->{'size'}, 789);         # 180

		ok(scalar @views, 3); # 181
	}

	{
		my @queries = $response->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 182
		ok($queries[0]->{'question'}, 'What is your name?'); # 183
		ok(!defined $queries[0]->{'value'});                 # 184
		ok(!exists $queries[0]->{'choices'});                # 185

		ok($queries[1]->{'type'}, 'Ask');                     # 186
		ok($queries[1]->{'question'}, 'Where are you from?'); # 187
		ok($queries[1]->{'value'}, 'Montana');                # 188
		ok(!exists $queries[1]->{'choices'});                 # 189

		ok($queries[2]->{'type'}, 'Choose');         # 190
		ok($queries[2]->{'question'},
			'What is your favorite color?');     # 191
		ok(!exists $queries[2]->{'value'});          # 192
		ok(ref $queries[2]->{'choices'}, 'ARRAY');   # 193
		ok($queries[2]->{'choices'}->[0], 'red');    # 194
		ok($queries[2]->{'choices'}->[1], 'green');  # 195
		ok($queries[2]->{'choices'}->[2], 'blue');   # 196
		ok(scalar @{ $queries[2]->{'choices'} }, 3); # 197

		ok($queries[3]->{'type'}, 'Select');                   # 198
		ok($queries[3]->{'question'}, 'Contact using Email:'); # 199
		ok($queries[3]->{'value'}, '1');                       # 200
		ok(!exists $queries[3]->{'choices'});                  # 201

		ok($queries[4]->{'type'}, 'Select');                               # 202
		ok($queries[4]->{'question'}, 'Contact using Instant Messenger:'); # 203
		ok($queries[4]->{'value'}, '1');                                   # 204
		ok(!exists $queries[4]->{'choices'});                              # 205

		ok($queries[5]->{'type'}, 'Select');                 # 206
		ok($queries[5]->{'question'}, 'Contact using IRC:'); # 207
		ok($queries[5]->{'value'}, '0');                     # 208
		ok(!exists $queries[5]->{'choices'});                # 209

		ok(scalar @queries, 6); # 210
	}
}





{
	my $ng = new Net::Gopher;

	my $response = $ng->directory_attribute(
		Host     => 'localhost',
		Selector => '/directory_blocks'
	);

	if ($response->is_success)
	{
		ok(1); # 211
	}
	else
	{
		warn $response->error;
	}



	{
		ok($response->has_block('ADMIN', Item => 1)); # 212

		my $block = $response->get_block('+ADMIN', Item => 1);

		ok($block->name, '+ADMIN');             # 213
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 214
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 215
	}

	{
		ok($response->has_block('INFO', [Item => 2])); # 216

		my $block = $response->get_block('INFO', {Item => 2});

		ok($block->name, '+INFO');           # 217
		ok($block->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 218
		ok($block->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 219
	}

	{
		ok($response->has_block('ADMIN', [
			Item => {
				Selector => '/gp_period_term'
			}
		])); # 220

		my $block = $response->get_block('ADMIN',
			[Item => [Display => 'Period terminated file']]
		);

		ok($block->name, '+ADMIN');             # 221
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 222
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 223

	}

	{
		ok($response->has_block('+ADMIN', [
			Item => {
				ItemType   => 0,
				Display    => qr/Non-terminated/i,
				Selector   => '/gp_no_term',
				Host       => qr/local/,
				Port       => 70,
				GopherPlus => '+'
			}
		])); # 224

		my $block = $response->get_block('ADMIN',
			[Item => {
				ItemType   => 0,
				Display    => qr/Non-terminat(?:ed)?\sfile/,
				Selector   => '/gp_no_term',
				Host       => 'localhost',
				Port       => 70,
				GopherPlus => '+'
				}
			]
		);

		ok($block->name, '+ADMIN');             # 225
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 226
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 227
	}

	{
		ok($response->has_block('+ADMIN', 
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		)); # 228

		my $block = $response->get_block('ADMIN',
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		);

		ok($block->name, '+ADMIN');             # 229
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 230
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 231
	}

	{
		ok(!$response->has_block('ADMIN',
			Item => {Display => 'bad display'})); # 232

		my $block = $response->get_block('ADMIN',
			Item => {
				Display => 'Bad display'
			}
		);

		ok(!defined $block); # 233
	}

	{
		my @directory_information = $response->get_blocks;

		ok(scalar @directory_information, 4); # 234



		my @gp_index = @{ shift @directory_information };

		ok($gp_index[0]->name, '+INFO');                       # 235
		ok($gp_index[0]->value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 236
		ok($gp_index[0]->raw_value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 237

		ok($gp_index[1]->name, '+ADMIN');       # 238
		ok($gp_index[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 239
		ok($gp_index[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 240



		my @gp_byte_term = @{ shift @directory_information };

		ok($gp_byte_term[0]->name, '+INFO'); # 241
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 242
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 243

		ok($gp_byte_term[1]->name, '+ADMIN');   # 244
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 245
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 246



		my @gp_period_term = @{ shift @directory_information };

		ok($gp_period_term[0]->name, '+INFO'); # 247
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 248
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 249

		ok($gp_period_term[1]->name, '+ADMIN'); # 250
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 251
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 252



		my @gp_no_term = @{ shift @directory_information };

		ok($gp_no_term[0]->name, '+INFO'); # 253
		ok($gp_no_term[0]->value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");       # 254
		ok($gp_no_term[0]->raw_value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");        # 255

		ok($gp_no_term[1]->name, '+ADMIN');     # 256
		ok($gp_no_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 257
		ok($gp_no_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 258
	}

	{
		my @gp_byte_term = $response->get_blocks(Item => 2);

		ok(scalar @gp_byte_term, 2); # 259

		ok($gp_byte_term[0]->name, '+INFO'); # 260
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 261
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 262

		ok($gp_byte_term[1]->name, '+ADMIN');   # 263
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 264
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 265
	}

	{
		my @gp_period_term = $response->get_blocks(
			Item => {
				Display  => 'Period terminated file',
				Selector => '/gp_period_term'
			}
		);

		ok(scalar @gp_period_term, 2); # 266

		ok($gp_period_term[0]->name, '+INFO'); # 267
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 268
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 269

		ok($gp_period_term[1]->name, '+ADMIN'); # 270
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 271
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 272
	}
}





{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->gopher_plus(
		Host     => 'localhost',
		Selector => '/gp_index'
	);

	ok($response->is_success); # 273

	# there are no blocks, so we should get errors when we try to parse
	# them:
	ok(!$response->has_block('Something')); # 274

	ok(scalar @warnings, 1);     # 275
	ok($warnings[0], join(' ',
		"You didn't send an item attribute or directory",
		"attribute information request, so why would the",
		"response contain attribute information blocks?"
	));                          # 276
	ok(scalar @fatal_errors, 1); # 277
	ok($fatal_errors[0], join(' ',
		'There was no leading "+" for the first block name at',
		'the beginning of the response. The response either',
		'does not contain any attribute information blocks or',
		'contains malformed attribute information blocks.'
	));                          # 278
}

ok(kill_servers()); # 279
