
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
use Time::Local;
use Net::Gopher::Utility qw($CRLF $NEWLINE);

$VERSION = '0.21';





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
request, this just returns the same thing as the as_string() method does.

=cut

sub content
{
	my $self = shift;
	
	return $self->{'content'};
}





#==============================================================================#

=item as_string()

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

=item as_menu()

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
 gopher+  = The Gopher+ string if this item is on a Gopher+ server;

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

=item as_blocks()

If the request was a Gopher+ attribute information request then you can use
method to parse the attribute information blocks in the server's response. This
method will return a hash (in list context) or a reference to a hash (in scalar
context) with information block names as its keys and block values as its
values. Please note that this method strips trailing colons from block names
(e.g., ADMIN: becomes ADMIN). Also, it should be pointed out that since the
structure of block values often differ from server to server, this method won't
attempt to parse any blocks except for INFO, ADMIN, and VIEWS blocks, which
each Gopher+ server is mandated to return (and in the same format) by the
Gopher+ protocol. Since INFO blocks contain tab separated item information just
like you'd find in a menu, the value for 'INFO' will be a reference to another
hash, one in the format described above (L<as_menu()>):

 my %blocks = $response->as_blocks;
 
 print "Type: $blocks{'INFO'}{'type'}\n",
       "Description: $blocks{'INFO'}{'text'}\n",
       "On $blocks{'INFO'}{'host'}\n",
       "At $blocks{'INFO'}{'port'}\n";

VIEWS blocks contain information about what type of applications can be used
to view the item as well as the total size of the item in bytes
(e.g., Text/plain: <77K>). This method will turn a VIEWS block into a hashref
where the MIME type is the key and the value is the size in bytes. Note, this
method converts the <\d+K?> format used in Gopher+ to an integer you can
preform arathmatic on (e.g., <80> becomes 80, <40K> becomes 40000, etc.):

print "Size: ", $blocks{'VIEWS'}{'Text/plain'};

ADMIN blocks contain information about the person running the Gopher+ server
and what the admin has done with the item in question. This method will
parse ADMIN blocks and create a hashref with two key=value pairs: Admin and
Mod-Date. Admin contains a string in the form of "John Doe <jdoe@fake.email>"
about who the adminstrator of this Gopher+ server is. Mod-Date is a timestamp
of when the item was last modified, usually like the ones returned by C's
ctime(). This method will convert the timestamp into an array contaiing values
returned by Perl's localtime() function corresponding with the Mod-Date (see
L<perldoc -f localtime>):

 print "This box is maintained by ", $blocks{'ADMIN'}{'admin'};
 
 my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
 @{ $blocks{'ADMIN'}{'Mod-Date'} };

=cut

