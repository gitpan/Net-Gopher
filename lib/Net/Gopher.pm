
package Net::Gopher;

=head1 NAME

Net::Gopher - The Perl Gopher/Gopher+ client API 

=head1 SYNOPSIS

 use Net::Gopher;
 
 my $ng = new Net::Gopher;
 
 # create a new Net::Gopher::Request object:
 my $request = new Net::Gopher::Request(
 	Gopher => {
 		Host     => 'gopher.host.com',
 		Selector => '/menu',
 		ItemType => 1
 	}
 );
 
 # request something from the server and get the Net::Gopher::Response object:
 my $response = $ng->request($request);
 
 # ...or store the content of the response in a separate file:
 $ng->request($request, File => 'somefile.txt');

 # ...or process the response as it's received:
 $ng->request($request, Callback => \&some_sub);

 sub some_sub
 {
 	my $content = shift;
 	# do something with $content...	
 }
 
 # See Net::Gopher::Request to find out how to create request objects for any
 # type of request, as well as methods to manipulate them.
 
 
 
 # Besides the Net::Gopher::Request object/request() combination, Net::Gopher
 # has shortcut methods for each type of request, which all return
 # Net::Gopher::Response objects:
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
 
 
 
 # After sending a request and getting a Net::Gopher::Response object:
 if ($response->is_success) {
 	# use the content() method to get the content of the response:
 	print $repsonse->content;
 
	# or use the as_string() method to get the entire (unmodified) response
	# as a string:
 	my $raw_response = $response->as_string;
 } else {
 	# if their was an error, call the error() method on the response object
 	# to get the error message:
 	print $response->error;
 }
 
 # See Net::Gopher::Response for more methods you can use to manipulate Gopher
 # and Gopher+ responses.
 ...

=head1 DESCRIPTION

B<Net::Gopher> is a Gopher/Gopher+ client API for Perl. B<Net::Gopher>
implements the Gopher and Gopher+ protocols as desbribed in
I<RFC 1436: The Internet Gopher Protocol>, Anklesaria, et al. and in
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol>,
Anklesaria, et al.; bringing Gopher and Gopher+ support to Perl, enabling
Perl 5 applications to easily interact with both Gopher as well as Gopher+
servers.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use vars qw($VERSION);
use Carp;
use IO::Socket qw(SOCK_STREAM inet_ntoa);
use IO::Select;
use Net::Gopher::Request;
use Net::Gopher::Response;
use Net::Gopher::Utility qw(check_params $CRLF);

$VERSION = '0.78';





#==============================================================================#

=head2 new([BufferSize => $num_bytes, Timeout => $seconds, Debug => $boolean])

This is the constructor method. It creates a new B<Net::Gopher> object and
returns a reference to it. This method takes several optional named parameters.

I<BufferSize> is the size (in bytes) of the buffer to use when reading data
from the socket. If you don't specify I<BufferSize>, then the default of 1024
will be used instead.

I<Timeout> specifies the number of seconds at which a timeout will occur when
trying to connect to the server, when sending requests to it, when reading
responses from it, etc. If you don't specify a number of seconds, then the
default of 30 seconds will be used instead.

Finally, I<Debug> allows you turn on or turn of debugging information, which by
default is off. If debugging is turned on, then formatted diagnostic messages
about the current request/response cycle will be outputted to the terminal.

Also see the corresponding get/set
L<buffer_size()|Net::Gopher/buffer_size([$size])>,
L<gopher_plus()|Net::Gopher/gopher_plus([$boolean])>,
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
		'socket'    => undef,

		# the IO::Select object for the socket stored in socket:
		'select'    => undef,

		# the number of seconds before a timeout occurs (when
		# connecting, trying to read, trying to write, etc.):
		timeout     => undef,

		# every single byte read from the socket:
		data_read   => undef,

		# When we read from the socket, we'll do so using a series of
		# buffers. Each buffer is stored here before getting added to
		# data_read:
		buffer      => undef,

		# the size of buffer:
		buffer_size => (defined $buffer_size) ? $buffer_size : 1024,

		# the number seconds before timeout occurs:
		timeout     => (defined $timeout) ? $timeout : 30,

		# enable debugging?
		debug       => $debug ? 1 : 0,

		# This stores internal error messages. It's accessed using the
		# internal _error() method
		error       => undef,
	};

	bless($self, $class);
	return $self;
}





