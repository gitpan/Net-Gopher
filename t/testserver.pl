#!/usr/bin/perl -w
# testserver.pl - a bare-bones test server for Net::Gopher.

package testserver;

use strict;
use Cwd;
use Errno 'EINTR';
use Getopt::Std;
use IO::Socket;
use IO::Select;
use Net::Gopher::Constants qw(:request);
use Net::Gopher::Utility qw($CRLF size_in_bytes remove_bytes);

use constant DEFAULT_PORT => 70;
use constant BUFFER_SIZE  => 4096;
use constant TIMEOUT      => 30;

my $error;
my %opts;
getopts('ep:', \%opts);

my $server = new IO::Socket::INET (
	LocalPort => $opts{'p'} || DEFAULT_PORT,
	Type      => SOCK_STREAM,
	Reuse     => 1,
	Listen    => 1
) or die "Couldn't listen on localhost at port $opts{'p'}: $@";





CLIENT: while (my $client = $server->accept)
{
	my $select = new IO::Select ($client);

	# make sure we can read from the socket; that there's something in the
	# OS buffer to read:
	next unless ($select->can_read(TIMEOUT));

	my $request = '';
	my $buffer;
	while (read_from_socket($client, $select, \$buffer))
	{
		$request .= $buffer;
	}
	die "(Test server) read error: $!" if ($error);

	my ($selector) = split(/(?:\t|$CRLF)/, $request);



	if ($opts{'e'})
	{
		# echo: send back the request we were sent:
		write_to_socket($client, $select, $request);
		die "(Test server) write error: $!" if ($error);
	}
	else
	{
		$selector =~ s{\\}{/}g;
		$selector =  "/$selector" unless (substr($selector,0,1) eq '/');

		my $path = (getcwd() =~ m|/t$|)
				? './items'
				: './t/items';

		open(FILE, "< $path$selector")
			|| die "Couldn't return file (.$path$selector): $!";
		binmode FILE;
		my $item = join('', <FILE>);
		close FILE;

		write_to_socket($client, $select, $item);
		die "(Test server) write error: $!" if ($error);
	}
}




sub read_from_socket
{
	my ($socket, $select, $buffer) = @_;

	# make sure we can read from the socket; that there's something in the
	# OS buffer to read:
	return error(1) unless ($select->can_read(TIMEOUT));

	while (1)
	{
		# read part of the request from the socket into the buffer:
		my $num_bytes_read = sysread($socket, $$buffer, BUFFER_SIZE);

		# make sure something was received:
		unless (defined $num_bytes_read)
		{
			redo if ($! == EINTR);

			return error(1);
		}

		return $num_bytes_read;
	}
}





sub write_to_socket
{
	my ($socket, $select, $data) = @_;

	# make sure we can write to the socket; that the OS buffer isn't full:
	return error(1) unless ($select->can_write(TIMEOUT));

	# now send the response to the client:
	while (1)
	{
		my $num_bytes_written =
			syswrite($socket, $data, size_in_bytes($data));

		# make sure *something* was sent:
		unless (defined $num_bytes_written)
		{
			redo if ($! == EINTR);

			return error(1);
		}

		# make sure the entire response was sent:
		return error(1)
			unless (size_in_bytes($data) == $num_bytes_written);

		return $num_bytes_written;
	}
}





sub error
{
	if (@_)
	{
		$error = shift;
		return;
	}
	else
	{
		return $error;
	}
}
