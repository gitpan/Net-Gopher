use strict;
use warnings;
use Test;

BEGIN { plan(tests => 247) }

use Net::Gopher;
use Net::Gopher::Constants qw(:item_types :request);
use Net::Gopher::Utility '$CRLF';

require './t/serverfunctions.pl';





run_server();

{
	my $ng = new Net::Gopher;

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Selector => '/item_blocks'
	);

	ok($response->is_success); # 1

	{
		ok($response->has_block('INFO')); # 2

		my $block = $response->get_block('+INFO');

		ok($block->name, '+INFO');                              # 3
		ok($block->value,
			"1Gopher+ Index\t/gp_index\tlocalhost\t70\t+"); # 4
		ok($block->raw_value,
			"1Gopher+ Index\t/gp_index\tlocalhost\t70\t+"); # 5
		ok(!$block->is_attributes);                             # 6

		my ($type, $display, $selector, $host, $port, $gp) =
			$block->extract_description;

		ok($type, GOPHER_MENU_TYPE);                        # 7
		ok($display, 'Gopher+ Index');                      # 8
		ok($selector, '/gp_index');                         # 9
		ok($host, 'localhost');                             # 10
		ok($port, 70);                                      # 11
		ok($gp, '+');                                       # 12
		ok($block->as_url,
			"gopher://localhost:70/1/gp_index%09%09+"); # 13

		{
			my $request = $block->as_request;

			ok($request->as_string, "/gp_index\t+$CRLF");       # 14
			ok($request->as_url,
				'gopher://localhost:70/1/gp_index%09%09+'); # 15
			ok($request->request_type, GOPHER_PLUS_REQUEST);    # 16
			ok($request->host, 'localhost');                    # 17
			ok($request->port, 70);                             # 18
			ok($request->selector, '/gp_index');                # 19
			ok(!defined $request->search_words);                # 20
			ok(!defined $request->representation);              # 21
			ok(!defined $request->data_block);                  # 22
			ok(!defined $request->attributes);                  # 23
			ok($request->item_type, GOPHER_MENU_TYPE);          # 24
		}
	}

	{
		ok($response->has_block('ADMIN')); # 25

		my $block = $response->get_block('+ADMIN');

		ok($block->name, '+ADMIN');                         # 26
		ok($block->value,
			join('',
				"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n",
				"Mod-Date: <20030728173012>\n",
				"Creation-Date: <20030728170201>\n",
				"Expiration-Date: <20030909090001>"
			));                                         # 27
		ok($block->raw_value,
			join('',
				" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\015",
				" Mod-Date: <20030728173012>\015",
				" Creation-Date: <20030728170201>\015",
				" Expiration-Date: <20030909090001>"
			));                                         # 28
		ok($block->is_attributes);                          # 29
		ok($block->has_attribute('Admin'));                 # 30
		ok($block->get_attribute('Admin'),
			'John Q. Sixpack <j_q_sixpack@yahoo.com>'); # 31
		ok($block->has_attribute('Mod-Date'));              # 32
		ok($block->get_attribute('Mod-Date'),
			'<20030728173012>');                        # 33
		ok($block->has_attribute('Creation-Date'));         # 34
		ok($block->get_attribute('Creation-Date'),
			'<20030728170201>');                        # 35
		ok($block->has_attribute('Expiration-Date'));       # 36
		ok($block->get_attribute('Expiration-Date'),
			'<20030909090001>');                        # 37



		my %attributes = $block->get_attributes;
		ok($attributes{'Admin'},
			'John Q. Sixpack <j_q_sixpack@yahoo.com>');    # 38
		ok($attributes{'Mod-Date'}, '<20030728173012>');       # 39
		ok($attributes{'Creation-Date'}, '<20030728170201>');  # 40
		ok($attributes{'Expiration-Date'},'<20030909090001>'); # 41



		my $attributes = $block->get_attributes;
		ok($attributes->{'Admin'},
			'John Q. Sixpack <j_q_sixpack@yahoo.com>');      # 42
		ok($attributes->{'Mod-Date'}, '<20030728173012>');       # 43
		ok($attributes->{'Creation-Date'}, '<20030728170201>');  # 44
		ok($attributes->{'Expiration-Date'},'<20030909090001>'); # 45



		my ($admin_name, $admin_email) = $block->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 46
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 47

		ok($block->extract_date_modified, 1059427812); # 48
		ok($block->extract_date_created, 1059426121);  # 49
		ok($block->extract_date_expires, 1063112401);  # 50
	}

	{
		ok($response->has_block('+VIEWS')); # 51

		my $block = $response->get_block('VIEWS');

		ok($block->name, '+VIEWS'); # 52
		ok($block->value,
			join('',
				"text/plain: <.40k>\n",
				"application/gopher+-menu En_US: <1200b>\n",
				"text/html: <.77KB>"
			));                 # 53
		ok($block->raw_value,
			join('',
				" text/plain: <.40k>\015",
				" application/gopher+-menu En_US: <1200b>\015",
				" text/html: <.77KB>"
			));                 # 54
		ok($block->is_attributes);  # 55



		my @views = $block->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 56
		ok(!defined $views[0]->{'language'});  # 57
		ok(!defined $views[0]->{'country'});   # 58
		ok($views[0]->{'size'}, 410);          # 59

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 60
		ok($views[1]->{'language'}, 'En');                   # 61
		ok($views[1]->{'country'}, 'US');                    # 62
		ok($views[1]->{'size'}, 1200);                       # 63

		ok($views[2]->{'type'}, 'text/html'); # 64
		ok(!defined $views[2]->{'language'}); # 65
		ok(!defined $views[2]->{'country'});  # 66
		ok($views[2]->{'size'}, 789);         # 67

		ok(scalar @views, 3); # 68
	}

	{
	
		ok($response->has_block('ASK')); # 69

		my $block = $response->get_block('ASK');

		ok($block->name, '+ASK');  # 70
		ok($block->value,
			join('',
				"Ask: What is your name?\n",
				"Ask: Where are you from?\tMontana\n",
				"Choose: What is your favorite color?\tred\tgreen\tblue\n",
				"Select: Contact using Email:\t1\n",
				"Select: Contact using Instant Messenger:\t1\n",
				"Select: Contact using IRC:\t0"
			));                # 71
		ok($block->raw_value,
			join('',
				" Ask: What is your name?\015",
				" Ask: Where are you from?\tMontana\015",
				" Choose: What is your favorite color?\tred\tgreen\tblue\015",
				" Select: Contact using Email:\t1\015",
				" Select: Contact using Instant Messenger:\t1\015",
				" Select: Contact using IRC:\t0"
			));                # 72
		ok($block->is_attributes); # 73



		my @queries = $block->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 74
		ok($queries[0]->{'question'}, 'What is your name?'); # 75
		ok(!defined $queries[0]->{'value'});                 # 76
		ok(!exists $queries[0]->{'choices'});                # 77

		ok($queries[1]->{'type'}, 'Ask');                     # 78
		ok($queries[1]->{'question'}, 'Where are you from?'); # 79
		ok($queries[1]->{'value'}, 'Montana');                # 80
		ok(!exists $queries[1]->{'choices'});                 # 81

		ok($queries[2]->{'type'}, 'Choose');         # 82
		ok($queries[2]->{'question'},
			'What is your favorite color?');     # 83
		ok(!exists $queries[2]->{'value'});          # 84
		ok(ref $queries[2]->{'choices'}, 'ARRAY');   # 85
		ok($queries[2]->{'choices'}->[0], 'red');    # 86
		ok($queries[2]->{'choices'}->[1], 'green');  # 87
		ok($queries[2]->{'choices'}->[2], 'blue');   # 88
		ok(scalar @{ $queries[2]->{'choices'} }, 3); # 89

		ok($queries[3]->{'type'}, 'Select');                   # 90
		ok($queries[3]->{'question'}, 'Contact using Email:'); # 91
		ok($queries[3]->{'value'}, '1');                       # 92
		ok(!exists $queries[3]->{'choices'});                  # 93

		ok($queries[4]->{'type'}, 'Select');                               # 94
		ok($queries[4]->{'question'}, 'Contact using Instant Messenger:'); # 95
		ok($queries[4]->{'value'}, '1');                                   # 96
		ok(!exists $queries[4]->{'choices'});                              # 97

		ok($queries[5]->{'type'}, 'Select');                 # 98
		ok($queries[5]->{'question'}, 'Contact using IRC:'); # 99
		ok($queries[5]->{'value'}, '0');                     # 100
		ok(!exists $queries[5]->{'choices'});                # 101

		ok(scalar @queries, 6); # 102
	}





	{
		my ($type, $display, $selector, $host, $port, $gp) =
			$response->extract_description;

		ok($type, GOPHER_MENU_TYPE);                        # 103
		ok($display, 'Gopher+ Index');                      # 104
		ok($selector, '/gp_index');                         # 105
		ok($host, 'localhost');                             # 106
		ok($port, 70);                                      # 107
		ok($gp, '+');                                       # 108
	}

	{
		my ($admin_name, $admin_email) = $response->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 109
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 110

		{
			my ($sec, $min, $hour, $mday, $mon,
			    $year, $wday, $yday, $isdst) =
				localtime $response->extract_date_modified;
			ok($sec, 12);   # 111
			ok($min, 30);   # 112
			ok($hour, 17);  # 113
			ok($mday, 28);  # 114
			ok($mon, 6);    # 115
			ok($year, 103); # 116
			ok($wday, 1);   # 117
			ok($yday, 208); # 118
			ok($isdst, 1);  # 119
		}

		{
			my ($sec, $min, $hour, $mday, $mon,
			    $year, $wday, $yday, $isdst) =
				localtime $response->extract_date_created;
			ok($sec, 1);    # 120
			ok($min, 2);    # 121
			ok($hour, 17);  # 122
			ok($mday, 28);  # 123
			ok($mon, 6);    # 124
			ok($year, 103); # 125
			ok($wday, 1);   # 126
			ok($yday, 208); # 127
			ok($isdst, 1);  # 128
		}

		{
			my ($sec, $min, $hour, $mday, $mon,
			    $year, $wday, $yday, $isdst) =
				localtime $response->extract_date_expires;
			ok($sec, 1);    # 129
			ok($min, 0);    # 130
			ok($hour, 9);   # 131
			ok($mday, 9);   # 132
			ok($mon, 8);    # 133
			ok($year, 103); # 134
			ok($wday, 2);   # 135
			ok($yday, 251); # 136
			ok($isdst, 1);  # 137
		}
	}

	{
		my @views = $response->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 138
		ok(!defined $views[0]->{'language'});  # 139
		ok(!defined $views[0]->{'country'});   # 140
		ok($views[0]->{'size'}, 410);          # 141

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 142
		ok($views[1]->{'language'}, 'En');                   # 143
		ok($views[1]->{'country'}, 'US');                    # 144
		ok($views[1]->{'size'}, 1200);                       # 145

		ok($views[2]->{'type'}, 'text/html'); # 146
		ok(!defined $views[2]->{'language'}); # 147
		ok(!defined $views[2]->{'country'});  # 148
		ok($views[2]->{'size'}, 789);         # 149

		ok(scalar @views, 3); # 150
	}

	{
		my @queries = $response->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 151
		ok($queries[0]->{'question'}, 'What is your name?'); # 152
		ok(!defined $queries[0]->{'value'});                 # 153
		ok(!exists $queries[0]->{'choices'});                # 154

		ok($queries[1]->{'type'}, 'Ask');                     # 155
		ok($queries[1]->{'question'}, 'Where are you from?'); # 156
		ok($queries[1]->{'value'}, 'Montana');                # 157
		ok(!exists $queries[1]->{'choices'});                 # 158

		ok($queries[2]->{'type'}, 'Choose');         # 159
		ok($queries[2]->{'question'},
			'What is your favorite color?');     # 160
		ok(!exists $queries[2]->{'value'});          # 161
		ok(ref $queries[2]->{'choices'}, 'ARRAY');   # 162
		ok($queries[2]->{'choices'}->[0], 'red');    # 163
		ok($queries[2]->{'choices'}->[1], 'green');  # 164
		ok($queries[2]->{'choices'}->[2], 'blue');   # 165
		ok(scalar @{ $queries[2]->{'choices'} }, 3); # 166

		ok($queries[3]->{'type'}, 'Select');                   # 167
		ok($queries[3]->{'question'}, 'Contact using Email:'); # 168
		ok($queries[3]->{'value'}, '1');                       # 169
		ok(!exists $queries[3]->{'choices'});                  # 170

		ok($queries[4]->{'type'}, 'Select');                               # 171
		ok($queries[4]->{'question'}, 'Contact using Instant Messenger:'); # 172
		ok($queries[4]->{'value'}, '1');                                   # 173
		ok(!exists $queries[4]->{'choices'});                              # 174

		ok($queries[5]->{'type'}, 'Select');                 # 175
		ok($queries[5]->{'question'}, 'Contact using IRC:'); # 176
		ok($queries[5]->{'value'}, '0');                     # 177
		ok(!exists $queries[5]->{'choices'});                # 178

		ok(scalar @queries, 6); # 179
	}
}





