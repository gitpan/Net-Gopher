
package Net::Gopher::Response;

=head1 NAME

Net::Gopher::Response - Class encapsulating Gopher/Gopher+ responses

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 my $response = $ng->request($request);
 
 die $response->error if ($response->is_error);
 
 if ($response->is_menu) {
 	# You can use extract_items() to parse a Gopher menu and retrieve
 	# its items as Net::Gopher::Response::MenuItem objects:
 	my @items = $response->extract_items(ExceptTypes => 'i');
 
 	foreach my $item_obj (@items)
 	{
 		printf("Requesting %s from %s at port %d\n",
 			$item_obj->selector,
 			$item_obj->host,
 			$item_obj->port
 		);
 
 		(my $filename = $item_obj->selector) =~ s/\W/_/g;
 		$ng->request($item_obj->as_request, File => $filename);
 	}
 
 	# See Net::Gopher::Response::MenuItem for more methods you
 	# can you can call on the objects returned by extract_items().
 } elsif ($response->is_blocks) {
 	# When issuing item/directory attribute information requests, use
 	# get_block() to retrieve an individual
 	# Net::Gopher::Response::InformationBlock object for a particular
 	# block, which you can then parse using methods like
 	# extract_description() and extract_adminstrator() depending on
 	# what type of block it is:
 	my $info_block = $response->get_block('+INFO');
 
 	my ($type, $display, $selector, $host, $port, $plus) =
 		$info_block->extract_description;
 
 	print "$type   $display ($selector from $host at $port)\n";
 
 
 	my $admin_block = $response->get_block('+ADMIN');
 
 	my ($name, $email) = $admin_block->extract_admin;
 
 	print "Maintained by $name who can be emailed at $email\n";
  
 
 
 	# for item attribute information requests, there are wrapper
 	# methods around the Net::Gopher::Response::InformationBlock
 	# extract_* methods; you can call them directly on the
 	# Net::Gopher::Response object and skip get_block():
 	($name, $email) = $response->extract_admin;
 	my $abstract    = $response->extract_abstract;
 	my @views       = $response->ectract_views;
 
 
 
 	# for directory attribute information requests, you'll have to
 	# specify which item you want the block from:
 	$info_block  = $response->get_block('+INFO', Item => 1);
 	$admin_block = $response->get_block('+INFO', Item => 2);
 
 	#... or use get_blocks() to multiple blocks at once:
 	my @blocks = $response->get_blocks;
 
 
 
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
Gopher and Gopher+ Gopherspaces.

In Gopher, a response consists of a series of bytes terminated by a period on a
line by itself.[1] In Gopher+, a response consists of a status line (the first
line), of which the first character is the status (success or failure; + or -)
followed by either -1 (meaning the content is terminated by a period on a line
by itself), -2 (meaning the content isn't terminated), or a positive number
indicating the length of the content in bytes, followed by a newline (CRLF) and
the content of the response.[2]

This class contains methods to help you manipulate both Gopher as well as
Gopher+ responses. In addition, there are two sub classes called
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
and L<Net::Gopher::Response::MenuItem|Net::Gopher::Response::MenuItem> that can
be used in conjunction with methods in this class to parse and manipulate
item/directory attribute information blocks and parse and manipulate Gopher
menu items.

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
use Net::Gopher::Constants qw(:all);
use Net::Gopher::Debugging;
use Net::Gopher::Exception;
use Net::Gopher::Response::InformationBlock;
use Net::Gopher::Response::MenuItem;
use Net::Gopher::Response::XML qw(gen_block_xml gen_menu_xml gen_text_xml);
use Net::Gopher::Utility qw(
	$CRLF $NEWLINE_PATTERN $ITEM_PATTERN %ITEM_DESCRIPTIONS

	check_params
	convert_newlines
	strip_status_line
	strip_terminator
);

push(@ISA, qw(Net::Gopher::Debugging Net::Gopher::Exception));







################################################################################
#
# The following subroutines are wrapper methods around
# Net::Gopher::Response::InformationBlock extract_* methods:
#

sub extract_admin
{
	my $self = shift;

	my $block = $self->get_block('+ADMIN');

	return $self->call_die('No +ADMIN block in response.')
		unless (defined $block);

	return $block->extract_admin;
}
sub extract_date_created
{
	my $self = shift;

	my $block = $self->get_block('+ADMIN');

	return $self->call_die('No +ADMIN block in response.')
		unless (defined $block);

	return $block->extract_date_created;
}
sub extract_date_expires
{
	my $self = shift;

	my $block = $self->get_block('+ADMIN');

	return $self->call_die('No +ADMIN block in response.')
		unless (defined $block);

	return $block->extract_date_expires;
}
sub extract_date_modified
{
	my $self = shift;

	my $block = $self->get_block('+ADMIN');

	return $self->call_die('No +ADMIN block in response.')
		unless (defined $block);

	return $block->extract_date_modified;
}
sub extract_queries
{
	my $self = shift;

	my $block = $self->get_block('+ASK');

	return $self->call_die('No +ASK block in response.')
		unless (defined $block);

	return $block->extract_queries;
}
sub extract_description
{
	my $self = shift;

	my $block = $self->get_block('+INFO');

	return $self->call_die('No +INFO block in response.')
		unless (defined $block);

	return $block->extract_description;
}
sub extract_views
{
	my $self = shift;

	my $block = $self->get_block('+VIEWS');

	return $self->call_die('No +VIEWS block in response.')
		unless (defined $block);

	return $block->extract_views;
}





################################################################################
# 
# The following subroutines are public methods:
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
		# information blocks as an array where each item is a reference
		# to an array containing the Net::Gopher::InformationBlock
		# objects:
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
of the response, including the newline (CRLF) character.[3] For a Gopher
request, this will return undef.

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
or failure.[4] For a Gopher request, this will return undef.
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
anyway--it's short)). Also, if the request was period terminated then any
escaped periods are unescaped (".." at the start of a line becomes ".")

The modifications listed above should go largely unnoticed by you, however, if
you try to download a non-text file--like, for example, a JPEG--but instead
tell B<Net::Gopher> you're downloading a text item like a Gopher menu (probably
because you forgot set the I<ItemType> parameter for your request object so it
defaulted to type "1", Gopher menu) it'll probably make changes to the content
it shouldn't. Just remember you can always get the entire, original, unmodified
response with the C<raw_response()> method.

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

If you got a Gopher menu as your response from the server,[5] then you can use
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
parameter in the same format as described above for I<OfTypes>:

 # get the Net::Gopher::Response::MenuItem object for each item on the
 # menu except for inline text and GIF images:
 my @items = $response->extract_items(ExceptTypes => 'ig');
 
 # the same thing but instead skip DOS binary files, mirrors, and
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
	strip_terminator($content) if ($self->is_terminated);

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
	my $current_item;
	foreach my $item (split(/\n/, $content))
	{
		$current_item++;

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
				$current_item,
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

=head2 get_block(NAME [, OPTIONS])

This method is used to retrieve an individual
I<Net::Gopher::Response::InformationBlock> object. The first argument this
method always takes is the name of the block to retrieve. The leading "+"
character in the block name is optional, but block names are case sensitive.[6]
If you made a directory attribute information request, than you'll have to be
more specific as to which item you want the block from--use the I<Item>
parameter to specify which item.

I<Item> can be either a number indicating the N'th item in the response or it
can be a reference to a hash (or array) containing one or more named parameters
describing the item, which will be compared against each item's C<+INFO> block
looking for an item that matches the template. The possible C<Name => value>
pairs for an I<Item> template hash are:

=over 4

=item N

The N'th item in the response. If specified, then the rest of the template will
only be compared against this specific item.

=item ItemType

The item type character in the C<+INFO> block, for example, "0", "1", or "g".
B<Net::Gopher::Constants> contains constants you can use to specify an item
type that are exported when you C<use()> B<Net::Gopher::Constants> with either
the I<:item_types> or I<:all> export tags.

=item Display

The display string field in the C<+INFO> block of the item.

=item Selector

The selector string field in the C<+INFO> block of the item.

=item Host

The host field in the C<+INFO> block of the item.

=item Port

The port field in the C<+INFO> block of the item.

=item GopherPlus

The Gopher+ string in the C<+INFO> block of the item.

=back

The value of any of the I<Item> template pair can either be a string or a
pattern compiled with the C<qr//> operator (it tells the difference using
C<ref()>). The first item that matches every parameter in the template is the
item the specified block object will be returned from.

This, for example, tries to retrieve the C<+ADMIN> block object from the second
item:

 my $block = $response->get_block('+ADMIN', Item => 2);

Remember that the leading "+" is optional:

 my $block = $response->get_block('VIEWS',
 	Item => {
 		Display => qr/Memeber Directory \(updated \d+\)/
 	}
 );

Specify more options for more accuracy:

 my $block = $response->get_block('+ABSTRACT',
 	Item => {
 		N        => 4,
		ItemType => TEXT_FILE_TYPE,
 		Display  => qr/^My big (?:eassy|article)$/,
 		Selector => qr/^\/stuff\/essay(?:\.txt)?$/,
		Host     => 'gopher.host.com',
		Port     => 70
 	}
 );

which means the fourth item in the response, which must be a text file, must
have a display string of "My big essay" or "My big article," must have a
selector string of "/stuff/essay.txt" or "/stuff/essay", and must be on
gopher.host.com at port 70.

See L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
for methods you can call on the object returned by this method.

=cut

sub get_block
{
	my $self = shift;
	my $name = shift;

	$self->call_warn(
		"You didn't send an item attribute or directory attribute " .
		"information request, so why would the response contain " .
		"attribute information blocks?"
	) unless ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST
		or $self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST);

	# parse each block into a Net::Gopher::Response::InformationBlock
	# object and store them in $self if we haven't done so yet:
	unless (defined $self->{'_blocks'})
	{
		$self->_exract_blocks() || return;
	}



	my @item_wanted_from;
	if (@_)
	{
		my $item = check_params(['Item'], \@_);

		@item_wanted_from = $self->_find_item_blocks($item);
	}
	else
	{
		@item_wanted_from = @{ $self->{'_blocks'}[0] };
	}

	return unless (@item_wanted_from);



	$name = '+' . $name unless (substr($name, 0, 1) eq '+');

	my $block_to_return;
	foreach my $block (@item_wanted_from)
	{
		if ($block->name eq $name)
		{
			$block_to_return = $block;
			last;
		}
	}

	return $block_to_return;
}





