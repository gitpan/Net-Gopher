
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
 	print "type: $item[0]{'type'}\n",
 	      "description: $item[0]{'text'}\n";
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

=cut

use 5.005;
use strict;
use warnings;
use vars qw($VERSION);
use Carp;
use Time::Local;
use Net::Gopher::Utility qw($CRLF $NEWLINE);

$VERSION = '0.28';





sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;
	my %args  = @_;

	my $self = {
		# any error that occurred while sending the request or while
		# receiving the response:
		error       => $args{'Error'},

		# the request that was sent to the server:
		request     => $args{'Request'},

		# entire response, every single byte:
		response    => $args{'Response'},

		# the first line of the response including the newline (only
		# in Gopher+):
		status_line => $args{'StatusLine'},

		# the status code (+ or -) (only in Gopher+):
		status      => $args{'Status'},

		# content of the response (same as response except in Gopher+,
		# where it's everything after the status line):
		content     => $args{'Content'},

		# if this was a Gopher+ item attribute information request
		# then this will be used to store the parsed information
		# blocks:
		blocks      => undef
	};

	bless($self, $class);
	return $self;
}





#==============================================================================#

=head2 status_line()

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

=head2 status()

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

=head2 content()

For a Gopher+ request, if the request was successful, this method will return
the content of the response (everything after the status line). For a Gopher
request, this just returns the same thing as the as_string() method does.

=cut

sub content
{
	my $self = shift;
	
	return $self->{'content'};
}





#==============================================================================#

=head2 as_string()

For both Gopher as well as Gopher+ requests, if the request was successful,
then this method will return the entire response, every single byte, from the
server. This includes the status line in Gopher+.

=cut

sub as_string
{
	my $self = shift;

	return $self->{'response'};
}





#==============================================================================#

=head2 as_menu()

If you got a Gopher menu as your response from the server, then you can use
this method to parse it and return its values. When called, this method will
parse the content returned by content() and return either an array (in list
context) or a reference to an array (in scalar context) containing hashrefs as
its elements. Each hash contains the data for one menu item, and has the
following keys:

 type     = The item type (e.g., 0, 1, I, s, etc.);
 text     = The item description (e.g., "A file you should download");
 selector = The selector string (e.g., /foo/bar);
 host     = The hostname (e.g., gopher.host.com);
 port     = The port number (e.g., 70);
 gopher+  = The Gopher+ character (e.g., +, !, ?, etc.);

The array will only contain hashrefs of items that list some type of resource
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

=head2 as_block([@block_names])

If the request was a Gopher+ item attribute information request, then you can
use method to parse the attribute information blocks in the server's response.
This method can be used to retrieve the content if a block by specifying the
block name or block names as arguments. If you don't supply any block names
then this method will return a list containing every block name. This method
strips leading '+' and trailing ':' from block names, so rather than asking for
'+INFO:' you should ask for just plain 'INFO'. This method will also strip
leading spaces from each line of a block value. For most blocks, this method
will just return the text of the block value. This is because the only block
values who's formats have been officially defined are INFO, ADMIN, and VIEWS,
and it would therefor be presumptuous for this method to attempt to parse them.
However, since the format of INFO, ADMIN, and VIEWS block values have been
officially defined, this method will parse those. What does it do to INFO,
ADMIN and VIEWS blocks? Well, since INFO blocks contain tab separated item
information just like you find in a menu, this method will parse the INFO block
value and create hash in the same format as the one described above
(L<as_menu()>), so you can use it like this:

 my $info = $response->as_block('INFO');
 
 print "Type: $info->{'type'}\n",
       "Description: $info->{'text'}\n",
       "On: $info->{'host'}\n",
       "At: $info->{'port'}\n";

