
package Net::Gopher;

=head1 NAME

Net::Gopher - The Perl Gopher/Gopher+ client API

=head1 SYNOPSIS

 use Net::Gopher;
 
 my $ng = new Net::Gopher;
 
 # Create a new request object for a Gopher-type request:
 my $request = new Net::Gopher::Request ('Gopher',
 	Host     => 'gopher.host.com',
 	Selector => '/menu',
 	ItemType => 1
 );
 
 # Now send the request to the server and get the Net::Gopher::Response
 # object for the server's response:
 my $response = $ng->request($request);
 
 # ...or send the request and store the content of the response in a
 # separate file:
 $ng->request($request, File => 'somefile.txt');
 
 # ...or send the request and process the response as it's received:
 $ng->request($request, Handler => \&response_callback);
 
 sub response_callback {
 	my ($buffer, $request_obj, $response_obj) = @_;
 
 	# do something with $buffer, $request_obj, and
 	# $response_obj...	
 }
 
 
 
 # Besides the request object/request() method combination, Net::Gopher
 # has shortcut methods for each type of request, all of which create the
 # Net::Gopher::Request objects for you, send the requests, then return the
 # Net::Gopher::Response objects. This creates and sends a Gopher request:
 $response = $ng->gopher(
 	Host     => 'gopher.host.com',
 	Selector => '/menu',
 	ItemType => 1
 );
 
 # ...this, a Gopher+ request:
 $response = $ng->gopher_plus(
 	Host           => 'gopher.host.com',
 	Selector       => '/doc.txt',
 	Representation => 'text/plain'
 	ItemType       => 0
 );
 
 # ...this, a Gopher+ item attirbute request:
 $response = $ng->item_attribute(
 	Host       => 'gopher.host.com',
 	Selector   => '/doc.txt',
 	Attributes => '+VIEWS'
 	ItemType   => 0
 );
 
 
 
 # For any Gopher request, item/directorty attribute information request,
 # or simple Gopher+ request, if you wish, you can use a URL to describe
 # your request instead of named parameters:
 $response = $ng->url('gopher://gopher.host.com/');
 
 # ...it can be partial too:
 $response = $ng->url('gopher.host.com');
 
 
 
 # After sending a request and getting your response in the form of a
 # Net::Gopher::Response object, use the content() method to get the
 # content of the response:
 print $repsonse->content;
 
 # or use the raw_response() method to get the entire (unmodified)
 # response as a string:
 my $raw_response = $response->raw_response;
 
 
 
 # See Net::Gopher::Request to find out how to create request objects for
 # any type of request as well as for methods to manipulate them.
 # See Net::Gopher::Response for more methods you can use to manipulate
 # Gopher and Gopher+ responses.
 # See the files in the /examples directory that came with the Net::Gopher
 # distribution for more working examples of Net::Gopher scripts.
 ...

=head1 DESCRIPTION

B<Net::Gopher> is the Gopher/Gopher+ client API for Perl. B<Net::Gopher>
implements the Gopher and Gopher+ protocols as described in
I<RFC 1436: The Internet Gopher Protocol>,[1] and in
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol>;[2]
bringing Gopher and Gopher+ support to Perl, enabling Perl 5 applications to
easily interact with both Gopher and Gopher+ Gopherspaces.

B<Net::Gopher> works in conjunction with several other modules. This diagram
shows the package hierarchy:

 Net::Gopher
 |
 |---Net::Gopher::Request
 |
 |---Net::Gopher::Response
 |   |
 |   |---Net::Gopher::Response::MenuItem
 |   |
 |   \---Net::Gopher::Response::InformationBlock
 |
 \---Net::Gopher::Constants

The L<Net::Gopher::Request|Net::Gopher::Request> class is used to create and
manipulate Gopher and Gopher+ requests. The
L<Net::Gopher::Response|Net::Gopher::Response> class is used to manipulate
Gopher and Gopher+ responses. B<Net::Gopher::Response> also has two sub
classes, L<Net::Gopher::Response::MenuItem|Net::Gopher::Response::MenuItem> to
manipulate menu items in Gopher and Gopher+ menus, and
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
to manipulate Gopher+ item/directory attribute information blocks.
Finaly, there's L<Net::Gopher::Constants|Net::Gopher::Constants>, which
defines and exports on demand one-to-three sets of constants.

The Gopher request/response cycle as implemented by B<Net::Gopher> is as
follows: you create a B<Net::Gopher::Request> object encapsulating your
request; you pass it on to the B<Net::Gopher> C<request()> method; the
C<request()> method sends the request to the server and then receives the
response; the response is then returned to you as a B<Net::Gopher::Response>
object for you to manipulate.

As far as requests go, there are four different kinds you can send using this
module: Gopher requests,[3] Gopher+ requests,[4] item attribute information
requests,[5] and directory attribute information requests.[6] This class also
has shortcut methods (C<gopher()>, C<gopher_plus()>, C<item_attribute()>, and
C<directory_attribute()>) for each type of request, which create the request
object for you, send the request, and return the corresponding response object.