#==============================================================================#

=head2 get_blocks([OPTIONS])

This method is used to retrieve one or more Gopher+ item or directory attribute
information blocks in the form of B<Net::Gopher::Response::InformationBlock>
objects.

This method takes two optional named parameters:

=over 4

=item Item

This optional parameter is the same as the I<Item> parameter for C<get_block()>
described above.

If you don't supply I<Item>, then blocks from every item in the response will
be returned.

=item Blocks

The optional I<Blocks> parameter is used to specify which blocks you want. You
can specify an individual block as a string, or if you want to retrieve
multiple blocks, as a reference to an array of strings.

If you don't supply this then the all of the blocks for the specified item
will be returned.

=back

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
 		Host     => qr/^(?:gopher)?.somehost.com/,
 		Port     => '70',
 	},
	Blocks => '+VIEWS'
 );

Which means the C<+VIEWS> B<Net::Gopher::Response::InformationBlock> object for
the 7th item in the response with a selector string of /welcome, a host field of
either "gopher.somehost.com" or ".somehost.com", and a port field of 70.

Note that in either case, the leading '+' character is optional when specifying
block names. You can add it if you like, though:

 my $admin = $response->get_blocks(Blocks => '+ADMIN');

 my ($abstract, $views) = $response->get_blocks(
 	Blocks => ['ABSTRACT', 'VIEWS']
 );

