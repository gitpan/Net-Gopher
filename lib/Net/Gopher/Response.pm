
package Net::Gopher::Response;

=head1 NAME

Net::Gopher::Response - Class encapsulating Gopher responses

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 my $response = $ng->request($request);
 
 if ($response->is_success) {
 	if ($response->is_menu) {
 		# you can use as_menu() to parse Gopher menus:
 		my @items = $response->as_menu;
 		foreach my $item (@items) {
 			print join("::",
 				$item->{'type'}, $item->{'display'},
 				$item->{'selector'}, $item->{'host'},
 				$item->{'port'}, $item->{'gopher_plus'}
 			), "\n";
 		}
 	}
 
 	if ($response->is_blocks) {
		# when issuing item attribute information requests, use
		# item_blocks() to retrieve Net::Gopher::Response::Blocks
		# objects, which you can call methods like as_info() and
		# as_admin() on to parse the block values:
 		my %info = $response->item_blocks('INFO')->as_info;
 
 		print join("::",
 			$info{'type'}, $info{'display'},
 			$info{'selector'}, $info{'host'},
 			$info{'port'}, $info{'gopher_plus'}
 		), "\n";
 
 		my %admin = $response->item_blocks('ADMIN')->as_admin;
 
 		print "Maintained by $admin{'Admin'}[0] ",
 		      "who can be emailed at $admin{'Admin'}[1]\n";
 	}
 } else {
 	print $response->error;
 }
 ...

=head1 DESCRIPTION

The L<Net::Gopher|Net::Gopher> C<request()>, C<gopher()>, C<gopher_plus()>,
C<item()>, and C<directory()> methods all return B<Net::Gopher::Response>
objects. These objects encapsulate responses from Gopher and Gopher+ servers.

In Gopher, a response is just a series of bytes terminated by a period on a
line by itself. In Gopher+, a response consists of a status line (the first
line), of which the first character is the status (success or failure; + or -),
followed by a newline (CRLF) and the content of the response. This class
contains methods to help you manipulate both Gopher as well as Gopher+
responses.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use Carp;
use Net::Gopher::Utility qw(
	check_params
	$CRLF $NEWLINE %GOPHER_ITEM_TYPES %GOPHER_PLUS_ITEM_TYPES
);
use base qw(Net::Gopher::Response::Blocks);







sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;
	
	my ($error, $request, $response, $status_line, $status, $content) =
		check_params(
			[
				'Error', 'Request', 'Response',
				'StatusLine', 'Status', 'Content'
			], @_
		);

	my $self = {
		# any error that occurred while sending the request or while
		# receiving the response:
		error       => $error,

		# the Net::Gopher::Request object:
		request     => $request,

		# the entire response--every single byte:
		response    => $response,

		# the first line of the response including the newline (only
		# in Gopher+):
		status_line => $status_line,

		# the status code (+ or -) (only in Gopher+):
		status      => $status,

		# content of the response:
		content     => $content,

		# if this was a Gopher+ item/directory attribute information
		# request, then this will be used to store the parsed
		# information blocks:
		blocks      => undef
	};

	bless($self, $class);

	# remove the socket class name from error messages (IO::Socket
	# puts them in):
	if (defined $self->error)
	{
		$self->{'error'} =~ s/IO::Socket::INET:\s//g;
	}

	return $self;
}





#==============================================================================#

=head2 status_line()

For a Gopher+ request, this method will return the status line (the first line)
of the response, including the newline character. For a Gopher request, this
will return undef.

=cut

sub status_line { return shift->{'status_line'} }





#==============================================================================#

=head2 status()

For a Gopher+ request, this method will return the status (the first character
of the status line) of the response, either a "+" or a "-" indicating success
or failure. For a Gopher request, this will return undef.

=cut

sub status { return shift->{'status'} }





#==============================================================================#

=head2 content()

