#!/usr/bin/perl -w
# testserver.pl - a bare-bones test server for Net::Gopher.

use strict;
use Cwd;
use Errno 'EINTR';
use Getopt::Std;
use IO::Socket qw(SOCK_STREAM SOMAXCONN);
use IO::Select;

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



# the script arguments:
my %opts;

# a string containing the error message for the last error to occur:
my $error;

# the blessed file handle of the IO::Socket server:
my $server;



# -e tells us to echo out what we're sent:
getopts('e', \%opts);

# now, create a TCP socket and listen() on what ever port the OS assigns to us:
$server = new IO::Socket::INET (
	Type      => SOCK_STREAM,
	Proto     => 'tcp',
	Timeout   => TIMEOUT,
	Listen    => SOMAXCONN,
	Reuse     => 1,
) or die "(Test server) Couldn't make TCP server: $@";

# this process is meant to be pipe opened for reading, so we write something
# meaningful back to the parent process for them to read...
printf("# Listening on port %d...\n", $server->sockport);

# ...and then redirect standard output to tell the kernel we're done writing.
# This makes sure that we get to the while loop below, and once we start
# blocking, waiting for incoming connections, control will be returned to the
# parent so it can start making requests of us:
if ($^O !~ /MSWin/i)
{
	open(STDOUT, '>/dev/null') || die "Can't redirect STDOUT: $!";
}
else
{
	close STDOUT;
}



while (my $client = $server->accept)
{
	# we do non-blocking IO on the socket:
	$client->blocking(0);

	my $select = new IO::Select ($client);

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

	# make sure we can read from the socket; that there's stuff waiting to
	# be read:
	return error('timeout while reading.')
		unless ($select->can_read(TIMEOUT));

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

	# make sure we can write to the socket; that the socket's ready for
	# writing:
	return error('timeout while writing.')
		unless ($select->can_write(TIMEOUT));

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