ADMIN blocks contain information about the person running the Gopher+ server
and what the admin has done with the item in question. This method will
parse ADMIN blocks and create a hashref with (at least) two key=value pairs:
Admin and Mod-Date. Admin attributes contain strings in the form of
"John Doe <jdoe@fake.email>" about who the administrator of this Gopher+ server
is. This method will parse Admin attributes and turn them into a reference to
a two-pair hash with the keys 'name' and 'email', where 'name' contains the
name of the administrator and 'email' contains the email address. Mod-Date is a
timestamp of when the item was last modified. This method will convert the
timestamp into an array containing values in the same format as those returned by
Perl's localtime() function corresponding with the Mod-Date timestamp (to find
out exactly what the array will contain, see perldoc -f localtime):

 my $admin = $response->as_block('ADMIN');
 
 print "This box is maintained by $admin->{'Admin'}{'name'}",
       " who can be emailed at $admin->{'Admin'}{'email'}";
 
 my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
 @{ $admin->{'Mod-Date'} };

VIEWS blocks contain information about what type of applications can be used
to view the item as well as the total size of the item in bytes and sometimes a
language as well (e.g., text/plain En_US: <77K>). This method will parse VIEWS
block values and create an array containing each view in the form of a hashref
with the keys 'type', 'language', and 'size' and with the MIME type,
language, and size in bytes as the values respectively. Note, this
method converts the <\d+K?> format used in Gopher+ to an integer you can
perform arithmetic on (e.g., <80> becomes 80, <40K> becomes 40000, etc.):

 my $views = $response->as_block('VIEWS');
 
 foreach my $view (@$views)
 {
 	print "$view->{'type'} ($view->{'size'} bytes) ($type->{'language'})\n";
 }

=cut

sub as_block
{
	my $self        = shift;
	my @block_names = @_;

	$self->_parse_blocks() unless (defined $self->{'blocks'});

	if (@block_names)
	{
		return @{ $self->{'blocks'} }{@block_names};
	}
	else
	{
		return sort keys %{ $self->{'blocks'} };
	}
}





sub _parse_blocks
{
	my $self    = shift;
	my $content = $self->{'content'};

	# Each block name is denoted by '+' as the first character on a line.
	# Any characters after the plus and up to the first space is the block
	# name, and everything after the space is the value.
	if ($self->is_terminated)
	{
		$content =~ s/$NEWLINE\.$//;
	}

	# remove all leading whitespace and the leading + for the first block
	# name:
	$content =~ s/^\s*\+//;

	my %blocks;
	foreach my $name_and_value (split(/$NEWLINE\+/, $content))
	{
		# get the space separated name and value:
		my ($name, $value) = $name_and_value =~ /(\S+)\s(.*)/s;

		#print "##$name\n";
		# block names are always postfixed with colons:
		$name =~ s/:$//;

		# now remove the leading spaces from each attribute:
		$value =~ s/($NEWLINE)\s/$1/g;

		# block values with multiple attributes often start with the
		# first attribute on the next line with a leading space, so
		# we remove the leading newline:
		$value =~ s/^$NEWLINE//;

		$blocks{$name} = $value;
	}
	
	if (exists $blocks{'INFO'})
	{
		# info blocks get turned into hashrefs like the items
		# in the array returned by as_menu():
		$blocks{'INFO'} = $self->_get_item_hashref($blocks{'INFO'});
	}

	if (exists $blocks{'VIEWS'})
	{
		# Views blocks contain attributes in the form of "MIME-type
		# lang: <size>" (e.g., "text/plain En_US: <10K>.").
		my @views = split(/$NEWLINE/, $blocks{'VIEWS'});

		# This block value is eventually going to contain an
		# array of views, with each view represented as hashref
		# containing the MIME type, language, and size:
		foreach my $view (@views)
		{
			# separate the MIME type, language, and size:
			my ($mime_type, $lang, $size) =
				$view =~ /^([^:]*?) (?: \s ([^:]{5}) )?:(.*)$/x;

			if ($size and $size =~ /<(\.?\d+)(k)?>/i)
			{
				# turn <55> into 55, <55K> into 55000,
				# and <.5K> into 500:
				$size  = $1;
				$size *= 1000 if ($2);
			}

			$view = {
				type     => $mime_type,
				language => $lang,
				size     => $size
			}
		}

		$blocks{'VIEWS'} = \@views;
	}

	if (exists $blocks{'ADMIN'})
	{
		# ADMIN blocks contain two attributes, Admin and Mod-Date, in
		# the form of:
		# 
		# 	Admin: Foo Bar <foobar@foo.com>
		# 	Mod-Date: WWW MMM DD hh:mm:ss YYYY <YYYYMMDDhhmmss>

		# first, get all of the attributes in the form of a hash ref:
		my $attributes =
			$self->_get_attribute_hashref($blocks{'ADMIN'});

		# now for the Admin attribute, get the admin name and email:
		my ($name, $email) =
			$attributes->{'Admin'} =~ /(.+?)\s*<(.*?)>\s*/;

		# save them:
		$attributes->{'Admin'} = {
			name  => $name,
			email => $email
		};

		# now for the Mod-Date attribute, get the values from the
		# timestamp:
		my ($year, $month, $day, $hour, $minute, $second) =
			$attributes->{'Mod-Date'} =~
				/<(\d{4})(\d{2})(\d{2})
				  (\d{2})(\d{2})(\d{2})>/x;

		foreach ($year, $month, $day, $hour, $minute, $second)
		{
			carp "Couldn't parse timestamp" unless (defined $_);
		}

		# We need to convert the year value into the number years since
		# 1900 (i.e., 2003 -> 103), since that's the format returned by
		# localtime():
		$year -= 1900;

		# localtime() months are numbered from 0 to 11, not 1 to 12:
		$month--;

		# now that we have the second, minute, hour, day, month, and
		# year, we use them to get a corresponding Perl time() value:
		my $time = timelocal(
			$second, $minute, $hour, $day, $month, $year
		);

		# now use the time() value to get the values we still don't
		# have (e.g., the day of the year, is it daylight savings time?
		# Etc.) and store them in the Mod-Date attribute value:
		$attributes->{'Mod-Date'} = [ localtime $time ];

		# save all of the ADMIN attributes:
		$blocks{'ADMIN'} = $attributes;
	}

	$self->{'blocks'} = \%blocks;
}





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
		type      => $type,
		text      => $text,
		selector  => $selector,
		host      => $host,
		port      => $port,
		'gopher+' => $gopher_plus
	};

	return $item_hash;
}