Just like the modules in I<libnet> (e.g., L<Net::NNTP|Net::NNTP>,
L<Net::FTP|Net::FTP>), many of the methods in the B<Net::Gopher> distribution
take named parameters. However, B<Net::Gopher> does not require that the
parameter names be specified in the same manor. You can use LWP-style parameter
names or even Tk-style parameter names, because neither case nor underscores
nor leading dashes matter: "ParamName", "param_name", and "-paramname" will be
accepted and treated as referring to the same thing.

The named parameters, for every method that takes them, can be sent optionally
as either a hash or array reference--though few methods, like
B<Net::Gopher::Request> C<new()> or B<Net::Gopher::Response> C<get_blocks()>,
will actually advocate this behavior.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use vars qw($VERSION @ISA);
use Carp;
use Errno 'EINTR';
use IO::Socket qw(SOCK_STREAM SHUT_WR);
use IO::Select;
use Net::Gopher::Constants ':all';
use Net::Gopher::Debugging;
use Net::Gopher::Exception;
use Net::Gopher::Request;
use Net::Gopher::Response;
use Net::Gopher::Utility qw(
	$CRLF
	
	get_named_params
	size_in_bytes
	strip_terminator
	remove_error_prefix
);

use constant DEFAULT_GOPHER_PORT  => 70;
use constant DEFAULT_TIMEOUT      => 30;
use constant DEFAULT_BUFFER_SIZE  => 4096;

use constant MAX_STATUS_LINE_SIZE => 64;

use constant PERIOD_TERMINATED    => -1;
use constant NOT_TERMINATED       => -2;

$VERSION = '1.15';

push(@ISA, qw(Net::Gopher::Debugging Net::Gopher::Exception));







################################################################################
# 
# The following subroutines are public methods:
# 

#==============================================================================#

=head2 new([OPTIONS])

This is the constructor method. It creates a new B<Net::Gopher> object and
returns a reference to it.

This method takes several optional named parameters:

=over 4

=item BufferSize

I<BufferSize> is the size (in bytes) of the buffer to use when reading data
from the socket. If you don't specify I<BufferSize>, then the default of 4096
will be used instead.

=item Timeout

I<Timeout> specifies the number of seconds at which a timeout will occur when
trying to connect to the server, when sending the request to it, and when
receiving the response from it. If you don't specify a number of seconds, then
the default of 30 seconds will be used instead.

=item UpwardCompatible

I<UpwardCompatible> allows you turn on or turn off upward compatibility by
specifying a true or false value respectively. When upward compatibility is
turned on, if you send a Gopher+ request, item attribute information request,
or directory attribute information request to a non-Gopher+ server (one that
does not respond with a status line first), B<Net::Gopher> will try to receive
the plain-old Gopher response and not raise any errors. When turned off,
sending a Gopher+ request or item attribute/directory attribute information
request to a non-Gopher+ server will result in an error. By default, upward
compatibility is turned on.

=item WarnHandler

I<WarnHandler> allows you to specify a callback for B<Net::Gopher> to use when
warning. When specified, B<Net::Gopher> will call your sub with the warning
message(s) as the argument(s) when it warns. If you don't supply
I<WarnHandler>, then B<Carp>'s C<carp()> function will be used instead.

=item DieHandler

I<DieHandler> allows you to specify a callback for B<Net::Gopher> to use when
dying. When specified, B<Net::Gopher> will call your sub with the fatal error
message(s) as the argument(s) when it dies. If you don't supply I<DieHandler>,
then B<Carp>'s C<croak()> function will be used instead.

=item Silent

If you don't want B<Net::Gopher> warning or dying at all, then supply a true
value to I<Silent>.

=item Debug

I<Debug> allows you turn on or turn off debugging by specifying a true or false
value respectively. If debugging is turned on, then formatted diagnostic
messages for each request/response cycle will be outputted to the terminal
(STDERR) or a file if you specify one for I<LogFile>. By default, debugging is
turned off.

=item LogFile

If I<Debug> is on, then you can use this parameter to specify the name of a
file to use as the log file. When specified, the diagnostic messages will be
outputted to the specified file as opposed to STDERR.

=back

See also the corresponding get/set
L<buffer_size()|Net::Gopher/buffer_size([BYTES])>,
L<timeout()|Net::Gopher/timeout([SECONDS])>,
L<upward_compatible()|Net::Gopher/upward_compatible([BOOLEAN])>,
L<warn_handler()|Net::Gopher/warn_handler([HANDLER])>,
L<die_handler()|Net::Gopher/die_handler([HANDLER])>,
L<silent()|Net::Gopher/silent([BOOLEAN])>,
L<debug()|Net::Gopher/debug([BOOLEAN])>,
and L<log_file()|Net::Gopher/log_file([FILENAME])> methods below.

