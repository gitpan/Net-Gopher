# Copyright 2003 by William G. Davis.
#
# This module defines and exports on demand variables for Net::Gopher. You
# really don't need to be looking in here unless you plan on hacking
# Net::Gopher.

package Net::Gopher::Utility;

use 5.005;
use strict;
use warnings;
use vars qw(
	@EXPORT_OK %EXPORT_TAGS

	$CRLF $NEWLINE %ITEM_DESCRIPTIONS
);
use base 'Exporter';
use Carp;










@EXPORT_OK = qw(
	$CRLF $NEWLINE %ITEM_DESCRIPTIONS

	check_params get_os_name chars_to_entities
);

%EXPORT_TAGS = (
	request_constants   => [qw(
		GOPHER_REQUEST
		GOPHER_PLUS_REQUEST
		ITEM_ATTRIBUTE_REQUEST
		DIRECTORY_ATTRIBUTE_REQUEST
	)],
	item_type_constants => [qw(
		TEXT_FILE_TYPE
		GOPHER_MENU_TYPE
		CCSO_NAMESERVER_TYPE
		ERROR_TYPE
		BINHEXED_MACINTOSH_FILE_TYPE
		DOS_BINARY_FILE_TYPE
		UNIX_UUENCODED_FILE_TYPE
		INDEX_SEARCH_SERVER_TYPE
		TELNET_SESSION_TYPE
		BINARY_FILE_TYPE
		GIF_IMAGE_TYPE
		IMAGE_FILE_TYPE
		TN3270_SESSION_TYPE
		BITMAP_IMAGE_TYPE
		MOVIE_TYPE
		SOUND_TYPE
		HTML_FILE_TYPE
		INLINE_TEXT_TYPE
		MIME_FILE_TYPE
		MULAW_AUDIO_TYPE
	)]
);







# This is the line ending used by Net::Gopher and Net::Gopher::response. You
# can change this to the line ending of your choosing, but I wouldn't recommend
# it since the Gopher protocol mandates standard ASCII carriage return/line
# feed (though most servers will accept any line ending):
$CRLF = "\015\012";

# This is pattern used to match newlines:
$NEWLINE = qr/(?:\015\012|\015|\012)/;

# This hash contains all of the item types described in __RFC 1436 : The
# Internet Gopher Protocol__ and in __Gopher+: Upward Compatible Enhancements
# to the Internet Gopher Protocol__ as well as some other item types in common
# usage (like 'i'). Each key is an item type and each value is a description of
# that type:
%ITEM_DESCRIPTIONS = (
	# Gopher types:
	0   => 'text file',
	1   => 'Gopher menu',
	2   => 'CCSO nameserver',
	3   => 'error',
	4   => 'binhexed Macintosh file',
	5   => 'DOS binary archive',
	6   => 'UNIX uuencoded file',
	7   => 'index-search server',
	8   => 'text-based telnet session',
	9   => 'binary file',
	'+' => 'redundant server',
	g   => 'GIF file',
	I   => 'image file',
	T   => 'text-based tn3270 session',

	# Gopher+ types:
	':' => 'bitmap image',
	';' => 'movie file',
	'<' => 'sound file',

	# non-standard but common types:
	h   => 'HTML file',
	i   => 'inline text',
	M   => 'MIME file',
	s   => 'Mulaw audio file',

);





################################################################################
#
#	Function
#		check_params(\@param_names, @arg_list)
#
#	Purpose
#		This method is used to validate and retrieve a subroutine's
#		named parameters. The first argument contains a reference to a
#		list containing the (case sensitive) parameter names your
#		subroutine can receive. The second argument contains the
#		Name => "Value" parameters. If this function finds named
#		parameters in @arg_list besides those specified in
#		@param_names, it will do a stack trace and croak listing the
#		name of your function and the invalid parameters.
#
#	Parameters
#		A list containing the values for the parameters you specified
#		in the order that you specified.
#

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





################################################################################
#
#	Function
#		get_os_name()
#
#	Purpose
#		This method reliably returns the name of the OS the script is
#		running one, checking $^O or using Config.pm if that doesn't
#		work.
#
#	Parameters
#		None.
#

sub get_os_name
{
	# first, find out what OS we're on:
	my $operating_system = $^O;

	# not all OS's support $^O:
	unless ($operating_system)
	{
		require Config;
		$operating_system = $Config::Config{'osname'};
	}

	return $operating_system;
}





################################################################################
#
#	Function
#		chars_to_entities($text)
#
#	Purpose
#		This method converts &, <, >, ", and ' to their XML/XHTML
#		entity equivalents. The text with the escaped characters is
#		returned
#
#	Parameters
#		$text - Text containing XHTML metasymbols to escape.
#

sub chars_to_entities
{
	my $text =  shift;
	   $text =~ s/&/&amp;/g;
	   $text =~ s/</&lt;/g;
	   $text =~ s/>/&gt;/g;
	   $text =~ s/"/&quot;/g;
	   $text =~ s/'/&apos;/g;

	return $text;
}

1;