See L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>
for methods you can call on these objects.

=cut

sub get_blocks
{
	my $self = shift;

	$self->call_warn(
		"You didn't send an item attribute or directory attribute " .
		"information request, so why would the response contain " .
		"attribute information blocks?"
	) unless ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST
		or $self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST);

	# parse each block into a Net::Gopher::Response::InformationBlock
	# object and store them in $self if we haven't done so yet:
	unless (defined $self->{'_blocks'})
	{
		$self->_exract_blocks() || return;
	}



	my ($item, $blocks) = check_params(['Item', 'Blocks'], \@_);

	# this hash will contain the name of every block requested, including
	# the leading "+," which we'll add if it was absent:
	my %blocks_to_get;
	if (defined $blocks)
	{
		foreach my $name (ref $blocks ? @$blocks : $blocks)
		{
			$name = '+' . $name
				unless (substr($name, 0, 1) eq '+');

			$blocks_to_get{$name} = 1;
		}
	}

	# this will store an array from $self->{'_blocks'} containing every
	# block object from the requested item (or from the *only* item if it
	# was an item attribute information request) or nothing if no item was
	# specified:
	my @item_wanted_from;

	if ($item)
	{
		@item_wanted_from = $self->_find_item_blocks($item) or return;
	}
	elsif ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST)
	{
		# it was an item attribute information request, so we'll get
		# blocks from the first and only item:
		@item_wanted_from = @{ $self->{'_blocks'}[0] };
	}



	my @blocks_to_return;
	if (@item_wanted_from)
	{
		# get only the requested blocks, or, if none we're request,
		# get all of them from the specified item:
		if (%blocks_to_get)
		{
			foreach my $block (@item_wanted_from)
			{
				push(@blocks_to_return, $block)
					if ($blocks_to_get{$block->name});
			}
		}
		else
		{
			@blocks_to_return = @item_wanted_from;
		}
	}
	else
	{
		@blocks_to_return = @{ $self->{'_blocks'} };
	}



	return wantarray ? @blocks_to_return : shift @blocks_to_return;
}