Both C<content()> and C<as_string()> can be used to retrieve the strings
containing the server's response. With C<content()>, however, if the item
requested was text, then escaped periods are unescaped (i.e., '..' at the start
of a line becomes '.'). Also if the response was terminated by a period on a
line by itself but it isn't a text file or menu, then the period on a line by
itself will be removed from the content (though you can still check to see if
it was period terminated using the
L<is_terminated()|Net::Gopher::Response/is_terminated()> method). This is
because if you were requesting an image or some other non-text file, odds are
you don't want the newline and period at the end the content. And finally if
the item was text, then line endings are converted from CRLF and CR to LF. This
is done so you can use '\n', '.', etc., in patterns (please read
C<perldoc -f binmode> (it's short)).

In Gopher+, besides the modifications listed above, C<content()> does not
include the status line (first line) of the response (since the status line
isn't content), only everything after it.

=cut

sub content { return shift->{'content'} }





#==============================================================================#

=head2 as_string()

For both Gopher as well as Gopher+ requests, if the request was successful,
then this method will return the entire unmodified response, every single byte,
from the server. This includes the status line in Gopher+.

=cut

sub as_string { return shift->{'response'} }





#==============================================================================#

=head2 as_menu()

If you got a Gopher menu as your response from the server, then you can use
this method to parse it and return its values. When called, this method will
parse the content returned by C<content()> and return either an array (in list
context) or a reference to an array (in scalar context) containing references
to hashes as its elements. Each hash contains the data for one menu item and
has the following key=value pairs:

 type        = The item type (e.g., 0, 1, I, g, etc.);
 display     = The display string (e.g., "A file you should download");
 selector    = The selector string (e.g., /foo/bar);
 host        = The hostname (e.g., gopher.host.com);
 port        = The port number (e.g., 70);
 gopher_plus = The Gopher+ character (e.g., +, !, ?, etc.);

Only items that list some type of resource that can be downloaded will be added
to the list; meaning that inline text ('i' item type) is skipped.

=cut

sub as_menu
{
	my $self = shift;

	# get the content, minus the period on a line by itself:
	(my $content = $self->content) =~ s/\n\.\n?$//;

	my @menu;
	MENU: foreach my $item (split(/\n/, $content))
	{
		# get the item type and display string, selector, host, port,
		# and Gopher+ string:
		my ($type_and_display, $selector, $host, $port, $gopher_plus) =
			split(/\t/, $item);

		# separate the item type and the item description:
		my ($type, $display) = $type_and_display =~ /^(.)(.*)/;

		# skip it if it's inline text:
		next if ($type eq 'i');

		foreach ($type, $display, $selector, $host, $port)
		{
			unless (defined $_)
			{
				carp "Couldn't parse menu item";
				last MENU;
			}
		}

		push(@menu, {
				type        => $type,
				display     => $display,
				selector    => $selector,
				host        => $host,
				port        => $port,
				gopher_plus => $gopher_plus
			}
		);
	}

	return (wantarray) ? @menu : \@menu;
}





#==============================================================================#

sub request { return shift->{'request'} };





#==============================================================================#

=head2 item_blocks([@block_names])

C<item_blocks()>, C<directory_blocks()>, and C<as_blocks()> allow you to parse
information blocks. Each of these methods returns one or more information
blocks in the form of L<Net::Gopher::Response::Blocks|BLOCK METHODS> objects.

This method is a more simple alternative to the C<directory_blocks()> method.
Use this method when you make item attribute information requests (!) and
use C<directory_blocks()> when you make directory attribute information
requests ($).

This method can be used to retrieve item information block values by specifying
the block name or block names as arguments. When specifying names, remember
that leading '+' and trailing ':' are stripped from block names, so rather
than asking for '+INFO:', you should ask for just plain 'INFO'. If you don't
supply any block names, then this method will return a list containing every
block name for the item:

 # Net::Gopher::Response::Blocks object for the INFO block:
 my $info = $response->item_blocks('INFO');
 
 # print the block value:
 print $info->content;
 
 # the name of every block:
 my @block_names = $response->item_blocks;

Please note that with this method, with the C<directory_blocks()> method, and
with the C<as_blocks()> method, the blocks in the server's response are only
parsed once, the first time you call any one of these methods, and stored in
the response object, so multiple calls to any of these three methods will not
result in performance degradation.

=cut

sub item_blocks
{
	my $self        = shift;
	my @block_names = @_;

	$self->_parse_blocks() unless (defined $self->{'blocks'});

	if (@block_names)
	{
		return @{ $self->{'blocks'}[0] }{@block_names};
	}
	else
	{
		return sort keys %{ $self->{'blocks'}[0] };
	}
}





#==============================================================================#

=head2 directory_blocks([\%item | $item] [, @block_names])

C<item_blocks()>, C<directory_blocks()>, and C<as_blocks()> allow you to parse
information blocks. Each of these methods returns one or more information
blocks in the form of L<Net::Gopher::Response::Blocks|BLOCK METHODS> objects.

If the request was a Gopher+ directory attribute information request, then you
can use method to get attribute information blocks for any of the items in the
server's response. This method works like the C<item_blocks()> method,
allowing you to specify the block values you want; however, with this method
you must also specify which item you want the block values from. This is done
using a hash ref as the first argument in which you specify certain attributes
about the item, then this method will go searching each item's INFO block to
see if it matches, and when the method finds the first matching item, it
returns the block values you specified, for that item.

The hash can contain any of the following key=value pairs:

 N          = The item must be the n'th item in the response.
 Type       = The item must be of this type.
 Display    = The item must have this display string.
 Selector   = The item must have this selector string.
 Host       = The item must be on this host.
 Port       = The item must be at this port.
 GopherPlus = The item must have this Gopher+ string.

So to get the VIEWS and ADMIN B<Net::Gopher::Response::Bocks> objects for the
item with the selector of /welcome, you'd do this:

 my ($views, $admin) = $response->directory_blocks(
 	{Selector => '/welcome'}, 'VIEWS', 'ADMIN'
 );

Or use even more options for more accuracy:

 my $views = $response->directory_blocks(
 	{
		N        => 7,
 		Selector => '/welcome',
 		Host     => 'gopher.somehost.com',
 		Port     => '70',
 	}, 'VIEWS'
 );

Which means the VIEWS B<Net::Gopher::Response::Blocks> object for the 7th item
in the response, which must have a selector string of /welcome, on
gopher.somehost.com at port 70.

If you only want to specify the item by number, you can forgo the hash ref
altogether. To get the ADMIN block object for the second item, you can just do
this:

 my $admin = $response->directory_blocks(2, 'ADMIN');

To get the names of all of the information blocks for a single item, don't
specify any block names, only a parameters hash or item number:

 my @block_names = $response->directory_blocks(
 	{
 		Type     => 1,
 		Selector => '/stuff',
 		Host     => 'gopher.somehost.com',
 		Port     => 70
 	}
 );

Or:

 # the names of all of the blocks for the fourth item:
 my @block_names = $response->directory_blocks(4);

To get the total number of items, don't specify a parameters hash/item number
or block names:

 my $num_items = $response->directory_blocks;

Please note that with this method, with the C<directory_blocks()> method, and
with the C<as_blocks()> method, the blocks in the server's response are only
parsed once, the first time you call any one of these methods, and stored in
the response object, so multiple calls to any of these three methods will not
result in performance degradation.

=cut

sub directory_blocks
{
	my $self        = shift;
	my $from_item   = shift;
	my @block_names = @_;

	$self->_parse_blocks() unless (defined $self->{'blocks'});

	if (defined $from_item and ref $from_item)
	{
		my %match;
		if (ref $from_item eq 'ARRAY')
		{
			%match = @$from_item;
		}
		else
		{
			%match = %$from_item;
		}

		my ($n,$type,$display,$selector,$host,$port,$gopher_plus) =
			check_params(
				[
					'N', 'Type', 'Display', 'Selector',
					'Host', 'Port', 'GopherPlus'
				], %match
		);

		# a reference to hash contaiing the block names and values
		# for the item the user specified:
		my $matching_item;

		# the items to search:
		my @items = (defined $n)
				? $self->{'blocks'}[$n - 1]
				: @{ $self->{'blocks'} };



		my %template = (
			type        => $type,
			display     => $display,
			selector    => $selector,
			host        => $host,
			port        => $port,
			gopher_plus => $gopher_plus
		);

		# now search the items looking for the one that matches:
		foreach my $item (@items)
		{
			# get the item's INFO block:
			my %info = $item->{'INFO'}->as_info;

			my $matches = 1;
			foreach my $key (keys %template)
			{
				next unless (defined $template{$key});

				# check the value against the template:
				if (ref $template{$key} eq 'Regexp')
				{
					unless ($info{$key} =~ $template{$key})
					{
						$matches = 0;
						last;
					}
				}
				else
				{
					unless ($info{$key} eq $template{$key})
					{
						$matches = 0;
						last;
					}
				}
			}

			if ($matches)
			{
				$matching_item = $item;
				last;
			}
		}

		return unless ($matching_item);

		if (@block_names)
		{
			return @{$matching_item}{@block_names};
		}
		else
		{
			return sort keys %$matching_item;
		}
	}
	elsif (defined $from_item)
	{
		my $i = $from_item - 1;

		if (@block_names)
		{
			# hash slice to lookup and return all of the block
			# values the user wanted from this item:
			return @{ $self->{'blocks'}[$i] }{@block_names};
		}
		else
		{
			return sort keys %{ $self->{'blocks'}[$i] };
		}
	}
	else
	{
		# return the total number of items:
		return scalar @{ $self->{'blocks'} };
	}
}





#==============================================================================#

=head2 as_blocks()

C<item_blocks()>, C<directory_blocks()>, and C<as_blocks()> allow you to parse
information blocks. Each of these methods returns one or more information
blocks in the form of L<Net::Gopher::Response::Blocks|BLOCK METHODS> objects.

This method can be used to directly get all of the information blocks at once.
If you made a directory attribute information request, then the blocks are
stored in an array, where each element of the array is reference to a hash
containing block names and block values for a single item. In list context this
method will return the array and in scalar context it will return a reference
to the array:

 my @items = $response->as_blocks;
 
 # INFO block for the second item:
 my %info = $items[1]{'INFO'}->as_info;

 print "$info{'display'} ($info{'host'}:$info{'port'}$info{'selector'})\n";

If you made an item attribute information request, then the block
names and values for the single item are stored in a hash, and the hash is
returned in list context, and a reference to the hash is returned in scalar
context:

 my %blocks = $response->as_blocks;
 
 # ADMIN block for the only item:
 my %admin = $blocks{'ADMIN'}->as_admin;
 
 print "Run by $admin{'Admin'}[0] ($admin{'Admin'}[1]).\n";

Please note that with this method, with the C<directory_blocks()> method, and
with the C<as_blocks()> method, the blocks in the server's response are only
parsed once, the first time you call any one of these methods, and stored in
the response object, so multiple calls to any of these three methods will not
result in performance degradation.

=cut

sub as_blocks
{
	my $self = shift;

	$self->_parse_blocks() unless (defined $self->{'blocks'});

	my @items;
	foreach my $item (@{ $self->{'blocks'} })
	{
		push(@items, { %$item });
	}

	if (@items == 1)
	{
		return wantarray ? %{ $items[0] } : $items[0];
	}
	else
	{
		return wantarray ? @items : \@items;
	}
}





#==============================================================================#

=head2 is_success()

This method will return true if the request was successful, false otherwise.
First, whether it's a Gopher or Gopher+ request, it won't be "successful" if
any network errors occurred. Beyond that, in Gopher+, for a request to be a
"success" means that the status code returned by the server indicated success
(a code of +). In plain old Gopher, success is rather loosely defined.
Basically, since Gopher has no built-in uniform error handling, as long as
some response was received from the server (even "An error has occurred" or
"The item you requested does not exist"), this method will return true. For
more accuracy with Gopher requests you can use the C<is_terminated()> method.

If C<is_success()> returns false, meaning an error has occurred, then you can
obtain the error message by calling the C<error()> method on the
B<Net::Gopher::Response> object.

=cut

sub is_success
{
	my $self = shift;

	if (defined $self->status)
	{
		if ($self->status eq '+')
		{
			return 1;
		}
		else
		{
			return;
		}
	}
	elsif (defined $self->error)
	{
		return;
	}
	else
	{
		return 1;
	}
}





#==============================================================================#

=head2 is_error()

This method will return true if the request was unsuccessful; false otherwise.
Success and failure are the same as described above
(see L<is_success()|Net::Gopher::Response/is_success()>).

=cut

sub is_error
{
	my $self = shift;

	if (defined $self->status)
	{
		if ($self->status eq '-')
		{
			return 1;
		}
		else
		{
			return;
		}
	}
	elsif (defined $self->error)
	{
		return 1;
	}
	else
	{
		return;
	}
}





#==============================================================================#

=head2 is_blocks()

This method will return true if the response contains item attribute
information blocks; false otherwise.

=cut

sub is_blocks
{
	my $self = shift;

	my $block = qr/\+\S+ \s .*?/sx;

	if ($self->content =~ /^$block (?: \n$block)*$/sx)
	{
		return 1;
	}
	else
	{
		return;
	}
	
}





#==============================================================================#

=head2 is_gopher_plus()

This method will return true if the response was a Gopher+ style response with
a status line, status, etc.

=cut

sub is_gopher_plus
{
	my $self = shift;

	if ($self->status_line)
	{
		return 1;
	}
	else
	{
		return;
	}
}





#==============================================================================#

=head2 is_menu()

This method will return true if the response is a Gopher menu that can be
parsed with as_menu(); false otherwise.

=cut

sub is_menu
{
	my $self = shift;

	my $field = qr/[^\t\012\015]*?/;
	my $item  = qr/$field\t$field\t$field\t$field (?:\t[\+\!\?\$])?/x;

	if ($self->content =~ /^ $item (?:\n $item)* (?:\n\.\n?|\n)? $/x)
	{
		return 1;
	}
	else
	{
		return;
	}
}





#==============================================================================#

=head2 is_terminated()

This returns true if the response was terminated by a period on a line by
itself; false otherwise.

=cut

sub is_terminated
{
	my $self  = shift;
	my $error = shift;

	# Since as_string() returns the unmodified response, it will always
	# have the period on a line by itself in it; but that also means the
	# line endings weren't converted to LF, so we can't use \n to match the
	# period on a line by itself:
	if ($self->as_string =~ /$NEWLINE\.$NEWLINE?$/)
	{
		return 1;
	}
	else
	{
		return;
	}
}





sub is_text
{
	my $self = shift;

	return unless ($self->is_success);

	if ($self->is_gopher_plus)
	{
		if ($self->request->item_type eq '0'
			or $self->request->item_type eq '1'
			or (defined $self->request->representation
				and $self->request->representation =~
					/^(text\/.*|
					   Directory\/.*|
					   application\/gopher\+?\-menu)/ix))
		{
			return 1;
		}
		else
		{
			return;
		}
			
	}
	else
	{
		if ($self->request->item_type eq '0'
			or $self->request->item_type eq '1')
		{
			return 1;
		}
		else
		{
			return;
		}
	}
}





#==============================================================================#

=head2 error()

This method returns the error message of the last error to occur or undef if no
error has occurred.

=cut

sub error { return shift->{'error'} }





################################################################################
#
#	Method
#		_convert_newlines()
#
#	Purpose
#		This method is used to conver all CRLF and CR line endings in
#		the response content with LF so the '\n', '.', '\s', etc. meta
#		symbols will work in pattern matches (see <perldoc -f binmode>
#		for more).
#
#	Parameters
#		None.
#

sub _convert_newlines
{
	my $self = shift;

	# replace CRLF and CR with LF:
	$self->{'content'} =~ s/\015\012/\012/g;
	$self->{'content'} =~ s/\015/\012/g;
}





################################################################################
#
#	Method
#		_clean_period_termination()
#
#	Purpose
#		For responses that are terminated by periods on lines by
#		themselves, this method will remove from the response content
#		everything on after the period on a line by itself, unescape
#		escaped periods, and--for non-text items--remove the period on
#		a line by itself too.
#
#	Parameters
#		None.
#

sub _clean_period_termination
{
	my $self = shift;

	# For items terminated by periods on lines by themselves, lines that
	# only contain periods are escaped by adding another period. Those
	# lines must be unescaped:
	$self->{'content'} =~ s/($NEWLINE)\.\.($NEWLINE)/$1.$2/g;

	# remove anything after the period on a line by itself:
	$self->{'content'} =~ s/($NEWLINE\.$NEWLINE?).*/$1/s;

	# if there's a status, then the response was a Gopher+ request, item
	# attribute information request, or a directory attribute information
	# request:
	my $type = $self->request->item_type;
	unless ($self->is_text)
	{
		if ($self->is_gopher_plus)
		{
			if (exists $GOPHER_PLUS_ITEM_TYPES{$type})
			{
				# remove the period on a line by itself in the
				# response content for this non-text response:
				$self->{'content'} =~ s/$NEWLINE\.$NEWLINE?//;
			}
		}
		else
		{
			if (exists $GOPHER_ITEM_TYPES{$type})
			{
				# remove the period on a line by itself in the
				# response content for this non-text response:
				$self->{'content'} =~ s/$NEWLINE\.$NEWLINE?//;
			}
		}
	}
}





################################################################################
#
#	Method
#		_parse_blocks()
#
#	Purpose
#		This method parses the information blocks in $self->{'content'}
#		and stores them in $self->{'blocks'}, where
#		$self->{'blocks'} is a reference to an array and each
#		element in the array is reference to a hash containing the
#		block names and block values for a single item.
#
#	Parameters
#		None.
#

sub _parse_blocks
{
	my $self    = shift;

	# $self->{'blocks'} will contain a reference to an array that
	# will have hashrefs as its elements. Each hash will contain the item
	# attribute information block names and block values for a single item.
	# For Gopher+ '!' requests, the $self->{'blocks'} array will only
	# contain one element (for the single item's blocks). But for
	# Gopher+ '$' requests, since $ retrieves item attribute information
	# blocks for every item in a directory, the array will contain multiple
	# elements:
	$self->{'blocks'} = [];

	# remove all leading whitespace and the leading + for the first block
	# name:
	(my $content = $self->content) =~ s/^\s*\+//;

	# this will store the block names and block values for each item, one
	# at a time:
	my %blocks;

	foreach my $name_and_value (split(/\n\+/, $content))
	{
		# get the space separated name and value:
		my ($name, $value) = $name_and_value =~ /(\S+)\s(.*)/s;

		# block names are usually postfixed with colons:
		$name =~ s/:$//;

		# if the current item already has a block by this name, then
		# this block belongs to the next item, so save this item's
		# hash and start a new one:
		if (exists $blocks{$name})
		{
			# we need to save a reference to a hash containing
			# %blocks names and values, but not %blocks itself
			# because we're going to empty it to make room
			# for this item:
			push(@{ $self->{'blocks'} }, { %blocks });

			%blocks = ();
		}



		$blocks{$name} = new Net::Gopher::Response::Blocks (
			BlockName  => $name,
			BlockValue => $value
		);
	}

	# add the last item's attribute information blocks to the list:
	push(@{ $self->{'blocks'} }, { %blocks });
}

1;

__END__


=head1 BLOCK METHODS

The C<item_blocks()>, C<directory_blocks()>, and C<as_blocks()> methods all
return one or more information blocks in the form of
B<Net::Gopher::Response::Blocks> objects. Here are all of the methods you can
call on these objects:

=head2 content()

This method will return the content of the block value, with the leading space
at the beginning of each line removed.

=head2 as_string()

This method will return the unmodified block value, with leading spaces still
intact.

=head2 as_admin()

ADMIN blocks contain attributes detailing information about a particular item
including who the administrator of it is and when it was last modified. ADMIN
blocks have at least two attributes: I<Admin> and I<Mod-Date>, though they can
(and often do) contain many more.

The I<Admin> attribute contains the name of the administrator and his or her
email address (e.g., "John Doe <jdoe@notreal.email>"). I<Mod-Date> contains a
timestamp for when the item was last modified.

Like C<as_attributes()>, this method will parse these attributes and return a
hash (in list context) or a reference to a hash (in scalar context) containing
the attribute names and values. Unlike C<as_attributes()>, this method parses
the individual I<Admin> and I<Mod-Date> attributes values and stores them as
arrays (each described below).

For the I<Admin> attribute, this method will extract the administrator name and
email from the Admin attribute value and create a two element array with them:

 my %admin = $response->item_blocks('ADMIN')->as_admin;
 
 my ($name, $email) = @{ $admin{'Admin'} };
 print "Run by $name ($email).n";

For the I<Mod-Date> attribute, this method will extract the timestamp convert
it into an array containing values in the same format as those returned by
Perl's C<localtime()> function corresponding with the timestamp (to find out
exactly what the array will contain, see C<perldoc -f localtime>):

 my %admin = $response->item_blocks('ADMIN')->as_admin;
 
 my ($name, $email) = @{ $admin{'Admin'} }
 print "This box is maintained by $name ($email).";
 
 my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
 @{ $admin{'Mod-Date'} };

As mentioned above, in addition to I<Admin> and I<Mod-Date>, the hash may
contain other attributes including I<Abstract>, I<Version>, I<Org>, I<Loc> and
others--all of which are stored as in the hash as plain text, not as arrays.

Note that this method is inherited by B<Net::Gopher::Response>. You can call
this method directly on a B<Net::Gopher::Response> object, in which case
this method will call C<$response-E<gt>item_blocks('ADMIN')> and use that.
Thus, this:

 my %admin = $response->as_admin;

is the same as this:

 my %admin = $response->item_blocks('ADMIN')->as_admin;

=head2 as_ask()

ASK blocks contain a form to be filled out by the user, with ASK queries on
lines by themselves consisting of query type, followed by the question and any
default values separated by tabs (e.g., "Ask: Some question?\tdefault
answer 1\tdefault answer 2", "Choose: A question?choice 1\tchoice 2\tchoice3").

This method parses the ASK block and will return an array (in list context) or
a reference to an array (in scalar context) containing hash refs of each query
in the order they appeared, with each hash having the following key=value
pairs:

 type     = The type of query (e.g, Ask, AskP, Select, Choose, etc.).
 question = The question.
 defaults = A reference to an array containing the default answers.

Note that this method is inherited by B<Net::Gopher::Response>. You can call
this method directly on a B<Net::Gopher::Response> object, in which case
this method will call C<$response-E<gt>item_blocks('ASK')> and use that.
Thus, this:

 my @ask = $response->as_ask;

is the same as this:

 my @ask = $response->item_blocks('ASK')->as_ask;

=head2 as_info()

INFO blocks contain tab delimited item information like that which you'd find
in a Gopher menu.

This method parses INFO blocks and returns a hash (in list context) or a
reference to a hash (in scalar context) containing the information from the
tab delimited fields in the same format as described above
(see L<as_menu()|Net::Gopher::Response/as_menu()>):

 my %info = $response->item_blocks('INFO')->as_info;

Note that this method is inherited by B<Net::Gopher::Response>. You can call
this method directly on a B<Net::Gopher::Response> object, in which case
this method will call C<$response-E<gt>item_blocks('INFO')> and use that.
Thus, this:

 my %info = $response->as_info;

is the same as this:

 my %info = $response->item_blocks('INFO')->as_info;

=head2 as_views()

VIEWS blocks contain a list of available formats for a particular item.

This method parses VIEWS blocks and returns an array (in list context) or a
reference to an array (in scalar context) containing each view in the form of a
reference to hash with the following key=value pairs:

 type     = The MIME type (e.g., text/plain, application/gopher+-menu, etc.).
 language = The ISO 639 language code (e.g., En_US).
 size     = The size in bytes.

Note that this method will convert the <> size format used in Gopher+ to
an integer; the total size in bytes (e.g., <80> becomes 80, <40K> becomes
40000, <.4K> becomes 400, <400B> becomes 400, etc.):

 my @views = $response->item_blocks('VIEWS')->as_views;
 
 foreach my $view (@views) {
 	print "$view->{'type'} ($view->{'size'} bytes) ($type->{'language'})\n";
 ...
 	my $another_response = $ng->request(
 		Gopher => {
			Host           => $host,
 			Selector       => $selector,
 			Representation => $view->{'type'}
 		}
 	);
 ...
 }

Note that this method is inherited by B<Net::Gopher::Response>. You can call
this method directly on a B<Net::Gopher::Response> object, in which case
this method will call C<$response-E<gt>item_blocks('VIEWS')> and use that.
Thus, this:

 my @views = $response->as_views;

is the same as this:

 my @views = $response->item_blocks('VIEWS')->as_views;

=head2 as_attributes()

If the block value contains a series of C<Name: value> attributes on lines by
themselves, then you can use this method to parse them. This method will
return a hash (in list context) or a reference to a hash (in scalar context)
containing the attribute names and values.

=head2 is_attributes()

This method checks to see if the block value can be successfully parsed by
C<as_attributes()>. If the value contains a series of C<Name: value> attributes,
then this method will return true; false otherwise.

=head1 BUGS

If you encounter bugs, you can alert me of them by emailing me at
<william_g_davis at users dot sourceforge dot net> or, if you have PerlMonks
account, you can go to perlmonks.org and /msg me (William G. Davis).

=head1 SEE ALSO

Net::Gopher, Net::Gopher::Request

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
