
package Net::Gopher;

=head1 NAME

Net::Gopher - The Perl Gopher/Gopher+ client API

=head1 SYNOPSIS

 use Net::Gopher;
 
 my $ng = new Net::Gopher (
	Timeout          => 60,
	BufferSize       => 1024,
	UpwardCompatible => 0
 );
 
 # Create a new Gopher-type request:
 my $request = new Net::Gopher::Request ('Gopher',
 	Host     => 'gopher.host.com',
 	Selector => '/menu',
 	ItemType => 1
 );
 
 # you can also send parameters as a hash reference; which ever style you
 # prefer:
 $request = new Net::Gopher::Request (
 	Gopher => {
 		Host     => 'gopher.host.com',
 		Selector => '/menu',
 		ItemType => 1
 	}
 );
 
 
 
 # Now send the request to the server and get the Net::Gopher::Response
 # object for the server's response:
 my $response = $ng->request($request);
 
 # ...or store the content of the response in a separate file:
 $ng->request($request, File => 'somefile.txt');
 
 # ...or process the response as it's received:
 $ng->request($request, Handler => \&response_callback);
 
 sub response_callback {
 	my ($buffer, $request_obj, $response_obj) = @_;

	# do something with $buffer, $request_obj, and
	# $response_obj...	
 }
 
 # See Net::Gopher::Request to find out how to create request objects for
 # any type of request as well as for methods to manipulate them.
 
 
 
 # Besides the Net::Gopher::Request object/request() method combination,
 # Net::Gopher has shortcut methods for each type of request, all of which
 # return Net::Gopher::Response objects. This creates and sends a Gopher
 # request:
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
 
 
 
 # for any Gopher request, item/directorty attribute information request,
 # or simple Gopher+ request, if you wish, you can use a URL to describe
 # your request instead of named parameters:
 $response = $ng->url('gopher://gopher.host.com/');
 
 # ...it can be partial too:
 $response = $ng->url('gopher.host.com');
 
 # you can use and store URL-derived request objects too:
 $request = new Net::Gopher::Request ('URL', 'gopher.host.com');
 
 $response = $ng->request($request); 
 
 
 
 # After sending a request and getting your response in the form of a
 # Net::Gopher::Response object, use the content() method to get the
 # content of the response:
 print $repsonse->content;
 
 # or use the raw_response() method to get the entire (unmodified)
 # response as a string:
 my $raw_response = $response->raw_response;
 
 # See Net::Gopher::Response for more methods you can use to manipulate
 # Gopher and Gopher+ responses.
 ...

=head1 DESCRIPTION

B<Net::Gopher> is the Gopher/Gopher+ client API for Perl. B<Net::Gopher>
implements the Gopher and Gopher+ protocols as described in
I<RFC 1436: The Internet Gopher Protocol>, Anklesaria et al., and in
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol>,
Anklesaria et al.; bringing Gopher and Gopher+ support to Perl, enabling
Perl 5 applications to easily interact with both Gopher and Gopher+
Gopherspaces.

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
to manipulate item/directory attribute information blocks.
Finaly, there's L<Net::Gopher::Constants|Net::Gopher::Constants>, which
defines and exports on demand one-to-three sets of constants.

The Gopher request/response cycle as implemented by B<Net::Gopher> is as
follows: you create a B<Net::Gopher::Request> object encapsulating your
request; you pass it on to the B<Net::Gopher> C<request()> method, which
sends the request to the server and then receives the response; the response is
then returned as a B<Net::Gopher::Response> object for you to manipulate.

B<Net::Gopher::Request> has methods and functions to make creating request
objects easier and more flexible. In addition, this class has shortcut methods
that create the request object for you, send the request, and return the
response object.

Just like the modules in I<libnet> (e.g., L<Net::NNTP|Net::NNTP>,
L<Net::FTP|Net::FTP>), many of the methods in the B<Net::Gopher> distribution
take named parameters. However, B<Net::Gopher> does not require usage of the
non-spaced, first letter uppercased libnet style
C<ParamName =E<gt> "value"> convention. The more common all lowercase,
underscore spaced C<param_name =E<gt> "value"> convention can be used instead,
because nether case nor underscores matter: "param_name", "Param_Name",
"ParamName", "PaRaMnAmE", and "PARAM_name" will all be accepted and treated as
the same thing--choose which ever style you prefer, but just make sure you
stick with it.

