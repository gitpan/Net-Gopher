package Net::Gopher;

=head1 NAME

Net::Gopher - The Perl Gopher/Gopher+ client API. 

=head1 SYNOPSIS

 use Net::Gopher;
 
 my $gopher = new Net::Gopher;
 
 # connect to a gopher server:
 $gopher->connect($host, Port => $port, Timeout => $timeout)
 	or die $gopher->error;
 
 # request something from the server:
 my $response = $gopher->request('/menu', Type => 1);
 
 # check for errors:
 if ($response->is_success)
 {
 	# get each item on the menu:
 	my @items = $response->as_menu;
 	print $item[0]->{'type'}, $item[0]->{'text'};
 }
 else
 {
	 print $response->error;
 }
 
 # disconnect from the server:
 $gopher->disconnect;
 
 # or, if you have a (even partial) URL, you can do it this way:
 $repsonse = $gopher->request_url($url) or die $gopher->error;
 
 # make sure what we got was terminated by a period on a line by itself:
 die "Not terminated by a period on a line by itself."
 	unless ($response->is_terminated);
 
 # get an arrayref containing all items listed on a menu:
 my $menu = $response->as_menu;
 print "Type: ", $menu->[0]{'type'}, ";\n",
       "Description: ", $menu->[0]{'text'}, ";\n",
       "On: ", $menu->[0]{'host'}, ";\n";
 
 # or just get the entire response as a string:
 my $string = $response->as_string;
 ...

=head1 DESCRIPTION

Net::Gopher is a Gopher/Gopher+ client API for Perl. Net::Gopher implements the
Gopher and Gopher+ protocols as desbribed in
I<RFC 1436: The Internet Gopher Protocol>, Anklesaria et al., and in
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol>,
Anklesaria et al., bringing Gopher and Gopher+ support to Perl and enabling
Perl 5 applications to easily interact with both Gopher as well as Gopher+
servers.

=head1 METHODS

The following methods are available:

=over 4

=cut

use 5.005;
use strict;
use warnings;
use vars qw($VERSION);
use Carp;
use IO::Select;
use IO::Socket;
use URI;
use Net::Gopher::Response;
use Net::Gopher::Utility qw(
	$CRLF $NEWLINE %GOPHER_ITEM_TYPES %GOPHER_PLUS_ITEM_TYPES
);

$VERSION = '0.20';





=item new()

The constructor method. Returns a reference to a Net::Gopher response.

=cut

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my $self = {
		# IO::Socket::INET socket:
		io_socket     => undef,

		# IO::Select object for the socket stored in io_socket:
		io_select     => undef,

		# every single byte read from the socket:
		socket_data   => undef,

		# we'll read from the socket in a series buffer. Each buffer
		# is stored here before getting added to socket_data:
		socket_buffer => undef,

		# the size of socket_buffer:
		buffer_size   => 1024,

		# the number of seconds before a timeout occurs (when
		# connecting, etc.):
		timeout       => undef,

		# support Gopher+?
		gopher_plus   => 1,

		# stores an error message to be retreived by the user with
		# the error() method:
		error         => undef

		
	};

	bless($self, $class);
	return $self;
}





#==============================================================================#

=item connect($host [, Port => $port_num, Timeout => $seconds])

This method attempts to connect to a Gopher server. If it's successful it
returns true; false otherwise (call L<error()> to find out why). As its first
argument it takes a mandatory hostname (e.g., gopher.host.com). As its second
argument, 'Port', it takes an optional port number. If you don't supply 'Port'
then the default of 70 will be used instead. As its final argument, 'Timeout',
it takes the number of second at which a timeout will occur when attempting to
connect to a Gopher server. If you don't supply 'Timeout' then the default of
60 seconds will be used instead.

=cut

