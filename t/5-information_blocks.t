use strict;
use warnings;
use Test;

BEGIN { plan(tests => 387) }

use Net::Gopher;
use Net::Gopher::Constants qw(:item_types :request);
use Net::Gopher::Utility '$CRLF';

require './t/serverfunctions.pl';





my $port = launch_item_server();
ok($port); # 1

{
	my $ng = new Net::Gopher;

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/item_blocks'
	);

	if ($response->is_success)
	{
		ok(1); # 2
	}
	else
	{
		ok(0);
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
			$block->extract_descriptor;

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
			$response->extract_descriptor;

		ok($type, GOPHER_MENU_TYPE);                        # 131
		ok($display, 'Gopher+ Index');                      # 132
		ok($selector, '/gp_index');                         # 133
		ok($host, 'localhost');                             # 134
		ok($port, 70);                                      # 135
		ok($gp, '+');                                       # 136
	}

	# Check for backwards compatability warnings:
	{
		my @warnings;

		my $old_warn_handler = $ng->warn_handler;

		$ng->warn_handler(sub {push(@warnings, shift)});
	
		my ($type, $display, $selector, $host, $port, $gp) =
			$response->extract_description;

		ok($warnings[0],
			"The extract_description() method is depricated. Use " .
			"extract_descriptor() instead."); # 137
		ok(@warnings, 1);                         # 138

		$ng->warn_handler($old_warn_handler);

		ok($type, GOPHER_MENU_TYPE);                        # 139
		ok($display, 'Gopher+ Index');                      # 140
		ok($selector, '/gp_index');                         # 141
		ok($host, 'localhost');                             # 142
		ok($port, 70);                                      # 143
		ok($gp, '+');                                       # 144
	}

	{
		my ($admin_name, $admin_email) = $response->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 145
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 146

		{
			my @gmtime = gmtime $response->extract_date_modified;
			
			ok(scalar @gmtime, 9); # 147

			ok($gmtime[0], 12);  # 148
			ok($gmtime[1], 30);  # 149
			ok($gmtime[2], 17);  # 150
			ok($gmtime[3], 28);  # 151
			ok($gmtime[4], 6);   # 152
			ok($gmtime[5], 103); # 153
			ok($gmtime[6], 1);   # 154
			ok($gmtime[7], 208); # 155
			ok($gmtime[8], 0);   # 156
		}

		{
			my @gmtime = gmtime $response->extract_date_created;

			ok(scalar @gmtime, 9); # 157

			ok($gmtime[0], 1);   # 158
			ok($gmtime[1], 2);   # 159
			ok($gmtime[2], 17);  # 160
			ok($gmtime[3], 28);  # 161
			ok($gmtime[4], 6);   # 162
			ok($gmtime[5], 103); # 163
			ok($gmtime[6], 1);   # 164
			ok($gmtime[7], 208); # 165
			ok($gmtime[8], 0);   # 166
		}

		{
			my @gmtime = gmtime $response->extract_date_expires;

			ok(scalar @gmtime, 9); # 167

			ok($gmtime[0], 1);   # 168
			ok($gmtime[1], 0);   # 169
			ok($gmtime[2], 9);  # 170
			ok($gmtime[3], 9);   # 171
			ok($gmtime[4], 8);   # 172
			ok($gmtime[5], 103); # 173
			ok($gmtime[6], 2);   # 174
			ok($gmtime[7], 251); # 175
			ok($gmtime[8], 0);   # 176
		}
	}

	{
		my @views = $response->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 177
		ok(!defined $views[0]->{'language'});  # 178
		ok(!defined $views[0]->{'country'});   # 179
		ok($views[0]->{'size'}, 410);          # 180

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 181
		ok($views[1]->{'language'}, 'En');                   # 182
		ok($views[1]->{'country'}, 'US');                    # 183
		ok($views[1]->{'size'}, 1200);                       # 184

		ok($views[2]->{'type'}, 'text/html'); # 185
		ok(!defined $views[2]->{'language'}); # 186
		ok(!defined $views[2]->{'country'});  # 187
		ok($views[2]->{'size'}, 789);         # 188

		ok(scalar @views, 3); # 189
	}

	{
		my @queries = $response->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 190
		ok($queries[0]->{'question'}, 'What is your name?'); # 191
		ok(!defined $queries[0]->{'value'});                 # 192
		ok(!exists $queries[0]->{'choices'});                # 193

		ok($queries[1]->{'type'}, 'Ask');                     # 194
		ok($queries[1]->{'question'}, 'Where are you from?'); # 195
		ok($queries[1]->{'value'}, 'Montana');                # 196
		ok(!exists $queries[1]->{'choices'});                 # 197

		ok($queries[2]->{'type'}, 'Choose');         # 198
		ok($queries[2]->{'question'},
			'What is your favorite color?');     # 199
		ok(!exists $queries[2]->{'value'});          # 200
		ok(ref $queries[2]->{'choices'}, 'ARRAY');   # 201
		ok($queries[2]->{'choices'}->[0], 'red');    # 202
		ok($queries[2]->{'choices'}->[1], 'green');  # 203
		ok($queries[2]->{'choices'}->[2], 'blue');   # 204
		ok(scalar @{ $queries[2]->{'choices'} }, 3); # 205

		ok($queries[3]->{'type'}, 'Select');                   # 206
		ok($queries[3]->{'question'}, 'Contact using Email:'); # 207
		ok($queries[3]->{'value'}, '1');                       # 208
		ok(!exists $queries[3]->{'choices'});                  # 209

		ok($queries[4]->{'type'}, 'Select');                               # 210
		ok($queries[4]->{'question'}, 'Contact using Instant Messenger:'); # 211
		ok($queries[4]->{'value'}, '1');                                   # 212
		ok(!exists $queries[4]->{'choices'});                              # 213

		ok($queries[5]->{'type'}, 'Select');                 # 214
		ok($queries[5]->{'question'}, 'Contact using IRC:'); # 215
		ok($queries[5]->{'value'}, '0');                     # 216
		ok(!exists $queries[5]->{'choices'});                # 217

		ok(scalar @queries, 6); # 218
	}
}





