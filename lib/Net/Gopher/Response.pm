
package Net::Gopher::Response;

=head1 NAME

Net::Gopher::Response - Class encapsulating Gopher responses

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 my $response = $gopher->request($selector, Type => $type);
 
 if ($response->is_success) {
 	if ($response->is_menu) {
 		# you can use as_menu() to parse Gopher menus:
 		my @items = $response->as_menu;
 		foreach my $item (@items) {
 			print join("::",
 				$item->{'type'}, $item->{'text'},
 				$item->{'selector'}, $item->{'host'},
 				$item->{'port'}, $item->{'gopher_plus'}
 			), "\n";
 		}
 	}
 
 	if ($response->is_blocks) {
 		my $info_block = $response->as_info_block;
 
 		print join("::",
 			$info_block->{'type'}, $info_block->{'text'},
 			$info_block->{'selector'}, $info_block->{'host'},
 			$info_block->{'port'}, $info_block->{'gopher_plus'}
 		), "\n";
 
 		my $admin_block = $response->as_admin_block;
 
 		print "Maintained by $admin_block->{'Admin'}[0] ",
 		      "who can be emailed at $admin_block->{'Admin'}[1]\n";
 	}
 } else {
 	 print $response->error;
 }
 ...

=head1 DESCRIPTION

Both the L<Net::Gopher|Net::Gopher> C<request()> and C<request_url()> methods
return B<Net::Gopher::Response> objects. These objects encapsulate responses
from Gopher and Gopher+ servers.

In Gopher, a response is just a series of bytes terminated by a period on a
line by itself. In Gopher+, a response consists of a status line, (the first
line) of which the first character is the status (success or failure; + or -),
followed by a newline (CRLF), and the content of the response. This class
contains methods to help you manipulate both Gopher as well as Gopher+
responses.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use Carp;
use Time::Local;
use Net::Gopher::Utility qw($CRLF $NEWLINE);







sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;
	my %args  = @_;
	
	# remove the socket class name from error messages (IO::Socket
	# puts them in):
	if (defined $args{'Error'})
	{
		$args{'Error'} =~ s/IO::Socket::INET:\s//g;
	}

	my $self = {
		# any error that occurred while sending the request or while
		# receiving the response:
		error       => $args{'Error'},

		# the request that was sent to the server:
		request     => $args{'Request'},

		# the entire response, every single byte:
		response    => $args{'Response'},

		# the first line of the response including the newline (only
		# in Gopher+):
		status_line => $args{'StatusLine'},

		# the status code (+ or -) (only in Gopher+):
		status      => $args{'Status'},

		# content of the response:
		content     => $args{'Content'},

		# if this was a Gopher+ item/directory attribute information
		# request, then this will be used to store the parsed
		# information blocks:
		blocks      => undef
	};

	bless($self, $class);
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
requested was a text file, then escaped periods are unescaped (i.e., '..' at
the start of a line becomes '.'). Also, if response was terminated by a period
on a line by itself but it isn't a text file or menu, then the period on a line
by itself will be removed from the content (though you can still check to see
if it was period terminated using the
L<is_terminated()|Net::Gopher::Response/is_terminated()> method). This is
because if you were requesting an image or some other non-text file (especially
in Gopher+), odds are you don't want the newline and period at the end the
content.

Note that in Gopher+, besides the modifications listed above, C<content()> does
not include the status line (first line) of the response (since the status line
isn't content).

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
context) or a reference to an array (in scalar context) containing hash refs as
its elements. Each hash contains the data for one menu item, and has the
following key=value pairs:

 type        = The item type (e.g., 0, 1, I, g, etc.);
 text        = The item description (e.g., "A file you should download");
 selector    = The selector string (e.g., /foo/bar);
 host        = The hostname (e.g., gopher.host.com);
 port        = The port number (e.g., 70);
 gopher_plus = The Gopher+ character (e.g., +, !, ?, etc.);

The array will only contain hash refs of items that list some type of resource
that can be downloaded; meaning that inline text ('i' item type) is skipped.

=cut