=cut

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my ($buffer_size, $timeout, $upward_compatible,
	    $warn_handler, $die_handler, $silent, $debug, $log_file);
	get_named_params({
		BufferSize       => \$buffer_size,
		Timeout          => \$timeout,
		UpwardCompatible => \$upward_compatible,
		WarnHandler      => \$warn_handler,
		DieHandler       => \$die_handler,
		Silent           => \$silent,
		Debug            => \$debug,
		LogFile          => \$log_file
		}, \@_
	);

	# turn upward compatability on by default:
	$upward_compatible = 1 unless (defined $upward_compatible);



	my $self = {
		# the size (in bytes) of $self->_buffer:
		buffer_size       => (defined $buffer_size)
					? $buffer_size
					: DEFAULT_BUFFER_SIZE,

		# the number seconds before a timeout occurs when connecting,
		# reading, writing, etc., etc.:
		timeout           => (defined $timeout)
					? $timeout
					: DEFAULT_TIMEOUT,

		# silently handle Gopher responses to Gopher+ type requests?
		upward_compatible => ($upward_compatible) ? 1 : 0,

		# When we read from the socket, we'll do so using a series of
		# buffers. This stores each buffer one at a time:
		_buffer           => undef,

		# the IO::Select object for the socket stored in
		# $self->_socket:
		_select           => undef,

		# the IO::Socket::INET socket:
		_socket           => undef,

		# this stores any network error that occurs during the
		# request/response cycle:
		_network_error    => undef
	};

	bless($self, $class);



	# set the global Net::Gopher::Exception variables (the warn_handler(),
	# die_handler() and silent() methods are inherited by this class and
	# its sub classes from Net::Gopher::Exception):
	$self->warn_handler($warn_handler);
	$self->die_handler($die_handler);
	$self->silent($silent); 

	# set the global Net::Gopher::Debugging variables (debug() and
	# log_file() are inherited from Net::Gopher::Debugging):
	$self->debug($debug);
	$self->log_file($log_file);

	return $self;
}





#==============================================================================#

=head2 request(REQUEST [, OPTIONS])

This method connects to a Gopherspace, sends a request, receives the response,
and disconnects from the Gopherspace. It returns a B<Net::Gopher::Response>
object encapsulating the server's response.

This method takes a B<Net::Gopher::Request> object encapsulating a Gopher or
Gopher+ request as its first argument. This is the only required argument.

If the C<port()> member of the request object is empty (probably because you
never filled it out during the creation of the request object or later on with
the C<port()> method), then the default IANA designated port of 70 will be used
to connect to the Gopherspace. If the C<item_type()> member of the request
object is empty (again, because you never set during creation or later on) and
the request is not an item attribute information request or directory attribute
information request, then "1", Gopher menu type, will be assumed.

Some typical usage of request objects in conjunction with this method is
illustrated in the L<SYNOPSIS|Net::Gopher/SYNOPSIS>. For a more detailed
description, see L<Net::Gopher::Request|Net::Gopher::Request>.

In addition to the request object, this method takes two optional named
parameters:

=over 4

=item File

I<File> takes the name of the file that, when supplied, B<Net::Gopher> will
output the content of the response to, overwriting anything in it if it exists
and creating it from scratch if it doesn't.

=item Handler

I<Handler> takes a reference to a subroutine that will be called as the
response is collected, with the buffer sent as the first argument to the
callback routine, the request object as the second, and the response object as
the third.

If you supply a response handler, then its return value will be used to
indicate whether or not C<request()> should keep receiving the response from
the server. A true return value means it should, a false return value means it
should stop abruptly.

=back

See L<Net::Gopher::Response|Net::Gopher::Response> for methods you can call on
response objects.

=cut

