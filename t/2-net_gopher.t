use strict;
use warnings;
use Test;

BEGIN { plan(tests => 107) }

use Net::Gopher;
use Net::Gopher::Request;
use Net::Gopher::Constants qw(:item_types);

require './t/serverfunctions.pl';







################################################################################
#
# These tests check the integrity of the Net::Gopher object itself, making
# sure initialization via the constructor and later modification via the
# accessor methods all work properly:
#

{
	my $ng = new Net::Gopher;

	ok($ng->buffer_size, 4096);                             # 1
	ok($ng->timeout, 30);                                   # 2
	ok($ng->upward_compatible, 1);                          # 3
	ok($ng->warn_handler ==
		$Net::Gopher::Exception::DEFAULT_WARN_HANDLER); # 4
	ok($ng->die_handler == 
		$Net::Gopher::Exception::DEFAULT_DIE_HANDLER);  # 5
	ok($ng->silent, 0);                                     # 6
	ok($ng->debug, 0);                                      # 7
	ok(!defined $ng->log_file);                             # 8
	ok(!defined $ng->_data_read);                           # 9
	ok(!defined $ng->_buffer);                              # 10
	ok(!defined $ng->_socket);                              # 11
	ok(!defined $ng->_select);                              # 12
}

{
	my $warn = sub { print "a warning" };
	my $die  = sub { print "a fatal error" };

	my $ng = new Net::Gopher (
		BufferSize       => 777777,
		TIMEOUT          => 60,
		upwardcompatible => 'true',
		WaRNHaNDleR      => $warn,
		DieHandler       => $die,
		SILENT           => undef,
		debug            => 'also true',
		LoGFiLe          => 'a_filename.txt'
	);

	ok($ng->buffer_size, 777777);         # 13
	ok($ng->timeout, 60);                 # 14
	ok($ng->upward_compatible, 1);        # 15
	ok($ng->warn_handler == $warn);       # 16
	ok($ng->die_handler  == $die);        # 17
	ok($ng->silent, 0);                   # 18
	ok($ng->debug, 1);                    # 19
	ok($ng->log_file, 'a_filename.txt');  # 20
	ok(!defined $ng->_data_read);         # 21
	ok(!defined $ng->_buffer);            # 22
	ok(!defined $ng->_socket);            # 23
	ok(!defined $ng->_select);            # 24
}

{
	my $ng = new Net::Gopher;

	$ng->buffer_size(1234567);
	ok($ng->buffer_size, 1234567); # 25

	$ng->timeout(100);
	ok($ng->timeout, 100);         # 26

	$ng->upward_compatible('true');
	ok($ng->upward_compatible, 1); # 27

	$ng->upward_compatible(0);
	ok($ng->upward_compatible, 0); # 28

	$ng->debug(100);
	ok($ng->debug, 1);             # 29

	$ng->debug(0);
	ok($ng->debug, 0);             # 30
}







