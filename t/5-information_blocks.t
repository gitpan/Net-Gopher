use strict;
use warnings;
use Test;

BEGIN { plan(tests => 215) }

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
				"Select: Contact using:\tEmail\tInstant messages\tIRC"
			));                # 71
		ok($block->raw_value,
			join('',
				" Ask: What is your name?\015",
				" Ask: Where are you from?\tMontana\015",
				" Choose: What is your favorite color?\tred\tgreen\tblue\015",
				" Select: Contact using:\tEmail\tInstant messages\tIRC"
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
		ok($queries[3]->{'question'}, 'Contact using:');       # 91
		ok(!exists $queries[3]->{'value'});                    # 92
		ok(ref $queries[3]->{'choices'}, 'ARRAY');             # 93
		ok($queries[3]->{'choices'}->[0], 'Email');            # 94
		ok($queries[3]->{'choices'}->[1], 'Instant messages'); # 95
		ok($queries[3]->{'choices'}->[2], 'IRC');              # 96
		ok(scalar @{ $queries[3]->{'choices'} }, 3);           # 97

		ok(scalar @queries, 4); # 98
	}





	{
		my ($type, $display, $selector, $host, $port, $gp) =
			$response->extract_description;

		ok($type, GOPHER_MENU_TYPE);                        # 99
		ok($display, 'Gopher+ Index');                      # 100
		ok($selector, '/gp_index');                         # 101
		ok($host, 'localhost');                             # 102
		ok($port, 70);                                      # 103
		ok($gp, '+');                                       # 104
	}

	{
		my ($admin_name, $admin_email) = $response->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 105
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 106

		ok($response->extract_date_modified, 1059427812); # 107
		ok($response->extract_date_created, 1059426121);  # 108
		ok($response->extract_date_expires, 1063112401);  # 109
	}

	{
		my @views = $response->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 110
		ok(!defined $views[0]->{'language'});  # 111
		ok(!defined $views[0]->{'country'});   # 112
		ok($views[0]->{'size'}, 410);          # 113

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 114
		ok($views[1]->{'language'}, 'En');                   # 115
		ok($views[1]->{'country'}, 'US');                    # 116
		ok($views[1]->{'size'}, 1200);                       # 117

		ok($views[2]->{'type'}, 'text/html'); # 118
		ok(!defined $views[2]->{'language'}); # 119
		ok(!defined $views[2]->{'country'});  # 120
		ok($views[2]->{'size'}, 789);         # 121

		ok(scalar @views, 3); # 122
	}

	{
		my @queries = $response->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 123
		ok($queries[0]->{'question'}, 'What is your name?'); # 124
		ok(!defined $queries[0]->{'value'});                 # 125
		ok(!exists $queries[0]->{'choices'});                # 126

		ok($queries[1]->{'type'}, 'Ask');                     # 127
		ok($queries[1]->{'question'}, 'Where are you from?'); # 128
		ok($queries[1]->{'value'}, 'Montana');                # 129
		ok(!exists $queries[1]->{'choices'});                 # 130

		ok($queries[2]->{'type'}, 'Choose');         # 131
		ok($queries[2]->{'question'},
			'What is your favorite color?');     # 132
		ok(!exists $queries[2]->{'value'});          # 133
		ok(ref $queries[2]->{'choices'}, 'ARRAY');   # 134
		ok($queries[2]->{'choices'}->[0], 'red');    # 135
		ok($queries[2]->{'choices'}->[1], 'green');  # 136
		ok($queries[2]->{'choices'}->[2], 'blue');   # 137
		ok(scalar @{ $queries[2]->{'choices'} }, 3); # 138

		ok($queries[3]->{'type'}, 'Select');                   # 139
		ok($queries[3]->{'question'}, 'Contact using:');       # 140
		ok(!exists $queries[3]->{'value'});                    # 141
		ok(ref $queries[3]->{'choices'}, 'ARRAY');             # 142
		ok($queries[3]->{'choices'}->[0], 'Email');            # 143
		ok($queries[3]->{'choices'}->[1], 'Instant messages'); # 144
		ok($queries[3]->{'choices'}->[2], 'IRC');              # 145
		ok(scalar @{ $queries[3]->{'choices'} }, 3);           # 146

		ok(scalar @queries, 4); # 147
	}
}





