
package Net::Gopher;

=head1 NAME

Net::Gopher - The Perl Gopher/Gopher+ client API 

=head1 SYNOPSIS

 use Net::Gopher;
 
 my $ng = new Net::Gopher;
 
 # Create a new Net::Gopher::Request object:
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
 
 
 
 # Send the request to the server and get the Net::Gopher::Response
 # object for the server's response:
 my $response = $ng->request($request);
 
 # ...or store the content of the response in a separate file:
 $ng->request($request, File => 'somefile.txt');
 
 # ...or process the response as it's received:
 $ng->request($request, Callback => \&some_sub);
 
 sub some_sub
 {
 	my ($buffer, $request_obj, $response_obj) = @_;
 	# do something with $buffer, $request_obj, and $response_obj...	
 }
 
 # See Net::Gopher::Request to find out how to create request objects for
 # any type of request as well as for methods to manipulate them.
 
 
 
 # Besides the Net::Gopher::Request object/request() combination,
 # Net::Gopher has shortcut methods for each type of request, all of which
 # return Net::Gopher::Response objects:
 $response = $ng->gopher(
 	Host     => 'gopher.host.com',
 	Selector => '/menu',
 	ItemType => 1
 );

 $response = $ng->gopher_plus(
 	Host           => 'gopher.host.com',
 	Selector       => '/doc.txt',
	Representation => 'text/plain'
 	ItemType       => 0
 );
 
 
 
 # After sending a request and gettingyour response in the form of a
 # Net::Gopher::Response object:
 if ($response->is_success) {
 	# use the content() method to get the content of the response:
 	print $repsonse->content;
 
	# or use the raw_response() method to get the entire
	# (unmodified) response as a string:
 	my $raw_response = $response->raw_response;
 } else {
 	# if there was an error, call the error() method on
	# the response object to get the error message:
 	die $response->error;
 }
 
 # See Net::Gopher::Response for more methods you can use to manipulate
 # Gopher and Gopher+ responses.
 ...

=head1 DESCRIPTION

B<Net::Gopher> is the Gopher/Gopher+ client API for Perl. B<Net::Gopher>
implements the Gopher and Gopher+ protocols as described in
I<RFC 1436: The Internet Gopher Protocol>, Anklesaria et al., and in
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol>,
Anklesaria et al.; bringing Gopher and Gopher+ support to Perl, enabling
Perl 5 applications to easily interact with both Gopher as well as Gopher+
servers.

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
manipulate menu items in Gopher and Gopher+ menus and
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
to manipulate item/directory attribute information blocks.
Finaly, there's L<Net::Gopher::Constants|Net::Gopher::Constants>, which several
different types of constants you can have imported

The Gopher request/response cycle as implemented by B<Net::Gopher> is as
follows: you create a B<Net::Gopher::Request> object encapsulating your
request, you pass it on to the B<Net::Gopher> C<request()> method, which
returns a B<Net::Gopher::Response> for you to manipulate.
B<Net::Gopher::Request> has methods and functions to make creating request
objects easier and more flexible. In addition, this class has shortcut methods
that create the request object for you, send the request, and return the
response object.

Just like the modules in I<libnet> (e.g., L<Net::NNTP|Net::NNTP>,
L<Net::FTP|Net::FTP>), many of the methods in the B<Net::Gopher> distribution
take parameters in the form of ParamName => "value" pairs. Also like in
I<libnet>, the case of these parameter names is sensitive. Unlike in
I<libnet>, if you specify an invalid parameter (e.g., "Somename," "SOMENAME,"
or "something" when the method expected "SomeName"), then the class will
croak, listing the offending parameter names.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);
use Carp;
use IO::Socket qw(SOCK_STREAM);
use IO::Select;
use Net::Gopher::Request;
use Net::Gopher::Response;
use Net::Gopher::Utility qw(check_params $CRLF);
use Net::Gopher::Constants qw(:request :response :item_types);

$VERSION = '0.90';







################################################################################
# 
# The following functions are public methods:
# 

#==============================================================================#

=head2 new([BufferSize => $num_bytes, Timeout => $seconds, Debug => $boolean])

This is the constructor method. It creates a new B<Net::Gopher> object and
returns a reference to it. This method takes several optional named parameters:

I<BufferSize> is the size (in bytes) of the buffer to use when reading data
from the socket. If you don't specify I<BufferSize>, then the default of 4096
will be used instead.