{
	my $ng = new Net::Gopher;

	my $response = $ng->directory_attribute(
		Host     => 'localhost',
		Selector => '/directory_blocks'
	);

	ok($response->is_success); # 180



	{
		ok($response->has_block('ADMIN', Item => 1)); # 181

		my $block = $response->get_block('+ADMIN', Item => 1);

		ok($block->name, '+ADMIN');             # 182
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 183
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 184
	}

	{
		ok($response->has_block('INFO', [Item => 2])); # 185

		my $block = $response->get_block('INFO', {Item => 2});

		ok($block->name, '+INFO');           # 186
		ok($block->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 187
		ok($block->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 188
	}

	{
		ok($response->has_block('ADMIN', [
			Item => {
				Selector => '/gp_period_term'
			}
		])); # 189

		my $block = $response->get_block('ADMIN',
			[Item => [Display => 'Period terminated file']]
		);

		ok($block->name, '+ADMIN');             # 190
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 191
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 192

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
		])); # 193

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

		ok($block->name, '+ADMIN');             # 194
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 195
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 196
	}

	{
		ok($response->has_block('+ADMIN', 
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		)); # 197

		my $block = $response->get_block('ADMIN',
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		);

		ok($block->name, '+ADMIN');             # 198
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 199
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 200
	}

	{
		ok(!$response->has_block('ADMIN',
			Item => {Display => 'bad display'})); # 201

		my $block = $response->get_block('ADMIN',
			Item => {
				Display => 'Bad display'
			}
		);

		ok(!defined $block); # 202
	}

	{
		my @directory_information = $response->get_blocks;

		ok(scalar @directory_information, 4); # 203



		my @gp_index = @{ shift @directory_information };

		ok($gp_index[0]->name, '+INFO');                       # 204
		ok($gp_index[0]->value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 205
		ok($gp_index[0]->raw_value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 206

		ok($gp_index[1]->name, '+ADMIN');       # 207
		ok($gp_index[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 208
		ok($gp_index[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 209



		my @gp_byte_term = @{ shift @directory_information };

		ok($gp_byte_term[0]->name, '+INFO'); # 210
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 211
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 212

		ok($gp_byte_term[1]->name, '+ADMIN');   # 213
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 214
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 215



		my @gp_period_term = @{ shift @directory_information };

		ok($gp_period_term[0]->name, '+INFO'); # 216
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 217
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 218

		ok($gp_period_term[1]->name, '+ADMIN'); # 219
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 220
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 221



		my @gp_no_term = @{ shift @directory_information };

		ok($gp_no_term[0]->name, '+INFO'); # 222
		ok($gp_no_term[0]->value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");       # 223
		ok($gp_no_term[0]->raw_value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");        # 224

		ok($gp_no_term[1]->name, '+ADMIN');     # 225
		ok($gp_no_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 226
		ok($gp_no_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 227
	}

	{
		my @gp_byte_term = $response->get_blocks(Item => 2);

		ok(scalar @gp_byte_term, 2); # 228

		ok($gp_byte_term[0]->name, '+INFO'); # 229
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 230
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 231

		ok($gp_byte_term[1]->name, '+ADMIN');   # 232
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 233
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 234
	}

	{
		my @gp_period_term = $response->get_blocks(
			Item => {
				Display  => 'Period terminated file',
				Selector => '/gp_period_term'
			}
		);

		ok(scalar @gp_period_term, 2); # 235

		ok($gp_period_term[0]->name, '+INFO'); # 236
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 237
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 238

		ok($gp_period_term[1]->name, '+ADMIN'); # 239
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 240
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 241
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

	ok($response->is_success); # 242

	# there are no blocks, so we should get errors when we try to parse
	# them:
	ok(!$response->has_block('Something')); # 243

	ok(scalar @warnings, 1);     # 244
	ok($warnings[0], join(' ',
		"You didn't send an item attribute or directory",
		"attribute information request, so why would the",
		"response contain attribute information blocks?"
	));                          # 245
	ok(scalar @fatal_errors, 1); # 246
	ok($fatal_errors[0], join(' ',
		'There was no leading "+" for the first block name at',
		'the beginning of the response. The response either',
		'does not contain any attribute information blocks or',
		'contains malformed attribute information blocks.'
	));                          # 247
}

kill_server();