{
	my $ng = new Net::Gopher;

	my $response = $ng->directory_attribute(
		Host     => 'localhost',
		Selector => '/directory_blocks'
	);

	ok($response->is_success); # 148



	{
		ok($response->has_block('ADMIN', Item => 1)); # 149

		my $block = $response->get_block('+ADMIN', Item => 1);

		ok($block->name, '+ADMIN');             # 150
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 151
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 152
	}

	{
		ok($response->has_block('INFO', [Item => 2])); # 153

		my $block = $response->get_block('INFO', {Item => 2});

		ok($block->name, '+INFO');           # 154
		ok($block->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 155
		ok($block->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 156
	}

	{
		ok($response->has_block('ADMIN', [
			Item => {
				Selector => '/gp_period_term'
			}
		])); # 157

		my $block = $response->get_block('ADMIN',
			[Item => [Display => 'Period terminated file']]
		);

		ok($block->name, '+ADMIN');             # 158
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 159
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 160

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
		])); # 161

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

		ok($block->name, '+ADMIN');             # 162
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 163
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 164
	}

	{
		ok($response->has_block('+ADMIN', 
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		)); # 165

		my $block = $response->get_block('ADMIN',
			Item => {
				N          => 2,
				Display    => qr/Byte terminated/,
				Selector   => '/gp_byte_term',
			}
		);

		ok($block->name, '+ADMIN');             # 166
		ok($block->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 167
		ok($block->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 168
	}

	{
		ok(!$response->has_block('ADMIN',
			Item => {Display => 'bad display'})); # 169

		my $block = $response->get_block('ADMIN',
			Item => {
				Display => 'Bad display'
			}
		);

		ok(!defined $block); # 170
	}

	{
		my @directory_information = $response->get_blocks;

		ok(scalar @directory_information, 4); # 171



		my @gp_index = @{ shift @directory_information };

		ok($gp_index[0]->name, '+INFO');                       # 172
		ok($gp_index[0]->value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 173
		ok($gp_index[0]->raw_value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 174

		ok($gp_index[1]->name, '+ADMIN');       # 175
		ok($gp_index[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 176
		ok($gp_index[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 177



		my @gp_byte_term = @{ shift @directory_information };

		ok($gp_byte_term[0]->name, '+INFO'); # 178
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 179
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 180

		ok($gp_byte_term[1]->name, '+ADMIN');   # 181
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 182
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 183



		my @gp_period_term = @{ shift @directory_information };

		ok($gp_period_term[0]->name, '+INFO'); # 184
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 185
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 186

		ok($gp_period_term[1]->name, '+ADMIN'); # 187
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 188
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 189



		my @gp_no_term = @{ shift @directory_information };

		ok($gp_no_term[0]->name, '+INFO'); # 190
		ok($gp_no_term[0]->value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");       # 191
		ok($gp_no_term[0]->raw_value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");        # 192

		ok($gp_no_term[1]->name, '+ADMIN');     # 193
		ok($gp_no_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 194
		ok($gp_no_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 195
	}

	{
		my @gp_byte_term = $response->get_blocks(Item => 2);

		ok(scalar @gp_byte_term, 2); # 196

		ok($gp_byte_term[0]->name, '+INFO'); # 197
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 198
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 199

		ok($gp_byte_term[1]->name, '+ADMIN');   # 200
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 201
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 202
	}

	{
		my @gp_period_term = $response->get_blocks(
			Item => {
				Display  => 'Period terminated file',
				Selector => '/gp_period_term'
			}
		);

		ok(scalar @gp_period_term, 2); # 203

		ok($gp_period_term[0]->name, '+INFO'); # 204
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 205
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 206

		ok($gp_period_term[1]->name, '+ADMIN'); # 207
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 208
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 209
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

	ok($response->is_success); # 210

	# there are no blocks, so we should get errors when we try to parse
	# them:
	ok(!$response->has_block('Something')); # 211

	ok(scalar @warnings, 1);     # 212
	ok($warnings[0], join(' ',
		"You didn't send an item attribute or directory",
		"attribute information request, so why would the",
		"response contain attribute information blocks?"
	));                          # 213
	ok(scalar @fatal_errors, 1); # 214
	ok($fatal_errors[0], join(' ',
		'There was no leading "+" for the first block name at',
		'the beginning of the response. The response either',
		'does not contain any attribute information blocks or',
		'contains malformed attribute information blocks.'
	));                          # 215
}

kill_server();