Please also remember that named parameters, for every method that takes them,
can be sent optionally as either a hash or array reference--though few methods,
like B<Net::Gopher::Request> C<new()> or B<Net::Gopher::Response>
C<get_blocks()>, will actually advocate this behavior.

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
	$CRLF $NEWLINE_PATTERN
	check_params size_in_bytes remove_bytes
);

use constant DEFAULT_GOPHER_PORT  => 70;
use constant DEFAULT_TIMEOUT      => 30;
use constant DEFAULT_BUFFER_SIZE  => 4096;
use constant MAX_STATUS_LINE_SIZE => 128;
use constant PERIOD_TERMINATED    => -1;
use constant NOT_TERMINATED       => -2;

$VERSION = '0.93';



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
trying to connect to the server, when sending requests to it, when reading
responses from it, etc. If you don't specify a number of seconds, then the
default of 30 seconds will be used instead.

=item UpwardCompatible

I<UpwardCompatible> allows you turn on or turn off upward compatibility by
specifying a true or false value respectively. When upward compatibility is
turned on, if you send a Gopher+ request, item attribute information request,
or directory attribute information request to a non-Gopher+ server (one that
does not respond with a status line first), B<Net::Gopher> will try to receive
the plain-old Gopher response and not raise any errors. When turned off,
sending a Gopher+ request, item attribute information request, or directory
attribute information request to a non-Gopher+ server will result in an error.
By default, upward compatibility is turned on.

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
	    $warn_handler, $die_handler, $silent, $debug, $log_file) =
		check_params([qw(
			BufferSize
			Timeout
			UpwardCompatible
			WarnHandler
			DieHandler
			Silent
			Debug
			LogFile
		)], \@_
	);

	# turn upward compatability on by default:
	$upward_compatible = 1 unless (defined $upward_compatible);



	my $self = {
		# the size (in bytes) of _buffer:
		buffer_size       => (defined $buffer_size)
					? $buffer_size
					: DEFAULT_BUFFER_SIZE,

		# the number seconds before timeout occurs:
		timeout           => (defined $timeout)
					? $timeout
					: DEFAULT_TIMEOUT,

		# enable upward compatability?
		upward_compatible => ($upward_compatible) ? 1 : 0,

		# When we read from the socket, we'll do so using a series of
		# buffers. Each buffer is stored here before getting added to
		# _data_read (see the _read() and _buffer() methods below):
		_buffer           => undef,

		# every single byte read from the socket (see the_read()
		# and _data_read() methods below):
		_data_read        => undef,

		# the IO::Select object for the socket stored in _socket:
		_select           => undef,

		# the IO::Socket::INET socket:
		_socket           => undef,
	};

	bless($self, $class);



	# set the global Net::Gopher::Exception variables (these can also be
	# modified using the warn_handler(), die_handler() and silent()
	# methods inherited by this class and its sub classes):
	$Net::Gopher::Exception::WARN_HANDLER =
		(ref $warn_handler eq 'CODE')
			? $warn_handler
			: $Net::Gopher::Exception::DEFAULT_WARN_HANDLER;

	$Net::Gopher::Exception::DIE_HANDLER =
		(ref $die_handler eq 'CODE')
			? $die_handler
			: $Net::Gopher::Exception::DEFAULT_DIE_HANDLER;

	$Net::Gopher::Exception::SILENT = $silent ? 1 : 0; 



	# set the global Net::Gopher::Debugging variables (these can also be
	# modified using the debug() and log_file() methods inherited by this
	# class and all of its sub classes):
	$Net::Gopher::Debugging::DEBUG    = $debug ? 1 : 0;
	$Net::Gopher::Debugging::LOG      = (defined $log_file) ? 1 : 0;
	$Net::Gopher::Debugging::LOG_FILE = $log_file;

	return $self;
}