sub as_menu
{
	my $self = shift;

	# get each item:
	my @items = split(/$NEWLINE/, $self->{'content'});

	my @menu;
	foreach my $item (@items)
	{
		# skip it if it's not a menu item:
		next unless ($item =~ /\t/);

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

=head2 item_blocks([@block_names])

C<item_blocks()>, C<directory_blocks()>, and C<as_blocks()> allow you to parse
information blocks.

If the request was a Gopher+ item attribute information request, then you can
use method to parse the attribute information blocks in the server's response.
This method is a more simple alternative to the C<directory_blocks()> method.
Use this method when you make item attribute information requests (!) and
use C<directory_blocks()> when you make directory attribute information
requests ($).

This method can be used to retrieve item information block values by specifying
the block name or block names as arguments. If you don't supply any block
names, then this method will return a list containing every block name for the
item.

Thess methods strips leading '+' and trailing ':' from block names, so rather
than asking for '+INFO:', you should ask for just plain 'INFO'. These methods
will also strip the leading spaces from each line of a multiline block value.

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
 Text       = The item must have this description text.
 Selector   = The item must have this selector string.
 Host       = The item must be on this host.
 Port       = The item must be at this port.
 GopherPlus = The item must have this Gopher+ string.

So to get the VIEWS and ADMIN block values for the item with the selector of
/welcome, you'd do this:

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

Which means the VIEWS block value for the 7th item in the response, which must
have a selector string of /welcome, on gopher.somehost.com at port 70.

If you only want to specify the item by number, you can forgo the hash ref
altogether. So get the ADMIN block for the second item, you can just do
this:

 my $admin = $response->directory_blocks(2, 'ADMIN');

To get the names of all of the information blocks for a single item, don't
specify any block names, only a parameters hash or item number:

 my @block_names = $response->directory_blocks({
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

This method will return undef if it couldn't find any of the blocks you
specified, or if the item you specified does not exist.

=cut

sub directory_blocks
{
	my $self        = shift;
	my $item_to_get = shift;
	my @block_names = @_;

	$self->_parse_blocks() unless (defined $self->{'blocks'});

	if (defined $item_to_get and ref $item_to_get)
	{
		my %match;
		if (ref $item_to_get eq 'ARRAY')
		{
			%match = @$item_to_get;
		}
		else
		{
			%match = %$item_to_get;
		}

		# a reference to hash contaiing the block names and values
		# for the item the user specified:
		my $matching_item;

		# the items to search:
		my @items = $match{'N'}
				? $self->{'blocks'}[$match{'N'} - 1]
				: @{ $self->{'blocks'} };

		# now search the items looking for the one that matches:
		foreach my $item (@items)
		{
			my %info = $self->as_info_block($item->{'INFO'});

			if (defined $match{'Type'})
			{
				unless ($info{'type'} eq $match{'Type'})
				{
					next;
				}
			}
			if (defined $match{'Text'})
			{
				unless ($info{'text'} eq $match{'Text'})
				{
					next;
				}
			}
			if (defined $match{'Selector'})
			{
				unless ($info{'selector'} eq $match{'Selector'})
				{
					next;
				}
			}
			if (defined $match{'Host'})
			{
				unless ($info{'host'} eq $match{'Host'})
				{
					next;
				}
			}
			if (defined $match{'Port'})
			{
				unless ($info{'port'} eq $match{'Port'})
				{
					next;
				}
			}
			if (defined $match{'GopherPlus'})
			{
				unless ($info{'gopher_plus'} eq $match{'GopherPlus'})
				{
					next;
				}
			}

			# it matches:
			$matching_item = $item;
			last;
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
	elsif (defined $item_to_get)
	{
		my $i = $item_to_get - 1;

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

This method can be used to directly get all of the information blocks at once.
If you made a directory attribute information request, then the blocks are
stored in an array, where each element of the array is reference to a hash
containing block names and block values for a single item. In list context this
method will return the array and in scalar context it will return a reference
to the array:

 my @items = $response->as_blocks;
 
 # INFO block for the second item:
 my %info = $response->as_info_block($items[1]{'INFO'});

 print "Type: $info{'type'}\n",
       "Description: $info{'text'}\n",
       "Selector: $info{'selector'}\n",
       "On: $info{'host'}\n",
       "Port: $info{'port'}\n";

If you made an item attribute information request, then the block
names and values for the single item are stored in a hash, and the hash is
returned in list context, and a reference to the hash is returned in scalar
context:

 my %blocks = $response->as_blocks;
 
 # ADMIN block for the only item:
 my %admin = $response->as_admin_block($blocks{'ADMIN'});

 print "Run by $admin{'Admin'}[0] (contact: $admin{'Admin'}[1]).\n";

=cut

sub as_blocks
{
	my $self = shift;

	$self->_parse_blocks() unless (defined $self->{'blocks'});

	# Since $self->{'blocks'} contains an array of references to hashes, we
	# can't just return one or more of those reference because then when
	# the user tried to modify any of the item blocks they received, they'd
	# end up modifying the copies stored in $self->{'blocks'} too. So we'll
	# create a copy of $self->{'blocks'} with references to anonymous
	# hashes containing the same values as those in $self->{'blocks'}:
	my @blocks;
	foreach my $item (@{ $self->{'blocks'} })
	{
		push(@blocks, { %$item });
	}

	if (@blocks == 1)
	{
		if (wantarray)
		{
			return %{ $blocks[0] };
		}
		else
		{
			return $blocks[0];
		}
	}
	else
	{
		if (wantarray)
		{
			return @blocks;
		}
		else
		{
			\@blocks;
		}
	}
}





#==============================================================================#

=head2 as_admin_block([$block_value])

ADMIN blocks contain information about the person running the Gopher+ server
and what the admin has done with the item in question. This method takes a
string containing an ADMIN block value as its only argument, parses the ADMIN
block, and returns a hash (in list context) or a reference to a hash (in scalar
context) with (at least) two key=value pairs: Admin and Mod-Date.

Admin attributes contain strings in the form of "John Doe <jdoe@fake.email>"
about who the administrator of the Gopher+ server is. This method will parse
Admin attributes and turn them into a reference to a two-element array
containing the name and email in that order.

Mod-Date is a timestamp of when the item was last modified. This method will
convert the timestamp into an array containing values in the same format as
those returned by Perl's C<localtime()> function corresponding with the
Mod-Date timestamp (to find out exactly what the array will contain, see
C<perldoc -f localtime>):

 my %admin = $response->as_admin_block($response->item_blocks('ADMIN'));
 
 my ($name, $email) = @{ $admin{'Admin'} }
 print "This box is maintained by $name ($email).";
 
 my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
 @{ $admin{'Mod-Date'} };

The hash may also contain Abstract, Version, Org, Loc or other attributes--all
of which are stored as in the hash as plain text.

If you don't supply a block value, then this method will call
item_blocks('ADMIN') and try to use that instead.

=cut

sub as_admin_block
{
	my $self  = shift;
	my $block = shift;

	$block = $self->item_blocks('ADMIN') unless (defined $block);

	# ADMIN blocks contain two attributes, Admin and
	# Mod-Date, in the form of:
	# 
	#   Admin: Foo Bar <foobar@foo.com>
	#   Mod-Date: WWW MMM DD hh:mm:ss YYYY <YYYYMMDDhhmmss>
	# 
	# first, get the Admin, Mod-Date, and any other
	# attributes in the form of a hash:
	my %attributes;
	foreach my $attribute (split(/$NEWLINE/, $block))
	{
		# get the "Name: value" attribute:
		my ($name, $value) = $attribute =~ /^(.+?):\s?(.*)/;

		$attributes{$name} = $value;
	}


	if (exists $attributes{'Admin'})
	{
		# now for the Admin attribute, get the admin name and email:
		my ($name, $email) =
			$attributes{'Admin'} =~ /(.+?)\s*<(.*?)>\s*/;


		$attributes{'Admin'} = [$name, $email];
	}

	if (exists $attributes{'Mod-Date'})
	{
		# now for the Mod-Date attribute, get the values from the
		# timestamp:
		my ($year, $month, $day, $hour, $minute, $second) =
			$attributes{'Mod-Date'} =~
				/<(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})>/x;

		foreach($year, $month, $day, $hour, $minute, $second)
		{
			carp "Couldn't parse timestamp" unless (defined $_);
		}

		# We need to convert the year value into the  number years
		# since 1900 (i.e., 2003 -> 103), since that's the format
		# returned by localtime():
		$year -= 1900;

		# localtime() months are numbered from 0 to 11, not 1 to 12:
		$month--;

		# now that we have the second, minute, hour, day, month, and
		# year, we use them to get a corresponding time() value:
		my $time = timelocal(
			$second, $minute, $hour, $day, $month, $year
		);

		# now use the time() value to get the values we still don't
		# have (e.g., the day of the year, is it daylight savings time?
		# etc.) and store them in the Mod-Date attribute value:
		$attributes{'Mod-Date'} = [ localtime $time ];
	}



	if (wantarray)
	{
		return %attributes;
	}
	else
	{
		return \%attributes;
	}
}





#==============================================================================#

=head2 as_ask_block([$block_value])

ASK blocks contain a form to be filled out by the user, with ASK queries on
lines by themselves consisting of query type, followed by the question and any
default values separated by tabs (e.g., "Ask: Some question?\tdefault
answer 1\tdefault answer 2", "Choose: A question?choice 1\tchoice 2\tchoice3").

This method takes an ASK block in a string as its only argument and parses the
ASK block and will return an array (in list context) or a reference to an
array (in scalar context) containing hash refs of each query in the order
they appeared, with each hash having the following key=value pairs:

 type     = The type of query (e.g, Ask, AskP, Select, Choose, etc.).
 question = The question.
 defaults = A reference to an array containing the default answers.

If you don't supply a block value, then this method will call
item_blocks('ASK') and try to use that instead.

=cut

sub as_ask_block
{
	my $self  = shift;
	my $block = shift;

	$block = $self->item_blocks('ASK') unless (defined $block);



	# ASK blocks contain Gopher+ queries which are to be filled out by the
	# user. Each ASK query has a type, followed by a quetion and optional
	# defaults separated by tabs. For example:
	#    Ask: How many?\tone\ttwo\tthree
	#    AskP: Your password:
	#    Choose: Pick one:\tred\tgreen\tblue
	#    
	# This will store each ASK query as a hashref containing the query
	# type, the question and any defaults:
	my @ask;

	foreach my $query (split(/$NEWLINE/, $block))
	{
		# get the query type, and the question and default values:
		my ($type, $question_and_defaults) = $query =~ /^(\S+)+:\s?(.*)/;

		# the question and any default values are all tab separated:
		my ($question, @defaults) = split(/\t/, $question_and_defaults);

		push(@ask, {
				type     => $type,
				question => $question,
				defaults => (@defaults)
						? \@defaults
						: undef
			}
		);	
	}



	if (wantarray)
	{
		return @ask;
	}
	else 
	{
		return \@ask;
	}
}





#==============================================================================#

=head2 as_info_block([$block_value])

This method takes an INFO block value as its only argument, parses it, and
returns a hash (in list context) or a reference to a hash (in scalar context)
containing the information from the tab delimited fields in the same format
described above (see L<as_menu()|Net::Gopher::Response/as_menu()>). So you can
use it like this:

 my %info = $response->as_info_block($response->item_blocks('INFO'));
 
 print "Item type: $info{'type'};\n",
       "Item description: $info{'text'};\n",
       "Selector: $info{'selector'};\n",
       "On: $info{'host'};\n",
       "At: $info{'port'};\n";

If you don't supply a block value, then this method will call
item_blocks('INFO') and try to use that instead.

=cut

sub as_info_block
{
	my $self  = shift;
	my $block = shift;

	$block = $self->item_blocks('INFO') unless (defined $block);



	my $info = $self->_get_item_hashref($block);

	if (wantarray)
	{
		return %$info;
	}
	else
	{
		return $info;
	}
}





#==============================================================================#

=head2 as_views_block([$block_value])

VIEWS blocks contain information about what type of applications can be used
to view the item, the total size of the item, and sometimes a language as well
(e.g., text/plain En_US: <77K>).

This method takes a string containing a VIEWS block as its only argument,
parses it, and returns an array (in list context) or a reference to an array
(in scalar context) containing each view in the form of a hash ref with the the
following key=value pairs:

 type     = The MIME type (e.g., text/plain, application/gopher+-menu, etc.).
 language = The ISO 639 language code (e.g., En_US).
 size     = The size in bytes.

Note that this method will convert the <\d+K?> size format used in Gopher+ to
an integer; the total size in bytes (e.g., <80> becomes 80, <40K> becomes
40000, <.4K> becomes 400, <400B> becomes 400, etc.):

 my @views = $response->as_views_block($response->item_blocks('VIEWS'));
 
 foreach my $view (@views) {
 	print "$view->{'type'} ($view->{'size'} bytes) ($type->{'language'})\n";
 }

If you don't supply a block value, then this method will call
item_blocks('VIEWS') and try to use that instead.

=cut

sub as_views_block
{
	my $self  = shift;
	my $block = shift;

	$block = $self->item_blocks('VIEWS') unless (defined $block);



	# Views blocks contain attributes in the form of
	# "MIME-type lang: <size>" (e.g., "text/plain En_US: <10K>."). This
	# array will store each view as a hashref:
	my @views;

	foreach my $view (split(/$NEWLINE/, $block))
	{
		# separate the MIME type, language, and size:
		my ($mime_type, $lang, $size) =
			$view =~ /^([^:]*?) (?: \s ([^:]{5}) )?:(.*)$/x;

		if (defined $size and $size =~ /<(\.?\d+)(?:(k)|b)?>/i)
		{
			# turn <55> into 55, <600B> into 600, <55K> into 55000,
			# and <.5K> into 500:
			$size  = $1;
			$size *= 1000 if ($2);
		}

		push(@views, {
				type     => $mime_type,
				language => $lang,
				size     => $size
			}
		);
	}



	if (wantarray)
	{
		return @views;
	}
	else
	{
		return \@views;
	}
}





#==============================================================================#

=head2 is_success()

This method will return true if the request was successful, false otherwise.
First, weather it's a Gopher or Gopher+ request, it won't be "successful" if
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

	if (defined $self->{'status'})
	{
		if ($self->{'status'} eq '+')
		{
			return 1;
		}
		else
		{
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





#==============================================================================#

=head2 is_error()

This method will return true if the request was unsuccessful; false otherwise.
Success and failure are the same as described above
(see L<is_success()|Net::Gopher::Response/is_success()>).

=cut

sub is_error
{
	my $self = shift;

	if (defined $self->{'status'})
	{
		if ($self->{'status'} eq '-')
		{
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





#==============================================================================#

=head2 is_blocks()

This method will return true if the response contains item attribute
information blocks; false otherwise.

=cut

sub is_blocks
{
	my $self = shift;

	if ($self->{'content'} =~ /^(?:\+\S+\s.*?) (?:$NEWLINE\+\S+ \s .*?)*$/sx)
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

This method will return true if the response is a Gopher menu which can be
parsed with as_menu(); false otherwise.

=cut

sub is_menu
{
	my $self = shift;

	my $field = qr/[^\t\012\015]*?/;
	my $item  = qr/$field\t$field\t$field\t$field (?:\t[\+\!\?\$])?/x;

	if ($self->{'content'} =~
		/^$item (?:$NEWLINE $item)*
		 (?:$NEWLINE\.$NEWLINE?|$NEWLINE)? $/x)
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

	if ($self->{'content'} =~ /$NEWLINE\.$NEWLINE?$/)
	{
		return 1;
	}
	else
	{
		return;
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
#		_get_item_hashref($item)
#
#	Purpose
#		This method parses an item in a Gopher menu and extracts the
#		item type, item description, selector string, host, port, and
#		Gopher+ character. It returns a reference to hash with the
#		following keys: "type"; "text"; "selector"; "host"; "port"; and
#		"gopher_plus".
#
#	Parameters
#		$item - A string containing the menu item.
#

sub _get_item_hashref
{
	my $self = shift;
	my $item = shift;

	# get the item type and description text, selector, host, port, and
	# Gopher+ string:
	my ($type_and_text, $selector, $host, $port, $gopher_plus) =
		split(/\t/, $item);

	# now we need to separate the item type and the item description:
	my ($type, $text) = $type_and_text =~ /^(.)(.*)/;

	foreach ($type, $text, $selector, $host, $port)
	{
		carp "Couldn't parse menu item" unless (defined $_);
	}

	my $item_hash = {
		type        => $type,
		text        => $text,
		selector    => $selector,
		host        => $host,
		port        => $port,
		gopher_plus => $gopher_plus
	};

	return $item_hash;
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
	my $content = $self->{'content'};

	# $self->{'blocks'} will contain a reference to an array which
	# will have hashrefs as its elements. Each hash will contain the item
	# attribute information block names and block values for a single item.
	# For Gopher+ '!' requests, the $self->{'blocks'} array will only
	# contain one element (for the single item's blocks). But for
	# Gopher+ '$' requests, since $ retrieves item attribute information
	# blocks for every item in a directory, the array will contain multiple
	# elements:
	$self->{'blocks'} = [];

	# Each block name is denoted by '+' as the first character at the start
	# of line. Any characters after the plus and up to the first space is
	# the block name, and everything after the first space is the value.
	if ($self->is_terminated)
	{
		$content =~ s/$NEWLINE\.$NEWLINE?$//;
	}

	# remove all leading whitespace and the leading + for the first block
	# name:
	$content =~ s/^\s*\+//;

	# this will store the block names and block values for each item, one
	# at a time:
	my %blocks;

	foreach my $name_and_value (split(/$NEWLINE\+/, $content))
	{
		# get the space separated name and value:
		my ($name, $value) = $name_and_value =~ /(\S+)\s(.*)/s;

		# block names are usually postfixed with colons:
		$name =~ s/:$//;

		# now remove the leading spaces from each attribute:
		$value =~ s/($NEWLINE)\s/$1/g;

		# block values with multiple attributes often start with the
		# first attribute on the next line with a leading space, so
		# we remove the leading newline:
		$value =~ s/^$NEWLINE//;

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



		$blocks{$name} = $value;
	}

	# add the last item's attribute information blocks:
	push(@{ $self->{'blocks'} }, { %blocks });
}

1;

__END__

=head1 BUGS

If you encounter bugs, you can alert me of them by emailing me at
<william_g_davis at users dot sourceforge dot net> or, if you have PerlMonks
account, you can go to perlmonks.org and /msg me (William G. Davis).

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
