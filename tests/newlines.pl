#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use File::Find;



# get the options:
my %opts;
getopts('f:n:h', \%opts) || usage();
usage() if (!$opts{'n'} || $opts{'h'});

# default to current dir:
push(@ARGV, '.') unless (@ARGV);

# the new line ending (either \015, \012, or \015\012):
my $newline = $opts{'n'};
   $newline =~ s/CR/\015/gi;
   $newline =~ s/R/\015/gi;
   $newline =~ s/LF/\012/gi;

# grab the names of the files or directories of files to convert:
foreach my $filename (@ARGV)
{
	# traverse the directory tree and look at each file:
	find(sub { convertNewlines() }, $filename);
}





sub convertNewlines
{
	my $filename = $_;
	
	# don't mess with it unless it's a text file:
	return unless (-T $filename);

	open(FILE, "< $filename")
		|| die "Couldn't open file ($filename) for reading: $!";

	# the number of newlines converted in this file:
	my $count = 0;

	# the text of the file with its newlines converted:
	my $text;

	# convert the newlines:
	while (my $line = <FILE>)
	{
		$count += ($line =~ s/(?:\015\012|\015|\012)/$newline/g);
		$text .= $line;
	}

	# make sure the status line is stil CRLF terminated:
	$text =~ s/(?:\015\012|\015|\012)/\015\012/
		if ($filename =~ /^gp_/i
			or $filename =~ /^error_/i
			or $filename =~ /^item_/i
			or $filename =~ /^directory_/i);

	# now save it, and binmode so Perl doesn't mess the new line endings:
	open(FILE, "> $filename")
		|| die "Couldn't open file ($filename) for writing: $!";
	binmode FILE;
	print FILE $text;
	close FILE;
}





sub usage
{
	print <<'END_OF_USAGE';
This script can be used to convert the line endings in a file to Unix, Windows,
or MacOS line endings.

Usage:
 $ newlines -n NEWLINE [FILENAMES...]

Arguments:
	-n   The newline type that the newlines in the files you specified
	     should be converted to. Either "CR" or "R" for carriage return,
	     "LF" for linefeed, or "CRLF" for carriage return/linefeed.
Flags:
	-h   Displays this message.
END_OF_USAGE

	exit;
}