#==============================================================================#

=head2 request(REQUEST [, OPTIONS])

This method connects to a Gopher/Gopher+ server, sends a request, receives the
server's response, and disconnects from the server. It always returns a
B<Net::Gopher::Response> object encapsulating the server's response.

This method takes a B<Net::Gopher::Request> object encapsulating a Gopher or
Gopher+ request as its first argument. This is the only required argument.

If you didn't specify the I<Port> parameter of your request object (and
never set it using the C<port()> method), then the default IANA designated port
of 70 will be used when connecting to the server. If you didn't specify the
I<ItemType> parameter for I<Gopher> or I<GopherPlus> type requests (and never
set it using the C<item_type()> method), then "1", Gopher menu type, will be
assumed.

Some typical usage of request objects in conjunction with this method is
illustrated in the L<SYNOPSIS|Net::Gopher/SYNOPSIS>. For a more detailed
description, see L<Net::Gopher::Request|Net::Gopher::Request>.

In addition to the request object, this method takes two optional named
parameters:

=over 4

=item File

The first named parameter, I<File>, takes a filename. When supplied,
B<Net::Gopher> will output the content of the response to the specified file,
overwriting anything in it if it exists and creating it if it doesn't.

=item Handler

The second named parameter, I<Handler>, takes a reference to a subroutine that
will be called as the response is collected, with the buffer sent as the first
argument to the callback routine, the request object as the second, and the
response object as the third.

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

	my ($file, $handler) = check_params(['File', 'Handler'], \@_);



	my $response = new Net::Gopher::Response;
	   $response->ng($self);
	   $response->request($request);

	# First, we need to connect to the Gopher server. To connect, at the
	# very least, we need a hostname:
	return $self->call_die(
		join(' ',
			"You never specified a hostname; it's impossible to",
			"send your request without one. Specify it during",
			"object creation or later on with the host() method."
		)
	) unless (defined $request->host and length $request->host);

	# we also need a port, but we can use the default IANA designated
	# Gopher port if none was specified:
	$request->port(DEFAULT_GOPHER_PORT) unless ($request->port);

	# default to Gopher menu type:
	$request->item_type(GOPHER_MENU_TYPE)
		unless (defined $request->item_type);

	# now try connect to the Gopher server and store the IO::Socket::INET
	# socket in our Net::Gopher object:
	$self->{'_socket'} = new IO::Socket::INET (
		PeerAddr => $request->host,
		PeerPort => $request->port,
		Timeout  => $self->timeout,
		Proto    => 'tcp',
		Type     => SOCK_STREAM
	);

	# make sure we connected successfully:
	if ($@)
	{
		$self->_network_error(
			sprintf("Couldn't connect to \"%s\" at port %d: %s",
				$request->host,
				$request->port,
				$@
			)
		);

		return $response->error($self->_network_error);
	}

	# show the hostname, IP address, and port number for debugging:
	$self->debug_print(
		sprintf("Connected to \"%s\" (%s) at port %d.",
			$request->host,
			$self->_socket->peerhost,
			$self->_socket->peerport
		)
	);

	# we want non-buffering, non-blocking IO:
	$self->_socket->autoflush(1);
	$self->_socket->blocking(0);

	# now initialize the IO::Select object for our socket:
	$self->{'_select'} = new IO::Select ($self->_socket);



	my $request_string = $request->as_string;

	# send the request to the server:
	$self->_write($request_string);

	return $response->error($self->_network_error)
		if ($self->_network_error);

	$self->debug_print("Sent this request:\n[$request_string]");

	# we sent the request, so we're finished writing:
	$self->_socket->shutdown(SHUT_WR);




	# empty the socket buffer and all of the data that was read from
	# the socket during any previous request:
	$self->_clear;

	# is this a Gopher+ style request/response cycle?
	my $is_gopher_plus;
	if ($request->request_type == GOPHER_PLUS_REQUEST
		or $request->request_type == ITEM_ATTRIBUTE_REQUEST
		or $request->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
	{
		$is_gopher_plus = 1;
	}

	# this sub is used to store the received response. It takes a buffer as
	# its only argument, adds it the response object, and calls any
	# user-defined response handler with the buffer as its first argument,
	# the request object as its second, and the response object as its
	# third:
	my $store_response = sub {
		my $buffer = shift;

		$response->_add_raw($buffer);
		$response->_add_content($buffer);

		$handler->($buffer, $request, $response)
			if (ref $handler eq 'CODE');

		$self->debug_print(
			sprintf("Saved %d bytes of response.",
				(defined $buffer) ? size_in_bytes($buffer) : 0
			)
		);
	};

	# if we sent a Gopher+ request or item/directory attribute information
	# request, we need to get the status line (the first line) of the
	# response. Otherwise, we just receive the Gopher response like normal:
	if ($is_gopher_plus
		and my ($status_line, $remainder) = $self->_get_status_line)
	{
		$response->_add_raw($status_line);

		# get the status (+ or -) and transfer type (either -1, -2, or
		# the length of the response in bytes) of the response:
		my ($status,$transfer_type) = $status_line =~ /^(.)(.+?)$CRLF$/;

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
			# (-2) be terminated by a period on a line by itself
			# and then close the connection. So we'll read the
			# server's response as a series of buffers using
			# _read() and add each buffer to the response object:
			while ($self->_read)
			{
				$store_response->($self->_buffer);
			}
		}
		else
		{
			# a transfer type other than -1 or -2 is the total
			# length of the response content in bytes:
			my $bytes_left = $transfer_type;
			while (my $bytes_read = $self->_read())
			{
				# if the remaining bytes couldn't fit in the
				# buffer, then just read enough to fill the
				# buffer:
				my $bytes_to_remove =
					($bytes_left > $bytes_read)
						? $bytes_read
						: $bytes_left;

				# remove bytes from the buffer:
				my $bytes = remove_bytes(
					$self->{'_buffer'}, $bytes_to_remove
				);

				$store_response->($bytes);

				$bytes_left -= size_in_bytes($bytes);
			}
		}

		return $response->error($self->_network_error)
			if ($self->_network_error);

		# make sure we received a response:
		return $response->error(
			'The server closed the connection without returning ' .
			'any response'
		) unless (defined $response->raw_response
			and size_in_bytes($response->raw_response));

		# If the response was terminated by a period on a line by
		# itself, we need to unescape escaped periods:
		$response->_unescape_periods
			if ($transfer_type == PERIOD_TERMINATED);

		# convert all newlines in the response content to standard Unix
		# linefeed characters or MacOS carriage returns so "\n", ".",
		# "\s", and other newline-matching meta symbols can be used in
		# patterns:
		$response->_convert_newlines if ($response->is_text);

		# If we've gotten this far, then we didn't encounter any
		# network errors. However, there may still have been errors on
		# the server side, like if the item we selected did not exist;
		# in which case the content of the response contains the error:
		if ($status eq NOT_OK)
		{
			my $error = $response->content;
			   $error =~ s/$NEWLINE_PATTERN\.$NEWLINE_PATTERN?$//
			   	if ($transfer_type == -1);

			$response->error($error);
		}
	}
	else
	{
		# If we got here then this is a plain old Gopher request, not a
		# Gopher+ request.

		if ($is_gopher_plus)
		{
			# if we got here, then either we couldn't get the
			# status line of the response or got the first line but
			# it wasn't in the proper format (wasn't a status line)
			# or, while getting the status line, we ran into
			# a network error:
			return $response->error($self->_network_error)
				if ($self->_network_error);

			# If it wasn't a network error, then that means
			# we sent a Gopher+ request to a Gopher server. If
			# upward compatability is on, we'll keep going anyway
			# and try to receive the Gopher response:
			return $response->error(
				'You sent a Gopher+ style request to a ' .
				'non-Gopher+ server'
			) unless ($self->upward_compatible);

			$store_response->($self->_data_read);
		}



		# now, read the server's response as a series of buffers,
		# storing each buffer one at a time in $self->_buffer and then
		# store them in the response object:
		while ($self->_read)
		{
			$store_response->($self->_buffer);
		}
	
		# if we ran into any errors receiving the response, save
		# the error to the Net::Gopher::Response object and exit:
		return $response->error($self->_network_error)
			if ($self->_network_error);

		# make sure we received a response:
		return $response->error(
			'The server closed the connection without returning ' .
			'any response'
		) unless (defined $response->raw_response
			and size_in_bytes($response->raw_response));

		$response->_unescape_periods
			if ($response->is_text and $response->is_terminated);

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

	# empty the buffers:
	$self->_clear;



	# output the content of the response to the file the user
	# specified:
	if ($file)
	{
		open(FILE, "> $file")
			|| return $self->call_die(
				"Couldn't open output file ($file): $!."
			);

		# if it's binary, we don't want Perl messing with it when
		# we output it:
		binmode FILE unless ($response->is_text);

		print FILE $response->content;
		close FILE;
	}

	return $response;
}