sub connect
{
	my $self  = shift;
	my $host  = (scalar @_ % 2) ? shift : undef;
	my %args  = @_;

	# I eventually hope to have this class work like the other Net::*
	# modules, looking for hostnames in libnet.cfg:
	# 
	# my @hosts = defined $host
	# 		? $host
	# 		: @{ $Net::Config::NetConfig{gopher_hosts} };
	# 
	# $host = shift @hosts unless (defined $host);



	# we at least need a hostname:
	return $self->error("No hostname specified for connect()")
		unless (defined $host);

	# default to IANA designated Gopher port:
	my $port    = $args{'Port'} || 70;

	# default to a 60 second timeout:
	my $timeout = $args{'Timeout'} || 60;

	# connect to the Gopher server and store the IO::Socket socket in our
	# Net::Gopher object:
	$self->{'io_socket'} = new IO::Socket::INET (
		PeerAddr => $host,
		PeerPort => $port,
		Timeout  => $timeout,
		Proto    => 'tcp',
		Type     => SOCK_STREAM
	) or return $self->error(
		"Couldn't connect to $host at port ${port}: $@"
	);

	# we'll need the timeout value for later:
	$self->{'timeout'} = $timeout;

	# now initialize the IO::Select object for our new socket:
	$self->{'io_select'} = new IO::Select ($self->{'io_socket'});
}





#==============================================================================#

=item request($selector [, Representation => $rep, DataBlock => $data [, Type => $type]])

This method sends a request to the Gopher/Gopher+ server you've connected to
(L<connect()>) and returns a Net::Gopher::Response object for the server's
response. The first argument is the selector string to send to the server. This
method also takes three optional Name=value pair arguments. The first two,
Representation and DataBlock, are for Gopher+ and enable you to send data to a
Gopher+ server. The third, Type, isn't needed for communicating with either
Gopher or Gopher+ servers, however, with Gopher servers it helps request()
tell how exactly it should receive the response from the server. Also note that
if you supply the Representation or DataBlock arguments, then you're selector
doesn't have to contain a tab followed by a plus; Net::Gopher will see the the
Representation and or DataBlock options and realize this is a Gopher+ request
and will add the tab and plus for you. 

=cut

