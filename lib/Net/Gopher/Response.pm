
package Net::Gopher::Response;

=head1 NAME

Net::Gopher::Response - Class encapsulating Gopher responses

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 my $response = $ng->request($request);
 
 if ($response->is_success) {
 	if ($response->is_menu) {
 		# You can use extract_menu_items() to parse a Gopher menu
 		# and retrieve its items as Net::Gopher::Response::MenuItem
		# objects:
 		my @items = $response->extract_menu_items(
 			IgnoreTypes => 'i'
 		);
 
 		foreach my $item_obj (@items)
 		{
 			printf("Requesting %s from %s at port %d\n",
				$item_obj->selector,
				$item_obj->host,
				$item_obj->port
			);
 
 			$ng->request($item_obj->as_request,
 				File => shift @file_names
 			);
 		}
 
 		# See Net::Gopher::Response::MenuItem for more methods you
 		# can you can call on these objects.
 	} elsif ($response->is_blocks) {
 		# When issuing item/directory attribute information
 		# requests, use get_blocks() to retrieve the
 		# Net::Gopher::Response::InformationBlock objects for each
 		# block, which you can call methods like as_info() and
 		# as_admin() on:
 		my ($type, $display, $selector, $host, $port, $plus) =
 			$response->get_blocks(
 				Blocks => '+INFO'
 			)->extract_description;
 
 		printf("%c   %s (%s from %s at %d)\n",
 			$type, $display, $selector, $host, $port
 		);
 
 
 
 		my ($name, $email) = $response->get_blocks(
 			Blocks => '+ADMIN'
		)->extract_adminstrator;
 
 		print("Maintained by $name who can be emailed at $email\n");
 	}
 } else {
 	print $response->error;
 }
 ...

=head1 DESCRIPTION

The L<Net::Gopher|Net::Gopher> C<request()>, C<gopher()>, C<gopher_plus()>,
C<item_attribute()>, C<directory_attribute()>, and C<url()> methods all return
B<Net::Gopher::Response> objects. These objects encapsulate responses from
Gopher and Gopher+ servers.

In Gopher, a response consists of a series of bytes terminated by a period on a
line by itself. In Gopher+, a response consists of a status line (the first
line), of which the first character is the status (success or failure; + or -)
followed by either -1 (meaning the content is terminated by a period on a line
by itself), -2 (meaning the content isn't terminated), or a positive number
indicating the length of the content in bytes, followed by a newline (CRLF) and
the content of the response.

This class contains methods to help you manipulate both Gopher as well as
Gopher+ responses. In addition, there are two sub classes called
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
and
L<Net::Gopher::Response::MenuItem|Net::Gopher::Response::MenuItem>
that can be used in conjunction with methods in this class to parse and
manipulate item/directory attribute information blocks and manipulate Gopher
menu items, respectively.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use vars qw(@ISA);
use Carp;
use IO::File;
use IO::String;
use XML::Writer;
use Net::Gopher::Request;
use Net::Gopher::Response::InformationBlock;
use Net::Gopher::Response::MenuItem;
use Net::Gopher::Response::XML qw(gen_block_xml gen_menu_xml gen_text_xml);
use Net::Gopher::Utility qw(check_params $CRLF $NEWLINE %ITEM_DESCRIPTIONS);
use Net::Gopher::Constants qw(:request :response :item_types);







################################################################################
# 
# The following functions are wrapper methods around
# Net::Gopher::Response::InformationBlock extract_* methods:
# 

sub extract_administrator
{
	return shift->get_blocks(Blocks => '+ADMIN')->extract_administrator;
}
sub extract_ask_queries
{
	return shift->get_blocks(Blocks => '+ASK')->extract_ask_queries;
}
sub extract_date_created
{
	return shift->get_blocks(Blocks => '+ADMIN')->extract_date_created;
}
sub extract_date_expires
{
	return shift->get_blocks(Blocks => '+ADMIN')->extract_date_expires;
}
sub extract_date_modified
{
	return shift->get_blocks(Blocks => '+ADMIN')->extract_date_modified;
}
sub extract_description
{
	return shift->get_blocks(Blocks => '+INFO')->extract_description;
}
sub extract_views
{
	return shift->get_blocks(Blocks => '+VIEWS')->extract_views;
}





################################################################################
# 
# The following functions are public methods:
# 

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my $self = {
		# any error that occurred while sending the request or while
		# receiving the response:
		error        => undef,

		# the Net::Gopher::Request object:
		request      => undef,

		# the entire response--every single byte:
		raw_response => undef,

		# the first line of the response including the newline (CRLF)
		# (only in Gopher+):
		status_line  => undef,

		# the status code (+ or -) (only in Gopher+):
		status       => undef,

		# content of the response:
		content      => undef,

		# if this was a Gopher+ item/directory attribute information
		# request, then this will be used to store the parsed
		# information block objects for each item:
		_blocks      => undef
	};

	bless($self, $class);

	return $self;
}