#==============================================================================#

=head2 gopher(OPTIONS)

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

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

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

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

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->item(
 	Host       => 'gopher.host.com',
 	Selector   => '/file.txt',
 	Attributes => ['+INFO', '+VIEWS']
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request ('ItemAttribute',
 		Host       => 'gopher.host.com',
 		Selector   => '/file.txt',
 		Attributes => ['+INFO', '+VIEWS']
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new(TYPE [, OPTIONS | URL])> method for a
complete list of named parameters you can supply for Gopher+ item attribute
information-type requests.

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

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->directory_attribute(
 	Host       => 'gopher.host.com',
 	Selector   => '/menu',
 	Attributes => ['+INFO']
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request ('DirectoryAttribute',
 		Host       => 'gopher.host.com',
 		Selector   => '/menu',
 		Attributes => ['+INFO']
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

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->url('gopher.host.com/1/menu');

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request (URL => 'gopher.host.com/1/menu')
 );

Note that partial URLs are acceptable; the scheme will be added for you, as
will the item type.

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
default warn handler calls L<Carp.pm|Carp>'s C<carp()> function and does a
stack trace. You can change this behavior by supplying your own handler, a
reference to a subroutine that will be called with the warnings as arguments.
Not that if I<Silent> is on, then neither the warn handler nor the die handler
will be called.

=head2 die_handler([HANDLER])

This is a get/set method that enables you to change the die handler. The
default die handler calls L<Carp.pm|Carp>'s C<croak()> function and does a
stack trace. You can change this behavior by supplying your own handler, a
reference to a subroutine that will be called with the fatal error messages as
arguments. Not that if I<Silent> is on, then neither the die handler
nor the warn handler will be invoked.

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







################################################################################
# 
# The following subroutines are private accessor methods. They are 'get' only:
#

sub _socket    { return shift->{'_socket'} }
sub _select    { return shift->{'_select'} }
sub _buffer    { return shift->{'_buffer'} }
sub _data_read { return shift->{'_data_read'} }







################################################################################
# 
# The following subroutines are private methods:
# 

################################################################################
#
#	Method
#		_clear()
#
#	Purpose
#		This method empties the socket buffer ($self->_buffer) and all
#		of the data that's been read from the socket
#		($self->_data_read).
#
#	Parameters
#		None.
#

sub _clear
{
	my $self = shift;

	$self->{'_buffer'}    = undef;
	$self->{'_data_read'} = undef;
}





################################################################################
#
#	Method
#		_read()
#
#	Purpose
#		This method reads from the socket stored in $self->_socket for
#		one $self->buffer_size length and stores the result in
#		$self->_buffer.	If successful, the number of bytes read is
#		returned. If not, call $self->_network_error to retrieve the
#		error message. This method also prepends the $self->_buffer
#		buffer it filled to $self->_data_read.
#
#	Parameters
#		None.
#

sub _read
{
	my $self = shift;

	while (1)
	{
		# first, make sure we can read from the socket; that we're
		# still connected to the server and there's something in the OS
		# buffer to read:
		return unless ($self->_select->can_read($self->timeout));

		# try to read part of the response from the socket into the
		# buffer:
		my $bytes_read = $self->_socket->sysread(
			$self->{'_buffer'}, $self->buffer_size
		);

		unless (defined $bytes_read)
		{
			# try again if we were interrupted by SIGCHLD or
			# whatever:
			redo if ($! == EINTR);

			# a network error occurred and there's nothing we can
			# do about it:
			return $self->_network_error("No response received: $!");
		}

		# add the buffer to $self->_data_read, which will store every
		# single byte read from the socket:
		$self->{'_data_read'} .= $self->_buffer;

		return $bytes_read;
	}
}





################################################################################
#
#	Method
#		_write($data)
#
#	Purpose
#		This method writes to the socket stored in $self->_socket. If
#		successful, it returns the number of bytes written. If not,
#		then call $self->_network_error to find out why.
#
#	Parameters
#		$data - A string of bytes to send to the server.
#

sub _write
{
	my ($self, $data) = @_;

	while (1)
	{
		# make sure we can write to the socket; that we're still
		# connected to the server and the OS buffer isn't full:
		return $self->_network_error('Request timed out')
			unless ($self->_select->can_write($self->timeout));

		# try to send the data to the server:
		my $bytes_written =
			$self->_socket->syswrite($data, size_in_bytes($data));

		unless (defined $bytes_written)
		{
			# try again if we were interrupted by SIGCHLD or
			# whatever:
			redo if ($! == EINTR);

			# a network error occurred and there's nothing we can
			# do about it:
			return $self->_network_error("Couldn't send request: $!");
		}
		
		# make sure the entire request was sent:
		return $self->_network_error(
			sprintf("Couldn't send the entire request (only %d " .
			        "%s of a %d byte request): %s",
				$bytes_written,
				($bytes_written == 1) ? 'byte' : 'bytes',
				size_in_bytes($data),
				$!
			)
		) unless (size_in_bytes($data) == $bytes_written);



		return $bytes_written;
	}
}





################################################################################
#
#	Method
#		_get_status_line()
#
#	Purpose
#		This method calls _read() and looks for a CRLF in the buffer,
#		calling _read() over and over again until it finds the CRLF or
#		the number bytes read has met or exceeded the maximum allowed
#		length of a status line (as specified by MAX_STATUS_LINE_SIZE).
#		If it finds the newline (CRLF), it checks to make sure the line
#		is in the format of a Gopher+ status line. If the line is a
#		status line, this method will return a list with a string
#		contaning the status line (including the terminating CRLF) and
#		a string containing the remainder, any bytes after the status
#		line that we're also read, as elements. If there was no CRLF or
#		if there was but the line wasn't a status line or if the line
#		was too big, this method will return undef.
#
#	Parameters
#		None.
#

sub _get_status_line
{
	my $self = shift;

	my $response;

	while (1)
	{
		$self->_read || return;
		return if ($self->_network_error);

		$response .= $self->_buffer;

		# look, starting from the end, for the CRLF terminator:
		if (rindex($response, $CRLF) >= 0)
		{
			if ($response =~ /^([\+\-](?:\-1|\-2|\d+)$CRLF)(.*)/so)
			{
				my $status_line = $1;
				my $remainder   = $2;

				# show the status line for debugging:
				$self->debug_print(
					"Got this status line:\n[$status_line]"
				);

				return($status_line, $remainder);
			}
			else
			{
				# a line, yes, but not a status line:
				return;
			}
		}
		else
		{
			return if (size_in_bytes($response) >= MAX_STATUS_LINE_SIZE);
		}
	}
}





################################################################################
#
#	Method
#		_network_error()
#
#	Purpose
#		This method is used to set and retrieve the last network error.
#		It removes those annoying IO::Socket::* package prefixes from
#		error messages too (e.g. "IO::Socket::INET: Bad hostname").
#
#	Parameters
#		None.
#

sub _network_error
{
	my $self  = shift;

	if (@_)
	{
		# remove the socket class name from error messages
		# (IO::Socket::* modules put them in):
		($self->{'_network_error'} = shift) =~ s/IO::Socket::\w+: //g;

		# return so the caller can do
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

Copyright 2003 by William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