#==============================================================================#

=head2 has_block(NAME [, OPTIONS])

This method is used to check whether or not the response contains a particular
B<Net::Gopher::Response::InformationBlock> object. The calling conventions for
this method are *exactly* the same as they are for the C<get_block()> method
described above, except rather than returning a block object, this method
just returns true if the block object exists.

Call this method before calling C<get_block()>.

See L<get_block()|Net::Gopher::Response/get_block(NAME [, OPTIONS])>.

=cut

sub has_block
{
	my $self = shift;
	my $name = shift;

	return $self->call_die('No block name supplied for has_block().')
		unless ($name);

	$self->call_warn(
		"You didn't send an item attribute or directory attribute " .
		"information request, so why would the response contain " .
		"attribute information blocks?"
	) unless ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST
		or $self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST);

	# parse each block into a Net::Gopher::Response::InformationBlock
	# object and store them in $self if we haven't done so yet:
	unless (defined $self->{'_blocks'})
	{
		$self->_exract_blocks() || return;
	}

	my @blocks_to_check;
	if (@_)
	{
		my $item = check_params(['Item'], \@_);

		@blocks_to_check = $self->_find_item_blocks($item);
	}
	else
	{
		@blocks_to_check = @{ $self->{'_blocks'}[0] };
	}

	return unless @blocks_to_check;



	$name = '+' . $name unless (substr($name, 0, 1) eq '+');
	foreach my $block (@blocks_to_check)
	{
		return 1 if ($block->name eq $name);
	}
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
add indentation. By default, pretty is true.

=item Declaration

The I<Declaration> parameter tells the method whether or not it should generate
an XML C<E<lt>?xml ...?E<gt> declaration at the beginning of the generated XML.
By default, this is true.

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
		DATA_MODE   => $pretty ? 1 : 0, # add newlines.
		DATA_INDENT => $pretty ? 3 : 0  # use a three-space indent.
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

	return 1 if (!$self->is_error);
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

	return 1 if (defined $self->content
		and $self->content =~ /^$block(?:\n$block)*$/so);	
}





