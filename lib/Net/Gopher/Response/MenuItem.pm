
package Net::Gopher::Response::MenuItem;

=head1 NAME

Net::Gopher::Response::MenuItem - Manipulate Gopher/Gopher+ menu items

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 
 my @items = $response->extract_items(ExceptTypes => 'i');
 
 foreach my $menu_item (@items)
 {
 	# there are accessor methods to access every element of a menu item:
 	printf("%s   %s (%s from %s at port %d)\n",
 		$menu_item->item_type,
 		$menu_item->display,
 		$menu_item->selector,
 		$menu_item->host,
 		$menu_item->port
 	);
 
 	# you can easily convert menu items into URLs:
 	my $url = $menu_item->as_url;
 
 	# ...or Net::Gopher::Request objects:
 	my $request = $menu_item->as_request;
 	$response   = $ng->request($request);

	# a string containing the item:
	print $menu_item->as_string;
 }

=head1 DESCRIPTION

The B<Net::Gopher::Response> C<extract_items()> method parses
Gopher menus and returns the parsed menu items in the form of
B<Net::Gopher::Response::MenuItem> objects. Use the methods in this class to
manipulate them.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use vars qw(@ISA);
use overload (
	'""'     => sub { shift->as_string },
	fallback => 1,
);
use Carp;
use URI;
use Net::Gopher::Constants ':item_types';
use Net::Gopher::Debugging;
use Net::Gopher::Exception;
use Net::Gopher::Request;
use Net::Gopher::Utility 'check_params';

push(@ISA, qw(Net::Gopher::Debugging Net::Gopher::Exception));







################################################################################

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my ($item_type, $display, $selector, $host, $port, $gopher_plus) =
		check_params([qw(
			ItemType
			Display
			Selector
			Host
			Port
			GopherPlus)], \@_
		);

	my $self = {
		item_type   => $item_type,
		display     => $display,
		selector    => $selector,
		host        => $host,
		port        => $port,
		gopher_plus => $gopher_plus
	};

	bless($self, $class);

	return $self;
}





#==============================================================================#

=head2 as_string()

This method returns a string containing the item.

=cut

sub as_string
{
	my $self = shift;

	my $string = sprintf("%s%s\t%s\t%s\t%s",
		$self->item_type,
		$self->display,
		$self->selector,
		$self->host,
		$self->port
	);

	$string .= "\t" . $self->gopher_plus if (defined $self->gopher_plus);

	return $string;
}





#==============================================================================#

=head2 as_request()

This method creates and returns a new B<Net::Gopher::Request> object using the
values present in the menu item.

=cut

sub as_request
{
	my $self = shift;

	$self->call_warn(
		"You're trying to convert an inline text (\"i\" item type) " .
		"menu item into a request object. Inline text items are not " .
		"supposed to be downloadable."
	) if ($self->item_type eq INLINE_TEXT_TYPE);

	my $request;
	if (defined $self->gopher_plus and length $self->gopher_plus)
	{
		my $request_char = substr($self->gopher_plus, 0, 1);

		if ($request_char eq '+' or $request_char eq '?')
		{
			$request = new Net::Gopher::Request ('GopherPlus',
				Host           => $self->host,
				Port           => $self->port,
				Selector       => $self->selector,
				ItemType       => $self->item_type
			);
		}
		else
		{
			return $self->call_die(
				"Can't convert malformed menu item into a " .
				"request object: the Gopher+ string contains " .
				"an invalid request type character " .
				"(\"$request_char\"). It should be \"+\" or " .
				'"?".'
			);
		}
	}
	else
	{
		$request = new Net::Gopher::Request ('Gopher',
			Host     => $self->host,
			Port     => $self->port,
			Selector => $self->selector,
			ItemType => $self->item_type
		);
	}

	return $request;
}





#==============================================================================#

=head2 as_url()

This method creates and returns a new gopher:// URL using the values in the
menu item.

=cut

sub as_url
{
	my $self = shift;

	$self->call_warn(
		"The menu item lacks a hostname, and any URL it's converted " .
		"to will be invalid."
	) unless (defined $self->host and length $self->host);

	$self->call_warn(
		"You're trying to convert an inline text (\"i\" item type) " .
		"menu item into a Gopher URL. Inline text items are not " .
		"supposed to be downloadable."
	) if ($self->item_type eq INLINE_TEXT_TYPE);

	my $uri = new URI (undef, 'gopher');
	   $uri->scheme('gopher');
	   $uri->host($self->host);
	   $uri->port($self->port);
	   $uri->gopher_type($self->item_type);
	   $uri->selector($self->selector);
	   $uri->string($self->gopher_plus);

	return $uri->as_string;
}





#==============================================================================#

=head2 item_type()

This method returns the item type character of the menu item.

=cut

sub item_type
{
	my $self = shift;

	if (@_)
	{
		$self->{'item_type'} = shift;
	}
	else
	{
		return $self->{'item_type'};
	}
}





#==============================================================================#

=head2 display()

This method returns the display string of the menu item.

=cut

sub display
{
	my $self = shift;

	if (@_)
	{
		$self->{'display'} = shift;
	}
	else
	{
		return $self->{'display'};
	}
}





#==============================================================================#

=head2 selector()

This method returns the selector string of the menu item.

=cut

sub selector
{
	my $self = shift;

	if (@_)
	{
		$self->{'selector'} = shift;
	}
	else
	{
		return $self->{'selector'};
	}
}





#==============================================================================#

=head2 host()

This method returns the host field of the menu item.

=cut

sub host
{
	my $self = shift;

	if (@_)
	{
		$self->{'host'} = shift;
	}
	else
	{
		return $self->{'host'};
	}
}





#==============================================================================#

=head2 port()

This method returns the port field of the menu item.

=cut

sub port
{
	my $self = shift;

	if (@_)
	{
		$self->{'port'} = shift;
	}
	else
	{
		return $self->{'port'};
	}
}





#==============================================================================#

=head2 gopher_plus()

For a Gopher+ menu item, this will return the Gopher+ string of a menu item.
With Gopher items it will just return undef.

=cut

sub gopher_plus
{
	my $self = shift;

	if (@_)
	{
		$self->{'gopher_plus'} = shift;
	}
	else
	{
		return $self->{'gopher_plus'};
	}
}

1;

__END__

=head1 BUGS

Bugs in this package can reported and monitored using CPAN's request
tracker: rt.cpan.org.

If you wish to report bugs to me directly, you can reach me via email at
<william_g_davis at users dot sourceforge dot net>.

=head1 SEE ALSO

L<Net::Gopher|Net::Gopher>, L<Net::Gopher::Response|Net::Gopher::Response>

=head1 COPYRIGHT

Copyright 2003-2004 by William G. Davis.

This module is free software released under the GNU General Public License,
the full terms of which can be found in the "COPYING" file that comes with
the distribution.

=cut
