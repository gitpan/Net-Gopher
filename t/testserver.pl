#!/usr/bin/perl -w
# testserver.pl - a bare-bones test server for Net::Gopher.

use strict;
use Cwd;
use Errno 'EINTR';
use Getopt::Std;
use IO::Socket qw(SOCK_STREAM SOMAXCONN);

use constant DEFAULT_PORT => 70;
use constant BUFFER_SIZE  => 4096;
use constant TIMEOUT      => 60;

use vars qw($CRLF);
$CRLF = "\015\012";



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



my %opts;
getopts('ep:', \%opts);



my $error;
my $port = $opts{'p'} || DEFAULT_PORT;
my $server = new IO::Socket::INET (
	Type      => SOCK_STREAM,
	Proto     => 'tcp',
	LocalPort => $port,
	Timeout   => TIMEOUT,
	Listen    => SOMAXCONN,
	Reuse     => 1,
) or die "(Test server) Couldn't listen on localhost at port $port: $@";





while (my $client = $server->accept)
{
	my $select;

	my $request = '';
	my $buffer;
	while (read_from_socket($client, $select, \$buffer))
	{
		$request .= $buffer;
	}
	die $error if ($error);

	my ($selector) = split(/(?:\t|$CRLF)/, $request);



	if ($opts{'e'})
	{
		# echo: send back the request we were sent:
		write_to_socket($client, $select, $request);
		die $error if ($error);
	}
	else
	{
		$selector =~ s{\\}{/}g;
		$selector =  "/$selector" unless ($selector =~ m|^/|);

		my $path = (getcwd() =~ m|/t$|)
				? './items'
				: './t/items';

		open(FILE, "< $path$selector")
			|| do {
				error("Couldn't return file (.$path$selector): $!");
				die $error;
			};
		binmode FILE;
		my $item = join('', <FILE>);
		close FILE;

		write_to_socket($client, $select, $item);
		die $error if ($error);
	}

	close $client;
}




sub read_from_socket
{
	my ($socket, $select, $buffer) = @_;

	# make sure we can read from the socket; that there's something in the
	# OS buffer to read:
	#	return error('timeout while reading.')
	#	unless ($select->can_read(TIMEOUT));

	while (1)
	{
		# read part of the request from the socket into the buffer:
		my $num_bytes_read = sysread($socket, $$buffer, BUFFER_SIZE);

		# make sure something was received:
		unless (defined $num_bytes_read)
		{
			redo if ($! == EINTR);

			return error("read error: $!.");
		}

		return $num_bytes_read;
	}
}





sub write_to_socket
{
	my ($socket, $select, $data) = @_;

	# make sure we can write to the socket; that the OS buffer isn't full:
	#return error('timeout while writing.')
	#	unless ($select->can_write(TIMEOUT));

	# now send the response to the client:
	while (1)
	{
		my $num_bytes_written =
			syswrite($socket, $data, size_in_bytes($data));

		# make sure *something* was sent:
		unless (defined $num_bytes_written)
		{
			redo if ($! == EINTR);

			return error("write error: $!");
		}

		# make sure the entire response was sent:
		return error("short write.")
			unless (size_in_bytes($data) == $num_bytes_written);

		return $num_bytes_written;
	}
}





sub error
{
	if (@_)
	{
		$error = '(Test Server) ' . shift;
		return;
	}
	else
	{
		return $error;
	}
}





sub size_in_bytes ($)
{
	use bytes;

	return length shift;
}
