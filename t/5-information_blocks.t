use strict;
use warnings;
use Test;

BEGIN { plan(tests => 249) }

use Net::Gopher;
use Net::Gopher::Constants qw(:item_types :request);
use Net::Gopher::Utility '$CRLF';

require './t/serverfunctions.pl';





ok(run_server()); # 1

{
	my $ng = new Net::Gopher;

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Selector => '/item_blocks'
	);

	ok($response->is_success); # 2

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

		ok($block->extract_date_modified, 1059427812); # 49
		ok($block->extract_date_created, 1059426121);  # 50
		ok($block->extract_date_expires, 1063112401);  # 51
	}

	{
		ok($response->has_block('+VIEWS')); # 52

		my $block = $response->get_block('VIEWS');

		ok($block->name, '+VIEWS'); # 53
		ok($block->value,
			join('',
				"text/plain: <.40k>\n",
				"application/gopher+-menu En_US: <1200b>\n",
				"text/html: <.77KB>"
			));                 # 54
		ok($block->raw_value,
			join('',
				" text/plain: <.40k>\015",
				" application/gopher+-menu En_US: <1200b>\015",
				" text/html: <.77KB>"
			));                 # 55
		ok($block->is_attributes);  # 56



		my @views = $block->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 57
		ok(!defined $views[0]->{'language'});  # 58
		ok(!defined $views[0]->{'country'});   # 59
		ok($views[0]->{'size'}, 410);          # 60

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 61
		ok($views[1]->{'language'}, 'En');                   # 62
		ok($views[1]->{'country'}, 'US');                    # 63
		ok($views[1]->{'size'}, 1200);                       # 64

		ok($views[2]->{'type'}, 'text/html'); # 65
		ok(!defined $views[2]->{'language'}); # 66
		ok(!defined $views[2]->{'country'});  # 67
		ok($views[2]->{'size'}, 789);         # 68

		ok(scalar @views, 3); # 69
	}

	{
	
		ok($response->has_block('ASK')); # 70

		my $block = $response->get_block('ASK');

		ok($block->name, '+ASK');  # 71
		ok($block->value,
			join('',
				"Ask: What is your name?\n",
				"Ask: Where are you from?\tMontana\n",
				"Choose: What is your favorite color?\tred\tgreen\tblue\n",
				"Select: Contact using Email:\t1\n",
				"Select: Contact using Instant Messenger:\t1\n",
				"Select: Contact using IRC:\t0"
			));                # 72
		ok($block->raw_value,
			join('',
				" Ask: What is your name?\015",
				" Ask: Where are you from?\tMontana\015",
				" Choose: What is your favorite color?\tred\tgreen\tblue\015",
				" Select: Contact using Email:\t1\015",
				" Select: Contact using Instant Messenger:\t1\015",
				" Select: Contact using IRC:\t0"
			));                # 73
		ok($block->is_attributes); # 74



		my @queries = $block->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 75
		ok($queries[0]->{'question'}, 'What is your name?'); # 76
		ok(!defined $queries[0]->{'value'});                 # 77
		ok(!exists $queries[0]->{'choices'});                # 78

		ok($queries[1]->{'type'}, 'Ask');                     # 79
		ok($queries[1]->{'question'}, 'Where are you from?'); # 80
		ok($queries[1]->{'value'}, 'Montana');                # 81
		ok(!exists $queries[1]->{'choices'});                 # 82

		ok($queries[2]->{'type'}, 'Choose');         # 83
		ok($queries[2]->{'question'},
			'What is your favorite color?');     # 84
		ok(!exists $queries[2]->{'value'});          # 85
		ok(ref $queries[2]->{'choices'}, 'ARRAY');   # 86
		ok($queries[2]->{'choices'}->[0], 'red');    # 87
		ok($queries[2]->{'choices'}->[1], 'green');  # 88
		ok($queries[2]->{'choices'}->[2], 'blue');   # 89
		ok(scalar @{ $queries[2]->{'choices'} }, 3); # 90

		ok($queries[3]->{'type'}, 'Select');                   # 91
		ok($queries[3]->{'question'}, 'Contact using Email:'); # 92
		ok($queries[3]->{'value'}, '1');                       # 93
		ok(!exists $queries[3]->{'choices'});                  # 94

		ok($queries[4]->{'type'}, 'Select');                               # 95
		ok($queries[4]->{'question'}, 'Contact using Instant Messenger:'); # 96
		ok($queries[4]->{'value'}, '1');                                   # 97
		ok(!exists $queries[4]->{'choices'});                              # 98

		ok($queries[5]->{'type'}, 'Select');                 # 99
		ok($queries[5]->{'question'}, 'Contact using IRC:'); # 100
		ok($queries[5]->{'value'}, '0');                     # 101
		ok(!exists $queries[5]->{'choices'});                # 102

		ok(scalar @queries, 6); # 103
	}





	{
		my ($type, $display, $selector, $host, $port, $gp) =
			$response->extract_description;

		ok($type, GOPHER_MENU_TYPE);                        # 104
		ok($display, 'Gopher+ Index');                      # 105
		ok($selector, '/gp_index');                         # 106
		ok($host, 'localhost');                             # 107
		ok($port, 70);                                      # 108
		ok($gp, '+');                                       # 109
	}

	{
		my ($admin_name, $admin_email) = $response->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 110
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 111

		{
			my ($sec, $min, $hour, $mday, $mon,
			    $year, $wday, $yday, $isdst) =
				localtime $response->extract_date_modified;
			ok($sec, 12);   # 112
			ok($min, 30);   # 113
			ok($hour, 17);  # 114
			ok($mday, 28);  # 115
			ok($mon, 6);    # 116
			ok($year, 103); # 117
			ok($wday, 1);   # 118
			ok($yday, 208); # 119
			ok($isdst, 1);  # 120
		}

		{
			my ($sec, $min, $hour, $mday, $mon,
			    $year, $wday, $yday, $isdst) =
				localtime $response->extract_date_created;
			ok($sec, 1);    # 121
			ok($min, 2);    # 122
			ok($hour, 17);  # 123
			ok($mday, 28);  # 124
			ok($mon, 6);    # 125
			ok($year, 103); # 126
			ok($wday, 1);   # 127
			ok($yday, 208); # 128
			ok($isdst, 1);  # 129
		}

		{
			my ($sec, $min, $hour, $mday, $mon,
			    $year, $wday, $yday, $isdst) =
				localtime $response->extract_date_expires;
			ok($sec, 1);    # 130
			ok($min, 0);    # 131
			ok($hour, 9);   # 132
			ok($mday, 9);   # 133
			ok($mon, 8);    # 134
			ok($year, 103); # 135
			ok($wday, 2);   # 136
			ok($yday, 251); # 137
			ok($isdst, 1);  # 138
		}
	}

	{
		my @views = $response->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 139
		ok(!defined $views[0]->{'language'});  # 140
		ok(!defined $views[0]->{'country'});   # 141
		ok($views[0]->{'size'}, 410);          # 142

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 143
		ok($views[1]->{'language'}, 'En');                   # 144
		ok($views[1]->{'country'}, 'US');                    # 145
		ok($views[1]->{'size'}, 1200);                       # 146

		ok($views[2]->{'type'}, 'text/html'); # 147
		ok(!defined $views[2]->{'language'}); # 148
		ok(!defined $views[2]->{'country'});  # 149
		ok($views[2]->{'size'}, 789);         # 150

		ok(scalar @views, 3); # 151
	}

	{
		my @queries = $response->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 152
		ok($queries[0]->{'question'}, 'What is your name?'); # 153
		ok(!defined $queries[0]->{'value'});                 # 154
		ok(!exists $queries[0]->{'choices'});                # 155

		ok($queries[1]->{'type'}, 'Ask');                     # 156
		ok($queries[1]->{'question'}, 'Where are you from?'); # 157
		ok($queries[1]->{'value'}, 'Montana');                # 158
		ok(!exists $queries[1]->{'choices'});                 # 159

		ok($queries[2]->{'type'}, 'Choose');         # 160
		ok($queries[2]->{'question'},
			'What is your favorite color?');     # 161
		ok(!exists $queries[2]->{'value'});          # 162
		ok(ref $queries[2]->{'choices'}, 'ARRAY');   # 163
		ok($queries[2]->{'choices'}->[0], 'red');    # 164
		ok($queries[2]->{'choices'}->[1], 'green');  # 165
		ok($queries[2]->{'choices'}->[2], 'blue');   # 166
		ok(scalar @{ $queries[2]->{'choices'} }, 3); # 167

		ok($queries[3]->{'type'}, 'Select');                   # 168
		ok($queries[3]->{'question'}, 'Contact using Email:'); # 169
		ok($queries[3]->{'value'}, '1');                       # 170
		ok(!exists $queries[3]->{'choices'});                  # 171

		ok($queries[4]->{'type'}, 'Select');                               # 172
		ok($queries[4]->{'question'}, 'Contact using Instant Messenger:'); # 173
		ok($queries[4]->{'value'}, '1');                                   # 174
		ok(!exists $queries[4]->{'choices'});                              # 175

		ok($queries[5]->{'type'}, 'Select');                 # 176
		ok($queries[5]->{'question'}, 'Contact using IRC:'); # 177
		ok($queries[5]->{'value'}, '0');                     # 178
		ok(!exists $queries[5]->{'choices'});                # 179

		ok(scalar @queries, 6); # 180
	}
}