{
	my $ng = new Net::Gopher;

	my $response = $ng->directory_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/directory_blocks'
	);

	if ($response->is_success)
	{
		ok(1); # 219
	}
	else
	{
		ok(0);
		warn $response->error;
	}



	{
		ok($response->has_block('ADMIN', Item => 1)); # 220

		my $block = $response->get_block('+ADMIN', Item => 1);

		ok($block->name, '+ADMIN');             # 221
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 222
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 223
	}

	{
		ok($response->has_block('INFO', [Item => 2])); # 224

		my $block = $response->get_block('INFO', {Item => 2});

		ok($block->name, '+INFO');           # 225
		ok($block->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 226
		ok($block->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 227
	}

	{
		ok($response->has_block('ADMIN', [
			Item => {
				Selector => '/gp_period_term'
			}
		])); # 228

		my $block = $response->get_block('ADMIN',
			[Item => [Display => 'Period terminated file']]
		);

		ok($block->name, '+ADMIN');             # 229
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 230
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 231

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
		])); # 232

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

		ok($block->name, '+ADMIN');             # 233
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 234
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 235
	}

	{
		ok($response->has_block('+ADMIN', 
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		)); # 236

		my $block = $response->get_block('ADMIN',
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		);

		ok($block->name, '+ADMIN');             # 237
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 238
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 239
	}

	{
		ok(!$response->has_block('ADMIN',
			Item => {Display => 'bad display'})); # 240

		my $block = $response->get_block('ADMIN',
			Item => {
				Display => 'Bad display'
			}
		);

		ok(!defined $block); # 241
	}

	{
		my @directory_information = $response->get_blocks;

		ok(scalar @directory_information, 4); # 242



		my @gp_index = @{ shift @directory_information };

		ok($gp_index[0]->name, '+INFO');                       # 243
		ok($gp_index[0]->value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 244
		ok($gp_index[0]->raw_value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 245

		ok($gp_index[1]->name, '+ADMIN');       # 246
		ok($gp_index[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 247
		ok($gp_index[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 248



		my @gp_byte_term = @{ shift @directory_information };

		ok($gp_byte_term[0]->name, '+INFO'); # 249
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 250
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 251

		ok($gp_byte_term[1]->name, '+ADMIN');   # 252
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 253
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 254



		my @gp_period_term = @{ shift @directory_information };

		ok($gp_period_term[0]->name, '+INFO'); # 255
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 256
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 257

		ok($gp_period_term[1]->name, '+ADMIN'); # 258
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 259
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 260



		my @gp_no_term = @{ shift @directory_information };

		ok($gp_no_term[0]->name, '+INFO'); # 261
		ok($gp_no_term[0]->value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");       # 262
		ok($gp_no_term[0]->raw_value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");        # 263

		ok($gp_no_term[1]->name, '+ADMIN');     # 264
		ok($gp_no_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 265
		ok($gp_no_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 266
	}

	{
		my @gp_byte_term = $response->get_blocks(Item => 2);

		ok(scalar @gp_byte_term, 2); # 267

		ok($gp_byte_term[0]->name, '+INFO'); # 268
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 269
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 270

		ok($gp_byte_term[1]->name, '+ADMIN');   # 271
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 272
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 273
	}

	{
		my @gp_period_term = $response->get_blocks(
			Item => {
				Display  => 'Period terminated file',
				Selector => '/gp_period_term'
			}
		);

		ok(scalar @gp_period_term, 2); # 274

		ok($gp_period_term[0]->name, '+INFO'); # 275
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 276
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 277

		ok($gp_period_term[1]->name, '+ADMIN'); # 278
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 279
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 280
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
		Port     => $port,
		Selector => '/gp_index'
	);

	if ($response->is_success)
	{
		ok(1);                          # 281
	}
	else
	{
		ok(0);
	}

	# there are no blocks, so we should get errors when we try to parse
	# them:
	ok(!$response->has_block('Something')); # 282
	ok(scalar @warnings, 1);                # 283
	ok($warnings[0], join(' ',
		"You didn't send an item attribute or directory",
		"attribute information request, so why would the",
		"response contain attribute information blocks?"
	));                                     # 284
	ok(scalar @fatal_errors, 1);            # 285
	ok($fatal_errors[0], join(' ',
		'There was no leading "+" for the first block name at',
		'the beginning of the response. The response either',
		'does not contain any attribute information blocks or',
		'contains malformed attribute information blocks.'
	));                                     # 286
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/item_blocks'
	);

	if ($response->is_success)
	{
		ok(1);             # 287
	}
	else
	{
		ok(0);
	}

	my $info = $response->get_block('+INFO');
	ok($info);                 # 288
	ok(!$info->get_attribute); # 289
	ok(@warnings, 0);          # 290
	ok(@fatal_errors, 1);      # 291
	ok($fatal_errors[0],
		'The name of the attribute to retrieve was not supplied.'
	);                         # 292
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/item_blocks'
	);

	if ($response->is_success)
	{
		ok(1);              # 293
	}
	else
	{
		ok(0);
	}

	my $info = $response->get_block('+INFO');
	ok($info);                  # 294
	ok(!$info->get_attributes); # 295
	ok(@warnings, 0);           # 296
	ok(@fatal_errors, 1);       # 297
	ok($fatal_errors[0],
		'This +INFO block either does not contain ' .
		'attributes or contains malformed attributes.'
	);                          # 298
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/directory_blocks'
	);

	if ($response->is_success)
	{
		ok(1);        # 299
	}
	else
	{
		ok(0);
	}

	my $info = $response->get_block('+INFO', Item => 7);
	ok(!$info);           # 300
	ok(@warnings, 0);     # 301
	ok(@fatal_errors, 1); # 302
	ok($fatal_errors[0],
		'There are only 4 items in the response. You specified item ' .
		'7, which does not exist.'
	);                    # 303
}



################################################################################
# 
# these tests ensure the +ADMIN block-specific methods raise proper errors:
# 

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);             # 304
	}
	else
	{
		ok(0);
	}

	my $info = $response->get_block('INFO');
	ok($info);                 # 305
	ok(!$info->extract_admin); # 306
	ok(@warnings, 1);          # 307
	ok(@fatal_errors, 1);      # 308
	ok($warnings[0],
		"Are you sure there's administrator information to " .
		"extract? The block object contains a +INFO block, not " .
		"an +ADMIN block."
	);                         # 309
	ok($fatal_errors[0],
		'This +INFO block either does not contain ' .
		'attributes or contains malformed attributes.'
	);                         # 310
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);              # 311
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('+BAD-ADMIN1');
	ok($admin);                 # 312
	ok(!$admin->extract_admin); # 313
	ok(@warnings, 1);           # 314
	ok(@fatal_errors, 1);       # 315
	ok($warnings[0],
		"Are you sure there's administrator information to " .
		"extract? The block object contains a +BAD-ADMIN1 block, not " .
		"an +ADMIN block."
	);                          # 316
	ok($fatal_errors[0],
		'The +BAD-ADMIN1 block has no Admin attribute to extract ' .
		'item administrator information from.'
	);                          # 317
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);              # 318
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('+BAD-ADMIN2');
	ok($admin);                 # 319
	ok(!$admin->extract_admin); # 320
	ok(@warnings, 1);           # 321
	ok(@fatal_errors, 1);       # 322
	ok($warnings[0],
		"Are you sure there's administrator information to " .
		"extract? The block object contains a +BAD-ADMIN2 block, not " .
		"an +ADMIN block."
	);                          # 323
	ok($fatal_errors[0],
		'The +BAD-ADMIN2 block contains a malformed Admin attribute.'
	);                          # 324
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);                      # 325
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('+BAD-ADMIN1');
	ok($admin);                         # 326
	ok(!$admin->extract_date_modified); # 327
	ok(@warnings, 1);                   # 328
	ok(@fatal_errors, 1);               # 329
	ok($warnings[0],
		"Are you sure there's a modification date timestamp " .
		"to extract? The block object contains a +BAD-ADMIN1 block, " .
		"not an +ADMIN block."
	);                                  # 330
	ok($fatal_errors[0],
		'The +BAD-ADMIN1 block has no Mod-Date attribute to extract ' .
		'a modification date from.'
	);                                  # 331
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);                      # 332
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('+BAD-ADMIN2');
	ok($admin);                         # 333
	ok(!$admin->extract_date_modified); # 334
	ok(@warnings, 1);                   # 335
	ok(@fatal_errors, 1);               # 336
	ok($warnings[0],
		"Are you sure there's a modification date timestamp " .
		"to extract? The block object contains a +BAD-ADMIN2 block, " .
		"not an +ADMIN block."
	);                                  # 337
	ok($fatal_errors[0],
		'The Mod-Date attribute either does not contain a ' .
		'timestamp or contains a malformed one.'
	);                                  # 338
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);                     # 339
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('+BAD-ADMIN1');
	ok($admin);                        # 340
	ok(!$admin->extract_date_created); # 341
	ok(@warnings, 1);                  # 342
	ok(@fatal_errors, 1);              # 343
	ok($warnings[0],
		"Are you sure there's a creation date timestamp " .
		"to extract? The block object contains a +BAD-ADMIN1 block, " .
		"not an +ADMIN block."
	);                                 # 344
	ok($fatal_errors[0],
		'The +BAD-ADMIN1 block has no Creation-Date attribute to ' .
		'extract a creation date from.'
	);                                 # 345
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);                     # 346
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('+BAD-ADMIN2');
	ok($admin);                        # 347
	ok(!$admin->extract_date_created); # 348
	ok(@warnings, 1);                  # 349
	ok(@fatal_errors, 1);              # 350
	ok($warnings[0],
		"Are you sure there's a creation date timestamp " .
		"to extract? The block object contains a +BAD-ADMIN2 block, " .
		"not an +ADMIN block.",
	);                                 # 351
	ok($fatal_errors[0],
		'The Creation-Date attribute either does not contain a ' .
		'timestamp or contains a malformed one.'
	);                                 # 352
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);                     # 353
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('+BAD-ADMIN1');
	ok($admin);                        # 354
	ok(!$admin->extract_date_expires); # 355
	ok(@warnings, 1);                  # 356
	ok(@fatal_errors, 1);              # 357
	ok($warnings[0],
		"Are you sure there's an expiration date timestamp " .
		"to extract? The block object contains a +BAD-ADMIN1 block, " .
		"not an +ADMIN block.",
	);                                 # 358
	ok($fatal_errors[0],
		'The +BAD-ADMIN1 block has no Expiration-Date attribute to ' .
		'extract an expiration date from.'
	);                                 # 359
}

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);                     # 360
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('+BAD-ADMIN2');
	ok($admin);                        # 361
	ok(!$admin->extract_date_expires); # 362
	ok(@warnings, 1);                  # 363
	ok(@fatal_errors, 1);              # 364
	ok($warnings[0],
		"Are you sure there's an expiration date timestamp " .
		"to extract? The block object contains a +BAD-ADMIN2 block, " .
		"not an +ADMIN block.",
	);                                 # 365
	ok($fatal_errors[0],
		'The Expiration-Date attribute either does not contain a ' .
		'timestamp or contains a malformed one.'
	);                                 # 366
}



