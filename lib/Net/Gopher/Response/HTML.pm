
package Net::Gopher::Response::HTML;

use 5.005;
use warnings;
use strict;
use vars qw(@EXPORT_OK);
use base qw(Exporter);
use Carp;
use Net::Gopher::Utility qw(check_params get_os_name);

@EXPORT_OK = qw(
	preserve_whitespace
	autocreate_links
	get_absolute_filename
	process_html_file
);







################################################################################
#
#	Method
#		preserve_whitespace($text)
#
#	Purpose
#		This method attempts to preserve plain text formatting for
#		HTML. It converts newlines to a newline and a <br> tag,
#		and multiple spaces and tabs to alternating space and &nbsp;
#		characters. It returns the converted text.
#
#	Parameters
#		$text - A string of text containing whitespace to presereve.
#

sub preserve_whitespace
{
	my $text =  shift;
	   $text =~ s/\n/\n<br>/g;
	   $text =~ s/  /&nbsp; /g;
	   $text =~ s/\t/&nbsp; &nbsp; &nbsp; &nbsp; /g;

	return $text;
}





################################################################################
#
#	Method
#		autocreate_links($text)
#
#	Purpose
#		This method looks for URLs in a string of text and converts
#		them to hyperlinks with the "href" attribute set to the URL and
#		with the URL in between the opening and closing <a> tags, then
#		returns the converted text.
#
#	Parameters
#		$text - A string of text containing URLs to turn into
#		        hyperlinks.
#

sub autocreate_links
{
	my $text =  shift;
	   $text =~ s{( [a-zA-Z]+://\S+ ) \b }
	             {<a href="$1">$1</a>}gix;
	   $text =~ s{\b([\w.\-]+\@(?:[\w\-]+\.)+\w+)\b}
	             {<a href="mailto:$1">$1</a>}gix;

	return $text;
}





sub process_html_file
{
	my ($file, $variables) = check_params(['File', 'Variables'], @_);

	my %vars = %$variables;



	# the separator for HTML sub files is represented on disk as ";"
	# instead of "::" in the file names, since on mac ":" is the directory
	# separator, and many other OS's don't allow them in file names at
	# all:
	$file =~ s/::/;/g;

	# get the absolute filename ($file is most likely only relative):
	my $filename = get_absolute_filename($file);

	open(HTML, "< $filename") || croak "Can't open file ($file): $!";

	# this will store all of the HTML from the file:
	my $html;

	while (my $line = <HTML>)
	{
		# turn off warnings so we don't get "Use of uninitialized..."
		# wanrings for variables that weren't defined:
		no warnings;

		# fill in the template variables as we process the file:
		$line  =~ s/(?<!\\)\$([a-zA-Z_]\w*)/$vars{$1}/g;
		$html .=  $line;
	}

	close HTML;



	return $html;
}





sub get_absolute_filename
{
	my $file = shift;



	# first, find out what OS we're on:
	my $operating_system = get_os_name();


	# we'll look in @INC for the Net/Gopher/Response/HTML/$file file:
	my @file_names;
	if($^O =~ /MacOS/i)
	{
		@file_names = map {$_ . ":Net:Gopher:Response:HTML:$file"} @INC;
	}
	else
	{
		@file_names = map {$_ . "/Net/Gopher/Response/HTML/$file"} @INC;
	}

	# now search for it file:
	my $found;
	foreach (@file_names)
	{
		if (-e $_)
		{
			$found = $_;
			last;
		}
	}



	return $found;
}

1;