#==============================================================================#

=head2 request($request [, File => 'filename', Callback => \&sub])

This method connects to a Gopher/Gopher+ server, sends a request, and
disconnects from the server.

This method takes one required argument, a Net::Gopher::Request object
encapsulating a Gopher or Gopher+ request. Some typical usage of request
objects in conjunction with this method is illustrated in the
L<Net::Gopher/SYNOPSIS|SYNOPSIS>. For a more detailed description, see
L<Net::Gopher::Request>.

If you never specified the I<Port> parameter for your request object (and never
set it later on with the C<port()>), then the default IANA designated port of
70 will be used when connecting to the server. If you didn't specify the
I<ItemType> parameter for Gopher or GopherPlus type requests (and never set it
using C<item_type()>), then '1', Gopher menu type, will be assumed.

In addition to the request object, this method takes two optional named
parameters:

The first named parameter, I<File>, specifies an output filename. When
specified, Net::Gopher will output the content of the response to this file,
overwriting anything in the file.

The second named parameter, I<Callback>, is a reference to a subroutine that
will be called as the response is collected, with the portion of the content
sent as the first argument to the callback routine.

=cut

sub request
{
	my $self    = shift;
	my $request = shift;

	croak "A Net::Gopher::Request object was not supplied"
		unless ($request and ref $request eq 'Net::Gopher::Request');

	my ($file, $callback) = check_params(['File', 'Callback'], @_);





	# Before we can send the requet, we need to connect to the Gopher
	# server.
	# 
	# At the very least, we need a hostname:
	croak "No hostname specified" unless (defined $request->host);

	# default to IANA designated Gopher port:
	my $port = $request->port || 70;

	# try connect to the Gopher server and store the IO::Socket socket in
	# our Net::Gopher object:
	$self->{'socket'} = new IO::Socket::INET (
		PeerAddr => $request->host,
		PeerPort => $port,
		Timeout  => $self->timeout,
		Proto    => 'tcp',
		Type     => SOCK_STREAM
	) or return new Net::Gopher::Response (
		Error => "Couldn't connect to " . $request->host .
		         " at port ${port}: $@"
	);

	# If you know when blocking/non-blocking socket support was added to
	# IO::Socket, please email me:
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
		'Connected to ', $request->host, ', ',
		inet_ntoa($self->{'socket'}->peeraddr),
		" at port $port."
	);

	# now initialize the IO::Select object for our new socket:
	$self->{'select'} = new IO::Select ($self->_socket);





	# default to Gopher menu item type:
	$request->item_type(1) unless (defined $request->item_type);

	# is this a Gopher+ request?
	my $is_gopher_plus = 1
		if ($request->request_type eq 'GopherPlus'
			or $request->request_type eq 'ItemAttribute'
			or $request->request_type eq 'DirectoryAttribute)');

	# send the request to the server:
	$self->_write($request->as_string);

	# show the request we just sent for debugging:
	$self->_debug_print("Sent this request:\n", $request->as_string);





	# the Net::Gopher::Response object:
	my $response;

	# empty the socket buffer and all of the data that was read from
	# the socket during any previous request:
	$self->_empty;

	# if we sent a Gopher+ request or item/directory attribute information
	# request, we need to get the status line (the first line) of the
	# response:
	if ($is_gopher_plus
		and my $status_line = $self->_get_status_line($callback))
	{
		# show the status line for debugging:
		$self->_debug_print("Got this status line:\n$status_line");

		# get the status (+ or -) and the length of the response
		# (either -1, -2, or the number of bytes):
		my ($status, $response_length) = $status_line =~ /^(.)(\-?\d+)/;

		# this will store the content of the response, everything after
		# the status line:
		my $content = '';

		# (Read the documentation below for _get_status_line().) Any
		# characters remaining in the buffer after calling the
		# _get_status_line() method are content:
		$content .= $self->_buffer if (length $self->_buffer);

		if ($response_length < 0)
		{
			# A length of -1 or -2 means the server is going to
			# send a series of bytes, which may (-1) or may not (-2)
			# be terminated by a period on a line by itself, and
			# then close the connection. So we'll read the server's
			# response as a series of buffers using _read(), and
			# add each buffer to the response content:
			while ($self->_read($callback))
			{
				$content .= $self->_buffer;
			}

			# exit if we ran into any errors while receiving the
			# response:
			return new Net::Gopher::Response(Error => $self->_error)
				if ($self->_error);
		}
		else
		{
			# a length other than -1 or -2 is the total length of
			# the response content in bytes:
			while ((my $bytes_remaining =
				$response_length - length $content))
			{
				# fill the buffer if it's empty:
				unless (length $self->_buffer)
				{ 
					my $bytes_read = $self->_read($callback);

					# break if we read everything and the
					# server's closed the connction or if
					# we ran into any errors getting the
					# last buffer:
					last unless ($bytes_read);
				}

				# try to read all of the remaining bytes of the
				# server's response from the buffer and add
				# them to the response content:
				$content .=
				substr($self->{'buffer'}, 0, $bytes_remaining, '');
			}

			# exit if we ran into any errors while receiving the
			# response:
			return new Net::Gopher::Response(Error => $self->_error)
				if ($self->_error);
		}

		# show the length of the response we got for debugging:
		$self->_debug_end(
			length($self->_data_read),
			' bytes (total) in response, with ',
			length($content), ' bytes of content.'
		);

		# If we've gotten this far, then we didn't encounter any
		# network errors. However, there may still have been errors on
		# the server side, like if the item we selected did not exist,
		# in which case the content if the response contains the error
		# code (number) followed by a description of the error (e.g.,
		# "1 Item is not available."):
		my $error = ($status eq '-') ? $content : undef;

		# Create the Net::Gopher::Response object for the Gopher+
		# response. 
		$response = new Net::Gopher::Response (
			Error      => $error,
			Request    => $request,
			Response   => $self->_data_read,
			StatusLine => $status_line,
			Status     => $status,
			Content    => $content
		);

		# if the response length was -1, then the response was
		# terminated by a period on a line by itself, which means we
		# need to unescape escaped periods, remove everything after the
		# terminating period on a line by itself, and remove the period
		# on a line by itself too for items other than text files,
		# text/plain formatted items, or menus:
		if ($response_length == -1)
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
			# if we got here, then either we couldn't get the status
			# line of the response or got the first line but it
			# wasn't in the proper format (wasn't a status line)
			# or we ran into an error:
			return $self->_error if ($self->_error);
		}

		# the content of the response:
		my $content = '';

		# now, read the server's response as a series of buffers,
		# storing each buffer one at a time in
		# $self->{'buffer'}:
		while ($self->_read($callback))
		{
			$content .= $self->_buffer;
		}
	
		# exit if we ran into any errors receiving the response:
		return new Net::Gopher::Response (Error => $self->_error)
			if ($self->_error);

		# show the length of the response we got for debugging:
		$self->_debug_end(
			length($self->_data_read),
			' bytes (total) in response, with ',
			length($content), ' bytes of content.'
		);



		# now create the response object:
		$response = new Net::Gopher::Response (
			Request  => $request,
			Response => $self->_data_read,
			Content  => $content
		);

		# In Gopher, with item types 5 and 9 the server sends a series
		# of bytes and then closes the connection. With all other
		# types, it sends a block of text terminated by a period on a
		# line by itself, in which case we need to unescape escaped
		# periods, remove everything after the terminating period on a
		# line by itself and remove the period on a line by itself too
		# for items other than text files and menus:
		if ($request->item_type ne '5' and $request->item_type ne '9'
			and $response->is_terminated)
		{
			$response->_clean_period_termination;
		}
	}

	# if the item is a text item, we need convert the CRLF and CR line
	# endings to LF, that way the user can use \n in regexes to match
	# newlines in the content (again, see <perldoc -f binmode>):
	if ($response->is_text)
	{
		$response->_convert_newlines;
	}

	# disconnect from the server:
	$self->{'socket'}->shutdown(2);

	# output the content of the response to the file the user specified:
	if ($file)
	{
		local *FILE;
		open(FILE, ">$file") || croak "Couldn't open file ($file): $!";

		# binmode it unless it's text:
		unless ($response->is_text)
		{
			binmode FILE;
		}
	
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
L<new()|Net::Gopher::Request/new($type, [%args | \%args | $url])> for a
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
L<new()|Net::Gopher::Request/new($type, [%args | \%args | $url])> for a
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

=head2 item(%args | \%args)

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
L<new()|Net::Gopher::Request/new($type, [%args | \%args | $url])> for a
complete list of named parameters you can supply for Gopher+ item attribute
information request types.

=cut

sub item
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('ItemAttribute', @_)
	);
}





