
package Net::Gopher;

=head1 NAME

Net::Gopher - The Perl Gopher/Gopher+ client API 

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

$VERSION = '0.32';





#==============================================================================#

=head2 new()

The constructor method. Returns a reference to a Net::Gopher object.

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
		# connecting, trying to read, trying to write, etc.):
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

=head2 connect($host [, Port => $port_num, Timeout => $seconds])

This method attempts to connect to a Gopher server. If connect() is able to
connect it returns true; false otherwise (call error() to find out why). As
its first argument it takes a mandatory hostname (e.g., gopher.host.com). In
addition to the hostname, it takes two optional named paramters. The first,
Port, takes an optional port number. If you don't supply this then the default
of 70 will be used instead. The second, Timeout, takes the number of second at
which a timeout will occur when attempting to connect to a Gopher server. If
you don't supply this then the default of 60 seconds will be used instead.

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
	croak "No hostname specified for connect()"
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

=head2 request($selector [, Representation => $mime_type, DataBlock => $data |, Attributes => $attributes] [, Type => $type])

This method sends a request to the Gopher/Gopher+ server you've connected to
(L<connect()>) and returns a Net::Gopher::Response object for the server's
response. The first argument is the selector string to send to the server. This
method also takes four optional named parameters. The first, Representation,
is used for Gopher+ requests to ask a Gopher+ server to return an item in a
specified format (MIME type):

 $gopher->request($selector,
 	Representation => 'text/plain'
 	Type           => $type
 );

The second named parameter, DataBlock, is for Gopher+ requests and enables you
to send data from a Gopher+ Ask form to a Gopher+ server. The third named
parameter, Attributes, is for Gopher+ item attribute information requests and
enables you to request only certain info blocks (e.g., "+INFO+ADMIN" to only
retrieve the INFO and ADMIN blocks). You can either specify each block name
for 'Attributes' in one big string:

 $gopher->request($selector,
 	Attributes => '+NAME+NAME2+NAME3',
 	Type       => $type
 );
 
or you can put them in an array ref:

 $gopher->request($selector,
 	Attributes => ['+NAME', '+NAME2', '+NAME3'],
 	Type       => $type
 );

Also note that when using the array ref format, you don't have to prefix each
block name with a plus; this method will do it for you if you don't. The fourth
named parameter, Type, isn't needed for communicating with either Gopher or
Gopher+ servers, however, with Gopher servers it helps request() tell how
exactly it should receive the response from the server. For Gopher+ requests,
while you'll usually need to add a trailing tab and plus to the selector
string, it's not always necessary; if either the Representation or DataBlock
parameters are defined, then this method will realize that this is a Gopher+
request and will add the trailing tab and plus to your selector string for you
if they are not already present. The same holds true for Gopher+ item attribute
information requests; if the Attributes parameter is defined then this method
will realize this is a Gopher+ item attribute information request and will add
the trailing tab and exclamation point to your selector string for you if there
isn't already either a tab and exclamation point or tab and dollar sign at the
end of your selector.

=cut