sub request
{
	my $self    = shift;
	my $request = shift;

	return $self->call_die(
		'A Net::Gopher::Request object was not supplied as the ' .
		'first argument.'
	) unless (UNIVERSAL::isa($request, 'Net::Gopher::Request'));

	my ($file, $handler);
	get_named_params({
		File    => \$file,
		Handler => \$handler
		}, \@_
	);



	my $response = new Net::Gopher::Response;
	   $response->ng($self);
	   $response->request($request);

	# First, we need to connect to the Gopher server. To connect, at the
	# very least, we need a hostname or IP address:
	return $self->call_die(
		"You never specified a host; it's impossible to send your " .
		"request. Specify one during request object creation or " .
		"later on with the host() method."
	) unless (defined $request->host and length $request->host);

	# we also need a port number, but we can use the default IANA
	# designated Gopher port number if none was specified:
	$request->port(DEFAULT_GOPHER_PORT) unless ($request->port);

	# if no item type was specified and it's not an item
	# attribute/directory attribute request, we'll just assume it's a
	# request for a Gopher menu:
	$request->item_type(GOPHER_MENU_TYPE)
		unless (defined $request->item_type
			or $request->request_type == ITEM_ATTRIBUTE_REQUEST
			or $request->request_type == DIRECTORY_ATTRIBUTE_REQUEST);

	# Is this a Gopher+ style request/response cycle? (Complete with
	# additional tab delimited fields in the request string we're going to
	# send and a status line prefixing the response we're going to receive?)
	my $is_gopher_plus;
	if ($request->request_type == GOPHER_PLUS_REQUEST
		or $request->request_type == ITEM_ATTRIBUTE_REQUEST
		or $request->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
	{
		$is_gopher_plus = 1;
	}

	# make sure we don't inherit errors from previous failled request()
	# calls:
	$self->_network_error(undef);



	# try to connect to the Gopherspace:
	my $socket = new IO::Socket::INET (
		Type     => SOCK_STREAM,
		Proto    => 'tcp',
		PeerAddr => $request->host,
		PeerPort => $request->port,
		Timeout  => $self->timeout
	) or return $response->error(
		sprintf("Couldn't connect to \"%s\" at port %d: %s",
			$request->host,
			$request->port,
			remove_error_prefix($@)
		)
	);

	$self->_socket($socket);

	$self->debug_print(
		sprintf("Connected to \"%s\" (%s) at port %d.",
			$request->host,
			$self->_socket->peerhost,
			$self->_socket->peerport
		)
	);

	# we want non-buffering, non-blocking (*especially* non-blocking) IO:
	$self->_socket->autoflush(1);
	$self->_socket->blocking(0);

	# we'll use this to check for timeouts:
	$self->_select(
		new IO::Select ($self->_socket)
	);



	# generate and send the Gopher or Gopher+ request:
	my $request_string = $request->as_string;

	$self->_write_to_socket($request_string);

	return $response->error($self->_network_error)
		if ($self->_network_error);

	$self->debug_print("Sent this request: [$request_string]");

	# we sent the request and we have nothing else to send, so we're
	# finished writing:
	$self->_socket->shutdown(SHUT_WR);



	# Now for the server's response:
	# 
	# This sub is used to store the received response inside of the
	# response object and make sure any user-defined response handler is
	# called. It takes a buffer as its only argument, adds it to the
	# response object, and calls any user-defined response handler with the
	# buffer as its first argument, the request object as its second, and
	# the response object as its third:
	my $store_response = sub {
		my $buffer = shift;


		$response->_add_raw($buffer);
		$response->_add_content($buffer);

		# if the user supplied a handler, we'll invoke it, and use its
		# return value to tell us whether or not to keep going:
		if (ref $handler eq 'CODE')
		{
			$handler->($buffer, $request, $response)
				or return $response;
		}

		# show how many bytes we stored for debugging:
		my $bytes_stored =
			(defined $buffer) ? size_in_bytes($buffer) : 0;
		$self->debug_print(
			sprintf("Stored %d %s of response.",
				$bytes_stored,
				($bytes_stored == 1) ? 'byte' : 'bytes'
			)
		);
	};

	# This branch of code below is used to receive the response. It does so
	# in one of two ways: either as a Gopher+ style response message or as
	# a plain-old Gopher response message. For Gopher+ responses, we first
	# need to read the status line prefixing the response so we can look at
	# the transfer type and decide how to receive it. For Gopher, we just
	# read from the stream until the server closes the connection.
	# 
	# For Gopher+, $remainder will store any additional bytes we end up
	# reading beyond the status line, or if we don't find the status line,
	# everything we've read while looking for it:
	my $remainder;
	if ($is_gopher_plus
		and my $status_line = $self->_read_status_line(\$remainder))
	{
		$response->_add_raw($status_line);

		# extract the status code (+ or -) and transfer type (either
		# -1, -2, or the length of the response content in bytes) of
		# the response:
		my $status        = substr($status_line, 0, 1);
		my $transfer_type = substr($status_line, 1, -2);

		$response->status_line($status_line);
		$response->status($status);

		# while getting the status line, we may have read more than we
		# had to, in which case we need to store the remainder:
		$store_response->($remainder)
			if (defined $remainder and size_in_bytes($remainder));

		if ($transfer_type == PERIOD_TERMINATED
			or $transfer_type == NOT_TERMINATED)
		{
			# A -1 or -2 transfer type means the server is going to
			# send a series of bytes, which may (-1) or may not
			# (-2) be terminated by a period on a line by itself,
			# and then close the connection. So we'll read from
			# the stream over and over again until the server
			# closes the connection or an error occurs:
			while ($self->_read_from_socket)
			{
				$store_response->($self->_buffer);
			}
		}
		else
		{
			# a transfer type other than -1 or -2 is the total
			# length of the response content in bytes:
			my $content_length = $transfer_type;

			# This keeps track of how many bytes of the response
			# content we've stored in the response object. Since we
			# may have already read some of the content with
			# read_status_line() and $remainder, we'll add that to
			# the total:
			my $bytes_stored =
				(defined $response->content)
					? size_in_bytes($response->content)
					: 0;

			while ($bytes_stored < $content_length
				and my $bytes_read = $self->_read_from_socket)
			{
				$store_response->($self->_buffer);

				$bytes_stored += $bytes_read;
			}
		}

		return $response->error($self->_network_error)
			if ($self->_network_error);

		# make sure we received *some* response--anything:
		return $response->error(
			'The server closed the connection without returning ' .
			'any response'
		) unless (defined $response->raw_response
			and size_in_bytes($response->raw_response));

		# if the transfer type was not -1 or -2 and instead contained
		# the length of the response content, then we'll make sure we
		# received a response containing at least that many bytes:
		if ($transfer_type != PERIOD_TERMINATED
			and $transfer_type != NOT_TERMINATED)
		{
			my $supposed_size = $transfer_type;
			my $actual_size   = size_in_bytes($response->content);

			# since we live in a world structured by things such as
			# NULL terminators, it makes sense to allow for at
			# least a one byte discrepancy between the size in the
			# transfer type and the actual size of the response
			# content, so we decrement the supposed size before
			# comparing it with the actual size:
			return $response->error(
				sprintf('Incomplete response received: only ' .
				        '%d %s of a suppossedly %d byte ' .
					'response',
				        $actual_size,
					($actual_size == 1) ? 'byte' : 'bytes',
					$supposed_size
				)
			) if ($actual_size < $supposed_size - 1);
		}

		# If the response was terminated by a period on a line by
		# itself, we need to unescape escaped periods at the start of a
		# line:
		$response->_unescape_periods
			if ($transfer_type == PERIOD_TERMINATED);

		# convert all newlines in the response content to standard Unix
		# linefeed characters or MacOS carriage returns so "\n", ".",
		# "\s", and other newline-matching meta symbols can be used in
		# patterns (see the POD for content() in
		# /Net/Gopher/Response.pm):
		$response->_convert_newlines if ($response->is_text);

		# If we've gotten this far, then we didn't encounter any
		# network errors. However, there may still have been errors on
		# the server side, like if the item we selected did not exist;
		# in which case the content of the response contains the error:
		if ($response->status eq NOT_OK)
		{
			my $error = $response->content;

			strip_terminator($error)
				if ($transfer_type == PERIOD_TERMINATED);

			$response->error($error);
		}
	}
	else
	{
		# If we got here then this is a plain old Gopher response, not
		# a Gopher+ response.

		if ($is_gopher_plus)
		{
			# if we got here, then maybe some network error
			# occurred while receiving the status line?
			return $response->error($self->_network_error)
				if ($self->_network_error);

			# If it wasn't a network error, then that means
			# we sent a Gopher+ request to a Gopher server, and
			# hence there was no valid status line prefixing the
			# response. If upward compatability is on, we'll keep
			# going anyway and try to receive the Gopher response:
			return $response->error(
				'You sent a Gopher+ style request to a ' .
				'non-Gopher+ server'
			) unless ($self->upward_compatible);

			$store_response->($remainder)
				if (defined $remainder
					and size_in_bytes($remainder));
		}



		# For the original Gopher, we're just gonna read from the TCP
		# stream over and over again using _read_from_socket() and
		# store each buffer read one at a time in $self->_buffer, then
		# store the buffer in the response object. When the server is
		# done sending its response, it should close the connection (or
		# at least shutdown write portion of it), resulting in an EOF
		# read and exiting of the while loop below.
		#
		# If we were going to follow RFC 1436 to the letter, we would
		# probably check each buffer for a terminating period on a line
		# by itself and stop reading if we find it, but not all items
		# contain this (binary items) and some text items aren't
		# properly escaped, potentially resulting in cut-off responses.
		# Plus, I've never seen an implementation that does check:
		while ($self->_read_from_socket)
		{
			$store_response->($self->_buffer);
		}

		return $response->error($self->_network_error)
			if ($self->_network_error);

		return $response->error(
			'The server closed the connection without returning ' .
			'any response'
		) unless (defined $response->raw_response
			and size_in_bytes($response->raw_response));

		# if the item is a text file, menu, or other text item and it's
		# terminated by a period on a line by itself, then periods at
		# the start of line need to be escaped; we'll unescape them:
		$response->_unescape_periods
			if ($response->is_text and $response->is_terminated);

		# convert every line ending in the response to CR or LF
		# (depending on what "\n" is on this platform) if we're
		# reasonably sure the response content contains text (please
		# see the POD for content() in /Net/Gopher/Resonse.pm):
		$response->_convert_newlines if ($response->is_text);
	}

	# show the size of the response we got for debugging:
	$self->debug_print(
		sprintf('Received a response of %d %s (total), with %d %s ' .
		        'content.',
			size_in_bytes($response->raw_response),
			(size_in_bytes($response->raw_response) == 1)
				? 'byte'
				: 'bytes',
			size_in_bytes($response->content),
			(size_in_bytes($response->content) == 1)
				? 'byte'
				: 'bytes',
		)
	);

	# disconnect from the server:
	$self->_socket->close;

	$self->debug_print('Disconnected from server.');



	# output the content of the response to the file the user
	# specified:
	if ($file)
	{
		open(FILE, "> $file")
			or return $self->call_die(
				"Couldn't open output file ($file): $!."
			);

		# if it's binary, we don't want bytes recognized as line
		# endings getting messed with:
		binmode FILE unless ($response->is_text);

		print FILE $response->content;
		close FILE;
	}

	return $response;
}





#==============================================================================#

=head2 gopher(OPTIONS)

This method is a shortcut around the B<Net::Gopher::Request>
object/C<request()> method combination for plain-old Gopher requests.[7] It
creates a Gopher-type B<Net::Gopher::Request> object, sends it, and then
returns the B<Net::Gopher::Response> object for the response.

This:

 $ng->gopher(
 	Host     => 'gopher.host.com',
 	Selector => '/menu',
 	ItemType => 1
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request ('Gopher',
 		Host     => 'gopher.host.com',
 		Selector => '/menu',
 		ItemType => 1
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new(TYPE [, OPTIONS | URL])> method for a
complete list of named parameters you can supply for Gopher-type requests.

=cut

sub gopher
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('Gopher', @_)
	);
}





#==============================================================================#

=head2 gopher_plus(OPTIONS)

This method is a shortcut around the B<Net::Gopher::Request>
object/C<request()> method combination for Gopher+ requests.[8] It creates a
Gopher+ B<Net::Gopher::Request> object, sends it, and then returns the
B<Net::Gopher::Response> object for the response.

This:

 $ng->gopher_plus(
 	Host           => 'gopher.host.com',
 	Selector       => '/menu',
 	Representation => 'application/gopher+-menu'
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request ('GopherPlus',
 		Host           => 'gopher.host.com',
 		selector       => '/menu',
 		Representation => 'application/goopher+-menu'
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new(TYPE [, OPTIONS | URL])> method for a
complete list of named parameters you can supply for Gopher+ type requests.

=cut

sub gopher_plus
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('GopherPlus', @_)
	);
}





#==============================================================================#

=head2 item_attribute(OPTIONS)

This method is a shortcut around the B<Net::Gopher::Request>
object/C<request()> method combination for item attribute information
requests.[9] It creates an item attribute information B<Net::Gopher::Request>
object, sends it, and then returns the B<Net::Gopher::Response> object for the
response.

This:

 $ng->item_attribute(
 	Host       => 'gopher.host.com',
 	Selector   => '/file.txt',
	Attributes => '+INFO'
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request ('ItemAttribute',
 		Host       => 'gopher.host.com',
 		Selector   => '/file.txt',
 		Attributes => '+INFO'
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new(TYPE [, OPTIONS | URL])> method for a complete
list of named parameters you can supply for item attribute information-type
requests.

=cut

sub item_attribute
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('ItemAttribute', @_)
	);
}





#==============================================================================#

=head2 directory_attribute(OPTIONS)

This method is a shortcut around the B<Net::Gopher::Request>
object/C<request()> method combination for directory attribute information
requests.[10] It creates a directory attribute information
B<Net::Gopher::Request> object, sends it, and then returns the
B<Net::Gopher::Response> object for the response.

This:

 $ng->directory_attribute(
 	Host       => 'gopher.host.com',
 	Selector   => '/menu',
 	Attributes => ['+INFO', '+ADMIN']
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request ('DirectoryAttribute',
 		Host       => 'gopher.host.com',
 		Selector   => '/menu',
 		Attributes => ['+INFO', '+ADMIN']
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new(TYPE [, OPTIONS | URL])> method for a
complete list of named parameters you can supply for Gopher+ directory
attribute information-type requests.

=cut

sub directory_attribute
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('DirectoryAttribute', @_)
	);
}





#==============================================================================#

=head2 url(URL)

This method is a shortcut around the B<Net::Gopher::Request>
object/C<request()> method for URLs.[11] It takes a URL, generates the
appropriate type of B<Net::Gopher::Request> object from it, sends the request,
then returns the server's response as a B<Net::Gopher::Response> object.

This:

 $ng->url('gopher.host.com/1/menu');

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request (URL => 'gopher.host.com/1/menu')
 );

