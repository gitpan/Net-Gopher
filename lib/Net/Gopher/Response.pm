
package Net::Gopher::Response;

=head1 NAME

Net::Gopher::Response - Class encapsulating Gopher/Gopher+ responses

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 my $response = $ng->request($request);

 die $response->error if ($response->is_error);
 
 if ($response->is_menu) {
 	# You can use extract_items() to parse a Gopher menu
 	# and retrieve its items as Net::Gopher::Response::MenuItem
	# objects:
 	my @items = $response->extract_items(ExceptTypes => 'i');
 
 	foreach my $item_obj (@items)
 	{
 		printf("Requesting %s from %s at port %d\n",
 			$item_obj->selector,
 			$item_obj->host,
 			$item_obj->port
 		);
 
 		$ng->request($item_obj->as_request, File => shift @file_names);
 	}
 
 	# See Net::Gopher::Response::MenuItem for more methods you
 	# can you can call on these objects.
 } elsif ($response->is_blocks) {
 	# When issuing item/directory attribute information
 	# requests, use get_blocks() to retrieve the
 	# Net::Gopher::Response::InformationBlock objects for each
 	# block, which you can call methods like
	# extract_description() and extract_adminstrator() on:
 	my ($type, $display, $selector, $host, $port, $plus) =
 		$response->extract_description;
 
 	print "$type   $display ($selector from $host at $port)\n";
 
 	my ($name, $email) = $response->extract_admin;
 
 	print "Maintained by $name who can be emailed at $email\n";
 
 	# See Net::Gopher::Response::InformationBlock for documentation
	# on how to manipulate block objects.
 } else {
 	print $response->content;
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
manipulate item/directory attribute information blocks and parse and manipulate
Gopher menu items.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use vars qw(@ISA);
use IO::File;
use IO::String;
use XML::Writer;
use Net::Gopher::Constants qw(:request :response :item_types);
use Net::Gopher::Debugging;
use Net::Gopher::Exception;
use Net::Gopher::Response::InformationBlock;
use Net::Gopher::Response::MenuItem;
use Net::Gopher::Response::XML qw(gen_block_xml gen_menu_xml gen_text_xml);
use Net::Gopher::Utility qw(
	$NEWLINE_PATTERN $ITEM_PATTERN %ITEM_DESCRIPTIONS 
	check_params get_os_name
);

push(@ISA, qw(Net::Gopher::Debugging Net::Gopher::Exception));







################################################################################
#
# The following functions are wrapper methods around
# Net::Gopher::Response::InformationBlock extract_* methods:
#

sub extract_admin
{
	my $block = shift->get_blocks(Blocks => '+ADMIN') or return;

	return $block->extract_admin;
}
sub extract_date_created
{
	my $block = shift->get_blocks(Blocks => '+ADMIN') or return;

	return $block->extract_date_created;
}
sub extract_date_expires
{
	my $block = shift->get_blocks(Blocks => '+ADMIN') or return;

	return $block->extract_date_expires;
}
sub extract_date_modified
{
	my $block = shift->get_blocks(Blocks => '+ADMIN') or return;

	return $block->extract_date_modified;
}
sub extract_queries
{
	my $block = shift->get_blocks(Blocks => '+ASK') or return;

	return $block->extract_queries;
}
sub extract_description
{
	my $block = shift->get_blocks(Blocks => '+INFO') or return;

	return $block->extract_description;
}
sub extract_views
{
	my $block = shift->get_blocks(Blocks => '+VIEWS') or return;

	return $block->extract_views;
}





################################################################################
# 
# The following functions are public methods:
# 

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my ($ng, $request, $raw_response, $status_line, $status,
	    $content, $error) =
		check_params([qw(
			NG
			Request
			RawResponse
			StatusLine
			Status
			Content
			Error
			)], \@_
		);



	my $self = {
		# the Net::Gopher object:
		ng            => $ng,

		# the Net::Gopher::Request object that was used to create this
		# response object:
		request       => $request,

		# the entire response--every single byte:
		raw_response  => $raw_response,

		# the first line of the response including the newline (CRLF)
		# (only with Gopher+):
		status_line   => $status_line,

		# the status code (+ or -) (only with Gopher+):
		status        => $status,

		# the content of the response:
		content       => $content,

		# any error that occurred wil receiving the response or any
		# Gopher+ server-side error (comprised of the error code,
		# administrator contact information, and error message):
		error         => $error,

		# the Gopher+ error code (e.g., "1", "2", or "3"):
		error_code    => undef,

		# a reference to a two-element array containing the Gopher+
		# error administrator name and email address:
		error_admin   => undef,

		# the Gopher+ error message itself:
		error_message => undef,

		# if this was a Gopher+ item/directory attribute information
		# request, then this will be used to store the parsed
		# information block objects for each item:
		_blocks       => undef
	};

	bless($self, $class);

	return $self;
}