#==============================================================================#

=head2 is_gopher_plus()

This method will return true if the response was a Gopher+ style response with
a status line, status, etc.; undef otherwise.

=cut

sub is_gopher_plus
{
	my $self = shift;

	return 1 if (defined $self->status_line and defined $self->status);
}





#==============================================================================#

=head2 is_menu()

This method will return true if the response is a Gopher menu that can be
parsed with extract_items(); undef otherwise.

=cut

sub is_menu
{
	my $self = shift;

	return 1 if (defined $self->content
		and $self->content =~ /^$ITEM_PATTERN (?:\n $ITEM_PATTERN)*
		                       (?:\n\.\n|\n\.|\n)?$/xo);
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
	# line endings weren't converted to LF on Unix and Windows or CR on
	# MacOS, so we can't use \n to match the period on a line by itself:
	return 1 if (defined $self->raw_response
		and $self->raw_response =~ /$NEWLINE_PATTERN\.$NEWLINE_PATTERN?$/o);
}





sub is_text
{
	my $self = shift;

	return unless (defined $self->content);
	
	if ($self->is_error)
	{
		return 1;
	}
	elsif ($self->is_gopher_plus)
	{
		if ($self->request->request_type == ITEM_ATTRIBUTE_REQUEST
			or $self->request->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
		{
			return 1;
		}
		elsif (my $mime_type = $self->request->representation)
		{
			return 1 if ($mime_type =~ /^text\/.*/i
				or $mime_type =~ /^directory\/.*/i
				or $mime_type =~ /^application\/gopher\+?\-menu/i);
		}
	}

	return 1 if (defined $self->request->item_type
		and $self->request->item_type eq TEXT_FILE_TYPE
			|| $self->request->item_type eq GOPHER_MENU_TYPE
			|| $self->request->item_type eq HTML_FILE_TYPE
			|| $self->request->item_type eq MIME_FILE_TYPE);
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
administrator, followed by the error message itself on the following lines,[7]
all of which are returned by this method as a single string. To get the
individual elements of a Gopher+ error, use C<error_code()>, C<error_admin()>,
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

	unless ($self->{'error_code'})
	{
		$self->_exract_error || return
	}

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

	unless ($self->{'error_admin'})
	{
		$self->_exract_error || return
	}

	return @{ $self->{'error_admin'} } if (ref $self->{'error_admin'});
}





#==============================================================================#

=head2 error_message()

This method returns the Gopher+ error message if present, undef otherwise.

=cut

sub error_message
{
	my $self = shift;

	return unless ($self->is_error);

	unless ($self->{'error_message'})
	{
		$self->_exract_error || return
	}

	return $self->{'error_message'};
}







################################################################################
# 
# The following subroutines are private methods:
# 

sub _add_raw
{
	my ($self, $buffer) = @_;

	$self->{'raw_response'} .= $buffer if (defined $buffer);
}





sub _add_content
{
	my ($self, $buffer) = @_;

	$self->{'content'} .= $buffer if (defined $buffer);
}





sub _unescape_periods
{
	my $self = shift;

	return unless (defined $self->content);

	my $unescaped_periods = $self->{'content'} =~ s/^\.\././gm;

	$self->debug_print(
		sprintf('Unescaped %d escaped %s in the response content.',
			$unescaped_periods,
			($unescaped_periods == 1) ? 'period' : 'periods'
		)
	);
}





sub _convert_newlines
{
	my $self = shift;

	return unless (defined $self->content);

	my $converted = convert_newlines($self->{'content'});

	$self->debug_print(
		sprintf('Converted %d %s in the response content.',
			$converted,
			($converted == 1) ? 'line ending' : 'line endings'
		)
	);
}





################################################################################
#
#	Method
#		_exract_blocks()
#
#	Purpose
#		This method parses the information blocks in $self->content
#		into Net::Gopher::Response::InformationBlock objects and stores
#		them in $self->{'_blocks'}, where $self->{'_blocks'} is a
#		reference to an array and each element in the array is a
#		reference to a array containing the block objects for a single
#		item.
#
#	Parameters
#		None.
#

sub _exract_blocks
{
	my $self = shift;

	# For Gopher+ item attribute information requests, the
	# $self->{'_blocks'} array will only contain one element (for the
	# single item's block objects). But for Gopher+ directory attribute
	# information requests, since they retrieve attribute information
	# blocks for every item in a directory, the array will contain multiple
	# elements:
	$self->{'_blocks'} = [];

	my $raw_response = $self->raw_response;

	# remove the status line:
	strip_status_line($raw_response) if ($self->is_gopher_plus);

	# remove the terminating period on a line by itself:
	strip_terminator($raw_response) if ($self->is_terminated);

	# remove the leading + for the first block name:
	$raw_response =~ s/^\+// or return $self->call_die(
		'There was no leading "+" for the first block name at the ' .
		'beginning of the response. The response either does not ' .
		'contain any attribute information blocks or contains ' .
		'malformed attribute information blocks.'
	);

	# this will store the Net::Gopher::Response::InformationBlock objects
	# for each item, one at a time. Each time we encounter the start of
	# another item's blocks, we save @blocks to $self->{'_blocks'} and
	# empty it:
	my @blocks;
	my %seen;

	# the start of block is denoted by a + at the beginning of a line:
	foreach my $name_and_value (split(/$NEWLINE_PATTERN\+/, $raw_response))
	{
		# get the newline/space separated name and value:
		my ($name, $raw_value) =
			split(/ |\015\012|\015|\012/, $name_and_value, 2);

		# block names are usually postfixed with colons:
		$name =~ s/:$//;

		my $value = $raw_value;

		# convert the newlines in the "pure" block value like we did
		# for the response content, but leave the original endings
		# intact for the "raw" value:
		convert_newlines($value);

		# each line of a block value contains a leading space, so we
		# strip the leading spaces for the "pure" value but leave
		# them intact for the "raw" value:
		$value =~ s/^ //mg;

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
		$seen{$name} = 1;
	}

	# add the last item's attribute information block objects to the list:
	push(@{ $self->{'_blocks'} }, [ @blocks ]);

	return 1;
}