sub _get_attribute_hashref
{
	my $self        = shift;
	my $block_value = shift;

	# get each "name: value" attribute:
	my @attributes = split(/$NEWLINE/, $block_value);

	my %block_attributes;
	foreach my $attribute (@attributes)
	{
		# get the "Name: value" attribute:
		my ($name, $value) = $attribute =~ /^(.+?):\s?(.*)/;

		$block_attributes{$name} = $value;
	}

	return \%block_attributes;
}





#==============================================================================#

=head2 is_success()

This method will return true if the request was successful, false otherwise.
First, weather it's a Gopher or Gopher+ request, it won't be "successful" if
any network errors occurred. Beyond that, in Gopher+, for a request to be a
"success" means that the status code returned by the server indicated success
(a code of +). In plain old Gopher, success is rather loosely defined.
Basically, since Gopher has no built-in uniform error-handling, as long as
some response was received from the server (even "An error has occurred" or
"The item you requested does not exist"), this method will return true. For
more accuracy with Gopher requests you can use the is_terminated() method. If
is_success() returns false, meaning an error has occurred, then you can obtain
the error message by calling the error() method on the Net::Gopher::Response
object.

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
Success and failure are the same as described above (L<is_success()>).

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

=head2 is_terminated()

This method checks if the response content was terminated by a period on a line
by itself. It returns true if the content is terminated by a period on a line
by itself; false otherwise,

=cut

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





#==============================================================================#

=head2 error()

This method returns the error message of the last error to occur or undef if no
error has occurred.

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

		# rather than returning undef like Net::Gopher, we return the
		# object since that's what the user will expect:
		return $self;
	}
	else
	{
		return $self->{'error'};
	}
}

1;

__END__

=head1 BUGS

Email any to me at <william_g_davis at users dot sourceforge dot net> or go
to perlmonks.com and /msg me (William G. Davis) and I'll fix 'em.

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