I<Timeout> specifies the number of seconds at which a timeout will occur when
trying to connect to the server, when sending requests to it, when reading
responses from it, etc. If you don't specify a number of seconds, then the
default of 30 seconds will be used instead.

Finally, I<Debug> allows you turn on or turn off debugging information, which
by default is off. If debugging is turned on, then formatted diagnostic
messages about the current request/response cycle will be outputted to the
terminal.

See also the corresponding get/set
L<buffer_size()|Net::Gopher/buffer_size([$size])>,
L<timeout()|Net::Gopher/timeout([$seconds])>,
and L<debug()|Net::Gopher/debug($boolean)> methods below.

=cut

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my ($buffer_size, $timeout, $debug) =
		check_params(['BufferSize', 'Timeout', 'Debug'], @_);

	my $self = {
		# the IO::Socket::INET socket:
		_socket        => undef,

		# the IO::Select object for the socket stored in _socket:
		_select        => undef,

		# the number of seconds before a timeout occurs (when
		# connecting, trying to read, trying to write, etc.):
		timeout        => undef,

		# every single byte read from the socket (see the_read()
		# and _data_read() methods below):
		_data_read     => undef,

		# When we read from the socket, we'll do so using a series of
		# buffers. Each buffer is stored here before getting added to
		# _data_read (see the _read() and _buffer() methods below):
		_buffer        => undef,

		# the size of _buffer:
		buffer_size    => (defined $buffer_size) ? $buffer_size : 4096,

		# the number seconds before timeout occurs:
		timeout        => (defined $timeout) ? $timeout : 30,

		# enable debugging?
		debug          => $debug ? 1 : 0,

		# if the user supplies *Callback* to request(), then this will
		# conain a reference to sub that will call their sub with the
		# buffer, request object, and response object as arguments:
		_callback      => undef,

		# This stores internal network error messages. It's accessed
		# using the internal _network_error() method:
		_network_error => undef,
	};

	bless($self, $class);

	return $self;
}





#==============================================================================#

=head2 request($request [, File => 'filename', Callback => \&sub])

This method connects to a Gopher/Gopher+ server, sends a request, and
disconnects from the server.

This method takes one required argument, a B<Net::Gopher::Request> object
encapsulating a Gopher or Gopher+ request. Some typical usage of request
objects in conjunction with this method is illustrated in the
L<SYNOPSIS|Net::Gopher/SYNOPSIS>. For a more detailed description, see
L<Net::Gopher::Request|Net::Gopher::Request>.

If you didn't specify the I<Port> parameter for your request object (and
never set it using the C<port()> method), then the default IANA designated port
of 70 will be used when connecting to the server. If you didn't specify the
I<ItemType> parameter for I<Gopher> or I<GopherPlus> type requests (and never
set it using the C<item_type()> method), then "1", Gopher menu type, will be
assumed.

In addition to the request object, this method takes two optional named
parameters.

The first named parameter, I<File>, specifies an output filename. When
specified, Net::Gopher will output the content of the response to this file,
overwriting anything in it if it exists, and creating it if it doesn't.

The second named parameter, I<Callback>, is a reference to a subroutine that
will be called as the response is collected, with the buffer sent as the first
argument to the callback routine, the request object as the second, and the
response object as the third.

Regardless of what you supply, this method will always return a
B<Net::Gopher::Response> object.

See L<Net::Gopher::Response|Net::Gopher::Response> for methods you can call on
response objects.

=cut