Note that partial URLs are acceptable; you can leave out the scheme, port, item
type, or selector string (and anything after it) if you wish.

=cut

sub url
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('URL', @_)
	);
}





#==============================================================================#

=head2 buffer_size([BYTES])

This is a get/set method for the buffer size. To change the buffer size, supply
a number indicating a new size in bytes to use instead. (The default is 4096
bytes.) If you don't supply a new number of bytes, then this method will
return the current buffer size.

=cut

sub buffer_size
{
	my $self = shift;

	if (@_)
	{
		$self->{'buffer_size'} = shift;
	}
	else
	{
		return $self->{'buffer_size'};
	}
}





#==============================================================================#

=head2 timeout([SECONDS])

This is a get/set method that enables you to change the number of seconds at
which a timeout will occur while trying to connect, read, write, etc. to a
server. (The default is 30.) If you don't supply a new number of seconds, then
this method will return the current number of seconds.

=cut

sub timeout
{
	my $self = shift;

	if (@_)
	{
		$self->{'timeout'} = shift;
	}
	else
	{
		return $self->{'timeout'};
	}
}





#==============================================================================#

=head2 upward_compatible([BOOLEAN])

This is a get/set method that enables you to turn on or turn off upward
compatibility (which by default is on).  Just supply a true value for on or a
false value for off. If you don't specify any value, the current value, 1 or 0,
will be returned.