sub request
{
	my $self     = shift;
	my $selector = shift;
	my %args     = @_;



	# remove the trailing newline from the selector:
	$selector = '' unless (defined $selector);
	$selector =~ s/$NEWLINE$//;

	# $request_type stores the type of request we're going to send (either
	# 1 for Gopher request, 2 for Gopher+ request, or 3 for Gopher+ item
	# attribute information request):
	my $request_type;
	if (defined $args{'Representation'} || defined $args{'DataBlock'})
	{
		# if there's a data block or representation then this is a a
		# Gopher+ request, which means we need to add the trailing tab
		# and + to the selector if the user hasn't done so:
		$request_type = 2;
		$selector    .= "\t+" unless ($selector =~ /\t\+$/);
	}
	elsif ($selector =~ /\t\+$/)
	{
		# if the selector has a tab and + at the end of it, then it's a
		# Gopher+ selector:
		$request_type = 2;
	}
	elsif ($selector =~ /\t\!$/)
	{
		# if the selector has a tab and ! at the end of it, then it's a
		# Gopher+ item attribute information request:
		$request_type = 3;
	}
	else
	{
		# default to Gopher request:
		$request_type = 1;
	}

	# even if it's a Gopher+ request, we won't act like a Gopher+ client
	# if the user has told us not to:
	$request_type = 1 unless ($self->{'gopher_plus'});



	# now we need to build our request:
	my $request = '';
	if ($request_type == 2)
	{
		$request .= $selector;
		$request .= $args{'Representation'}
			if (defined $args{'Representation'});

		if (defined $args{'DataBlock'})
		{
			# add the data flag to indecate the presence of the
			# data block:
			$request .= "\t1";

			# add the data block:
			$request .= $CRLF;
			$request .= $args{'DataBlock'};
		}
		else
		{
			# add a newline to the request:
			$request .= $CRLF unless ($request =~ /$NEWLINE$/);
		}
	}
	else
	{
		$request .= $selector;

		# add a newline to the selector string:
		$request .= $CRLF unless ($request =~ /$NEWLINE$/);
	}





	# create our Net::Gopher::Response object for the response:
	my $ngr = new Net::Gopher::Response;

	# make sure we can write to the socket:
	return $ngr->error("Can't send request: $@")
		unless ($self->{'io_select'}->can_write($self->{'timeout'}));

	# now, send the request to the Gopher server:
	my $num_bytes_writen =
		syswrite($self->{'io_socket'}, $request, length $request);

	# make sure *something* was sent:
	return $ngr->error("Nothing was sent: $!")
		unless (defined $num_bytes_writen);

	# make sure all the bytes were sent:
	return $ngr->error("Couldn't send entire request: $!")
		unless (length $request == $num_bytes_writen);





	# Now we need to get the server's response. First, make sure we can
	# read the socket:
	return $ngr->error("Can't read response from socket: $@")
		unless ($self->{'io_select'}->can_read($self->{'timeout'}));

	# Find out if we need to read until we see a period on a line
	# by itself or if we should read until the server closes the
	# connection. (For Gopher only, not Gopher+; in Gopher+ a length of
	# -1 tells us to read until we see a period on a line by itself):
	my $read_until_period;
	if (exists $args{'Type'})
	{
		# with types 5 and 9 we read until the server closes
		# the connection, all others we read until we see the period:
		my @item_types =
		grep {$_ ne 9 and $_ ne 5} keys %GOPHER_ITEM_TYPES;

		foreach (@item_types)
		{
			if ($args{'Type'} eq $_)
			{
				$read_until_period = 1;
				last;
			}
		}
	}





	if ($request_type > 1)
	{
		# Since we sent a Gopher+ request or item attribute information
		# request, we need to get the first line (the status line) of
		# the response and the status of the response (success or
		# failure, + or -), and the total length of the content of the
		# response (if the server knows and is telling) or weither or
		# not to read until we see a period on a line by itself or
		# weither to read until the server closes the connection.

		# To get the first line, we'll use the _get_buffer() method to
		# read and store a buffer in $self->{'socket_buffer'}, then
		# remove character after character from the beginning of the
		# buffer and add them to $first_line, then check for the CRLF
		# in $first_line. If we end up removing everything from the
		# buffer, then we refill it. If we can't refill it, then that
		# means we read everything and the server has closed the
		# connection and that the server is not a Gopher+ server.

		my $first_line;      # the first line of the response.

		my $found_newline;   # did we find the newline?

		my $read_everything; # did we read everything and not find
		                     # the newline?

		my $response_error;  # any errors while reading the buffer.

		FIRSTLINE: while (1)
		{
			# fill the buffer:
			$self->_get_buffer(\$response_error);

			# exit if we ran into any errors:
			return $ngr->error($response_error)
				if ($response_error);

			# if the buffer has nothing in it even after calling
			# _get_buffer(), then we're read everything and the
			# server has closed the connection:
			unless (length $self->{'socket_buffer'})
			{
				# we read everything, break out:
				$read_everything = 1;
				last;
			}

			while (length $self->{'socket_buffer'})
			{
				# add another character to the first line
				# from the buffer:
				$first_line .= substr(
					$self->{'socket_buffer'}, 0, 1, ''
				);

				# ok, check for the CRLF:
				if (index($first_line, $CRLF, -1) > 0)
				{
					$found_newline = 1;
					last FIRSTLINE;
				}
			}
		}



		# if we found the newline and the first character contains
		# the status (+ or -) followed by a postive or negative number,
		# then the response is a Gopher+ response:
		if ($found_newline
			and $first_line =~ /^( (\+|\-) (\-\d|\d+) $CRLF)/x)
		{
			# get the status line, status (+ or -), and length:
			my $status_line    = $1;
			my $status         = $2;
			my $content_length = $3;

			# add the status line and status code to our
			# Net::Gopher::Response object:
			$ngr->{'status_line'} = $status_line;
			$ngr->{'status'}      = $status;

			# the request content is everything after the
			# status line:
			my $content;

			# anything remaining in the buffer after the newline
			# that we removed is content:
			$content .= $self->{'socket_buffer'}
				if (length $self->{'socket_buffer'});

			if ($content_length == -1)
			{
				# a length of -1 means we should read until
				# we see a period on a line by itself:
				while ($self->_get_buffer(\$response_error))
				{
					# exit if we ran into any errors
					# getting the last buffer:
					return $ngr->error($response_error)
						if $ngr->error($response_error);

					# the buffer contains content:
					$content .= $self->{'socket_buffer'};
				}

				# now, remove everything after the period on a
				# line by itself:
				$content =~
				s/($NEWLINE[.]) (?: \z|$NEWLINE .*)/$1/xs;
			}
			elsif ($content_length == -2)
			{
				# a length or -2 means we read until the server
				# closes the connection:
				while ($self->_get_buffer(\$response_error))
				{
					# exit if we ran into any errors
					# getting the last buffer:
					return $ngr->error($response_error)
						if $ngr->error($response_error);

					# the buffer contains content:
					$content .= $self->{'socket_buffer'};
				}
			}
			else
			{
				# a length other than -1 or -2 is the total
				# length of the response content:
				while (1)
				{
					# refill the buffer:
					$self->_get_buffer(\$response_error);

					# exit if we ran into any errors while
					# refilling the buffer:
					return $ngr->error($response_error)
						if ($response_error);

					while (length $content < $content_length
						and length $self->{'socket_buffer'})
					{
						$content .= substr($self->{'socket_buffer'}, 0, 1, '');
					}
				}
			}

			# now add the entire response and just the content of
			# the response to the Net::Gopher::Response object:
			$ngr->{'response'} = $self->{'socket_data'};
			$ngr->{'content'}  = $content;

			# The Gopher+ response may have been an error. In which
			# case the content contains an error code (number)
			# followed by a description of the error (e.g., "1 Item
			# is not available."):
			if ($status eq '-')
			{
				$ngr->error($content);
			}
		}
		else
		{
			# Alright, if we couldn't find the newline or if we
			# could find it but the line wasn't a Gopher+
			# status line, then even though the request was a
			# Gopher+ request, the server wasn't a Gopher+ server.
			# So read the rest of the response and store everything
			# in the Net::Gopher::Response object like we would for
			# a normal Gopher response:
			$self->_get_response($ngr, $read_until_period);
		}
	}
	else
	{
		# If we got here then this is a plain old Gopher request, not a
		# Gopher+ request. Get the response from the Gopher server and
		# store it in the Net::Gopher::Response object:
		$self->_get_response($ngr, $read_until_period);

		
	}

	return $ngr;
}





