# Copyright 2003-2004 by William G. Davis.
#
# This module is free software released under the GNU General Public License,
# the full terms of which can be found in the "COPYING" file that comes with
# the distribution.
#
# This module defines and exports on demand global variablesand utility
# functions for Net::Gopher. You really don't need to be looking in here unless
# you plan on hacking Net::Gopher.

package Net::Gopher::Utility;

use 5.005;
use strict;
use warnings;
use vars qw(
	@EXPORT_OK %EXPORT_TAGS

	$CRLF $NEWLINE_PATTERN $ITEM_PATTERN %ITEM_DESCRIPTIONS
);
use base 'Exporter';
use Carp;

BEGIN
{
	# this hack allows us to "use bytes" or fake it for older (pre-5.6.1)
	# versions of Perl (thanks to Liz from PerlMonks):
	eval { require bytes };

	if ($@)
	{
		# couldn't find it, but pretend we did anyway:
		$INC{'bytes.pm'} = 1;

		# 5.005_03 doesn't inherit UNIVERSAL::unimport:
		eval "sub bytes::unimport { return 1 }";
	}
}

@EXPORT_OK = qw(
	$CRLF $NEWLINE_PATTERN $ITEM_PATTERN %ITEM_DESCRIPTIONS

	check_params
	size_in_bytes
	remove_bytes
	get_os_name
	chars_to_entities
	convert_newlines
	strip_status_line
	strip_terminator
);





# This is the line ending used by Net::Gopher and Net::Gopher::response. You
# can change this to the line ending of your choosing, but I wouldn't recommend
# it since the Gopher protocol mandates standard ASCII carriage return/line
# feed:
$CRLF = "\015\012";



# This pattern is used to match newlines:
$NEWLINE_PATTERN = qr/(?:\015\012|\015|\012)/;



# $ITEM_PATTERN pattern is used to match item descriptions within Gopher menus
# and other areas:
my $field = qr/[^\t\012\015]*?/; # a tab delimited field.
$ITEM_PATTERN = qr/$field\t$field\t$field\t$field(?:\t$field)?/;



# This hash contains all of the item types described in *RFC 1436 : The
# Internet Gopher Protocol* and in *Gopher+: Upward Compatible Enhancements
# to the Internet Gopher Protocol* as well as some other item types in common
# usage (like 'i'). Each key is an item type and each value is a description of
# that type:
%ITEM_DESCRIPTIONS = (
	# Gopher types:
	0   => 'text file',
	1   => 'Gopher menu',
	2   => 'CCSO nameserver',
	3   => 'Gopher error',
	4   => 'binhexed Macintosh file',
	5   => 'DOS binary archive',
	6   => 'Unix uuencoded file',
	7   => 'index-search server',
	8   => 'text-based telnet session',
	9   => 'binary file',
	'+' => 'redundant server',
	g   => 'GIF image file',
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
	s   => 'Mulaw audio file'
);





################################################################################
#
#	Function
#		check_params($param_names, $arg_list, $strict)
#
#	Purpose
#		This function is used to validate and retrieve the named
#		parameters sent to a function. It takes a reference to a list
#		containing the paramter names whose values you want as its
#		first argument, a reference to a list (either a hash or array)
#		containing named parameters as its second
#
#	Parameters
#		$param_names - A reference to an array containing the names of
#		               the parameters to accept and return.
#		$arg_list    - Either a reference to a hash or array containing
#		               "ParamName => 'value'" pairs. This can just be
#		               a reference to @_.
#

