#!/usr/bin/perl -w
use strict;
use Getopt::Std;

my %opts;
usage() unless (getopts('h', \%opts));
usage() if ($opts{'h'});
usage() unless (@ARGV);


foreach my $filename (@ARGV)
{
	open(FILE, "< $filename")
		|| die "Couldn't open test ($filename) for reading: $!";

	my $code = '';
	my $test_num = 1;
	while (defined(my $line = <FILE>))
	{
		$test_num++ if ($line =~ s/# \d+\n/# $test_num\n/);
		$code .= $line;
	}

	close FILE;



	open(FILE, "> $filename")
		|| die "Couldn't open test ($filename) for writing: $!";
	print FILE $code;
	close FILE;
}





sub usage
{
	print <<'END_OF_USAGE';
This script looks for test number comments in one or more scripts and makes
sure they're correct.

Usage:
	$ perl number_each_test.pl [FLAGS... | FILES...]
Flags:
	-h   Displays this message.

END_OF_USAGE
	exit;
}