sub request
{
	my $self    = shift;
	my $request = shift;

	croak "A Net::Gopher::Request object was not supplied"
		unless (UNIVERSAL::isa($request, 'Net::Gopher::Request'));

	my ($file, $callback) = check_params(['File', 'Callback'], @_);



	my $response = new Net::Gopher::Response;

	# save the request object in the response object:
	$response->request($request);



	# Before we can send the requet, we need to connect to the Gopher
	# server. To connect, at the very least, we need a hostname:
	croak "No hostname specified" unless (defined $request->host);

	# we also need a port, but we can use the default IANA designated
	# Gopher port if none was specified:
	$request->port(70) unless ($request->port);

	# now try connect to the Gopher server and store the IO::Socket::INET
	# socket in our Net::Gopher object:
	$self->{'_socket'} = new IO::Socket::INET (
		PeerAddr => $request->host,
		PeerPort => $request->port,
		Timeout  => $self->timeout,
		Proto    => 'tcp',
		Type     => SOCK_STREAM
	) or return $response->error(
		sprintf("Couldn't connect to '%s' at port %d: %s",
			$request->host,
			$request->port,
			$@
		)
	);

	# XXX If you know when blocking/non-blocking socket support was added
	# to IO::Socket::INET, please email me:
	eval { $self->_socket->blocking(0); };
	if ($@)
	{
		croak(
			"Your version of IO::Socket does not support " .
			"non-blocking mode. Please upgrade to a more " .
			"recent version"
		);
	}

	# show the hostname, IP address, and port number for debugging:
	$self->_debug_start(
		sprintf("Connected to '%s' (%s) at port %d.",
			$request->host,
			$self->_socket->peerhost,
			$self->_socket->peerport
		)
	);

	# now initialize the IO::Select object for our socket:
	$self->{'_select'} = new IO::Select ($self->_socket);




	# is this a Gopher+ request?
	my $is_gopher_plus;
	if ($request->request_type == GOPHER_PLUS_REQUEST
		or $request->request_type == ITEM_ATTRIBUTE_REQUEST
		or $request->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
	{
		$is_gopher_plus = 1;
	}

	# default to Gopher menu item type:
	$request->item_type(GOPHER_MENU_TYPE)
		unless (defined $request->item_type);

	# send the request to the server:
	my $request_string = $request->as_string;
	$self->_write($request_string);

	# show the request we just sent for debugging:
	$self->_debug_print("Sent this request:\n$request_string");





	# empty the socket buffer and all of the data that was read from
	# the socket during any previous request and remove the current
	# callback routine:
	$self->_clear;

	# if the user supplied a callback sub, then we'll create a routine to
	# call their sub with the buffer just received as the first argument,
	# the request object as the second, and the response object as the
	# third:
	if ($callback and ref $callback eq 'CODE')
	{
		$self->{'_callback'} = sub {
			$callback->($self->_buffer, $request, $response)
		}
	}



	# if we sent a Gopher+ request or item/directory attribute information
	# request, we need to get the status line (the first line) of the
	# response:
	if ($is_gopher_plus and my $status_line = $self->_get_status_line)
	{
		# get the status (+ or -) and the transfer type of the response
		# (either -1, -2, or the length of the response in bytes):
		my ($status, $transfer_type) = $status_line =~ /^(.)(\-?\d+)/;

		# add the status line and status to our response object:
		$response->status_line($status_line);
		$response->status($status);



		# this will store the content of the response, everything after
		# the status line:
		my $content = '';

		# (Read the documentation below for _get_status_line().) Any
		# characters remaining in the buffer after calling the
		# _get_status_line() method are content:
		$content .= $self->_buffer if (length $self->_buffer);

		if ($transfer_type == -1 or $transfer_type == -2)
		{
			# A -1 or -2 transfer type means the server is going to
			# send a series of bytes, which may (-1) or may not
			# (-2) be terminated by a period on a line by itself,
			# and then close the connection. So we'll read the
			# server's response as a series of buffers using
			# _read() and add each buffer to the response content:
			while ($self->_read)
			{
				$content .= $self->_buffer;
			}
		}
		else
		{
			# a transfer type other than -1 or -2 is the total
			# length of the response content in bytes:
			while (my $bytes_left = $transfer_type - length $content)
			{
				# fill the buffer if it's empty:
				unless (length $self->_buffer)
				{
					# break out if we read everything and
					# the server's closed the connction or
					# if we ran into any errors getting the
					# last buffer, and thus couldn't refill
					# the buffer:
					$self->_read() or last;
				}

				# try to read all of the remaining bytes of the
				# server's response from the buffer and add
				# them to the response content:
				$content .=
				substr($self->{'_buffer'}, 0, $bytes_left, '');
			}
		}

		# if we ran into any network errors while receiving the
		# response, get the error, save it in the response object, and
		# exit:
		return $response->error($self->_network_error)
			if ($self->_network_error);

		# save the raw response and the response content in the
		# Net::Gopher::Response object: 
		$response->raw_response($self->_data_read);
		$response->content($content);

		# If we've gotten this far, then we didn't encounter any
		# network errors. However, there may still have been errors on
		# the server side, like if the item we selected did not exist,
		# in which case the content of the response contains the error
		# code (number) followed by a description of the error (e.g.,
		# "1 Item is not available."):
		if ($response->status eq FAILURE_CODE)
		{
			$response->error($response->content);
		}

		# If the response length was -1, then the response was
		# terminated by a period on a line by itself, which means we
		# need to unescape escaped periods, remove everything after the
		# terminating period on a line by itself, and remove the period
		# on a line by itself too for items other than text files,
		# text/plain formatted items, or Gopher/Gopher+ menus:
		if ($transfer_type == -1)
		{
			$response->_clean_period_termination;
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
			# it wasn't in the proper format (wasn't a status
			# line) or, while getting the status line, we ran into
			# a network error:
			return $self->_network_error if ($self->_network_error);
		}



		# this will store the content of the response:
		my $content = '';

		# now, read the server's response as a series of buffers,
		# storing each buffer one at a time in $self->_buffer and
		# adding each buffer to $self->_data_read:
		while ($self->_read)
		{
			$content .= $self->_buffer;
		}
	
		# if we ran into any errors receiving the response, save
		# the error to the Net::Gopher::Response object and exit:
		return $response->error($self->_network_error)
			if ($self->_network_error);

		# now save the raw response and the response content to the
		# Net::Gopher::Response object:
		$response->raw_response($self->_data_read);
		$response->content($content);

		# In Gopher, with MS DOS binary files (type 5) and with generic
		# binary-type files (type 9), the server sends a series of
		# bytes and then closes the connection. With all other types,
		# it sends a block of text terminated by a period on a line by
		# itself, in which case we need to unescape escaped periods,
		# remove everything after the terminating period on a line by
		# itself, and remove the period on a line by itself too for
		# items other than text files and menus:
		if ($request->item_type ne DOS_BINARY_FILE_TYPE
			and $request->item_type ne BINARY_FILE_TYPE
			and $response->is_terminated)
		{
			$response->_clean_period_termination;
		}
	}

	# show the length of the response we got for debugging:
	$self->_debug_end(
		sprintf('Received a response of %d bytes (total), with %d ' .
		        'bytes of content.',
			length $response->raw_response,
			length $response->content
		)
	);

	# disconnect from the server:
	$self->_socket->shutdown(2);

	# if the item is a text item, we need convert the CRLF and CR line
	# endings to LF, that way the user can use \n, ., \s, etc. in regexes
	# to match newlines in $response->content (see <perldoc -f binmode>):
	if ($response->is_text)
	{
		$response->_convert_newlines;
	}

	# output the content of the response to the file the user specified:
	if ($file)
	{
		open(FILE, "> $file") || croak "Couldn't open file ($file): $!";

		# don't convert LF characters to CRLF (on Windows) or CR on
		# (MacOS) unless it's text:
		binmode FILE unless ($response->is_text);

		print FILE $response->content;
		close FILE;
	}

	return $response;
}





#==============================================================================#

=head2 gopher(%args | \%args)

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->gopher(
 	Host     => 'gopher.host.com',
 	Selector => '/menu',
	ItemType => 1
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request('Gopher',
 		Host     => 'gopher.host.com',
 		Selector => '/menu',
 		ItemType => 1
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new($type, [%args | \%args | $url])> method for a
complete list of named parameters you can supply for Gopher request types.

=cut

sub gopher
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('Gopher', @_)
	);
}





#==============================================================================#

=head2 gopher_plus(%args | \%args)

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->gopher_plus(
 	Host           => 'gopher.host.com',
 	Selector       => '/menu',
 	Representation => 'application/gopher+-menu'
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request('GopherPlus',
 		Host           => 'gopher.host.com',
 		selector       => '/menu',
 		Representation => 'application/goopher+-menu'
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new($type, [%args | \%args | $url])> method for a
complete list of named parameters you can supply for Gopher+ request types.

=cut

sub gopher_plus
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('GopherPlus', @_)
	);
}





#==============================================================================#

=head2 item_attribute(%args | \%args)

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->item(
 	Host       => 'gopher.host.com',
 	Selector   => '/file.txt',
 	Attributes => ['+INFO', '+VIEWS']
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request('ItemAttribute',
 		Host       => 'gopher.host.com',
 		Selector   => '/file.txt',
 		Attributes => ['+INFO', '+VIEWS']
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new($type, [%args | \%args | $url])> method for a
complete list of named parameters you can supply for Gopher+ item attribute
information request types.

=cut

sub item_attribute
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('ItemAttribute', @_)
	);
}





#==============================================================================#

=head2 directory_attribute(%args | \%args)

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->directory_attribute(
 	Host       => 'gopher.host.com',
 	Selector   => '/menu',
 	Attributes => ['+INFO']
 );

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request('DirectoryAttribute',
 		Host       => 'gopher.host.com',
 		Selector   => '/menu',
 		Attributes => ['+INFO']
 	)
 );