=cut

sub upward_compatible
{
	my $self = shift;

	if (@_)
	{
		$self->{'upward_compatible'} = (shift @_) ? 1 : 0;
	}
	else
	{
		return $self->{'upward_compatible'};
	}
}





#==============================================================================#
#
# NOTE: These methods are inherited by this class and its sub classes. Look for
# them in Net/Gopher/Exception.pm:
# 

=head2 warn_handler([HANDLER])

This is a get/set method that enables you to change the warn handler. The
default warn handler calls B<Carp.pm>'s C<carp()> function and does a stack
trace. You can change this behavior by supplying your own handler, a reference
to a subroutine that will be called with the warnings as arguments. Not that
if I<Silent> is on, then neither the warn handler nor the die handler will be
invoked.

=head2 die_handler([HANDLER])

This is a get/set method that enables you to change the die handler. The
default die handler calls B<Carp.pm>'s C<croak()> function and does a stack
trace. You can change this behavior by supplying your own handler, a reference
to a subroutine that will be called with the fatal error messages as
arguments. Not that if I<Silent> is on, then neither the die handler nor the
warn handler will be invoked.

=head2 silent([BOOLEAN])

This is a get/set method that enables you to turn on or turn off error
reporting. When turned on, B<Net::Gopher> will warn using the warn handler and
die using the die handler. When off, B<Net::Gopher> will keep quite and won't
warn or die at all.

