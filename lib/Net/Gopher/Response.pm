
package Net::Gopher::Response;

=head1 NAME

Net::Gopher::Reponse - Class encapsulating Gopher responses

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 my $response = $gopher->request($selector, Type => $type);
 
 # check for errors:
 if ($response->is_success)
 {
 	# get each item on the menu:
 	my @items = $response->as_menu;
 	print "type: $item[0]->{'type'}\n",
 	      "description: $item[0]->{'text'}\n";
 }
 else
 {
	 print $response->error;
 }
 ...

=head1 DESCRIPTION

Both the Net::Gopher request() and request_url() methods return
Net::Gopher::Response objects. These objects encapsulate responses from
Gopher and Gopher+ servers. In Gopher, a response is just a series of bytes
terminated by a period on a line by itself. In Gopher+, a response consist of
a status line (the first line) of which the first character is the status
(success or failure (+ or -)), followed by a newline (CRLF), and the content
of the request which is a series of bytes terminated by a period on a line by
itself. This class contains methods to help you manipulate both Gopher as well
as Gopher+ responses.

=head1 METHODS

The following methods are available:

=over 4

=cut

use 5.005;
use strict;
use warnings;
use vars qw($VERSION);
use Carp;
use Net::Gopher::Utility qw($CRLF $NEWLINE);

$VERSION = '0.17';




sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my $self = {
		error          => undef,
		is_gopher_plus => 1,

		# entire response, every single byte:
		response       => undef,

		# the first line of the response including the newline (only
		# in Gopher+):
		status_line    => undef,

		# the status code (+ or -) (only in Gopher+):
		status         => undef,

		# content of the response (same as response except in Gopher+,
		# where it's everything after the status line):
		content        => undef,
	};

	bless($self, $class);
	return $self;
}





#==============================================================================#

=item status_line()

For a Gopher+ request, if the request was successful, this method will return
the status line (the first line) of the response, including the newline
character. For a Gopher request, this will return undef.

=cut

sub status_line
{
	my $self = shift;

	return $self->{'status_line'};
}





#==============================================================================#

=item status()

For a Gopher+ request, if the request was successful, this method will return
the status (the first character of the status line) of the response, either a
"+" or a "-" indicating success or failure. For a Gopher request, this will
return undef.

=cut

sub status
{
	my $self = shift;

	return $self->{'status'};
}





#==============================================================================#

=item content()

For a Gopher+ request, if the request was successful, this method will return
the content of the response (everything after the status line). For a Gopher
request, this just returns the same thing as the L<as_string()> method does.

=cut

sub content
{
	my $self = shift;
	
	return $self->{'content'};
}





#==============================================================================#

=item as_string()

For both Gopher as well as Gopher+ requests, if the request was successful,
then this method will return the entire response, every single byte, from the server. This includes the status line in Gopher+.

=cut

sub as_string
{
	my $self = shift;

	return $self->{'response'};
}





#==============================================================================#

=item as_menu()

If you got a Gopher menu as your response from the server, then you can use
this method to parse it and return its values. When called, this method will
parse the content returned by content() and return either an array (in list
context) or a reference to an array (in scalar context) containing hashrefs as
its elements. Each hash contains the data for one menu item, and has the
following keys:

     type     (the item type, e.g., 0, 1, g, s, etc.);
     text     (the item description, e.g., "A file you should download");
     selector (the selector string, e.g., /foo/bar);
     host     (the hostname, e.g., gopher.host.com);
     port     (the port number, e.g., 70);
     gopher+  (the Gopher+ string if this item is on a Gopher+ box);

The array will only contain hashrefs of items that list some type of resource
that can be downloaded; meaning that inline text is skipped ('i' item type).

=cut

sub as_menu
{
	my $self = shift;

	# get each item:
	my @items = split(/$NEWLINE/, $self->{'content'});

	my @menu;
	foreach my $item (@items)
	{
		# create a hashref of this item:
		my $item_hash = $self->_get_item_hashref($item);

		# skip it if it's inline text:
		next if ($item_hash->{'type'} eq 'i');

		push(@menu, $item_hash);
	}

	if (wantarray)
	{
		return @menu;
	}
	else
	{
		return \@menu;
	}
}