sub request
{
	my $self     = shift;
	my $selector = shift;
	my %args     = @_;


	# clear the socket buffer and all of the socket data that's been read:
	$self->{'socket_buffer'} = undef;
	$self->{'socket_data'}   = undef;

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
	elsif (defined $args{'Attributes'})
	{
		# if there are attributes then this is a Gopher+ item attribute
		# information request, which means we need to add the trailing
		# tab and ! to the selector if there isn't one or if there
		# isn't a trailing tab and $:
		$request_type = 3;
		$selector    .= "\t!" unless ($selector =~ /\t(?:\!|\$)$/);
	}
	elsif ($selector =~ /\t(?:\!|\$)$/)
	{
		# if the selector has a tab and ! at the end of it or a tab and
		# a $ at the end of it, then it's a Gopher+ item attribute
		# information request:
		$request_type = 3;
	}
	else
	{
		# default to Gopher request:
		$request_type = 1;
	}

	# even if it's a Gopher+ request we won't act like a Gopher+ client
	# if the user has told us not to:
	$request_type = 1 unless ($self->{'gopher_plus'});



	# the request string to send to the server:
	my $request = '';

	if ($request_type == 2)
	{
		$request .= $selector;
		$request .= $args{'Representation'}
			if (defined $args{'Representation'});

		if (defined $args{'DataBlock'})
		{
			# add the data flag to indicate the presence of the
			# data block:
			$request .= "\t1";

			# add the data block:
			$request .= $CRLF;
			$request .= $args{'DataBlock'};
		}
		else
		{
			# add a newline to terminate request:
			$request .= $CRLF unless ($request =~ /$NEWLINE$/);
		}
	}
	elsif ($request_type == 3)
	{
		$request .= $selector;

		if (defined $args{'Attributes'})
		{
			# the block names can be sent as either one big string
			# or as an array of strings:
			if (ref $args{'Attributes'})
			{
				foreach my $name (@{$args{'Attributes'}})
				{
					# add the leading plus if isn't already
					# there then add this block name to
					# the item attribute information
					# request:
					$name = "+$name" unless ($name=~/^\+/);
					$request .= $name;
				}
			}
			else
			{
				$request .= $args{'Attributes'};
			}
		}
		
		# add a newline to terminate the item attribute information
		# request:
		$request .= $CRLF unless ($request =~ /$NEWLINE$/);
	}
	else
	{
		$request .= $selector;
		$request .= $CRLF unless ($request =~ /$NEWLINE$/);
	}





	# make sure we can write to the socket:
	return new Net::Gopher::Response (Error => "Can't send request")
		unless ($self->{'io_select'}->can_write($self->{'timeout'}));

	# now, send the request to the Gopher server:
	my $num_bytes_writen =
		syswrite($self->{'io_socket'}, $request, length $request);

	# make sure *something* was sent:
	return new Net::Gopher::Response (Error => "Nothing was sent: $!")
		unless (defined $num_bytes_writen);

	# make sure all the bytes were sent:
	return new Net::Gopher::Response (
		Error => "Couldn't send entire request: $!"
	) unless (length $request == $num_bytes_writen);





	# Now we need to get the server's response. First, make sure we can
	# read the socket:
	return new Net::Gopher::Response (
		Error => "Can't read response from socket."
	) unless ($self->{'io_select'}->can_read($self->{'timeout'}));

	# this variable stores any errors encountered while receiving the
	# response:
	my $response_error;



	# if we sent a Gopher+ request or item attribute information request,
	# we need to get the first line (the status line) of the response:
	if ($request_type > 1
		and my $status_line = $self->_get_status_line(\$response_error))
	{
		# get the status (+ or -) and the length of the response
		# (either -1, -2, or the number of bytes):
		my ($status, $response_length) =
			$status_line =~ /^(.)(\-?\d+)/;

		# this will store the content of the response, everything after
		# the status line:
		my $content;

		# (Read the documentation below for _get_status_line().) Any
		# characters remaining in the buffer after calling the
		# _get_status_line() method are content:
		$content .= $self->{'socket_buffer'}
			if (length $self->{'socket_buffer'});

		if ($response_length < 0)
		{
			while ($self->_get_buffer(\$response_error))
			{
				# exit if we ran into any errors getting the
				# last buffer:
				return new Net::Gopher::Response (
					Error => $response_error
				) if ($response_error);

				$content .= $self->{'socket_buffer'};
			}

			if ($response_length == -1)
			{
				# A length of -1 means the response is
				# terminated by a period on a line by itself.
				# Remove anything after the period on a line by
				# itself:
				$content =~
				s/($NEWLINE[.]) (?: \z|$NEWLINE .*)/$1/xs;
			}
		}
		else
		{
			# a length other than -1 or -2 is the total length of
			# the response content in bytes:
			while (1)
			{
				# refill the buffer:
				$self->_get_buffer(\$response_error);

				# exit if we ran into any errors while
				# refilling the buffer:
				return new Net::Gopher::Response (
					Error => $response_error
				) if ($response_error);

				
				while (length $content < $response_length
					and length $self->{'socket_buffer'})
				{
					$content .= substr(
						$self->{'socket_buffer'},0,1,''
					);
				}
			}
		}

		if (exists $args{'Type'} and $args{'Type'} eq 1)
		{
			# For text files, lines that only contain periods are
			# escaped by adding another period. Those lines must be
			# shrunk:
			$content =~ s/($NEWLINE)..($NEWLINE)/$1.$2/;
		}
		
		
		# Now, time to create the Net::Gopher::Response object for the
		# Gopher+ response. If the response was an error, then the
		# content contains an error code (number) followed by a
		# description of the error (e.g., "1 Item is not available."):
		return new Net::Gopher::Response (
			Error      => ($status eq '-') ? $content : undef,
			Request    => $request,
			Response   => $self->{'socket_data'},
			StatusLine => $status_line,
			Status     => $status,
			Content    => $content
		);
	}
	else
	{
		# If we got here then this is a plain old Gopher request, not a
		# Gopher+ request.
		if ($request_type > 1)
		{
			# if we got here then either we couldn't get the status
			# line of the response, or got the first line but it
			# wasn't in the proper format; wasn't a status line,
			# or we ran into an error: 
			return new Net::Gopher::Response (
				Error => $response_error
			) if ($response_error);
		}

		# now, read the server's response as a series of buffers,
		# storing each buffer one at a time in $self->{'socket_buffer'}
		# and add each buffer to the end of $self->{'socket_data'}:
		while ($self->_get_buffer(\$response_error))
		{
			# exit if we ran into any errors getting the last
			# buffer:
			return new Net::Gopher::Response (
				Error => $response_error
			) if ($response_error);
		}

		# the content of the response:
		my $content = $self->{'socket_data'};

		# For Gopher, we need to find out if the server's response will
		# be terminatred by a perioid on a line by itself. With types 5
		# and 9, the server sends a series of bytes then closes the
		# connection. With all other types, it sends a block of text
		# terminated by a period on a line by itself:
		if (exists $args{'Type'}
			and $args{'Type'} ne 5 and $args{'Type'} ne 9)
		{
			if (exists $GOPHER_ITEM_TYPES{$args{'Type'}})
			{
				# remove everything after the period on a line
				# by itself:
				$content =~
				s/($NEWLINE[.]) (?: \z|$NEWLINE.*)/$1/xs;
			}

			if ($args{'Type'} eq 1)
			{
				# For text files, lines that only contain
				# periods are escaped by adding another
				# period. Those lines must be shrunk:
				$content =~ s/($NEWLINE)..($NEWLINE)/$1.$2/;
			}
		}

		return new Net::Gopher::Response (
			Request  => $request,
			Response => $self->{'socket_data'},
			Content  => $content
		);
	}
}