#==============================================================================#

=head2 directory(%args | \%args)

This method is shortcut around the C<request()>/B<Net::Gopher::Request> object
combination. This:

 $ng->directory(
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
L<new()|Net::Gopher::Request/new($type, [%args | \%args | $url])> for a
complete list of named parameters you can supply for Gopher+ directory
attribute information request types.

=cut

sub directory
{
	my $self = shift;

	return $self->request(
		new Net::Gopher::Request ('DirectoryAttribute', @_)
	);
}





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





################################################################################
# 
# The following methods are accessor methods. Each one is get/set:
# 



#==============================================================================#

=head2 buffer_size([$size])

This is a get/set method that enables you to change the buffer sized used. (The
default is 1024.)

=cut

sub buffer_size
{
	my $self = shift;
	my $size = shift;

	if (defined $size)
	{
		$self->{'buffer_size'} = $size;
	}
	else
	{
		return $self->{'buffer_size'};
	}
}





=head2 timeout([$seconds])

This is a get/set method that enables you to change the number of seconds at
which a timeout will occur while trying to connect, read, write, etc. to a
server. If you don't supply a new number of seconds, then this method will
return the current number.

=cut

sub timeout
{
	my $self    = shift;
	my $timeout = shift;

	if (defined $timeout)
	{
		$self->{'timeout'} = $timeout ? 1 : 0;
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
	my $self  = shift;
	my $debug = shift;

	if (defined $debug)
	{
		$self->{'debug'} = $debug ? 1 : 0;
	}
	else
	{
		return $self->{'debug'};
	}
}





sub _error
{
	my $self  = shift;
	my $error = shift;

	if (defined $error)
	{
		$self->{'error'} = $error;
		return;
	}
	else
	{
		return $self->{'error'};
	}
}





################################################################################
# 
# The following methods are private accessor methods. They are 'get' only:
#



################################################################################

sub _socket
{
	return shift->{'socket'};
}



################################################################################

sub _select
{
	return shift->{'select'};
}



################################################################################

sub _buffer
{
	return shift->{'buffer'};
}



################################################################################

sub _data_read
{
	return shift->{'data_read'};
}





################################################################################
# 
# The following subroutines are private methods:
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
		print '#' x 79, "\n",
		      @_,
		      "\n", '-' x 79, "\n";
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
		print @_,
		      "\n", '-' x 79, "\n";
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
		print "\n",
		      @_,
		      "\n", '#' x 79, "\n\n";
	}
}





