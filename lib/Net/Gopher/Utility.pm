# Copyright 2003, William G. Davis.
#
# This module defines and exports on demand variables for Net::Gopher. You
# really don't need to be looking in here unless you plan on hacking
# Net::Gopher.

package Net::Gopher::Utility;

use 5.005;
use strict;
use warnings;
use vars qw(
	@EXPORT_OK

	$CRLF $NEWLINE %GOPHER_ITEM_TYPES %GOPHER_PLUS_ITEM_TYPES
);
use base 'Exporter';
use Carp;

@EXPORT_OK = qw(
	check_params

	$CRLF
	$NEWLINE
	%GOPHER_ITEM_TYPES
	%GOPHER_PLUS_ITEM_TYPES
);





# This is the line ending used by Net::Gopher and Net::Gopher::response. You
# can change this to the line ending of your choosing, but I wouldn't recommend
# it since the Gopher protocol mandates standard ASCII carriage return/line
# feed (though most servers will accept any line ending):
$CRLF = "\015\012";

# This is pattern used to match newlines:
$NEWLINE = qr/(?:\015\012|\015|\012)/;

# This hash contains all of the item types described in RFC 1436 : The Internet
# Gopher Protocol as well as some other types in common usage (like 'i'). Each
# key is an item type and each value is a description of that type:
%GOPHER_ITEM_TYPES = (
	0   => 'text file',
	1   => 'directory',
	2   => 'CCSO nameserver',
	3   => 'error',
	4   => 'binhexed Macintosh file',
	5   => 'DOS binary archive',
	6   => 'UNIX uuencoded file',
	7   => 'index-search server',
	8   => 'text-based telnet session',
	9   => 'binary file',
	'+' => 'redundant server',
	s   => 'sound file',
	g   => 'GIF file',
	M   => 'MIME file',
	h   => 'HTML file',
	i   => 'inline text',
	I   => 'image file',
	T   => 'text-based tn3270 session',
);

# This hash contains all of the item types described in Gopher+: Upward
# Compatible Enhancements to the Internet Gopher Protocol as well as some other
# types in common usage (like 'i'). Each key is an item type and each value i
# a description of that type:
%GOPHER_PLUS_ITEM_TYPES = (
	0   => 'text file',
	1   => 'directory',
	2   => 'CCSO nameserver',
	3   => 'error',
	4   => 'binhexed Macintosh file',
	5   => 'DOS binary archive',
	6   => 'UNIX uuencoded file',
	7   => 'index-search server',
	8   => 'text-based telnet session',
	9   => 'binary file',
	'+' => 'redundant server',
	M   => 'MIME file',
	h   => 'HTML file',
	i   => 'inline text',
	T   => 'text-based tn3270 session',
	':' => 'bitmap image',
	';' => 'movie',
	'<' => 'sound'
);





sub check_params
{
	my $param_names = shift;
	my %params      = @_;

	my @values;
	foreach my $name (@$param_names)
	{
		push(@values, delete $params{$name});
	}

	# We should have deleted everything from %params. If there's anything
	# left, then the remaining parameters are invaid:
	if (my @invalid_keys = sort keys %params)
	{
		croak(
			"Can't supply \"",
			join('", "', @invalid_keys),
			"\" to ", (caller(1))[3]
		);
	}

	return @values;
}

1;