################################################################################
#
#	Method
#		_exract_error()
#
#	Purpose
#		This method parses $self->error and attempts to extract a
#		Gopher+ error message containing an error code, administrator
#		contact information, and an error message. It stores them in
#		$self->error_code, $self->error_admin, and $self->error_message
#		respectively.
#
#	Parameters
#		None.
#

sub _exract_error
{
	my $self = shift;

	if ($self->error =~ /^(\d+) *(.*?) *<(.*?)>\n(?s)(.*)/)
	{
		$self->{'error_code'}    = $1;
		$self->{'error_admin'}   = [$2, $3];
		$self->{'error_message'} = $4;
	}
	else
	{
		return $self->call_die(
			'The response either does not a contain a Gopher+ ' .
			'error or it contains a malformed Gopher+ error.'
		)
	}
}





################################################################################
#
#	Method
#		_find_item_blocks($item)
#
#	Purpose
#		This method searchs $self->{'_blocks'} for an item either by
#		number (e.g., "2" for the second item) or by a template
#		describing the item, and returns an array containing every
#		single block object from the specified item. The template
#		parameters are described above in the POD for get_block().
#
#	Parameters
#		$item - Either a number specifying the n'th item or a reference
#		        to a hash or an array contaiing named parameters
#		        describing the item wanted (see get_block()).
#