################################################################################
#
# These tests ensure +ASK block-specific methods raise proper errors:
#

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/bad_blocks'
	);

	if ($response->is_success)
	{
		ok(1);               # 367
	}
	else
	{
		ok(0);
	}

	my $info = $response->get_block('INFO');
	ok($info); # 368
	ok(!$info->extract_queries); # 369
	ok(@warnings, 1);            # 370
	ok(@fatal_errors, 1);        # 371
	ok($warnings[0],
		'Are you sure there are queries to extract? The block '.
		'object contains a +INFO block, not an +ASK block.'
	);                           # 372
	ok($fatal_errors[0],
		'This +INFO block either does not contain ' .
		'any queries or it contains malformed queries.'
	);                           # 373
}



################################################################################
#
# These tests ensure +INFO block-specific methods raise proper errors:
#

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/item_blocks'
	);

	if ($response->is_success)
	{
		ok(1);                   # 374
	}
	else
	{
		ok(0);
	}

	my $admin = $response->get_block('ADMIN');
	ok($admin);                      # 375
	ok(!$admin->extract_descriptor); # 376
	ok(@warnings, 0);                # 377
	ok(@fatal_errors, 1);            # 378
	ok($fatal_errors[0],
		'The +ADMIN block either does not contain an item ' .
		'descriptor or it contains a malformed one.'
	);                               # 379
}



################################################################################
#
# These tests ensure +VIEWS block-specific methods raise proper errors:
#

{
	my (@warnings, @fatal_errors);
	my $ng = new Net::Gopher (
		WarnHandler => sub { push(@warnings, shift) },
		DieHandler  => sub { push(@fatal_errors, shift) }
	);

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Port     => $port,
		Selector => '/item_blocks'
	);

	if ($response->is_success)
	{
		ok(1);             # 380
	}
	else
	{
		ok(0);
	}

	my $info = $response->get_block('INFO');
	ok($info);                 # 381
	ok(!$info->extract_views); # 382
	ok(@warnings, 1);          # 383
	ok(@fatal_errors, 1);      # 384
	ok($warnings[0],
		'Are you sure there are views to extract? The block '.
		'object contains a +INFO block, not a +VIEWS block.'
	);                         # 385
	ok($fatal_errors[0],
		'This +INFO block either does not contain ' .
		'any views or it contains malformed views.'
	);                         # 386
}

ok(kill_servers()); # 387