{
	my $ng = new Net::Gopher;

	my $response = $ng->directory_attribute(
		Host     => 'localhost',
		Selector => '/directory_blocks'
	);

	ok($response->is_success); # 181



	{
		ok($response->has_block('ADMIN', Item => 1)); # 182

		my $block = $response->get_block('+ADMIN', Item => 1);

		ok($block->name, '+ADMIN');             # 183
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 184
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 185
	}

	{
		ok($response->has_block('INFO', [Item => 2])); # 186

		my $block = $response->get_block('INFO', {Item => 2});

		ok($block->name, '+INFO');           # 187
		ok($block->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 188
		ok($block->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 189
	}

	{
		ok($response->has_block('ADMIN', [
			Item => {
				Selector => '/gp_period_term'
			}
		])); # 190

		my $block = $response->get_block('ADMIN',
			[Item => [Display => 'Period terminated file']]
		);

		ok($block->name, '+ADMIN');             # 191
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 192
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 193

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
		])); # 194

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

		ok($block->name, '+ADMIN');             # 195
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 196
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 197
	}

	{
		ok($response->has_block('+ADMIN', 
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		)); # 198

		my $block = $response->get_block('ADMIN',
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		);

		ok($block->name, '+ADMIN');             # 199
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 200
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 201
	}

	{
		ok(!$response->has_block('ADMIN',
			Item => {Display => 'bad display'})); # 202

		my $block = $response->get_block('ADMIN',
			Item => {
				Display => 'Bad display'
			}
		);

		ok(!defined $block); # 203
	}

	{
		my @directory_information = $response->get_blocks;

		ok(scalar @directory_information, 4); # 204



		my @gp_index = @{ shift @directory_information };

		ok($gp_index[0]->name, '+INFO');                       # 205
		ok($gp_index[0]->value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 206
		ok($gp_index[0]->raw_value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 207

		ok($gp_index[1]->name, '+ADMIN');       # 208
		ok($gp_index[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 209
		ok($gp_index[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 210



		my @gp_byte_term = @{ shift @directory_information };

		ok($gp_byte_term[0]->name, '+INFO'); # 211
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 212
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 213

		ok($gp_byte_term[1]->name, '+ADMIN');   # 214
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 215
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 216



		my @gp_period_term = @{ shift @directory_information };

		ok($gp_period_term[0]->name, '+INFO'); # 217
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 218
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 219

		ok($gp_period_term[1]->name, '+ADMIN'); # 220
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 221
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 222



		my @gp_no_term = @{ shift @directory_information };

		ok($gp_no_term[0]->name, '+INFO'); # 223
		ok($gp_no_term[0]->value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");       # 224
		ok($gp_no_term[0]->raw_value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");        # 225

		ok($gp_no_term[1]->name, '+ADMIN');     # 226
		ok($gp_no_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 227
		ok($gp_no_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 228
	}

	{
		my @gp_byte_term = $response->get_blocks(Item => 2);

		ok(scalar @gp_byte_term, 2); # 229

		ok($gp_byte_term[0]->name, '+INFO'); # 230
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 231
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 232

		ok($gp_byte_term[1]->name, '+ADMIN');   # 233
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 234
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 235
	}

	{
		my @gp_period_term = $response->get_blocks(
			Item => {
				Display  => 'Period terminated file',
				Selector => '/gp_period_term'
			}
		);

		ok(scalar @gp_period_term, 2); # 236

		ok($gp_period_term[0]->name, '+INFO'); # 237
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 238
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 239

		ok($gp_period_term[1]->name, '+ADMIN'); # 240
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 241
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 242
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

	ok($response->is_success); # 243

	# there are no blocks, so we should get errors when we try to parse
	# them:
	ok(!$response->has_block('Something')); # 244

	ok(scalar @warnings, 1);     # 245
	ok($warnings[0], join(' ',
		"You didn't send an item attribute or directory",
		"attribute information request, so why would the",
		"response contain attribute information blocks?"
	));                          # 246
	ok(scalar @fatal_errors, 1); # 247
	ok($fatal_errors[0], join(' ',
		'There was no leading "+" for the first block name at',
		'the beginning of the response. The response either',
		'does not contain any attribute information blocks or',
		'contains malformed attribute information blocks.'
	));                          # 248
}

ok(kill_server()); # 249