################################################################################
#
#	Method
#		_read($callback)
#
#	Purpose
#		This method reads from the socket stored in $self->_socket for
#		one $self->buffer_size length and stores the result in
#		$self->_buffer.	If successful, the number of bytes read is
#		returned and the callback (if supplied) is executed with what
#		was just read sent as its only argument. If not, call
#		$self->_error to find out why. This method also prepends
#		$self->_buffer to $self->_data_read.
#
#	Parameters
#		$callback - A reference to a subroutine.
#

sub _read
{
	my $self     = shift;
	my $callback = shift;

	# first, make sure we can read from the socket:
	return $self->_error("Can't read response from server")
		unless ($self->_select->can_read($self->timeout));

	# read part of the response from the socket into the buffer:
	my $num_bytes_read = sysread(
		$self->_socket,
		$self->{'buffer'},
		$self->buffer_size
	);

	# make sure something was received:
	unless (defined $num_bytes_read)
	{
		return $self->_error("No response received: $!");
	}

	# add the buffer to data_read, which will store every single byte
	# read from the socket:
	$self->{'data_read'} .= $self->_buffer;

	# execute the callback:
	if (defined $callback and ref $callback eq 'CODE')
	{
		$callback->($self->_buffer);
	}

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
#		then call $self->_error to find out why.
#
#	Parameters
#		$data - A string to send to the server.
#

sub _write
{
	my $self = shift;
	my $data = shift;



	# make sure we can write to the socket:
	return $self->_error("Can't send request")
		unless ($self->_select->can_write($self->timeout));

	# now send the request to the Gopher server:
	my $num_bytes_written =
		syswrite($self->_socket, $data, length $data);

	# make sure *something* was sent:
	return $self->_error("Nothing was sent: $!")
		unless (defined $num_bytes_written);

	# make sure the entire request was sent:
	return $self->_error("Couldn't send entire request: $!")
		unless (length $data == $num_bytes_written);

	return $num_bytes_written;
}





################################################################################
#
#	Method
#		_empty()
#
#	Purpose
#		This method empties the socket buffer ($self->_buffer) and all
#		of the data that's been read from the socket
#		($self->_data_read).
#
#	Parameters
#		None.
#

sub _empty
{
	my $self = shift;

	$self->{'buffer'}    = undef;
	$self->{'data_read'} = undef;
}





################################################################################
#
#	Method
#		_get_status_line($callback)
#
#	Purpose
#		This method fills the buffer stored in $self->{'buffer'}
#		(using _read()) and removes character after character
#		from the the buffer looking for the the newline, refilling
#		the buffer if it gets empty. Once it finds the newline, it
#		checks to make sure the line is in the format of a Gopher+
#		status line. If the line is a status line, this method will
#		return it. Otherwise, this method will return undef (call
#		_error() to find out why).
#
#	Parameters
#		$callback - (Optional.) A reference to a subroutine. This
#		            method will pass this on to _read().
#

sub _get_status_line
{
	my $self     = shift;
	my $callback = shift;

	# To get the status line (the first line), we'll use the _read()
	# method to read and store a buffer in $self->{'buffer'}, then
	# remove character after character from the beginning of the buffer and
	# add them to $first_line, checking for the CRLF in $first_line. If
	# we end up removing everything from the buffer, then we refill it. If
	# we can't refill it, then that means we read everything and the server
	# has closed the connection and that the server is not a Gopher+
	# server.

	my $first_line;    # everything up till the first CRLF in the response.
	my $found_newline; # did we find the newline?

	FIRSTLINE: while ($self->_read($callback))
	{
		while (length $self->{'buffer'})
		{
			# grab a single character from the buffer:
			$first_line .= substr($self->{'buffer'},0,1,'');

			# now, look (starting at the end) for the CRLF:
			if (index($first_line, $CRLF, -1) > 0)
			{
				$found_newline = 1;
				last FIRSTLINE;
			}
		}
	}
	
	# exit if we ran into any errors:
	return if ($self->_error);



	# if we found the newline and the first character contains
	# the status (+ or -) followed by a positive or negative number,
	# then the response is a Gopher+ response:
	if ($found_newline and $first_line =~ /^[\+\-] (?:\-[12]|\d+) $CRLF/x)
	{
		return $first_line;
	}
	else
	{
		return;
	}
}

1;

__END__

=head1 BUGS

If you encounter bugs, you can alert me of them by emailing me at
<william_g_davis at users dot sourceforge dot net> or, if you have PerlMonks
account, you can go to perlmonks.org and /msg me (William G. Davis).

=head1 SEE ALSO

Net::Gopher::Request, Net::Gopher::Response

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
