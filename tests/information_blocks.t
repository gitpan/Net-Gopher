use strict;
use warnings;
use Test;

BEGIN { plan(tests => 149) }

use Net::Gopher;
use Net::Gopher::Constants qw(:item_types :request);
use Net::Gopher::Utility '$CRLF';

require './tests/serverfunctions.pl';





run_server();

{
	my $ng = new Net::Gopher;

	my $response = $ng->item_attribute(
		Host     => 'localhost',
		Selector => '/item_blocks'
	);

	ok($response->is_success); # 1

	{
		my $block = $response->get_block('+INFO');

		ok($block->name, '+INFO');                              # 2
		ok($block->value,
			"1Gopher+ Index\t/gp_index\tlocalhost\t70\t+"); # 3
		ok($block->raw_value,
			"1Gopher+ Index\t/gp_index\tlocalhost\t70\t+"); # 4
		ok(!$block->is_attributes);                             # 5

		my ($type, $display, $selector, $host, $port, $gp) =
			$block->extract_description;

		ok($type, GOPHER_MENU_TYPE);                        # 6
		ok($display, 'Gopher+ Index');                      # 7
		ok($selector, '/gp_index');                         # 8
		ok($host, 'localhost');                             # 9
		ok($port, 70);                                      # 10
		ok($gp, '+');                                       # 11
		ok($block->as_url,
			"gopher://localhost:70/1/gp_index%09%09+"); # 12

		{
			my $request = $block->as_request;

			ok($request->as_string, "/gp_index\t+$CRLF");       # 13
			ok($request->as_url,
				'gopher://localhost:70/1/gp_index%09%09+'); # 14
			ok($request->request_type, GOPHER_PLUS_REQUEST);    # 15
			ok($request->host, 'localhost');                    # 16
			ok($request->port, 70);                             # 17
			ok($request->selector, '/gp_index');                # 18
			ok(!defined $request->search_words);                # 19
			ok(!defined $request->representation);              # 20
			ok(!defined $request->data_block);                  # 21
			ok(!defined $request->attributes);                  # 22
			ok($request->item_type, GOPHER_MENU_TYPE);          # 23
		}
	}

	{
		my $block = $response->get_block('+ADMIN');

		ok($block->name, '+ADMIN');                         # 24
		ok($block->value,
			join('',
				"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n",
				"Mod-Date: <20030728173012>\n",
				"Creation-Date: <20030728170201>\n",
				"Expiration-Date: <20030909090001>"
			));                                         # 25
		ok($block->raw_value,
			join('',
				" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\015",
				" Mod-Date: <20030728173012>\015",
				" Creation-Date: <20030728170201>\015",
				" Expiration-Date: <20030909090001>"
			));                                         # 26
		ok($block->is_attributes);                          # 27
		ok($block->has_attribute('Admin'));                 # 28
		ok($block->get_attribute('Admin'),
			'John Q. Sixpack <j_q_sixpack@yahoo.com>'); # 29
		ok($block->has_attribute('Mod-Date'));              # 30
		ok($block->get_attribute('Mod-Date'),
			'<20030728173012>');                        # 31
		ok($block->has_attribute('Creation-Date'));         # 32
		ok($block->get_attribute('Creation-Date'),
			'<20030728170201>');                        # 33
		ok($block->has_attribute('Expiration-Date'));       # 34
		ok($block->get_attribute('Expiration-Date'),
			'<20030909090001>');                        # 35

		my ($admin_name, $admin_email) = $block->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 36
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 37

		ok($block->extract_date_modified, 1059427812); # 38
		ok($block->extract_date_created, 1059426121);  # 39
		ok($block->extract_date_expires, 1063112401);  # 40
	}

	{
		my $block = $response->get_block('VIEWS');

		ok($block->name, '+VIEWS'); # 41
		ok($block->value,
			join('',
				"text/plain: <.40k>\n",
				"application/gopher+-menu En_US: <1200b>\n",
				"text/html: <.77KB>"
			));                 # 42
		ok($block->raw_value,
			join('',
				" text/plain: <.40k>\015",
				" application/gopher+-menu En_US: <1200b>\015",
				" text/html: <.77KB>"
			));                 # 43
		ok($block->is_attributes);  # 44



		my @views = $block->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 45
		ok(!defined $views[0]->{'language'});  # 46
		ok(!defined $views[0]->{'country'});   # 47
		ok($views[0]->{'size'}, 410);          # 48

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 49
		ok($views[1]->{'language'}, 'En');                   # 50
		ok($views[1]->{'country'}, 'US');                    # 51
		ok($views[1]->{'size'}, 1200);                       # 52

		ok($views[2]->{'type'}, 'text/html'); # 53
		ok(!defined $views[2]->{'language'}); # 54
		ok(!defined $views[2]->{'country'});  # 55
		ok($views[2]->{'size'}, 789);         # 56

		ok(scalar @views, 3); # 57
	}

	{
		my $block = $response->get_block('ASK');

		ok($block->name, '+ASK');  # 58
		ok($block->value,
			join('',
				"Ask: What is your name?\n",
				"Choose: What is your favorite color?\tred\tgreen\tblue\n",
				"Select: Contact using:\tEmail\tInstant messages\tIRC"
			));                # 59
		ok($block->raw_value,
			join('',
				" Ask: What is your name?\015",
				" Choose: What is your favorite color?\tred\tgreen\tblue\015",
				" Select: Contact using:\tEmail\tInstant messages\tIRC"
			));                # 60
		ok($block->is_attributes); # 61



		my @queries = $block->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 62
		ok($queries[0]->{'question'}, 'What is your name?'); # 63
		ok(ref $queries[0]->{'defaults'}, 'ARRAY');          # 64
		ok(scalar @{ $queries[0]->{'defaults'} }, 0);        # 65

		ok($queries[1]->{'type'}, 'Choose');          # 66
		ok($queries[1]->{'question'},
			'What is your favorite color?');      # 67
		ok(ref $queries[1]->{'defaults'}, 'ARRAY');   # 68
		ok($queries[1]->{'defaults'}->[0], 'red');    # 69
		ok($queries[1]->{'defaults'}->[1], 'green');  # 70
		ok($queries[1]->{'defaults'}->[2], 'blue');   # 71
		ok(scalar @{ $queries[1]->{'defaults'} }, 3); # 72

		ok($queries[2]->{'type'}, 'Select');                    # 73
		ok($queries[2]->{'question'}, 'Contact using:');        # 74
		ok(ref $queries[2]->{'defaults'}, 'ARRAY');             # 75
		ok($queries[2]->{'defaults'}->[0], 'Email');            # 76
		ok($queries[2]->{'defaults'}->[1], 'Instant messages'); # 77
		ok($queries[2]->{'defaults'}->[2], 'IRC');              # 78
		ok(scalar @{ $queries[2]->{'defaults'} }, 3);           # 79

		ok(scalar @queries, 3); # 80
	}





	{
		my ($type, $display, $selector, $host, $port, $gp) =
			$response->extract_description;

		ok($type, GOPHER_MENU_TYPE);                        # 81
		ok($display, 'Gopher+ Index');                      # 82
		ok($selector, '/gp_index');                         # 83
		ok($host, 'localhost');                             # 84
		ok($port, 70);                                      # 85
		ok($gp, '+');                                       # 86
	}

	{
		my ($admin_name, $admin_email) = $response->extract_admin;

		ok($admin_name, 'John Q. Sixpack');        # 87
		ok($admin_email, 'j_q_sixpack@yahoo.com'); # 88

		ok($response->extract_date_modified, 1059427812); # 89
		ok($response->extract_date_created, 1059426121);  # 90
		ok($response->extract_date_expires, 1063112401);  # 91
	}

	{
		my @views = $response->extract_views;

		ok($views[0]->{'type'}, 'text/plain'); # 92
		ok(!defined $views[0]->{'language'});  # 93
		ok(!defined $views[0]->{'country'});   # 94
		ok($views[0]->{'size'}, 410);          # 95

		ok($views[1]->{'type'}, 'application/gopher+-menu'); # 96
		ok($views[1]->{'language'}, 'En');                   # 97
		ok($views[1]->{'country'}, 'US');                    # 98
		ok($views[1]->{'size'}, 1200);                       # 99

		ok($views[2]->{'type'}, 'text/html'); # 100
		ok(!defined $views[2]->{'language'}); # 101
		ok(!defined $views[2]->{'country'});  # 102
		ok($views[2]->{'size'}, 789);         # 103

		ok(scalar @views, 3); # 104
	}

	{
		my @queries = $response->extract_queries;

		ok($queries[0]->{'type'}, 'Ask');                    # 105
		ok($queries[0]->{'question'}, 'What is your name?'); # 106
		ok(ref $queries[0]->{'defaults'}, 'ARRAY');          # 107
		ok(scalar @{ $queries[0]->{'defaults'} }, 0);        # 108

		ok($queries[1]->{'type'}, 'Choose');          # 109
		ok($queries[1]->{'question'},
			'What is your favorite color?');      # 110
		ok(ref $queries[1]->{'defaults'}, 'ARRAY');   # 111
		ok($queries[1]->{'defaults'}->[0], 'red');    # 112
		ok($queries[1]->{'defaults'}->[1], 'green');  # 113
		ok($queries[1]->{'defaults'}->[2], 'blue');   # 114
		ok(scalar @{ $queries[1]->{'defaults'} }, 3); # 115

		ok($queries[2]->{'type'}, 'Select');                    # 116
		ok($queries[2]->{'question'}, 'Contact using:');        # 117
		ok(ref $queries[2]->{'defaults'}, 'ARRAY');             # 118
		ok($queries[2]->{'defaults'}->[0], 'Email');            # 119
		ok($queries[2]->{'defaults'}->[1], 'Instant messages'); # 120
		ok($queries[2]->{'defaults'}->[2], 'IRC');              # 121
		ok(scalar @{ $queries[2]->{'defaults'} }, 3);           # 122

		ok(scalar @queries, 3); # 123
	}
}