{
	# this runs testserver.pl with -e to echo back each request:
	run_echo_server();

	my $ng = new Net::Gopher;



	#######################################################################
	#
	# These tests are used to make sure that the Net::Gopher request()
	# method properly sends the request strings generated by the
	# Net::Gopher::Request as_string() method to the server:
	#

	{
		my $request = new Net::Gopher::Request (
			Gopher => {
				Host        => 'localhost',
				Port        => 70,
				Selector    => '/something',
				SearchWords => ['red', 'green', 'blue']
			}
		);

		my $response = $ng->request($request);

		ok($response->is_success);                        # 31
		ok($response->raw_response, $request->as_string); # 32
	}

	{
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/something_else',
				Representation => 'text/plain'
			}
		);

		my $response = $ng->request($request);

		ok($response->is_success);                        # 33
		ok($response->raw_response, $request->as_string); # 34
	}

	{
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/something_else',
				Representation => 'text/plain',
				DataBlock      => 'This is a single-line block'
			}
		);

		my $response = $ng->request($request);

		ok($response->is_success);                        # 35
		ok($response->raw_response, $request->as_string); # 36
	}

	{
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/something_else',
				Representation => 'text/plain',
				DataBlock      => 'This is a big single-line block ' x 2000
			}
		);

		my $response = $ng->request($request);

		ok($response->is_success);                        # 37
		ok($response->raw_response, $request->as_string); # 38
	}

	{ 
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/something_else',
				Representation => 'text/plain',
				DataBlock      =>
				"This\015\012is\012a\015\012multi-line\012block"
			}
		);

		my $response = $ng->request($request);

		ok($response->is_success);                        # 39
		ok($response->raw_response, $request->as_string); # 40
	}

	{
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/something_else',
				Representation => 'text/plain',
				DataBlock      =>
				"This\015\012is\012a\015\012multi-line\012block " x 2000,
			}
		);

		my $response = $ng->request($request);

		ok($response->is_success);                        # 41
		ok($response->raw_response, $request->as_string); # 42
	}

	{
		my $request = new Net::Gopher::Request (
			ItemAttribute => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/some_item',
				Attributes     => '+ATTR'
			}
		);

		my $response = $ng->request($request);

		ok($response->is_success);                        # 43
		ok($response->raw_response, $request->as_string); # 44
	}

	{
		my $request = new Net::Gopher::Request (
			DirectoryAttribute => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/some_dir',
				Attributes     => '+ATTR'
			}
		);

		my $response = $ng->request($request);

		ok($response->is_success);                        # 45
		ok($response->raw_response, $request->as_string); # 46
	}







	########################################################################
	# 
	# These tests are used to make sure that the named request methods
	# create the proper request objects:
	#

	{
		my $request = new Net::Gopher::Request (
			Gopher => {
				Host        => 'localhost',
				Port        => 70,
				Selector    => '/something',
				SearchWords => ['red', 'green', 'blue']
			}
		);

		my $response = $ng->gopher(
			Host        => 'localhost',
			Port        => 70,
			Selector    => '/something',
			SearchWords => ['red', 'green', 'blue']
		);

		ok($response->is_success);                                    # 47
		ok($response->request->request_type, $request->request_type); # 48
		ok($response->request->as_string, $request->as_string);       # 49
	}

	{
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/something_else',
				Representation => 'text/plain'
			}
		);

		my $response = $ng->gopher_plus(
			Host           => 'localhost',
			Port           => 70,
			Selector       => '/something_else',
			Representation => 'text/plain'
		);

		ok($response->is_success);                                    # 50
		ok($response->request->request_type, $request->request_type); # 51
		ok($response->request->as_string, $request->as_string);       # 52
	}

	{
		my $request = new Net::Gopher::Request (
			ItemAttribute => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/some_dir',
				Attributes     => '+ATTR'
			}
		);

		my $response = $ng->item_attribute(
			Host           => 'localhost',
			Port           => 70,
			Selector       => '/some_dir',
			Attributes     => '+ATTR'
		);

		ok($response->is_success);                                    # 53
		ok($response->request->request_type, $request->request_type); # 54
		ok($response->request->as_string, $request->as_string);       # 55
	}

	{
		my $request = new Net::Gopher::Request (
			DirectoryAttribute => {
				Host           => 'localhost',
				Port           => 70,
				Selector       => '/some_dir',
				Attributes     => '+ATTR'
			}
		);

		my $response = $ng->directory_attribute(
			Host           => 'localhost',
			Port           => 70,
			Selector       => '/some_dir',
			Attributes     => '+ATTR'
		);

		ok($response->is_success);                                    # 56
		ok($response->request->request_type, $request->request_type); # 57
		ok($response->request->as_string, $request->as_string);       # 58
	}

	kill_server();





	########################################################################
	# 
	# This test makes sure Net::Gopher can connect to a server on a port
	# other than 70:
	#

	run_server(7070);

	{
		my $response = $ng->gopher(
			Host     => 'localhost',
			Port     => 7070,
			Selector => '/index'
		);

		ok($response->is_success); # 59
	}

	kill_server();
}