################################################################################
#
#	Method
#		_get_response($response, $til_period)
#
#	Purpose
#		This method receives the response from a Gopher server, either
#		reading until the server closes the connection or until it sees
#		a period on a line on itself and stores the entire response and
#		any errors encountered in theNet::Gopher::Object you specify.
#		This method returns the modified Net::Gopher::Response object.
#
#	Parameters
#		$response   - A Net::Gopher::Response object where the response
#		              will be stored.
#		$til_period - (Boolean.) Should _get_response() read
#		              until it sees a period on a line by itself?
#

sub _get_response
{
	my $self              = shift;
	my $ngr               = shift;
	my $read_until_period = shift;

	# now, fill up $self->{'socket_data'}:
	my $response_error;
	while ($self->_get_buffer(\$response_error))
	{
		# exit if we ran into any errors getting the last buffer:
		return $ngr->error($response_error)
			if ($ngr->error($response_error));
	}

	my $response;
	if ($read_until_period)
	{
		$response =  $self->{'socket_data'};

		# remove everything after the period on a line by itself:
		$response =~ s/($NEWLINE[.]) (?: \z|$NEWLINE .*)/$1/xs;
	}
	else
	{
		$response = $self->{'socket_data'};
	}

	# Now store the response in the Net::Gopher::Response object. We store
	# the response in both $ngr->{'response'} and $ngr->{'content'} so
	# the content() and as_string() methods return the same thing since
	# this is a non-Gopher+ response:
	$ngr->{'response'} = $response;
	$ngr->{'content'}  = $response;

	return $ngr;
}