sub as_blocks
{
	my $self = shift;

	# remove the leading +:
	(my $blocks = $self->{'content'}) =~ s/[^+]*? \+//x;

	# get each block name and value:
	my @block_name_and_values = split(/\n\+/, $blocks);

	my %blocks;
	foreach my $block (@block_name_and_values)
	{
		# get the block name and block value (separated by the first
		# space):
		my ($name, $value) = $block =~ /(\S+)\s(.*)/s;

		# remove the colon that most block names contain:
		$name =~ s/:$//;

		if ($name =~ /^INFO$/)
		{
			# info blocks get turned into hashrefs like the items
			# in the array returned by as_menu():
			$value = $self->_get_item_hashref($value);
		}
		elsif ($name =~ /^VIEWS$/)
		{
			# Views blocks contain attributes in the form
			# of "MIMEtype: <size>" (e.g., "Text/plain: <10K>.").
			# So we need to get all of the MIME types and sizes in
			# the form of a hashref:
			$value = $self->_get_infoblock_hashref($value);

			# A size in the form of <55K> is of little use to the
			# user. Let's change that to an integer:
			foreach my $mime_type (keys %$value)
			{
				if ($value->{$mime_type} =~ /<(\d+)(k)?>/i)
				{
					# turn <55> into 55 and <55K> into
					# 55000:
					$value->{$mime_type}  = $1;
					$value->{$mime_type} *= 1000 if ($2);
				}
			}
		}
		elsif ($name =~ /^ADMIN$/)
		{
			# ADMIN blocks contain two attributes, Admin and
			# Mod-Date, in the form of:
			# 
			# Admin: Foo Bar <foobar@foo.com>
			# Mod-Date: Wed Jul 28 17:02:01 1993
			# 
			# first, get both of them in a hashref:
			$value = $self->_get_infoblock_hashref($value);

			# get the values from the Mod-Date timestamp: 
			my ($day, $month, $month_day,
			    $hour, $minute, $second, $year) = 
					$value->{'Mod-Date'} =~
						/(\w+)\s+(\w+)\s+(\d+)\s+
						 (\d+):(\d+):(\d+)\s+(\d+)/x;

			foreach ($day, $month, $month_day, $hour, $minute,
				$second, $year)
			{
				croak "Couldn't parse timestamp"
					unless (defined);
			}

			# if the server's date format contains a full
			# month name then we need to shorten it to just the
			# first three letters so we can easily convert it to
			# its respective localtime() number:
			$month =~ s/^(\w{3})\w+/$1/;

			# it's easier to convert it if it's in all lowercase:
			$month = lc $month;
	
			# now, replace the month name with a number like the
			# one returned localtime():
			$month = {
				jan   => 0,
				feb   => 1,
				mar   => 2,
				apr   => 3,
				may   => 4,
				jun   => 5,
				jul   => 6,
				aug   => 7,
				sep   => 8,
				'oct' => 9,
				nov   => 10,
				dec   => 11,
			}->{$month};

			# turn 2 diget years into 4 diget years:
			$year = 20 . $year if (length $year < 4);

			# convert the year to the number of years since 1900
			# (e.g., 2003 -> 103) since that's the format returned
			# by localtime():
			$year -= 1900;

			# now that we have the second, minute, hour, day,
			# month, and year, we use them to get a corresponding
			# Perl time() value:
			my $time = timelocal(
				$second, $minute, $hour,
				$month_day, $month, $year
			);

			# now use the time() value to get the values we still
			# don't have (e.g., the day of the year, is it daylight
			# savings time? Etc.) and store them in the Mod-Date
			# attribute value:
			$value->{'Mod-Date'} = [ localtime $time ];
		}

		$blocks{$name} = $value;
	}

	if (wantarray)
	{
		return %blocks;
	}
	else
	{
		return \%blocks;
	}
}





sub _get_item_hashref
{
	my $self = shift;
	my $item = shift;

	# get the item type and description text, selector, host, port, and
	# Gopher+ string:
	my ($type_and_text, $selector, $host, $port, $gopher_plus) =
		split(/\t/, $item);

	# now we need to separate the type and the text:
	my ($type, $text) = $type_and_text =~ /^(.)(.*)/;

	foreach ($type, $text, $selector, $host, $port)
	{
		croak "Couldn't parse menu item" unless (defined $_);
	}

	# create a hashref for this item:
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




sub _get_infoblock_hashref
{
	my $self        = shift;
	my $block_value = shift;

	# strip leading white space from the value:
	$block_value =~ s/^\s*//;

	# now seaparate each attribute:
	my @attributes = split(/$NEWLINE/, $block_value);

	my %block_attributes;
	foreach my $attribute (@attributes)
	{
		# first, get rid of all leading whitespace:
		$attribute =~ s/^\s*//;

		# get the "Name: value" attribute:
		my ($name, $value) = $attribute =~ /^(.+?):\s*(.*)/;

		$block_attributes{$name} = $value;
	}

	return \%block_attributes;
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
method returns false, meaning an error has occurred, then you can obtain the
error message by calling the error() method on the Net::Gopher::Response
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

1;

__END__

=back

=head1 BUGS

Email any to me at <william_g_davis at users dot sourceforge dot net> or go
to perlmonks.com and /msg me (William G. Davis) and I'll fix 'em.

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