=cut





#==============================================================================#
#
# NOTE: These methods, as well as the debug_print() method, are inherited by
# this class and its sub classes. Look for them in Net/Gopher/Debugging.pm:
# 

=head2 debug([BOOLEAN])

This is a get/set method that enables you to turn on or turn off B<Net::Gopher>
debugging (which by default is off). Just supply a true value for on or a false
value for off. If you don't specify any value, the current value, 1 or 0,
will be returned.

=head2 log_file([FILENAME])

This method can be used to specify a file that all debugging messages should be
outputted to when debugging is turned on. If the file specified does not exist,
it will be created. If it does exist, anything in it will be overwritten.

=cut







###############################################################################
#
# The following subroutines are private accessor methods.

sub _socket
{
	my $self = shift;

	if (@_)
	{
		$self->{'_socket'} = shift;
	}
	else
	{
		return $self->{'_socket'};
	}
}

sub _select {
	my $self = shift;

	if (@_)
	{
		$self->{'_select'} = shift;
	}
	else
	{
		return $self->{'_select'};
	}
}

sub _buffer
{
	my $self = shift;

	if (@_)
	{
		$self->{'_buffer'} = shift;
	}
	else
	{
		return $self->{'_buffer'};
	}
}







################################################################################
# 
# The following subroutines are private methods:
# 

################################################################################
#
#	Method
#		_read_from_socket([$bytes_to_read])
#
#	Purpose
#		This method tries to read $length worth of bytes from the
#		socket stored in $self->_socket and stores the result in
#		$self->_buffer.	If successful, the number of bytes read is
#		returned. If not, call $self->_network_error to retrieve the
#		error message. If you ommit $length, $self->buffer_size bytes
#		will be read instead. (Or at least it will try to read that
#		many; TCP is a stream protocol, and with reading, we often get
#		far fewer bytes than we asked for.)
#
#	Parameters
#		$bytes_to_read - How many bytes to read. If this is not
#		                 supplied, $self->buffer_size bytes will be
#		                 read instead.
#

sub _read_from_socket
{
	my $self          = shift;
	my $bytes_to_read = shift || $self->buffer_size;

	# first, empty the buffer:
	$self->_buffer(undef);

	while (1)
	{
		# make sure the socket's ready for reading:
		return $self->_network_error('Response timed out')
			unless ($self->_select->can_read($self->timeout));

		my $bytes_read = sysread(
			$self->_socket, $self->{'_buffer'}, $bytes_to_read
		);

		unless (defined $bytes_read)
		{
			# try again if we were interrupted by SIGCHLD or
			# something else:
			redo if ($! == EINTR);

			# a real network error occurred and there's nothing we
			# can do about it:
			return $self->_network_error(
				"Couldn't receive response: $!"
			);
		}

		$self->debug_print(
			sprintf('Received %d %s of data from server.',
				$bytes_read,
				($bytes_read == 1) ? 'byte' : 'bytes'
			)
		);

		return $bytes_read;
	}
}





################################################################################
#
#	Method
#		_write_to_socket($data [, $length])
#
#	Purpose
#		This method writes $length worth of $data to the socket stored
#		in $self->_socket. If successful, it returns the number of
#		bytes written. If not, then call $self->_network_error to find
#		out why. If you ommit $length, size_in_bytes($data) will be
#		written instead.
#
#	Parameters
#		$data   - A scalar containing bytes to send to the server.
#		$length - Amount of bytes from $data to write to the socket.
#

sub _write_to_socket
{
	my $self           = shift;
	my $data           = shift;
	my $bytes_to_write = shift || size_in_bytes($data);

	while (1)
	{
		# make sure that the socket is ready for writing:
		return $self->_network_error('Request timed out')
			unless ($self->_select->can_write($self->timeout));

		my $bytes_written = syswrite(
			$self->_socket, $data, $bytes_to_write
		);

		unless (defined $bytes_written)
		{
			# try again if we were interrupted by SIGCHLD or
			# something else:
			redo if ($! == EINTR);

			# a real network error occurred and there's nothing we
			# can do about it:
			return $self->_network_error("Couldn't send request: $!");
		}
		
		# make sure the entire request was sent:
		return $self->_network_error(
			sprintf("Couldn't send the entire request (only %d " .
			        "%s of a %d byte request): %s",
				$bytes_written,
				($bytes_written == 1) ? 'byte' : 'bytes',
				$bytes_to_write,
				$!
			)
		) unless ($bytes_written == $bytes_to_write);

		$self->debug_print(
			sprintf('Sent %d %s of data to server.',
				$bytes_written,
				($bytes_written == 1) ? 'byte' : 'bytes'
			)
		);

		return $bytes_written;
	}
}