{
	my $ng = new Net::Gopher;

	my $response = $ng->directory_attribute(
		Host     => 'localhost',
		Selector => '/directory_blocks'
	);

	ok($response->is_success); # 124

	{
		my @directory_information = $response->get_blocks;

		ok(scalar @directory_information, 4); # 125



		my @gp_index = @{ shift @directory_information };

		ok($gp_index[0]->name, '+INFO');                       # 126
		ok($gp_index[0]->value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 127
		ok($gp_index[0]->raw_value,
			"1Gopher+ Index	/gp_index\tlocalhost\t70\t+"); # 128

		ok($gp_index[1]->name, '+ADMIN');       # 129
		ok($gp_index[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20030728173012>");  # 130
		ok($gp_index[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20030728173012>"); # 131



		my @gp_byte_term = @{ shift @directory_information };

		ok($gp_byte_term[0]->name, '+INFO'); # 132
		ok($gp_byte_term[0]->value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 133
		ok($gp_byte_term[0]->raw_value,
			"0Byte terminated file\t/gp_byte_term\t" .
			"localhost\t70\t+");         # 134

		ok($gp_byte_term[1]->name, '+ADMIN');   # 135
		ok($gp_byte_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20031201123000>");  # 136
		ok($gp_byte_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20031201123000>"); # 137



		my @gp_period_term = @{ shift @directory_information };

		ok($gp_period_term[0]->name, '+INFO'); # 138
		ok($gp_period_term[0]->value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 139
		ok($gp_period_term[0]->raw_value,
			"0Period terminated file\t/gp_period_term\t" .
			"localhost\t70\t+");           # 140

		ok($gp_period_term[1]->name, '+ADMIN'); # 141
		ok($gp_period_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040101070206>");  # 142
		ok($gp_period_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040101070206>"); # 143



		my @gp_no_term = @{ shift @directory_information };

		ok($gp_no_term[0]->name, '+INFO'); # 144
		ok($gp_no_term[0]->value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");       # 145
		ok($gp_no_term[0]->raw_value,
			"0Non-terminated file\t/gp_no_term\t" .
			"localhost\t70\t+");        # 146

		ok($gp_no_term[1]->name, '+ADMIN');     # 147
		ok($gp_no_term[1]->value,
			"Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\n" .
			"Mod-Date: <20040201182005>");  # 148
		ok($gp_no_term[1]->raw_value,
			" Admin: John Q. Sixpack <j_q_sixpack\@yahoo.com>\012" .
			" Mod-Date: <20040201182005>"); # 149
	}
}

kill_server();