sub check_params
{
	my ($names_ref, $params_ref, $strict) = @_;

	my @args = (ref $params_ref eq 'ARRAY')
			? @$params_ref
			: %$params_ref;

	my %params;
	if (@args == 1 and my $ref_type = ref $args[0])
	{
		if ($ref_type eq 'HASH')
		{
			%params = %{ shift @args };
		}
		elsif ($ref_type eq 'ARRAY')
		{
			%params = @{ shift @args };
		}
		else
		{
			croak(
				"Bad reference type \"$ref_type\" for " .
				"parameters. Use either a hash or array " .
				"reference instead."
			);
		}
	}
	else
	{
		croak("Odd number elements for what should be named parameters")
			if (@args % 2);

		%params = @args;
	}



	my @params_wanted;
	my %values;
	foreach my $name (@$names_ref)
	{
		my $real_name = lc $name;
		   $real_name =~ s/^-//;
		   $real_name =~ s/_//g;

		push(@params_wanted, $real_name);

		$values{$real_name} = undef;
	}



	my @bad_names;
	foreach my $name (keys %params)
	{
		my $real_name = lc $name;
		   $real_name =~ s/^-//;
		   $real_name =~ s/_//g;

		if (exists $values{$real_name})
		{
			$values{$real_name} = $params{$name};
		}
		else
		{
			push(@bad_names, $name);
		}
	}



	if ($strict and @bad_names)
	{
		(my $function_name = (caller(1))[3]) =~ s/.*:://;

		croak sprintf("Can't supply \"%s\" to %s",
			join('", "', @bad_names),
			$function_name
		);
	}

	return @values{@params_wanted};
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
	my $text = shift;

	   $text =~ s/&/&amp;/g;
	   $text =~ s/</&lt;/g;
	   $text =~ s/>/&gt;/g;
	   $text =~ s/"/&quot;/g;
	   $text =~ s/'/&apos;/g;

	return $text;
}





################################################################################
#
#	Function
#		get_os_name()
#
#	Purpose
#		This function reliably returns the name of the OS the script is
#		running one, checking $^O or using Config.pm if that doesn't
#		work.
#
#	Parameters
#		None.
#

sub get_os_name
{
	my $operating_system = $^O;

	# not all systems support $^O:
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
#		remove_bytes($string, $bytes)
#
#	Purpose
#		This function removes one or more bytes from the beginning of
#		of string. Use this instead of the built-in substr() function
#		(that, as of 5.6.1, is used to retrieve or remove one or more
#		characters from a string as opposed to bytes) when you need to
#		remove bytes specifically, not characters, from a string.
#
#	Parameters
#		None.
#

sub remove_bytes ($$)
{
	use bytes;

	return substr($_[0], 0, $_[1], '');
}





################################################################################
#
#	Function
#		size_in_bytes($scalar)
#
#	Purpose
#		This function returns the size of a scalar value in bytes. Use
#		this instead of the built-in length() function (which, as of
#		5.6.1, returns the length in characters as opposed to bytes)
#		when you need to find out out the number of bytes in a scalar,
#		not the number of characters.
#
#	Parameters
#		$scalar - The scalar you want the size of.
#

sub size_in_bytes ($)
{
	use bytes;

	return length shift;
}





sub convert_newlines
{
	my $converted;
	if (get_os_name() =~ /^MacOS/i)
	{
		# convert Windows CRLF and Unix LF line endings to MacOS CR:
		$converted += $_[0] =~ s/\015\012/\015/g;
		$converted += $_[0] =~ s/\012/\015/g;
	}
	else
	{
		# convert Windows CRLF and MacOS CR line endings to Unix LF:
		$converted += $_[0] =~ s/\015\012/\012/g;
		$converted += $_[0] =~ s/\015/\012/g;
	}

	return $converted;
}





################################################################################
#
#	Function
#		strip_status_line($string)
#
#	Purpose
#		This function strips the status line (first line) from $string.
#		Note that it modifies $string directly.
#
#	Parameters
#		$string - The string you want the status line removed from.
#

sub strip_status_line
{
	return scalar $_[0] =~ s/^.+?$CRLF//o;
}





################################################################################
#
#	Function
#		strip_terminator($string)
#
#	Purpose
#		This function strips any period on a line by itself from
#		$string. The newline before the period and the newline after it
#		can be either a carriage return, a line feed, or a carriage
#		return/line feed combination. Note that this function modifies
#		$string directly.
#
#	Parameters
#		$string - The string you want the period terminator removed
#		          from.
#

sub strip_terminator
{
	return scalar $_[0] =~ s/$NEWLINE_PATTERN\.$NEWLINE_PATTERN?$//o;
}

1;