################################################################################
#
#	Method
#		_get_status_line($error)
#
#	Purpose
#		This method fills the buffer stored in $self->{'socket_buffer'}
#		(using _get_buffer()) and removes character after character
#		from the the buffer looking for the the newline, refilling
#		the buffer if it gets empty. Once it finds the newline, it
#		checks to make sure the line is in the format of a status line.
#		If the line is a status line, this method will return it.
#		Otherwise, this method will return undef.
#
#	Parameters
#		$error - A reference to a scalar; _get_status_line() will store
#		         any error encountered while looking for the status
#		         line.
#

sub _get_status_line
{
	my $self  = shift;
	my $error = shift;

	# To get the first line, the status line, we'll use the _get_buffer()
	# method to read and store a buffer in $self->{'socket_buffer'}, then
	# remove character after character from the beginning of the buffer and
	# add them to $first_line, then check for the CRLF in $first_line. If
	# we end up removing everything from the buffer, then we refill it. If
	# we can't refill it, then that means we read everything and the server
	# has closed the connection and that the server is not a Gopher+
	# server.

	my $first_line;    # the first line of the response.
	my $found_newline; # did we find the newline?

	FIRSTLINE: while ($self->_get_buffer($error))
	{
		# exit if we ran into any errors:
		return if ($$error);

		while (length $self->{'socket_buffer'})
		{
			# grab a single character from the buffer:
			$first_line .= substr(
				$self->{'socket_buffer'}, 0, 1, ''
			);

			# ok, look (starting at the end) for the CRLF:
			if (index($first_line, $CRLF, -1) > 0)
			{
				$found_newline = 1;
				last FIRSTLINE;
			}
		}
	}



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





################################################################################
#
#	Method
#		_get_buffer($error)
#
#	Purpose
#		This method reads the socket stored in $self->{'io_socket'}
#		for one $self->{'buffer_size'} length and stores the data in
#		$self->{'socket_buffer'} and stores any error it encounters in
#		the variable you specifiy. It also copies the buffer to the
#		end of $self->{'socket_data'}. This method returns either the
#		number of bytes read into $self->{'socket_buffer'} or undef if
#		an error occurred.
#
#	Parameters
#		$error - A reference to a scalar; _get_buffer() will store any
#		         error encountered while reading the buffer in this
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

	# add the buffer to socket_data, which will store every single byte
	# read from the socket:
	$self->{'socket_data'} .= $self->{'socket_buffer'};

	return $num_bytes_read;
}





