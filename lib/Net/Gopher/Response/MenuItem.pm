
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

	# the menu item as it appeared in the Gopher menu:
	print $menu_item->raw_item;
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
	'""'     => sub { shift->raw_item },
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

	my ($raw_item, $item_type, $display, $selector, $host, $port,
	    $gopher_plus) =
		check_params([qw(
			RawItem
			ItemType
			Display
			Selector
			Host
			Port
			GopherPlus)], \@_
		);

	my $self = {
		raw_item    => $raw_item,
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

=head2 raw_item()

This method returns a string containing the item as it appeared in the menu.

=cut

sub raw_item { return shift->{'raw_item'} }





#==============================================================================#

=head2 as_request()

This method creates and returns a new B<Net::Gopher::Request> object using the
values present in the menu item.

=cut

sub as_request
{
	my $self = shift;

	$self->call_warn(
		join(' ',
			"You're trying to convert an inline text (\"i\" item",
			"type) menu item into a Net::Gopher::Request object.",
			"Inline text items are not supposed to be downloadable."
		)
	) if ($self->item_type eq INLINE_TEXT_TYPE);

	my $request;
	if (defined $self->gopher_plus and length $self->gopher_plus)
	{
		my ($request_char, $other_stuff) =
		(substr($self->gopher_plus,0,1), substr($self->gopher_plus,1));

		# The usage of $other_stuff here to allow someone to put an
		# item representation following the "+" or to allow someone
		# to create a menu item pointing to an attribute/directory
		# information request and then even put attributes following
		# the "!" or "$" in the Gopher+ string field isn't in the
		# Gopher+ standard, but it's possible someone will attempt to
		# use Gopher+ menu items in this way:
		if ($request_char eq '+' or $request_char eq '?')
		{
			$request = new Net::Gopher::Request ('GopherPlus',
				Host           => $self->host,
				Port           => $self->port,
				Selector       => $self->selector,
				Representation => $other_stuff,
				ItemType       => $self->item_type
			);
		}
		elsif ($request_char eq '!')
		{
			$request = new Net::Gopher::Request ('ItemAttribute',
				Host       => $self->host,
				Port       => $self->port,
				Selector   => $self->selector,
				Attributes => $other_stuff
			);
		}
		elsif ($request_char eq '$')
		{
			$request = new Net::Gopher::Request ('DirectoryAttribute',
				Host       => $self->host,
				Port       => $self->port,
				Selector   => $self->selector,
				Attributes => $other_stuff
			);
		}
		else
		{
			return $self->call_die(
				join(' ',
					"Can't convert malformed menu item",
					"into a request object: the Gopher+",
					"string contains an invalid request",
					'type character ("$request_char"). It',
					'should be "+", "?", "!", or "$".'
				)
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
		join(' ',
			"You're trying to convert an inline text (\"i\" item",
			"type) menu item into a Gopher URL. Inline text items",
			"are not supposed to be downloadable."
		)
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

sub item_type { return shift->{'item_type'} }





#==============================================================================#

=head2 display()

This method returns the display string of the menu item.

=cut

sub display { return shift->{'display'} }





#==============================================================================#

=head2 selector()

This method returns the selector string of the menu item.

=cut

sub selector { return shift->{'selector'} }





#==============================================================================#

=head2 host()

This method returns the host field of the menu item.

=cut

sub host { return shift->{'host'} }





#==============================================================================#

=head2 port()

This method returns the port field of the menu item.

=cut

sub port { return shift->{'port'} }





#==============================================================================#

=head2 gopher_plus()

For a Gopher+ menu item, this will return the Gopher+ string of a menu item.
With Gopher items it will just return undef.

=cut

sub gopher_plus { return shift->{'gopher_plus'} }

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

Copyright 2003 by William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
