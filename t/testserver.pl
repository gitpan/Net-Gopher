#!/usr/bin/perl -w
# testserver.pl - a bare-bones test server for Net::Gopher.

package testserver;

use strict;
use Cwd;
use Getopt::Std;
use IO::Socket;
use IO::Select;
use Net::Gopher::Constants qw(:request);
use Net::Gopher::Utility qw($CRLF size_in_bytes remove_bytes);

use constant BUFFER_SIZE           => 4096;
use constant TIMEOUT               => 30;
use constant MAX_REQUESTS          => 10;
use constant MAX_REQUEST_LINE_SIZE => BUFFER_SIZE;
use constant MAX_DATA_BLOCK_SIZE   => BUFFER_SIZE * 4;

my $error;
my %opts;
getopts('ep:', \%opts);

my $server = new IO::Socket::INET (
	LocalPort => $opts{'p'} || 70,
	Type      => SOCK_STREAM,
	Reuse     => 1,
	Listen    => 1
) or die "Couldn't listen on localhost at port 70: $@";





CLIENT: while (my $client = $server->accept)
{
	my $select = new IO::Select ($client);

	# make sure we can read from the socket; that there's something in the
	# OS buffer to read:
	next unless ($select->can_read(TIMEOUT));

	my ($request, $request_type, $selector, $search_words,
	    $is_gopher_plus, $gopher_plus_string, $representation, $attributes,
	    $data_flag, $data_block); 

	my ($buffer, $n);
	while ($n = read_from_socket($client, $select, \$buffer))
	{
		# exit if we ran into any errors:
		next CLIENT if (error());

		$request .= $buffer;

		if (index($request, $CRLF) >= 0)
		{
			my ($first_line, $other_lines) =
				split(/$CRLF/, $request, 2);

			my @other_fields;
			($selector, $other_lines) = split(/\t/, $first_line, 2);

			$search_words = shift @other_fields
				if (@other_fields
					and $other_fields[0] !~ /^[\+\!\$]/);

			if (@other_fields)
			{
				$is_gopher_plus++;
				my $request_char =
					substr($other_fields[0], 0, 1, '');

				if ($request_char eq '+')
				{
					$request_type = GOPHER_PLUS_REQUEST;

					$representation = shift @other_fields;
					$data_flag      = shift @other_fields;
				}
				elsif ($request_char eq '!')
				{
					$request_type = ITEM_ATTRIBUTE_REQUEST;

					$attributes = shift @other_fields;
					$data_flag  = shift @other_fields;
				}
				elsif ($request_char eq '$')
				{
					$request_type =
						DIRECTORY_ATTRIBUTE_REQUEST;

					$attributes = shift @other_fields;
					$data_flag  = shift @other_fields;
				}
			}
			else
			{
				$request_type = GOPHER_REQUEST;
			}

			if ($data_flag)
			{
				until (index($other_lines, $CRLF) >= 0)
				{
					read_from_socket($client, $select, \$buffer);

					next CLIENT if (error()
						or size_in_bytes($other_lines) >= MAX_DATA_BLOCK_SIZE
					);

					$request     .= $buffer;
					$other_lines .= $buffer;
				}

				my $data_heading;
				($data_heading, $data_block) = split(/$CRLF/, $other_lines);

				my ($status, $transfer_type);
				if ($data_heading =~ /^(\+|\-)(\-1|\-2|\d+)$/)
				{
					$status        = $1;
					$transfer_type = $2;
				}
				else
				{
					next CLIENT;
				}

				
			}
		}
		else
		{
			next CLIENT if (
				size_in_bytes($request) >= MAX_REQUEST_LINE_SIZE
			);
		}
	}



	if ($opts{'e'})
	{
		# echo: send back the request we were sent:
		write_to_socket($client, $select, $request);  
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
	}
}




sub read_from_socket
{
	my ($socket, $select, $buffer) = @_;

	# make sure we can read from the socket; that there's something in the
	# OS buffer to read:
	return unless ($select->can_read(0));

	# read part of the request from the socket into the buffer:
	my $num_bytes_read;

	$num_bytes_read = sysread($socket, $$buffer, BUFFER_SIZE);

	# make sure something was received:
	return error(1) unless (defined $num_bytes_read);

	return $num_bytes_read;
}





sub write_to_socket
{
	my ($socket, $select, $data) = @_;

	# make sure we can write to the socket; that the OS buffer isn't full:
	return error(1) unless ($select->can_write(TIMEOUT));

	# now send the response to the Gopher server:
	my $num_bytes_written = syswrite($socket, $data, size_in_bytes($data));

	# make sure *something* was sent:
	return error(1) unless (defined $num_bytes_written);

	# make sure the entire response was sent:
	return error(1) unless (size_in_bytes($data) == $num_bytes_written);

	return $num_bytes_written;
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