#==============================================================================#

=head2 request()

This returns the request object. You probably won't need to use this much since
you'll usually have the request object anyway; however, when you need to store
and manipulate multiple response objects, you may find this useful.

=cut

sub request
{
	my $self = shift;

	if (@_)
	{
		$self->{'request'} = shift;
	}
	else
	{
		return $self->{'request'};
	}
}





#==============================================================================#

=head2 status_line()

For a Gopher+ request, this method will return the status line (the first line)
of the response, including the newline (CRLF) character. For a Gopher request,
this will return undef.

=cut

sub status_line
{
	my $self = shift;

	if (@_)
	{
		$self->{'status_line'} = shift;
	}
	else
	{
		return $self->{'status_line'};
	}
}





#==============================================================================#

=head2 status()

For a Gopher+ request, this method will return the status (the first character
of the status line) of the response, either a "+" or a "-" indicating success
or failure. For a Gopher request, this will return undef.

=cut

sub status
{
	my $self = shift;

	if (@_)
	{
		$self->{'status'} = shift;
	}
	else
	{
		return $self->{'status'};
	}
}





#==============================================================================#

=head2 content()

Both C<content()> and C<raw_response()> can be used to retrieve the strings
containing the server's response. With C<content()>, however, if the item is
text type (e.g., text file, menu, etc.), then escaped periods are unescaped
(i.e., ".." at the start of a line becomes "."). Also if the response was
terminated by a period on a line by itself but it isn't a text type, then the
period on a line by itself will be removed from the content (though you can
still check to see if it was period terminated using the
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

sub content
{
	my $self = shift;

	if (@_)
	{
		$self->{'content'} = shift;
	}
	else
	{
		return $self->{'content'};
	}
}





#==============================================================================#

=head2 raw_response()

For both Gopher as well as Gopher+ requests, if the request was successful,
then this method will return the entire unmodified response, every single byte,
from the server. This includes the status line in Gopher+.

=cut

sub raw_response
{
	my $self = shift;

	if (@_)
	{
		$self->{'raw_response'} = shift;
	}
	else
	{
		return $self->{'raw_response'};
	}
}





#==============================================================================#

=head2 as_xml([File => $filename, Pretty => $boolean, Declaration => $boolean])

This method converts a Gopher or Gopher+ response to XML; either returning the
generated XML or saving it to disk.

The I<File> parameter is used to specify the filename of the file where the XML
should be outputted to. If a file with that name doesn't exist, it will be
created. If a file with that name already exists, anything in it will be
overwritten.

The I<Pretty> parameter is used to control the style of the markup. If
I<Pretty> is true, then this method will insert linebreaks between tags and
add indentation. By default, this is on.

The I<Declaration> parameter tells the method whether or not it should generate
an XML <?xml ...?> declaration at the beginning of the generated XML. By
default, it will generate the declaration.

If you don't specify I<File>, then rather than being saved to disk, a string
containing the generated XML will be returned to you.

=cut

sub as_xml
{
	my $self = shift;

	croak "Can't convert non-text type to XML" unless ($self->is_text);

	my ($filename, $pretty, $declaration) =
		check_params(['File', 'Pretty', 'Declaration'], @_);

	# default to on if one was not supplied:
	$pretty      = (defined $pretty) ? $pretty : 1;
	$declaration = (defined $declaration) ? $declaration : 1;



	# either an IO::Handle object if a filename was supplied or an
	# IO::String object:
	my $handle;

	# this will store the generated XML to be returned if no filename was
	# supplied:
	my $xml;

	if (defined $filename)
	{
		$handle = new IO::File ("> $filename")
			or croak "Couldn't open file ($filename): $!";
	}
	else
	{
		# use a string instead:
		$handle = new IO::String ($xml);
	}



	my $writer = new XML::Writer (
		OUTPUT      => $handle,
		DATA_MODE   => $pretty ? 1 : 0,
		DATA_INDENT => $pretty ? 3 : 0  # use a three-space indent
	);

	$writer->xmlDecl('UTF-8') if ($declaration);



	if (($self->request->request_type == ITEM_ATTRIBUTE_REQUEST
		or $self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
			and $self->is_blocks)
	{
		gen_block_xml($self, $writer);
	}
	elsif (($self->request->item_type eq GOPHER_MENU_TYPE
		or $self->request->item_type eq INDEX_SEARCH_SERVER_TYPE)
			and $self->is_menu)
	{
		gen_menu_xml($self, $writer);
	}
	else
	{
		gen_text_xml($self, $writer);
	}

	$writer->end;



	if (defined $filename)
	{
		$handle->close;
	}
	else
	{
		return $xml;
	}
}





#==============================================================================#

=head2 extract_menu_items([GetTypes => \@item_types | $item_types] | [IgnoreTypes => \@item_types | $item_type])

If you got a Gopher menu as your response from the server, then you can use
this method to parse it. When called, this method will parse the content
returned by C<content()> and return an array containing
B<Net::Gopher::Response::MenuItem> objects for the items in the menu.

To retrieve only items of certain types, you can use the I<GetTypes> parameter.
This parameter takes as its argument one or more item type characters as either
a string or a reference to an array of strings, and will only retrieve items
if they are of those types. E.g.:

 # get the Net::Gopher::Response::MenuItem object for each text file or menu
 # item:
 my @items = $response->extract_menu_items(GetTypes => '01');
 
 # the same thing, but instead get only DOS binary file and other binary files:
 my @items = $response->extract_menu_items(GetTypes => ['5', '9']);

If there are certain items you would rather not retrieve (i.e., if you don't
want inline text items, only items that list downloadable resources), then you
can instead supply the item types to ignore to the I<IgnoreTypes> parameter as
either a string or as a reference to an array containing strings of each item
type character:

 # get the Net::Gopher::Response::MenuItem object for each item on the menu
 # except for inline text and GIF images:
 my @items = $response->extract_menu_items(IgnoreTypes => 'ig');
 
 # the same thing, but instead skip DOS binary files, mirrors, and inline text:
 my @items = $response->extract_menu_items(IgnoreTypes => ['5', '+', 'i']);

See L<Net::Gopher::Response::MenuItems|Net::Gopher::Response::MenuItem> for
methods you can call on these objects.

=cut

sub extract_menu_items
{
	my $self = shift;

	my ($get_types, $ignore_types) =
		check_params(['GetTypes', 'IgnoreTypes'], @_);



	# we need the response content, minus the period on a line by itself
	# if its period terminated:
	my $content = $self->content;
	   $content =~ s/\n\.\n?$// if ($self->is_terminated);

	# To compare the item type of each item in the menu with
	# the ones we were told to get, or alternately, the ones we were told
	# to ignore, we'll use a regex character class comprised of all of the
	# item type characters.
	my $get_class;
	my $ignore_class;
	if (defined $get_types)
	{
		# grab all of the types to retrieve:
		my @types_to_get = ref $get_types ? @$get_types : $get_types;
 
		# Since one or more of the type characters may be meta symbols
		# (like the + type for redundant servers), we need to quote
		# them:
		my $escaped_types = quotemeta join('', @types_to_get);

		# compile the character class:
		$get_class = qr/^[$escaped_types]$/;
	}
	elsif (defined $ignore_types)
	{
		# grab all of the item types to ignore:
		my @types_to_ignore = ref $ignore_types
						? @$ignore_types
						: $ignore_types;
 
		# Since one or more of the type characters may be meta symbols
		# (like the + type for redundant servers), we need to quote
		# them:
		my $escaped_types = quotemeta join('', @types_to_ignore);

		# compile the character class:
		$ignore_class = qr/^[$escaped_types]$/;
	}



	my @menu;
	foreach my $item (split(/\n/, $content))
	{
		# get the item type and display string, selector, host, port,
		# and Gopher+ string:
		my ($type_and_display, $selector, $host, $port, $gopher_plus) =
			split(/\t/, $item);

		unless (defined $type_and_display
			and defined $selector
			and defined $host
			and defined $port)
		{
			carp "Couldn't parse menu item";
			last;
		}
	
		# separate the item type and the item description:
		my ($type, $display) = $type_and_display =~ /^(.)(.*)/;

		if (defined $get_class)
		{
			# skip unless it's an item we were told to retrieve:
			next unless ($type =~ $get_class);
		}
		elsif (defined $ignore_class)
		{
			# skip it if it's an item we were told to ignore:
			next if ($type =~ $ignore_class);
		}

		push(@menu, new Net::Gopher::Response::MenuItem (
				RawItem    => $item,
				ItemType   => $type,
				Display    => $display,
				Selector   => $selector,
				Host       => $host,
				Port       => $port,
				GopherPlus => $gopher_plus
			)
		);
	}

	return @menu;
}





#==============================================================================#

=head2 get_blocks([Item => \%item | $num [, Blocks => \@block_names | $name]])

This method is used to retrieve one or more Gopher+ item attribute or directory
attribute blocks in the form of
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
objects.

This method takes two named parameters.

The first parameter, I<Item>, is used only for directory attribute information
requests, where the response will contain the information blocks for every item
in a directory. This parameter is used to specify the item you want blocks
from. I<Item> can be either a reference to hash containing name=value pairs
that identify the item you want or a number indicating the n'th item.

The hash can contain any of the following Name=value pairs:

 N          = The item must be the n'th item in the response;
 ItemType   = The item must be of this type;
 Display    = The item must have this display string;
 Selector   = The item must have this selector string;
 Host       = The item must be on this host;
 Port       = The item must be at this port;
 GopherPlus = The item must have this Gopher+ string;

The I<Blocks> parameter is used to specify the blocks you want. You specify an
individual block name as a string, or multiple block names as a reference to an
array of strings.

So to get the +VIEWS and +ADMIN B<Net::Gopher::Response::InformationBlock>
objects for the item with the selector of /welcome, you'd do this:

 my ($views, $admin) = $response->get_blocks(
 	Item   => {
		Selector => '/welcome'
	},
 	Blocks => ['VIEWS', 'ADMIN']
 );

For the +INFO block from the second item:

 my $info = $response->get_blocks(
 	Item   => 2,
 	Blocks => 'INFO'
 );

Use more options for more accuracy:

 my $views = $response->get_blocks(
 	Item   => {
		N        => 7,
 		Selector => '/welcome',
 		Host     => 'gopher.somehost.com',
 		Port     => '70',
 	},
	Blocks => 'VIEWS'
 );

Which means the +VIEWS B<Net::Gopher::Response::InformationBlock> object for the
7th item in the response with a selector string of /welcome and host and port
fields of gopher.somehost.com and 70.

For item attribute information blocks, you need not supply the I<Item>
parameter, since there's only one item:

 my $info = $response->get_blocks(Blocks => 'INFO');

Note that in either case, the leading '+' character is optional when specifying
block names. You can add it if you like, though:

 my $admin = $response->get_blocks(Blocks => '+ADMIN');

 my ($abstract, $views) = $response->get_blocks(
 	Blocks => ['+ABSTRACT', '+VIEWS']
 );

See L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
for methods you can call on these objects.

=cut

sub get_blocks
{
	my $self = shift;

	$self->_parse_blocks() unless (defined $self->{'_blocks'});

	my ($item, $blocks) = check_params(['Item', 'Blocks'], @_);

	# this hash will contain the name of every block request--minus the
	# leadig "+" if it was present:
	my %blocks_to_extract;
	if (defined $blocks)
	{
		foreach my $name (ref $blocks ? @$blocks : $blocks)
		{
			$name = '+' . $name unless ($name =~ /^\+/);
			$blocks_to_extract{$name} = 1;
		}
	}

	# this will store an array from $self->{'_blocks'} containing every
	# block object from the requested item (or from the *only* item if it
	# was an item attribute information request) or nothing if no item was
	# specified:
	my @item_to_extract_from;

	if (defined $item and ref $item)
	{
		unless ($self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
		{
			return;
		}

		# If Item argument contains a reference to a hash or array,
		# then it contains named parameters to specify a particular
		# item by elements in its INFO block:
		my %must_match;
		if (ref $item eq 'ARRAY')
		{
			%must_match = @$item;
		}
		else
		{
			%must_match = %$item;
		}

		my ($n, @template) =
			check_params(
				[
					'N', 'ItemType', 'Display', 'Selector',
					'Host', 'Port', 'GopherPlus'
				], %must_match
			);



		# If an item number was specified, then we'll only check that
		# item against the template. Otherwise, we'll check each item
		# agaisnt the template looking for one that matches:
		my @items_to_search = (defined $n)
						? $self->{'_blocks'}[$n - 1]
						: @{ $self->{'_blocks'} };

		# now search the items looking for the first item that
		# matches:
		foreach my $item (@items_to_search)
		{
			my $info_block = $item->[0];

			# break out if there was no +INFO block:
			unless ($info_block and $info_block->name eq 'INFO')
			{
				last;
			}

			# parse the item's +INFO block:
			my @info = $info_block->as_info;

			# We assume the item matches. It's only when user
			# specifies certain parameters in the template and
			# those parameters don't match the corresponding fields
			# in the +INFO block that the item doesn't match:
			my $does_not_match;
			for (my $i = 0; $i <= $#template; $i++)
			{
				my ($temp, $value) = ($template[$i], $info[$i]);

				next unless (defined $temp);

				# check the value against the template:
				if (ref $temp eq 'Regexp')
				{
					if ($value !~ $temp)
					{
						$does_not_match = 1;
						last;
					}
				}
				else
				{
					if ($value ne $temp)
					{
						$does_not_match = 1;
						last;
					}
				}

			}

			# check the next item if this one didn't match the
			# template:
			next if ($does_not_match);

			# we found one that matches:
			@item_to_extract_from = @$item;
			last;
		}

		return unless (@item_to_extract_from);
	}
	elsif (defined $item)
	{
		unless ($self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
		{
			return;
		}

		# for zero-indexing:
		my $i = $item - 1;

		my @item_to_extract_from = @{ $self->{'_blocks'}[$i] };

		return unless (@item_to_extract_from);
	}
	elsif ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST)
	{
		# it was an item attribute information request, so we'll
		# extract from the first, only item:
		@item_to_extract_from = @{ $self->{'_blocks'}[0] };
	}



	my @blocks_to_return;
	if (@item_to_extract_from)
	{
		# extract the request blocks, or if none we're request, extract
		# all of them for from the specified item:
		if (%blocks_to_extract)
		{
			foreach my $block (@item_to_extract_from)
			{
				push(@blocks_to_return, $block)
					if ($blocks_to_extract{$block->name});
			}
		}
		else
		{
			@blocks_to_return = @item_to_extract_from;
		}
	}
	else
	{
		@blocks_to_return = @{ $self->{'_blocks'} };
	}



	return wantarray ? @blocks_to_return : shift @blocks_to_return;
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

	if (defined $self->error)
	{
		return 1;
	}
	elsif ($self->is_gopher_plus and $self->status eq FAILURE_CODE)
	{
		return 1;
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

If C<is_success()> returns undef, meaning an error has occurred, then you can
obtain the error message by calling the C<error()> method on the
B<Net::Gopher::Response> object.

=cut

sub is_success
{
	my $self = shift;

	if (!$self->is_error)
	{
		return 1;
	}
}





#==============================================================================#

=head2 is_blocks()

This method will return true if the response contains one or more
item/directory attribute information blocks; undef otherwise.

=cut

sub is_blocks
{
	my $self = shift;

	my $block = qr/\+\S+ .*?/so;

	if ($self->content =~ /^$block(?:\n$block)*$/so)
	{
		return 1;
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

	if (defined $self->status_line and defined $self->status)
	{
		return 1;
	}
}





#==============================================================================#

=head2 is_menu()

This method will return true if the response is a Gopher menu that can be
parsed with extract_menu_items(); false otherwise.

=cut

sub is_menu
{
	my $self = shift;

	# this pattern matches a tab delimited field within an item:
	my $field = qr/[^\t\012\015]*?/o;

	# this pattern matches an item within a Gopher menu:
	my $item = qr/$field \t $field \t $field \t $field (?:\t[\+\!\?\$])?/xo;

	if ($self->content =~ /^ $item (?:\n $item)* (?:\n\.\n?|\n)? $/xo)
	{
		return 1;
	}
}





#==============================================================================#

=head2 is_terminated()

This returns true if the response was terminated by a period on a line by
itself; false otherwise.

=cut

sub is_terminated
{
	my $self = shift;

	# Since raw_response() returns the unmodified response, it will always
	# have the period on a line by itself in it; but that also means the
	# line endings weren't converted to LF, so we can't use \n to match the
	# period on a line by itself:
	if ($self->raw_response =~ /$NEWLINE\.$NEWLINE?$/o)
	{
		return 1;
	}
}





sub is_text
{
	my $self = shift;

	return unless ($self->is_success);

	if ($self->is_gopher_plus)
	{
		if ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST
			or $self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
		{
			return 1;
		}
		elsif ($self->request->item_type eq TEXT_FILE_TYPE
			or $self->request->item_type eq GOPHER_MENU_TYPE
			or (defined $self->request->representation
				and $self->request->representation =~
					/^(?:text\/.*|
					     directory\/.*|
					     application\/gopher\+?\-menu)/ix))
		{
			return 1;
		}
			
	}
	elsif ($self->request->item_type eq TEXT_FILE_TYPE
		or $self->request->item_type eq GOPHER_MENU_TYPE)
	{
		return 1;
	}
}





#==============================================================================#

=head2 error()

This method returns the error message of the last error to occur or undef if no
error has occurred.

=cut

sub error
{
	my $self = shift;

	if (@_)
	{
		# remove the socket class name from error messages (IO::Socket
		# puts them in):
		($self->{'error'} = shift) =~ s/IO::Socket::INET:\s//g;

		# return the object so the caller can do
		# "return $response->error($msg);" and their sub will exit
		# correctly, giving their callers this object to call
		# is_error()/is_success() on:
		return $self;
	}
	else
	{
		return $self->{'error'};
	}
}





################################################################################
# 
# The following functions are private methods:
# 

################################################################################
#
#	Method
#		_convert_newlines()
#
#	Purpose
#		This method is used to convert all CRLF and CR line endings in
#		the response content with LF so the '\n', '.', '\s', etc. meta
#		symbols will work in pattern matches (see <perldoc -f binmode>
#		for more information).
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


	unless ($self->is_text)
	{
		# remove the period on a line by itself in the
		# response content for this non-text response:
		$self->{'content'} =~ s/$NEWLINE\.$NEWLINE?//;
	}
}





################################################################################
#
#	Method
#		_parse_blocks()
#
#	Purpose
#		This method parses the information blocks in $self->content
#		and stores them in $self->{'_blocks'}, where
#		$self->{'_blocks'} is a reference to an array and each
#		element in the array is reference to a array containing the 
#		Net::Gopher::Response::InformationBlock objects for a single
#		item.
#
#	Parameters
#		None.
#

sub _parse_blocks
{
	my $self = shift;

	# For Gopher+ item attribute information requests, the
	# $self->{'_blocks'} array will only contain one element (for the
	# single item's block objects). But for Gopher+ directory attribute
	# information requests, since they retrieve attribute information
	# blocks for every item in a directory, the array will contain multiple
	# elements:
	$self->{'_blocks'} = [];

	# remove the leading + for the first block name and the period
	# terminator if it was period terminated:
	my $content = $self->content;
	   $content =~ s/^\+//;
	   $content =~ s/\n\.\n?$// if ($self->is_terminated);

	# this will store the Net::Gopher::Response::InformationBlock objects
	# for each item, one at a time. Each time we encounter the start of
	# another item's blocks, we save @blocks to $self->{'_blocks'} and
	# empty it:
	my @blocks;
	my %seen;

	# the start of block is denoted by a + at the beginning of a line:
	foreach my $name_and_value (split(/\n\+/, $content))
	{
		# get the space separated name and value:
		my ($name, $raw_value) = split(/\s/, $name_and_value, 2);

		# block names are usually postfixed with colons:
		$name =~ s/:$//;

		# each line of a block value contains a leading space, so we
		# strip the leading spaces for the "pure" value but leave
		# them intact for the "raw" value:
		(my $value = $raw_value) =~ s/^ //mg;

		my $obj = new Net::Gopher::Response::InformationBlock (
			Name     => $name,
			RawValue => $raw_value,
			Value    => $value
		);

		if ($seen{$name})
		{
			# we need to save a reference to an array containing
			# the block objects in @blocks, but not @blocks itself
			# because we're going to empty it to make room
			# for this item:
			push(@{ $self->{'_blocks'} }, [ @blocks ]);

			@blocks = ();
			%seen   = ();
		}

		push(@blocks, $obj);
		$seen{$name}++;
	}

	# add the last item's attribute information block objects to the list:
	push(@{ $self->{'_blocks'} }, [ @blocks ]);
}

1;

__END__

=head1 BUGS

Bugs in this package can reported and monitored using CPAN's request
tracker: rt.cpan.org.

If you wish to report bugs to me directly, you can reach me via email at
<william_g_davis at users dot sourceforge dot net>.

=head1 SEE ALSO

L<Net::Gopher|Net::Gopher>,
L<Net::Gopher::Response::MenuItem|Net::Gopher::Response::MenuItem>
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>

=head1 COPYRIGHT

Copyright 2003 by William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