#==============================================================================#

=head2 disconnect()

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

=head2 request_url($url)

This method allows you to bypass the connect(), request(), and disconnect()
methods. If you have a Gopher URL you can just supply it to this method and it
will connect to the server and request it for you. This method will return a
Net::Gopher::Response object just like request() does.

=cut

sub request_url
{
	my $self = shift;
	my $url  = shift;

	# We need to add a scheme if one isn't there yet. We have to do this
	# insead of just using URI's scheme() method cause that--for some
	# reason--just adds the scheme name plus colon to the beginning of
	# the URL if a scheme isn't already there (e.g., if you call
	# scheme("foo") on a URL like subdomain.domain.com, you end up with
	# foo:subdomain.domain.com, which is not what we want).
	$url = "gohper://$url" unless ($url =~ /^[a-zA-Z0-9]+?:\/\//);

	my $uri = new URI $url;

	# make sure the URL's scheme isn't something other than gopher:
	return $self->error('Protocol "' . $uri->scheme . '" is not supported')
		unless ($uri->scheme eq 'gopher');

	# set the scheme to gopher:
	$uri->scheme('gopher');

	# grab the item type, selector, host, port, any search words, and the
	# Gopher+ string:
	my $item_type    = $uri->gopher_type;
	my $selector     = $uri->selector;
	my $host         = $uri->host;
	my $port         = $uri->port;
	my $search_words = $uri->search;
	my $gopher_plus  = $uri->string;

	# now build the request string:
	my $request_string  = $selector;
	   $request_string .= "\t$search_words" if (defined $search_words);
	   $request_string .= $gopher_plus      if (defined $gopher_plus);

	# connect to the Gopher server send the request:
	$self->connect($host, Port => $port);
	my $ngr = $self->request($request_string, Type => $item_type);
	$self->disconnect;

	return $ngr;
}





#==============================================================================#

=head2 gopher_plus($boolean)

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

=head2 buffer_size($size)

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

=head2 error()

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

=head1 BUGS

If you encounter bugs, you can alert me of them by emailing me at
<william_g_davis at users dot sourceforge dot net> or, if you have PerlMonks
account, you can go to perlmonks.org and /msg me (William G. Davis).

=head1 SEE ALSO

Net::Gopher::Response

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