################################################################################
#
#	Method
#		_get_buffer($error)
#
#	Purpose
#		This method reads the socket stored in $self->{'io_socket'}
#		for one $self->{'buffer_size'} length and stores the data in
#		$self->{'socket_buffer'} and stores any error it encounters in
#		the variable you specifiy. It also copies the buffer into
#		$self->{'socket_data'}. This method returns either the number of
#		bytes read into $self->{'socket_buffer'} or undef if an error
#		occurred.
#
#	Parameters
#		$error - A reference to a scalar: _get_buffer() will store any
#		         error encountered while receiving the response in this
#		         variable.
#

sub _get_buffer
{
	my $self      = shift;
	my $error_var = shift;

	# read part of the response into the buffer:
	my $num_bytes_read = sysread(
		$self->{'io_socket'},
		$self->{'socket_buffer'},
		$self->{'buffer_size'}
	);

	# make sure something was received:
	unless (defined $num_bytes_read)
	{
		$$error_var = "No response received: $!";
		return;
	}

	# copy the buffer to socket_data:
	$self->{'socket_data'} .= $self->{'socket_buffer'};

	return $num_bytes_read;
};





#==============================================================================#

=item disconnect()

Call this method to disconnect from the Gopher server after requesting
something from it. Not really necessary since the Gopher server will usually
close the connection first.

=cut

sub disconnect
{
	my $self = shift;

	if (ref $self->{'io_socket'})
	{
		$self->{'io_socket'}->shutdown(2);
	}
}





#==============================================================================#

=item request_url($url)

This method allows you to bypass the connect(), request(), and disconnect()
methods. If you have a gopher URL you can simply supply it to this method
and it will connect to the server and request it for you. It will return
a Net::Gopher::Response object just like request() does.

=cut

sub request_url
{
	my $self = shift;
	my $url  = shift;

	# add a scheme if one isn't there yet:
	$url = 'gohper://' . $url unless ($url =~ m/^[a-z0-9]+:\/\//);

	
	$url = new URI $url;
	$url->scheme;

	# make sure the URL's scheme isn't something other than gopher:
	return $self->error('Protocol "' . $url->scheme . '" is not supported')
		unless ($url->scheme eq 'gopher');

	# update the URL:
	$url->scheme('gopher');
	$url->canonical;

	# grab the item type, selector, host, port, Gopher+ string, and any 
	# search words:
	my $item_type    = $url->gopher_type;
	my $selector     = $url->selector;
	my $host         = $url->host;
	my $port         = $url->port;
	my $gopher_plus  = $url->string;
	my $search_words = $url->search;



	# now build the request string:
	my $request_string  = $selector;
	   $request_string .= "\t" . $search_words if (defined $search_words);
	   $request_string .= "\t" . $gopher_plus  if (defined $gopher_plus);

	# connect to the Gopher server:
	$self->connect($host, Port => $port);

	# issue the request:
	my $ngr = $self->request($request_string, Type => $item_type);

	# disconnect from the server:
	$self->disconnect;

	return $ngr;
}





#==============================================================================#

=item gopher_plus($boolean)

This is a get/set method that enables you to turn on or turn off support for
Gopher+ (default is on). Just supply a true value for on or a false value for
off.

=cut

sub gopher_plus
{
	my $self      = shift;
	my $supported = shift;

	if (defined $supported)
	{
		$self->{'gopher_plus'} = $supported ? 1 : 0;
	}
	else
	{
		return $self->{'gopher_plus'};
	}
}





#==============================================================================#

=item buffer_size($size)

This is a get/set method that enables you to change the buffer sized used. (The
default is 1024).

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





#==============================================================================#

=item error()

This method returns a string containing an error message or undef if no error
has occurred.

=cut


sub error
{
	my $self  = shift;
	my $error = shift;

	if (defined $error)
	{
		# remove the socket class name from error messages (IO::Socket
		# puts them in):
		$error =~ s/IO::Socket::INET:\s//g;

		$self->{'error'} = $error;

		
		return;
	}
	else
	{
		return $self->{'error'};
	}
}





sub DESTROY
{
	my $self = shift;
	   $self->disconnect;
}

1;

__END__

=back

=head1 BUGS

Email any to me at <william_g_davis at users dot sourceforge dot net> or go
to perlmonks.com and /msg me (William G. Davis) and I'll fix 'em.

=head1 SEE ALSO

Net::Gopher::Response

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