See the B<Net::Gopher::Request>
L<new()|Net::Gopher::Request/new($type, [%args | \%args | $url])> method for a
complete list of named parameters you can supply for Gopher+ directory
attribute information request types.

=cut

sub directory_attribute
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('DirectoryAttribute', @_)
	);
}





#==============================================================================#

=head2 url($url)

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->url('gopher.host.com/1/menu');

is roughly equivalent to this:

 $ng->request(
 	new Net::Gopher::Request(URL => 'gopher.host.com/1/menu')
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

=head2 buffer_size([$size])

This is a get/set method that enables you to change the buffer sized used. (The
default is 4096.)

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

=head2 timeout([$seconds])

This is a get/set method that enables you to change the number of seconds at
which a timeout will occur while trying to connect, read, write, etc. to a
server. If you don't supply a new number of seconds, then this method will
return the current number.

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

=head2 debug([$boolean])

This is a get/set method that enables you to turn on or turn off B<Net::Gopher>
debugging (default is off). Just supply a true value for on, or a false value
for off.

=cut

sub debug
{
	my $self = shift;

	if (@_)
	{
		$self->{'debug'} = shift @_ ? 1 : 0;
	}
	else
	{
		return $self->{'debug'};
	}
}







################################################################################
# 
# The following functions are private accessor methods. They are 'get' only:
#

sub _socket    { return shift->{'_socket'} }
sub _select    { return shift->{'_select'} }
sub _buffer    { return shift->{'_buffer'} }
sub _data_read { return shift->{'_data_read'} }
sub _callback
{
	my $self = shift;

	# if a sub was defined, call it:
	if ($self->{'_callback'} and ref $self->{'_callback'} eq 'CODE')
	{
		$self->{'_callback'}->();
	}
}







################################################################################
# 
# The following functions are private methods:
# 

################################################################################
#
#	Method
#		_debug_start(@messages)
#
#	Purpose
#		This method outputs a debugging message to the console. Call it
#		before calling _debug_print(). Call _debug_print() to print any
#		more messages after this one. Note that for this method, for
#		_debug_print, and for _debug_end, you can supply a list of
#		messages instead of a single string; they will be concatenated
#		together and treated as one message.
#
#	Parameters
#		@messages - One or more messages that will be outputted to the
#		            console, end-to-end.
#

sub _debug_start
{
	my $self = shift;

	if ($self->debug)
	{
		printf("%s\n%s\n%s\n",
			'#' x 79,
			join('', @_),
			'-' x 79
		);
	}
}





################################################################################
#
#	Method
#		_debug_print(@messages)
#
#	Purpose
#		After printing your initial message with _debug_start(), use
#		this method to print any more messages besides the final
#		message. To print the final message, use _debug_end().
#
#	Parameters
#		@messages - One or more messages that will be outputted to the
#		            console, end-to-end.
#

sub _debug_print
{
	my $self = shift;

	if ($self->debug)
	{
		printf("%s\n%s\n",
			join('', @_),
			'-' x 79
		);
	}
}





################################################################################
#
#	Method
#		_debug_end(@messages)
#
#	Purpose
#		Use this method to print the final message.
#
#	Parameters
#		@messages - One or more messages that will be outputted to the
#		            console, end-to-end.
#

sub _debug_end
{
	my $self = shift;

	if ($self->debug)
	{
		printf("%s\n%s\n\n",
			join('', @_),
			'#' x 79
		);
	}
}





################################################################################
#
#	Method
#		_clear()
#
#	Purpose
#		This method empties the socket buffer ($self->_buffer) and all
#		of the data that's been read from the socket
#		($self->_data_read) and clears the current callback subroutine
#		($self->_callback).
#
#	Parameters
#		None.
#

sub _clear
{
	my $self = shift;

	$self->{'_buffer'}    = undef;
	$self->{'_data_read'} = undef;
	$self->{'_callback'}  = undef;
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
#		returned and the callback in $self->_callback (if defined) is
#		executed with what was just read sent as the argument. If not,
#		call $self->_network_error to retrieve the error message. This
#		method also prepends the $self->_buffer it filled to
#		$self->_data_read.
#	Parameters
#		None.
#

sub _read
{
	my $self = shift;



	# make sure we can read from the socket; that there's something in the
	# OS buffer to read:
	return $self->_network_error('Response timed out')
		unless ($self->_select->can_read($self->timeout));

	# read part of the response from the socket into the buffer:
	my $num_bytes_read;

	{
		$num_bytes_read = sysread(
			$self->_socket, $self->{'_buffer'}, $self->buffer_size
		);
	}

	# make sure something was received:
	unless (defined $num_bytes_read)
	{
		return $self->_network_error("No response received: $!");
	}

	# add the buffer to _data_read, which will store every single byte
	# read from the socket:
	$self->{'_data_read'} .= $self->_buffer;

	# call the callback routine (if the user defined one):
	$self->_callback;

	return $num_bytes_read;
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
#		$data - A string to send to the server.
#

sub _write
{
	my $self = shift;
	my $data = shift;



	# make sure we can write to the socket; that the OS buffer isn't full:
	return $self->_network_error('Request timed out')
		unless ($self->_select->can_write($self->timeout));

	# now send the request to the Gopher server:
	my $num_bytes_written = syswrite($self->_socket, $data, length $data);

	# make sure *something* was sent:
	return $self->_network_error("Nothing was sent: $!")
		unless (defined $num_bytes_written);

	# make sure the entire request was sent:
	return $self->_network_error("Couldn't send entire request: $!")
		unless (length $data == $num_bytes_written);

	return $num_bytes_written;
}





################################################################################
#
#	Method
#		_get_status_line()
#
#	Purpose
#		This method fills the buffer stored in $self->{'_buffer'}
#		(using _read()) and removes character after character
#		from the the buffer looking for the the newline, refilling
#		the buffer if it gets empty. Once it finds the newline, it
#		checks to make sure the line is in the format of a Gopher+
#		status line. If the line is a status line, this method will
#		return it. Otherwise, this method will return undef (call
#		_network_error() to find out why).
#
#	Parameters
#		None.
#

sub _get_status_line
{
	my $self = shift;

	# To get the status line (the first line), we'll use the _read()
	# method to read and store a buffer in $self->_buffer, then remove
	# character after character from the beginning of the buffer and add
	# them to $first_line, checking for the CRLF in $first_line. If we end
	# up removing everything from the buffer, then we'll refill it. If we
	# can't refill it, then that means we read everything and the server
	# has closed the connection and that the server is not a Gopher+
	# server.

	my $first_line;    # everything up till the first CRLF in the response.
	my $found_newline; # did we find the newline?

	FIRSTLINE: while ($self->_read)
	{
		while (length $self->_buffer)
		{
			# grab a single character from the buffer:
			$first_line .= substr($self->{'_buffer'}, 0, 1, '');

			# now, look (starting at the end) for the CRLF:
			if (index($first_line, $CRLF, -1) > 0)
			{
				$found_newline = 1;
				last FIRSTLINE;
			}
		}
	}
	
	# exit if we ran into any errors:
	return if ($self->_network_error);



	# if we found the newline and the first character contains
	# the status (+ or -) followed by a positive or negative number,
	# then the response is a Gopher+ response:
	if ($found_newline and $first_line =~ /^[\+\-] (?:\-[12]|\d+) $CRLF/x)
	{

		# show the status line for debugging:
		$self->_debug_print("Got this status line:\n$first_line");

		return $first_line;
	}
}





################################################################################
#
#	Method
#		_network_error()
#
#	Purpose
#		This method is used to set and retrieve the last network error.
#
#	Parameters
#		None.
#

sub _network_error
{
	my $self  = shift;

	if (@_)
	{
		# remove the socket class name from error messages (IO::Socket
		# puts them in):
		($self->{'_network_error'} = shift) =~ s/IO::Socket::INET:\s//g;

		# return so the caller can do
		# "return $self->_network_error($msg);" and their sub will exit
		# correctly:
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
L<Net::Gopher::Constants|Net::Gopher::Constants>,

=head1 COPYRIGHT

Copyright 2003 by William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