################################################################################
#
#	Method
#		_read_status_line($remainder_ref)
#
#	Purpose
#		This calls _read_from_socket() over and over again until it
#		finds a CRLF or the number bytes read has met or exceeded the
#		maximum allowed length for a status line (as specified by
#		MAX_STATUS_LINE_SIZE). If it finds the newline (CRLF), it
#		checks to make sure the line is in the format of a Gopher+
#		status line. If the line is indeed a valid status line, this
#		method will return a string containing the status line
#		(including the terminating CRLF), and any additional bytes read
#		beyond the CRLF will be stored in $remainder_ref. If it doesn't
#		find a status line or if the line is to long, then it returnes
#		undef and stores everything it read in $remainder_ref.
#
#	Parameters
#		$remainder_ref - A reference to a scalar where
#		                 _read_status_line() will store anything read
#		                 beyond the status line, or everything read if
#		                 there is no status line.
#

sub _read_status_line
{
	my ($self, $remainder_ref) = @_;

	my $response;
	while (1)
	{
		$self->_read_from_socket(MAX_STATUS_LINE_SIZE) or return;
		return if ($self->_network_error);

		$response .= $self->_buffer;

		# look, starting from the end, for the CRLF terminator:
		if (rindex($response, $CRLF) >= 0)
		{
			if ($response =~ s/(^[\+\-]-1$CRLF)//o
				or $response =~ s/(^[\+\-]-2$CRLF)//o
				or $response =~ s/(^[\+\-]\d+$CRLF)//o)
			{
				my $status_line = $1;

				$$remainder_ref = $response;

				# show the status line for debugging:
				$self->debug_print(
					"Got this status line: [$status_line]"
				);

				return $status_line;
			}
			else
			{
				# it's a line, yes, but not a Gopher+ status
				# line:
				$self->debug_print('Not a valid status line.');

				$$remainder_ref = $response;

				return;
			}
		}
		else
		{
			if (size_in_bytes($response) >= MAX_STATUS_LINE_SIZE)
			{
				$self->debug_print(
					sprintf('Read %d %s and found no ' .
					        'status line; exceeding the ' .
						'%d byte limit',
						size_in_bytes($response),
						(size_in_bytes($response) == 1)
							? 'byte'
							: 'bytes',
						MAX_STATUS_LINE_SIZE
					)
				);

				$$remainder_ref = $response;

				return;
			}
		}
	}
}





################################################################################
#
#	Method
#		_network_error([$error_message])
#
#	Purpose
#		This method is used to set and retrieve the last network error.
#		When you supply $error_message, it stores it in the Net::Gopher
#		object and returns undef. (Allowing private methods to
#		"return $self->_network_error('Something')").
#
#		If you don't supply $error_message, then it returns
#		the last error message supplied to it.
#
#	Parameters
#		$error_message - A string containing a network error message of
#		                 some sort.
#

sub _network_error
{
	my $self  = shift;

	if (@_)
	{
		my $error = shift;

		$self->{'_network_error'} = $error;

		# return nothing so the caller can do
		# "return $self->_network_error($msg);" and their sub will exit
		# correctly, returning nothing:
		return;
	}
	else
	{
		return $self->{'_network_error'};
	}
}

1;

__END__

=head1 FOOTNOTES

[1] Anklesaria et al., I<RFC 1436: The Internet Gopher Protocol>, available at
gopher://gopher.floodgap.com/0/gopher/tech/RFC-1436 (Mar. 1993) [hereinafter
I<RFC 1436>].

[2] Anklesaria et al.,
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol>,
available at gopher://gopher.floodgap.com/0/gopher/tech/Gopher+ (Jul. 1993)
[hereinafter I<Gopher+>].

[3] I<See RFC 1436>, supra note 1, at 3-5.

[4] I<See Gopher+>, supra note 2, § 2.3.

[5] I<See Gopher+>, supra note 2, § 2.5.

[6] I<See Gopher+>, supra note 2, § 2.7.

[7] I<See> note 3.

[8] I<See> note 4.

[9] I<See> note 5.

[10] I<See> note 6.

[11] I<See> Berners-Lee et al., I<RFC 1738: Uniform Resource Locators (URL)>
§ 3.4, available at http://www.w3.org/Addressing/rfc1738.txt (Dec. 1994).

=head1 BUGS

Bugs in this package can reported and monitored using CPAN's request
tracker: rt.cpan.org.

If you wish to report bugs to me directly, you can reach me via email at
<william_g_davis at users dot sourceforge dot net>.

=head1 SEE ALSO

L<Net::Gopher::Request|Net::Gopher::Request>,
L<Net::Gopher::Response|Net::Gopher::Response>,
L<Net::Gopher::Response::MenuItem|Net::Gopher::Response::MenuItem>,
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>,
L<Net::Gopher::Constants|Net::Gopher::Constants>.

=head1 COPYRIGHT

Copyright 2003-2004 by William G. Davis.

This library is free software released under the terms of the GNU Lesser
General Public License (LGPL), the full terms of which can be found in the
"COPYING" file that comes with the distribution.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
PARTICULAR PURPOSE.

=cut