{
	run_server();

	my $ng = new Net::Gopher;



	########################################################################
	# 
	# These tests are used to make sure that the request method handles
	# response handlers correctly:
	#

	{
		# see the "index" file in the ./t/items directory:
		my $request = new Net::Gopher::Request (
			Gopher => {
				Host        => 'localhost',
				Selector    => '/index'
			}
		);

		my $content;
		my $content_matches;
		my $last_request_obj;
		my $last_response_obj;
		my $response = $ng->request($request,
			Handler => sub {
				my $buffer = shift;
				($last_request_obj, $last_response_obj) = @_;

				$content .= $buffer;
				$content_matches++
					if ($content eq $last_response_obj->content);
			}
		);

		ok($response->is_success);          # 60
		ok($request == $last_request_obj);  # 61
		ok($response== $last_response_obj); # 62
		ok($content_matches);               # 63
	}

	{
		# see the "gp_period_term" file in the ./t/items directory:
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host        => 'localhost',
				Selector    => '/gp_period_term'
			}
		);

		my $content;
		my $content_matches;
		my $last_request_obj;
		my $last_response_obj;
		my $response = $ng->request($request,
			Handler => sub {
				my $buffer = shift;
				($last_request_obj, $last_response_obj) = @_;

				$content .= $buffer;
				$content_matches++
					if ($content eq $last_response_obj->content);
			}
		);

		ok($response->is_success);           # 64
		ok($request == $last_request_obj);   # 65
		ok($response == $last_response_obj); # 66
		ok($content_matches);                # 67
	}

	{
		# see the "gp_no_term" file in the ./t/items directory:
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host        => 'localhost',
				Selector    => '/gp_no_term'
			}
		);

		my $content;
		my $content_matches;
		my $last_request_obj;
		my $last_response_obj;
		my $response = $ng->request($request,
			Handler => sub {
				my $buffer = shift;
				($last_request_obj, $last_response_obj) = @_;

				$content .= $buffer;
				$content_matches++
					if ($content eq $last_response_obj->content);
			}
		);

		ok($response->is_success);         # 68
		ok($request, $last_request_obj);   # 69
		ok($response, $last_response_obj); # 70
		ok($content_matches);              # 71
	}

	{
		# see the "gp_byte_term" file in the ./t/items directory:
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host        => 'localhost',
				Selector    => '/gp_byte_term'
			}
		);

		my $content;
		my $content_matches;
		my $last_request_obj;
		my $last_response_obj;
		my $response = $ng->request($request,
			Handler => sub {
				my $buffer = shift;
				($last_request_obj, $last_response_obj) = @_;

				$content .= $buffer;
				$content_matches++
					if ($content eq $last_response_obj->content);
			}
		);

		ok($response->is_success);           # 72
		ok($request == $last_request_obj);   # 73
		ok($response == $last_response_obj); # 74
		ok($content_matches);                # 75
	}

	{
		# see the "gp_s_period_term" file in the ./t/items directory:
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host        => 'localhost',
				Selector    => '/gp_s_period_term'
			}
		);

		my $content;
		my $content_matches;
		my $last_request_obj;
		my $last_response_obj;
		my $response = $ng->request($request,
			Handler => sub {
				my $buffer = shift;
				($last_request_obj, $last_response_obj) = @_;

				$content .= $buffer;
				$content_matches++
					if ($content eq $last_response_obj->content);
			}
		);

		ok($response->is_success);           # 76
		ok($request == $last_request_obj);   # 77
		ok($response == $last_response_obj); # 78
		ok($content_matches);                # 79
	}

	{
		# see the "gp_s_no_term" file in the ./t/items directory:
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host        => 'localhost',
				Selector    => '/gp_s_no_term'
			}
		);

		my $content;
		my $content_matches;
		my $last_request_obj;
		my $last_response_obj;
		my $response = $ng->request($request,
			Handler => sub {
				my $buffer = shift;
				($last_request_obj, $last_response_obj) = @_;

				$content .= $buffer;
				$content_matches++
					if ($content eq $last_response_obj->content);
			}
		);

		ok($response->is_success);           # 80
		ok($request == $last_request_obj);   # 81
		ok($response == $last_response_obj); # 82
		ok($content_matches);                # 83
	}

	{
		# see the "gp_s_byte_term" file in the ./t/items directory:
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host        => 'localhost',
				Selector    => '/gp_s_byte_term'
			}
		);

		my $content;
		my $content_matches;
		my $last_request_obj;
		my $last_response_obj;
		my $response = $ng->request($request,
			Handler => sub {
				my $buffer = shift;
				($last_request_obj, $last_response_obj) = @_;

				$content .= $buffer;
				$content_matches++
					if ($content eq $last_response_obj->content);
			}
		);

		ok($response->is_success);           # 84
		ok($request == $last_request_obj);   # 85
		ok($response == $last_response_obj); # 86
		ok($content_matches);                # 87
	}

	{
		# see the "index" file in the ./t/items directory:
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host        => 'localhost',
				Selector    => '/index'
			}
		);

		my $content;
		my $content_matches;
		my $last_request_obj;
		my $last_response_obj;
		my $response = $ng->request($request,
			Handler => sub {
				my $buffer = shift;
				($last_request_obj, $last_response_obj) = @_;

				$content .= $buffer;
				$content_matches++
					if ($content eq $last_response_obj->content);
			}
		);

		ok($response->is_success);           # 88
		ok($request == $last_request_obj);   # 89
		ok($response == $last_response_obj); # 90
		ok($content_matches);                # 91
	}






	{
		my $request = new Net::Gopher::Request (
			Gopher => {
				Host        => 'localhost',
				Selector    => '/index'
			}
		);

		my $response = $ng->request($request, File => 'test.txt');

		ok($response->is_success);                # 92
		ok(open(TEST, 'test.txt'));               # 93
		ok(join('', <TEST>), $response->content); # 94
		close TEST;
		ok(unlink('test.txt'));                   # 95
		ok(!-e 'test.txt');                       # 96
	}

	{
		my $request = new Net::Gopher::Request (
			GopherPlus => {
				Host        => 'localhost',
				Selector    => '/gp_index'
			}
		);

		my $response = $ng->request($request, File => 'test2.txt');

		ok($response->is_success);                 # 97
		ok(open(TEST2, 'test2.txt'));              # 98
		ok(join('', <TEST2>), $response->content); # 99
		close TEST2;
		ok(unlink('test2.txt'));                   # 100
		ok(!-e 'test2.txt');                       # 101
	}







	########################################################################
	# 
	# These tests make sure Net::Gopher raises exceptions in the proper
	# places:
	#

	{
		my (@warnings, @fatal_errors);

		my $ng = new Net::Gopher(
			WarnHandler => sub { push(@warnings, @_) },
			DieHandler  => sub { push(@fatal_errors, @_) }
		);

		$ng->request();

		ok(scalar @warnings, 0);        # 102
		ok(scalar @fatal_errors, 1);    # 103
		ok($fatal_errors[0],
			'A Net::Gopher::Request object was not supplied as ' .
			'the first argument.'); # 104
	}

	{
		my (@warnings, @fatal_errors);

		my $ng = new Net::Gopher(
			WarnHandler => sub { push(@warnings, @_) },
			DieHandler  => sub { push(@fatal_errors, @_) }
		);

		$ng->request(new Net::Gopher::Request('Gopher') );

		ok(@warnings, 0);     # 105
		ok(@fatal_errors, 1); # 106
		ok($fatal_errors[0],
			join(' ',
				"You never specified a hostname; it's",
				"impossible to send your request without one.",
				"Specify it during object creation or later on",
				"with the host() method."
			));           # 107
	}



	kill_server();
}