#==============================================================================#

=item as_info()

If the request was a Gopher+ attribute information request, then you can use
method to parse the attribute information in the server's response. This
method will return a hash (in list context) or a reference to a hash (in scalar
context) with information block names as its keys and block values as its
values. Please note that this method strips trailing colons from block names
(e.g., ADMIN: becomes ADMIN). Also, it should be pointed out that since the
structure of block values often differ from server to server, this method won't
attempt to parse them; that is, except for INFO: blocks which each Gopher+
server is mandated to return (and the same format) by the Gopher+ protocol
(I'll be adding ADMIN: and VIEWS: block parsing soon). Since INFO: blocks
contain tab separated item information just like you'd find in a menu, the hash
value for 'INFO' will contain a reference to another hash, one in the format
described above (L<as_menu()>).

=cut

sub as_info
{
	my $self = shift;

	# remove the leading +:
	(my $blocks = $self->{'content'}) =~ s/[^+]* \+//x;
	my @blocks = split(/\n\+/, $blocks);

	my %info;
	foreach my $block (@blocks)
	{
		# get the block name and block value (separated by the first
		# space):
		my ($name, $value) = $block =~ /(\S+)\s(.*)/s;

		# remove the colon that most block names contain:
		$name =~ s/:$//;

		# info blocks get turned into hashrefs like the items in the
		# array returned by as_menu():
		if ($name =~ /^INFO$/i)
		{
			$value = $self->_get_item_hashref($value);
		}

		# now save the block:
		$info{$name} = $value;
	}

	if (wantarray)
	{
		return %info;
	}
	else
	{
		return \%info;
	}
}





sub _get_item_hashref
{
	my $self = shift;
	my $item = shift;

	# get the item type and description text, selector, host, port:
	my ($type_and_text, $selector, $host, $port, $gopher_plus) =
		split(/\t/, $item);

	# now we need to separate the type and the text:
	my ($type, $text) = $type_and_text =~ /^(.)(.*)/;

	my $item_hash = {
		type      => $type,
		text      => $text,
		selector  => $selector,
		host      => $host,
		port      => $port,
		'gopher+' => $gopher_plus
	};

	return $item_hash;
}





#==============================================================================#

=item is_success()

This method will return true if the request was successful, false otherwise.
First, weather it's a Gopher or Gopher+ request, it won't be "successful" if
any network errors occurred. Beyond that, in Gopher+, for a request to be a
"success" means that the status code returned by the server indicated success
(a code of +). In plain old Gopher, success is rather loosely defined.
Basically, since Gopher has no built-in uniform error-handling, as long as
some response was received from the server (even "An error has occurred" or
"The item you requested does not exist"), this will return true. For more
accuracy with Gopher requests, you can use the is_terminated() method. If this
method returns false, meaning an error has occurred, then you can find out why
by calling the error() method on the Net::Gopher::Response object.

=cut

sub is_success
{
	my $self = shift;

	if (defined $self->{'status'})
	{
		if ($self->{'status'} eq '+')
		{
			return 1;
		}
		else
		{
			# the content contains the error message, so:
			$self->error($self->{'content'});

			return;
		}
	}
	elsif (defined $self->{'error'})
	{
		return;
	}
	else
	{
		return 1;
	}
}





sub is_error
{
	my $self = shift;

	if (defined $self->{'status'})
	{
		if ($self->{'status'} eq '-')
		{
			$self->error($self->{'content'});
			return 1;
		}
		else
		{
			return;
		}
	}
	elsif (defined $self->{'error'})
	{
		return 1;
	}
	else
	{
		return;
	}
}





sub is_terminated
{
	my $self  = shift;
	my $error = shift;

	if ($self->{'content'} =~ /$NEWLINE [.] $NEWLINE? $/x)
	{
		return 1;
	}
	else
	{
		return;
	}
}





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

		# rather than returning undef like Net::Gopher, we return the
		# object since that's what the user will expect:
		return $self;
	}
	else
	{
		return $self->{'error'};
	}
}