sub _find_item_blocks
{
	my $self = shift;
	my $item = shift;


	my $item_wanted_from;
	if (ref $item)
	{
		my ($n, %template);
		($n,
		 $template{'item_type'}, $template{'display'},
		 $template{'selector'}, $template{'host'},
		 $template{'port'}, $template{'gopher_plus'}) =
		 	check_params([qw(
				N
				ItemType
				Display
				Selector
				Host
				Port
				GopherPlus
			)], $item
		);



		# If an item number was specified, then we'll only check that
		# item against the template. Otherwise, we'll check each item
		# against the template looking for one that matches:
		my @items_to_search;
		if ($n)
		{
			my $number_of_items = scalar @{ $self->{'_blocks'} };
			return $self->call_die(
				sprintf('There %s only %d %s in the ' .
				        'response.You specified item %d, ' .
					'which does not exist.',
					($number_of_items == 1) ? 'is' : 'are',
					$number_of_items,
					($number_of_items == 1) ?'item':'items',
					$n
				)
			) if ($n > $number_of_items);

			@items_to_search = $self->{'_blocks'}[$n - 1];	
		}
		else
		{
			@items_to_search = @{ $self->{'_blocks'} };
		}

		# now search the items looking for the first item that
		# matches:
		foreach my $item (@items_to_search)
		{
			my $info_block = $$item[0];

			# skip it if there was no +INFO block:
			next unless ($info_block and $info_block->name eq '+INFO');

			# parse the item's +INFO block:
			my @values = $info_block->extract_description or next;

			# we'll use these keys to build a hash containing
			# values from the +INFO block, then use them again to
			# compare the values hash against the template hash:
			my @keys = qw(
				item_type display selector host port gopher_plus
			);

			my %values;
			foreach my $key (@keys)
			{
				$values{$key} = shift @values;
			}

			# We assume the item matches. It's only when user
			# specifies certain parameters in the template and
			# those parameters don't match the corresponding fields
			# in the +INFO block that the item doesn't match:
			my $does_not_match;
			foreach my $key (@keys)
			{
				next unless (defined $template{$key});

				# check the value against the template:
				if (ref $template{$key} eq 'Regexp')
				{
					unless ($values{$key} =~ $template{$key})
					{
						$does_not_match++;
						last;
					}
				}
				else
				{
					unless ($values{$key} eq $template{$key})
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
			$item_wanted_from = $item;
			last;
		}
	}
	else
	{
		my $number_of_items = scalar @{ $self->{'_blocks'} };
		return $self->call_die(
			sprintf('There %s only %d %s in the response. You ' .
			        'specified item %d, which does not exist.',
				($number_of_items == 1) ? 'is' : 'are',
				$number_of_items,
				($number_of_items == 1) ? 'item' : 'items',
				$item
			)
		) if ($item > $number_of_items);

		my $i = $item - 1;
		$item_wanted_from = $self->{'_blocks'}[$i]; 
	}

	return unless ($item_wanted_from);

	return @$item_wanted_from;
}

1;

__END__

=head1 FOOTNOTES

[1] I<See> Anklesaria et al., I<RFC 1436: The Internet Gopher Protocol> 3,
available at gopher://gopher.floodgap.com/0/gopher/tech/RFC-1436 (Mar. 1993)
[hereinafter I<RFC 1436>].

[2] I<See> Anklesaria et al.,
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol> §
2.3, available at gopher://gopher.floodgap.com/0/gopher/tech/Gopher+ (Jul.
1993) [hereinafter I<Gopher+>].

[3] I<Id>.

[4] I<Id>.

[5] I<See RFC 1436>, supra note 1, at 4-5 and 13.

[6] I<See Gopher+>, supra note 2, § 2.5.

[7] I<See Gopher+>, supra note 2, § 2.3.

=head1 BUGS

Bugs in this package can reported and monitored using CPAN's request
tracker: rt.cpan.org.

If you wish to report bugs to me directly, you can reach me via email at
<william_g_davis at users dot sourceforge dot net>.

=head1 SEE ALSO

L<Net::Gopher|Net::Gopher>,
L<Net::Gopher::Response::MenuItem|Net::Gopher::Response::MenuItem>,
L<Net::Gopher::Response::InformationBlock|Net::Gopher::Response::InformationBlock>

=head1 COPYRIGHT

Copyright 2003 by William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