sub ng
{
	my $self = shift;

	if (@_)
	{
		$self->{'ng'} = shift;
	}
	else
	{
		return $self->{'ng'};
	}
}





#==============================================================================#

=head2 request()

This returns the request object. You probably won't need to use this much since
you'll usually have the request object anyway, however, when you need to store
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

=head2 raw_response()

For both Gopher as well as Gopher+ requests, this method can be used to
retrieve the entire unmodified response, every single byte, from the server.
This includes the status line in Gopher+.

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
of the status line) of the response, either a "+" or a "-", indicating success
or failure. For a Gopher request, this will return undef.
B<Net::Gopher::Constants> contains two constants, C<OK> and C<NOT_OK>, you can
compare this value against. You can import them by C<use()>ing
B<Net::Gopher::Constants> with either the I<:response> or I<:all> export tags,
or you can import them by name explicitly.

See L<Net::Gopher::Constants|Net::Gopher::Constants>.

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

Both C<content()> and C<raw_response()> can be used to retrieve strings
containing the server's response. With C<content()>, however, if the item is
text (e.g., a text file, a Gopher menu, an index-search server, etc.), then the
line endings are converted from CRLF and CR to LF on Unix and Windows and from
CRLF and LF to CR on MacOS. This is done to ensure the content contains as line
endings whatever Perl considers "\n" to be on your platform; that way you can,
for example, use "\n", ".", "\s", and other meta symbols in patterns to match
newlines in the content and it will work correctly. (If that made no sense,
please read C<perlfunc binmode>. Actually, even if that made sense, read it
anyway--it's short)).

If the request was period terminated, then any escaped periods are unescaped
(".." at the start of a line becomes ".")

The modifications listed above should go largely unnoticed by you, however, if
you try to download a non-text file like, for example, a JPEG via Gopher but
instead tell B<Net::Gopher> you're downloading a text item like a Gopher menu
(probably because you forgot set the I<ItemType> parameter for your request
object so it defaulted to type "1", Gopher menu) it'll probably make changes to
the content it shouldn't. Just remember you can always get the entire, original, 
unmodified response via the C<raw_response()> method.

In Gopher+, besides the modifications mentioned, C<content()> does not
include the status line (the first line) of the response (since the status line
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

=head2 extract_items([OPTIONS])

If you got a Gopher menu as your response from the server, then you can use
this method to parse it. When called, this method will parse the content
returned by C<content()> and return an array containing
B<Net::Gopher::Response::MenuItem> objects for the items in the menu.

This method takes two optional named parameters:

=over 4

=item OfTypes

To retrieve only items of certain types, you can use the I<OfTypes> parameter.
This parameter takes as its argument one or more item type characters as either
a string or a reference to an array of strings and will only retrieve items
if they are of those types:

 # get the Net::Gopher::Response::MenuItem object for each
 # text file item or menu item:
 my @items = $response->extract_items(OfTypes => '01');
 
 # the same thing, but instead get only DOS binary files
 # and other binary files:
 my @items = $response->extract_items(OfTypes => ['5', '9']);

=item ExceptTypes

If there are certain items you would rather not retrieve (e.g., if you don't
want inline text items, only items that list downloadable resources), then you
can instead supply the item types of the items to skip to the I<ExceptTypes>
parameter as just as described above for I<OfTypes>:

 # get the Net::Gopher::Response::MenuItem object for each item on the
 # menu except for inline text and GIF images:
 my @items = $response->extract_items(ExceptTypes => 'ig');
 
 # the same thing, but instead skip DOS binary files, mirrors, and
 # inline text:
 my @items = $response->extract_items(ExceptTypes => ['5', '+', 'i']);

=back

Note that B<Net::Gopher::Constants> contains constants you can use to specify
item types that are exported when you C<use()> B<Net::Gopher::Constants> with
either the I<:item_types> or I<:all> export tags; for example:

 # get the Net::Gopher::Response::MenuItem object for each
 # text file item or menu item:
 my @items = $response->extract_items(
 	OfTypes => [TEXT_FILE_TYPE, GOPHER_MENU_TYPE]
 );

See L<Net::Gopher::Response::MenuItems|Net::Gopher::Response::MenuItem> for
methods you can call on the objects returned by this method.
See also L<Net::Gopher::Constants|Net::Gopher::Constants> for constants you can
use to specify item types.

=cut

sub extract_items
{
	my $self = shift;

	my ($of_types, $except_types) =
		check_params(['OfTypes', 'ExceptTypes'], \@_);



	# we need the response content, minus the period on a line by itself
	# if the content is period terminated:
	my $content = $self->content;
	   $content =~ s/\n\.\n?$// if ($self->is_terminated);

	# To compare the item type of each item in the menu with
	# the ones we were told to get, or alternately, the ones we were told
	# to ignore, we'll use a regex character class comprised of all of the
	# item type characters.
	my $retrieval_class;
	my $skip_class;
	if (defined $of_types)
	{
		# grab all of the types to retrieve:
		my @types_to_retrieve = ref $of_types ? @$of_types : $of_types;
 
		# Since one or more of the type characters may be meta symbols
		# (like the + type for redundant servers), we need to quote
		# them:
		my $escaped_types = quotemeta join('', @types_to_retrieve);

		# compile the character class:
		$retrieval_class = qr/^[$escaped_types]$/;
	}
	elsif (defined $except_types)
	{
		# grab all of the item types to ignore:
		my @types_to_skip = ref $except_types
						? @$except_types
						: $except_types;
 
		# Since one or more of the type characters may be meta symbols
		# (like the + type for redundant servers), we need to quote
		# them:
		my $escaped_types = quotemeta join('', @types_to_skip);

		# compile the character class:
		$skip_class = qr/^[$escaped_types]$/;
	}



	my @menu_items;
	
	foreach my $raw_item (split(/\n/, $content))
	{
		chomp(my $item = $raw_item);

		# get the item type and display string, selector, host, port,
		# and Gopher+ string:
		my ($type_and_display, $selector, $host, $port, $gopher_plus) =
			split(/\t/, $item);



		# make sure all required fields are present:
		my @missing_fields;
		push(@missing_fields, 'an item type/display string field')
			unless (defined $type_and_display);
		push(@missing_fields, 'a selector string field')
			unless (defined $selector);
		push(@missing_fields, 'a host field')
			unless (defined $host);
		push(@missing_fields, 'a port field')
			unless (defined $port);

		return $self->call_die(
			sprintf('Menu item %d lacks the following required '.
			        'fields: %s. The response either does not ' .
				'contain a Gopher menu or contains a '.
				'malformed Gopher menu.',
				scalar @menu_items + 1,
				join(', ', @missing_fields)
			)
		) if (@missing_fields);



		# extract the item type character and the item display string:
		my $type    = substr($type_and_display, 0, 1);
		my $display = substr($type_and_display, 1);

		if (defined $retrieval_class)
		{
			# skip unless it's an item we were told to retrieve:
			next unless ($type =~ $retrieval_class);
		}
		elsif (defined $skip_class)
		{
			# skip it if it's an item we were told to ignore:
			next if ($type =~ $skip_class);
		}

		push(@menu_items,
			new Net::Gopher::Response::MenuItem (
				RawItem    => $raw_item,
				ItemType   => $type,
				Display    => $display,
				Selector   => $selector,
				Host       => $host,
				Port       => $port,
				GopherPlus => $gopher_plus
			)
		);
	}

	return @menu_items;
}





#==============================================================================#

=head2 get_blocks([OPTIONS])

This method is used to retrieve one or more Gopher+ item or directory attribute
information blocks in the form of B<Net::Gopher::Response::InformationBlock>
objects.

This method takes two named parameters:

=over 4

=item Item

The first, I<Item>, is used only for directory attribute information requests,
where the response will contain the information blocks for every item in a
directory. This parameter is used to specify the item you want blocks
from. I<Item> can be either a reference to a hash containing name=value pairs
that identify the item you want or a number indicating the n'th item.

The hash can contain any of the following C<Name =E<gt> "value"> pairs:

 N          = The item must be the n'th item in the response;
 ItemType   = The item must be of this type;
 Display    = The item must have this display string;
 Selector   = The item must have this selector string;
 Host       = The item must be on this host;
 Port       = The item must be at this port;
 GopherPlus = The item must have this Gopher+ string;

=item Blocks

The I<Blocks> parameter is used to specify the blocks you want. You can specify
an individual block as a string, or if you want to retrieve multiple block
names, as a reference to an array of strings.

So to get the C<+VIEWS> and C<+ADMIN>
B<Net::Gopher::Response::InformationBlock> objects for the item with the
selector of /welcome, you'd do this:

 my ($views, $admin) = $response->get_blocks(
 	Item   => {
		Selector => '/welcome'
	},
 	Blocks => ['+VIEWS', '+ADMIN']
 );

For the C<+INFO> block from the second item:

 my $info = $response->get_blocks(
 	Item   => 2,
 	Blocks => '+INFO'
 );

Use more options for more accuracy:

 my $views = $response->get_blocks(
 	Item   => {
		N        => 7,
 		Selector => '/welcome',
 		Host     => 'gopher.somehost.com',
 		Port     => '70',
 	},
	Blocks => '+VIEWS'
 );

Which means the C<+VIEWS> B<Net::Gopher::Response::InformationBlock> object for
the 7th item in the response with a selector string of /welcome and host and
port fields of gopher.somehost.com and 70.

For item attribute information blocks, you need not supply the I<Item>
parameter, since there's only one item:

 my $info = $response->get_blocks(Blocks => 'INFO');

Note that in either case, the leading '+' character is optional when specifying
block names. You can add it if you like, though:

 my $admin = $response->get_blocks(Blocks => '+ADMIN');

 my ($abstract, $views) = $response->get_blocks(
 	Blocks => ['ABSTRACT', 'VIEWS']
 );

=back

See L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
for methods you can call on these objects.

=cut

sub get_blocks
{
	my $self = shift;

	$self->call_warn(
		join(' ',
			"You didn't send an item attribute or directory",
			"attribute information request, so why would the",
			"response contain attribute information blocks?"
		)
	) unless ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST
		or $self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST);

	# parse each block into a Net::Gopher::Response::InformationBlock
	# object and store them in $self if we haven't done so yet:
	unless (defined $self->{'_blocks'})
	{
		$self->_parse_blocks() || return;
	}



	my ($item, $blocks) = check_params(['Item', 'Blocks'], \@_);

	# this hash will contain the name of every block requested, including
	# the leading "+," which we'll add if it was absent:
	my %blocks_to_extract;
	if (defined $blocks)
	{
		foreach my $name (ref $blocks ? @$blocks : $blocks)
		{
			$name = '+' . $name unless (substr($name, 0, 1) eq '+');
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
		# If Item argument contains a reference to a hash or array,
		# then it contains named parameters to specify a particular
		# item by elements in its +INFO block:
		my ($n, @template) = check_params([qw(
			N ItemType Display Selector Host Port GopherPlus
			)], $item
		);



		# If an item number was specified, then we'll only check that
		# item against the template. Otherwise, we'll check each item
		# agaisnt the template looking for one that matches:
		my @items_to_search = (defined $n)
					? $self->{'_blocks'}->[$n - 1]
					: @{ $self->{'_blocks'} };

		# now search the items looking for the first item that
		# matches:
		foreach my $item (@items_to_search)
		{
			my $info_block = $item->[0];

			# skip it if there was no +INFO block:
			next unless ($info_block
				and $info_block->name eq '+INFO');

			# parse the item's +INFO block:
			my @info = $info_block->extract_description or next;

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
						$does_not_match++;
						last;
					}
				}
				else
				{
					if ($value ne $temp)
					{
						$does_not_match++;
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
		# for zero-indexing:
		my $i = $item - 1;

		my @item_to_extract_from = @{ $self->{'_blocks'}->[$i] };

		return unless (@item_to_extract_from);
	}
	elsif ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST)
	{
		# it was an item attribute information request, so we'll
		# extract from the first, only item:
		@item_to_extract_from = @{ $self->{'_blocks'}->[0] };
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

=head2 as_xml([OPTIONS])

This method converts a Gopher or Gopher+ response to XML; either returning the
generated XML or saving it to disk.

This method takes several named parameters:

=over 4

=item File

The I<File> parameter is used to specify the filename of the file where the XML
will be outputted to. If a file with that name doesn't exist, it will be
created. If a file with that name already exists, anything in it will be
overwritten.

=item Pretty

The I<Pretty> parameter is used to control the style of the markup. If
I<Pretty> is true, then this method will insert linebreaks between tags and
add indentation. By default, this is on.

=item Declaration

The I<Declaration> parameter tells the method whether or not it should generate
an XML <?xml ...?> declaration at the beginning of the generated XML. By
default, it will generate the declaration.

=back

If you don't specify I<File>, then rather than being saved to disk, a string
containing the generated XML will be returned to you.

=cut

sub as_xml
{
	my $self = shift;

	$self->call_warn(
		sprintf("You sent a %s request for a %s item. The response " .
		        "shouldn't contain text and shouldn't be " .
			"convertable to XML.",
			$self->request->request_type == GOPHER_PLUS_REQUEST
				? 'Gopher+'
				: 'Gopher',
			$ITEM_DESCRIPTIONS{$self->request->item_type}
		)
	) unless ($self->is_text
		or !exists $ITEM_DESCRIPTIONS{$self->request->item_type});

	my ($filename, $pretty, $declaration) =
		check_params(['File', 'Pretty', 'Declaration'], \@_);

	# default to on if either was not supplied:
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
			or return $self->call_die(
				"Couldn't open file ($filename) to " .
				"save XML to: $!."
			);
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

=head2 is_success()

This method will return true if the request was successful, undef otherwise.

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

=head2 is_error()

This method will return true if the request was unsuccessful; false otherwise.
Success and failure are the same as described above for C<is_success()>.

=cut

sub is_error
{
	my $self = shift;

	if (defined $self->error)
	{
		return 1;
	}
	elsif ($self->is_gopher_plus and $self->status eq NOT_OK)
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

	my $block = qr/\+\S+ .*?/s;

	if ($self->content =~ /^$block(?:\n$block)*$/so)
	{
		return 1;
	}
	
}





#==============================================================================#

=head2 is_gopher_plus()

This method will return true if the response was a Gopher+ style response with
a status line, status, etc.; undef otherwise.

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
parsed with extract_items(); undef otherwise.

=cut

sub is_menu
{
	my $self = shift;

	if ($self->content =~
		/^$ITEM_PATTERN (?:\n $ITEM_PATTERN)* (?:\n\.\n|\n\.|\n|)$/xo)
	{
		return 1;
	}
}





#==============================================================================#

=head2 is_terminated()

This returns true if the response was terminated by a period on a line by
itself; undef otherwise.

=cut

sub is_terminated
{
	my $self = shift;

	# Since raw_response() returns the unmodified response, it will always
	# have the period on a line by itself in it; but that also means the
	# line endings weren't converted to LF, so we can't use \n to match the
	# period on a line by itself:
	if ($self->raw_response =~ /$NEWLINE_PATTERN\.$NEWLINE_PATTERN?$/o)
	{
		return 1;
	}
}





# XXX Maybe this should be in Request.pm?

sub is_text
{
	my $self = shift;

	return 1 if ($self->is_error);

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

If an error has occurred, this method can be used to retrieve a string
containing the entire error message. Generally, if C<is_error()> returns true
or C<is_success()> returns false, it's probably a good idea to call this
method to find out why or at least to tell the user what went wrong.

With Gopher, this generally only returns network errors like "Couldn't connect
to..." or "The server closed the connection without returning any response."

With Gopher+, this may also return, in addition to network errors, server-side
errors, indicated by a status code of "-" at the start of the status line
followed by the error in the content of the response. The content itself
typically contains an error code, followed by contact information for the
administrator, followed by the error message itself on the following lines, all
of which are returned by this method as a single string. To get the individual
elements of a Gopher+ error, use C<error_code()>, C<error_admin()>,
and C<error_message()> respectively.

=cut

sub error
{
	my $self = shift;
	
	if (@_)
	{
		$self->{'error'} = shift;
		return $self;
	}
	else
	{
		return $self->{'error'};
	}
}





#==============================================================================#

=head2 error_code()

This method returns the Gopher+ error code if present, undef otherwise.

=cut

sub error_code
{
	my $self = shift;

	return unless ($self->is_error);

	$self->_parse_error unless ($self->{'error_code'});

	return $self->{'error_code'};
}





#==============================================================================#

=head2 error_admin()

This method returns the Gopher+ error adminstrator contact information in the
form of an array containing the administrator name and email address if
present, undef otherwise.

=cut

sub error_admin
{
	my $self = shift;

	return unless ($self->is_error);

	$self->_parse_error unless ($self->{'error_admin'});

	return @{ $self->{'error_admin'} }
		if (ref $self->{'error_admin'});
}





#==============================================================================#

=head2 error_message()

This method returns the Gopher+ error message if present, undef otherwise.

=cut

sub error_message
{
	my $self = shift;

	return unless ($self->is_error);

	$self->_parse_error unless ($self->{'error_message'});

	return $self->{'error_message'};
}





################################################################################
# 
# The following functions are private methods:
# 

sub _add_raw
{
	my $self = shift;

	if (defined $_[0])
	{
		$self->{'raw_response'} .= $_[0];
	}
}

sub _add_content
{
	my $self = shift;

	if (defined $_[0])
	{
		$self->{'content'} .= $_[0];
	}
}




sub _unescape_periods
{
	my $self = shift;

	$self->{'content'} =~ s/^\.\././gm;
}





sub _convert_newlines
{
	my $self = shift;
	my $os   = get_os_name();

	if ($os =~ /^MacOS/i)
	{
		# convert Windows CRLF and Unix LF line endings to MacOS CR:
		$self->{'content'} =~ s/\015\012/\015/g;
		$self->{'content'} =~ s/\012/\015/g;
	}
	else
	{
		# convert Windows CRLF and MacOS CR line endings to Unix LF:
		$self->{'content'} =~ s/\015\012/\012/g;
		$self->{'content'} =~ s/\015/\012/g;
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

	my $content = $self->content;

	# remove the leading + for the first block name:
	$content =~ s/^\+// or return $self->call_die(
		join(' ',
			'There was no leading "+" for the first block name in',
			'the response content. The response either does not',
			'contain any attribute information blocks or contains',
			'malformed attribute information blocks.'
		)
	);

	# remove the terminating period on a line by itself (if it's present):
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
			Response => $self,
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

	return 1;
}





sub _parse_error
{
	my $self = shift;

	if ($self->error =~ /^(\d+) *(.*?) *<(.*?)>\n(?s)(.*)/)
	{
		$self->{'error_code'}    = $1;
		$self->{'error_admin'}   = [$2, $3];
		$self->{'error_message'} = $4;
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

L<Net::Gopher|Net::Gopher>,
L<Net::Gopher::Response::MenuItem|Net::Gopher::Response::MenuItem>
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>

=head1 COPYRIGHT

Copyright 2003 by William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
