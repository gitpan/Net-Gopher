
package Net::Gopher::Request;

=head1 NAME

Net::Gopher::Request - Class encapsulating Gopher requests

=head1 SYNOPSIS

 use Net::Gopher::Request;
 
 # to create a Gopher rerquest:
 my $request = new Net::Gopher::Request ('Gopher',
 	Host     => 'gopher.host.com',
 	Selector => '/menu',
 	ItemType => 1
 );
 
 # to create a Gopher+ request:
 my $request = new Net::Gopher::Request ('GopherPlus',
 	Host           => 'gopher.host.com',
 	Selector       => '/item',
 	Representation => 'text/plain',
 	ItemType       => 0
 );
 
 # to create a Gopher+ item attribute information request:
 $request = new Net::Gopher::Request ('ItemAttribute',
 	Host       => 'gopher.host.com',
 	Selector   => '/some_item.txt',
 	Attributes => ['+INFO', '+VIEWS']
 );
 
 # to create a Gopher+ directory attribute information request:
 $request = new Net::Gopher::Request ('DirectoryAttribute',
 	Host       => 'gopher.host.com',
 	Selector   => '/some_dir',
 	Attributes => ['+INFO', '+ADMIN']
 );
 
 # or, use a URL to create one of the above types of requesnt:
 $request = new Net::Gopher::Request ('URL', 'gopher://gopher.host.com/1');

 # You can also send arguments as a hashref instead; which ever style you
 # prefer:
 my $request = new Net::Gopher::Request (
	 Gopher => {
 		Host     => 'gopher.host.com',
 		Selector => '/menu',
 		ItemType => 1
 	}
 );
 
 # all of the possible parameters to new() have accessor methods:
 my $item_type = $request->item_type;
 $request->selector('/another_item');      # change the selector string
 $request->host('gopher.anotherhost.com'); # change the hostname
 ...

=head1 DESCRIPTION

This module encapsulates Gopher and Gopher+ requests. Typical usage of this
module is calling the C<new()> method to create a new request object, then
passing it on to the B<Net::Gopher> C<request()> method.

An aternative to the C<new()> method is the five named constructors detailed
below in L<FUNCTIONS|Net::Gopher::Request/FUNCTIONS>. You can also import them
and call them like functions. In addition, there are four constants which are
exported automatically and are described below in
L<CONSTANTS|Net::Gopher::Request/CONSTANTS>.

For storing and manipulating requests, this class also provides accessor
methods to manipulate every element of a request object.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Carp;
use Net::Gopher::Utility qw(check_params $CRLF);
use Net::Gopher::Constants qw(:request :item_types);
use URI;

@EXPORT_OK = qw(
	Gopher GopherPlus ItemAttribute DirectoryAttribute URL	
);

%EXPORT_TAGS = (
	gopher      => [qw(Gopher URL)],
	gopher_plus => [qw(GopherPlus ItemAttribute DirectoryAttribute URL)],
	all         => [
		qw(Gopher GopherPlus ItemAttribute DirectoryAttribute URL)
	]
);







#==============================================================================#

=head2 new($type, [%args | \%args | $url])

This method creates a new B<Net::Gopher::Request> object, encapsulating a
Gopher or Gopher+ request.

The first argument specifies what type of request you're creating. You're
options are as follows: I<Gopher>, for a Gopher request; I<GopherPlus>, for a
Gopher+ request; I<ItemAttribute>, for a Gopher+ item attribute information
request; I<DirectoryAttribute>, for a Gopher+ directory attribute information
request; and I<URL>, which allows you to create one of the aforementioned
requests using a URL instead of a series of named parameters.

For all types other than I<URL>, following the type are a series of named
parameters optionally in the form of a hash ref.

Depending on which type you specify, your usage will vary:

=over 4

=item I<Gopher>

For Gopher requests the available Name=value pairs are:

 Host        = A hostname (e.g., 'gopher.host.com');
 Port        = A port number (e.g., 70);
 Selector    = A selector string (e.g., '/');
 SearchWords = Query words for a Gopher search type (e.g., 'red blue green');
 ItemType    = The Gopher item type (e.g., '0', '1', '7', 'g', etc.);

E.g.:

 my $request = new Net::Gopher::Request ('Gopher',
 	Host        => 'gopher.host.com',
	Selector    => '/doc.txt',
 	ItemType    => 0
 );

You can send the search words as a reference to an array containing each word
as opposed to one big string containing the words:

 my $request = new Net::Gopher::Request ('Gopher',
 	Host        => 'gopher.host.com',
 	Selector    => '/search_engine.pl',
 	SearchWords => ['red', 'green', 'blue'],
 	ItemType    => 7
 );

=item I<GopherPlus>

For Gopher+ requests, in addition to the I<Host>, I<Port>, I<Selector>, and
I<ItemType> options, you have the following Name=value pairs:

 Representation = What format you want the resource in (e.g., 'text/plain');
 DataBlock      = For Gopher+ Ask forms. Data to be sent to the server.

E.g.:

 my $request = new Net::Gopher::Request ('GopherPlus',
 	Host           => 'gopher.host.com',
 	Selector       => '/script',
 	Representation => 'text/plain',
 	DataBlock      => "Some data"
 );

=item I<ItemAttribute>

For item attribute information requests, in addition to the I<Host>, I<Port>,
and I<Selector> options, you have the following Name=value pairs:

 Attributes = A string or list containing block names (e.g., "+VIEWS+ADMIN");

E.g.:

 my $request = new Net::Gopher::Request ('ItemAttribute',
 	Host       => 'gopher.host.com',
 	Selector   => '/item',
 	Attributes => '+VIEWS+ADMIN'
 );

Also note that you can specify the block names in a list as opposed to a
string and that when doing so, the leading '+' is optional (it will be added
for you):

 my $request = new Net::Gopher::Request ('ItemAttribute',
 	Host       => 'gopher.host.com',
 	Selector   => '/item',
 	Attributes => ['VIEWS', 'ADMIN']
 );

=item I<DirectoryAttribute>

For directory attribute information requests, you have the same parameters as
with item attribute information requests:

 my $request = new Net::Gopher::Request ('DirectoryAttribute',
 	Host       => 'gopher.host.com',
 	Selector   => '/directory',
 	Attributes => ['INFO', 'VIEWS']
 );

=back

Keep in mind that the named parameters can also be sent separately as a
hash reference:

 my $request = new Net::Gopher::Request (
 	Gopher => {
 		Host        => 'gopher.host.com',
 		Selector    => '/',
 		ItemType    => 1
 	}
 );

In addition to C<new()>, there are named constructors you can import and call
like functions L<FUNCTIONS|Net::Gopher::Request/FUNCTIONS> below on how to
import and use the functions.

=cut

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;
	my $type  = shift;

	croak 'No request type specified' unless ($type);



	my %args;
	if ($type =~ /^URL$/i)
	{
		# Since the calling convention is different for URL type
		# requests than all others, we first need to parse the URL
		# and set $type to whatever type of request (Gopher,
		# GopherPlus, ItemAttribute, DirectoryAttribute) this URL is,
		# then put all of the elements of the URL (scheme host, port,
		# search words, etc.) in %args.
		my $url = shift;

		# We need to manually add the scheme to the URL if one isn't
		# there yet. We have to do this instead of just using URI.pm's
		# scheme() method because that--for some reason (I think so
		# URI.pm can handle mailto: URLs)--just adds the scheme name
		# plus a colon to the beginning of the URL if a scheme isn't
		# already there (e.g., if you call  $url->scheme("foo") on a
		# URL like subdomain.domain.com, you end up with
		# foo:subdomain.domain.com, which is not what we want):
		$url = "gopher://$url" unless ($url =~ m|^[a-zA-Z0-9]+?://|);



		my $uri = new URI $url;

		# make sure the URL's scheme isn't something other than gopher:
		croak sprintf('Protocol "%s" is not supported', $uri->scheme)
			unless ($uri->scheme =~ /^gopher$/i);

		# get the host, port, selector, and item type:
		$args{'Host'}     = $uri->host;
		$args{'Port'}     = $uri->port;
		$args{'Selector'} = $uri->selector;
		$args{'ItemType'} = $uri->gopher_type;



		# look for a Gopher+ string:
		if (defined $uri->string and length $uri->string)
		{
			# get the request type character ('+', '?', '!', or
			# '$') and everything after it:
			my ($type_char, $string) = $uri->string =~ /^(.)(.*)/;

			if ($type_char eq '+' or $type_char eq '?')
			{
				$type = 'GopherPlus';

				$args{'Representation'} = $string;
				$args{'SearchWords'} = $uri->search
					if (defined $uri->search and length $uri->search);
			}
			elsif ($type_char eq '!')
			{
				$type = 'ItemAttribute';

				$args{'Attributes'} = $string;
			}
			elsif ($type_char eq '$')
			{
				$type = 'DirectoryAttribute';

				$args{'Attributes'} = $string;
			}
		}
		else
		{
			$type = 'Gopher';

			$args{'SearchWords'} = $uri->search
				if (defined $uri->search and length $uri->search);
		}
	}
	else
	{
		# get the Name=value pairs either from the remaining elements
		# in the array, or, if they were sent instead in a reference 
		# to a hash or array, from the first element in the list:
		if (@_ == 1 and my $ref_type = ref $_[0])
		{
			if ($ref_type eq 'HASH')
			{
				%args = %{ shift(@_) };
			}
			elsif ($ref_type eq 'ARRAY')
			{
				%args = @{ shift(@_) };
			}
			else
			{
				croak "Bad ref type ($ref_type) for parameters"
			}
		}
		else
		{
			%args = @_;
		}
	}



	# now create and fill the request object:
	my $self;

	if ($type =~ /^Gopher$/i)
	{
		my ($host, $port, $selector, $words, $type) =
			check_params(
				[
					'Host', 'Port', 'Selector',
					'SearchWords', 'ItemType'
				], %args
			);

		$self = {
			request_type => GOPHER_REQUEST,
			host         => $host,
			port         => $port || 70,
			selector     => $selector,
			search_words => _parse_words($words),
			item_type    => (defined $type)
						? $type
						: GOPHER_MENU_TYPE
		};
	}
	elsif ($type =~ /^GopherPlus$/i)
	{
		my ($host, $port, $selector, $words, $rep, $data, $type) =
			check_params(
				[
					'Host', 'Port', 'Selector',
					'SearchWords', 'Representation',
					'DataBlock', 'ItemType'
				], %args
			);

		$self = {
			request_type   => GOPHER_PLUS_REQUEST,
			host           => $host,
			port           => $port || 70,
			selector       => $selector,
			search_words   => _parse_words($words),
			representation => $rep,
			data_block     => $data,
			item_type      => (defined $type)
						? $type
						: GOPHER_MENU_TYPE
		};
	}
	elsif ($type =~ /^ItemAttribute$/i)
	{
		my ($host, $port, $selector, $attributes, $type) =
			check_params(
				[
					'Host', 'Port', 'Selector',
					'Attributes', 'ItemType'
				], %args
			);

		$self  = {
			request_type => ITEM_ATTRIBUTE_REQUEST,
			host         => $host,
			port         => $port || 70,
			selector     => $selector,
			attributes   => _parse_attributes($attributes),
			item_type    => $type
		};
	}
	elsif ($type =~ /^DirectoryAttribute$/i)
	{
		my ($host, $port, $selector, $attributes, $type) =
			check_params(
				[
					'Host', 'Port', 'Selector',
					'Attributes', 'ItemType'
				], %args
			);

		$self = {
			request_type => DIRECTORY_ATTRIBUTE_REQUEST,
			host         => $host,
			port         => $port || 70,
			selector     => $selector,
			attributes   => _parse_attributes($attributes),
			item_type    => $type
		};
	}
	else
	{
		croak "Request type ($type) is not valid";
	}
	
	bless($self, $class);

	return $self;
}





################################################################################
# 
# The named constructor methods/exported constructor functions:
# 

sub URL           { return new Net::Gopher::Request ('URL', @_); }
sub Gopher        { return new Net::Gopher::Request ('Gopher', @_); }
sub GopherPlus    { return new Net::Gopher::Request ('GopherPlus', @_); }
sub ItemAttribute { return new Net::Gopher::Request ('ItemAttribute', @_); }
sub DirectoryAttribute
{
	return new Net::Gopher::Request ('DirectoryAttribute', @_);
}





#==============================================================================#

=head2 as_string()

This method returns a string containing a textual representation of the
request. (The B<Net::Gopher> C<request()> method calls this method and sends
the result to the server.)

=cut

sub as_string
{
	my $self = shift;

	my $selector = (defined $self->selector) ? $self->selector : '';

	my $request_string;
	if ($self->request_type == GOPHER_REQUEST)
	{
		$request_string  = $selector;
		$request_string .= "\t" . $self->search_words
			if (defined $self->search_words);

		$request_string .= $CRLF;
	}
	elsif ($self->request_type == GOPHER_PLUS_REQUEST)
	{
		$request_string .= $selector;
		$request_string .= "\t" . $self->search_words
			if (defined $self->search_words);

		$request_string .= "\t+";
		$request_string .= $self->representation
			if (defined $self->representation);

		if (defined $self->data_block)
		{
			# add the data flag to indicate the presence of the
			# data block:
			$request_string .= "\t1";

			# add the data block:
			$request_string .= $CRLF;
			$request_string .= '+' . length $self->data_block;
			$request_string .= $self->data_block;
			$request_string .= $CRLF;
		}
		else
		{
			$request_string .= $CRLF;
		}
	}
	elsif ($self->request_type == ITEM_ATTRIBUTE_REQUEST)
	{
		$request_string .= $selector;
		$request_string .= "\t!";
		$request_string .= $self->attributes
			if (defined $self->attributes);

		$request_string .= $CRLF;
	}
	elsif ($self->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
	{
		$request_string .= $selector;
		$request_string .= "\t\$";
		$request_string .= $self->attributes
			if (defined $self->attributes);

		$request_string .= $CRLF;
	}

	return $request_string;
}





#==============================================================================#

=head2 as_url()

This method returns a string containing a URL constructed from the elements
of the request.

=cut

sub as_url
{
	my $self = shift;

	my $uri = new URI (undef, 'gopher');
	   $uri->scheme('gopher');
	   $uri->host($self->host);
	   $uri->port($self->port);
	   $uri->selector($self->selector)     if (defined $self->selector);
	   $uri->search($self->search_words)   if (defined $self->search_words);
	   $uri->gopher_type($self->item_type) if (defined $self->item_type);

	my $gopher_plus_string;
	if ($self->request_type == GOPHER_PLUS_REQUEST)
	{
		$gopher_plus_string .= '+';
		$gopher_plus_string .= $self->representation
			if (defined $self->representation);
	}
	elsif ($self->request_type == ITEM_ATTRIBUTE_REQUEST)
	{
		$gopher_plus_string .= '!';
		$gopher_plus_string .= $self->attributes
			if (defined $self->attributes);
	}
	elsif ($self->request_type == DIRECTORY_ATTRIBUTE_REQUEST)
	{
		$gopher_plus_string .= '$';
		$gopher_plus_string .= $self->attributes
			if (defined $self->attributes);
	}

	$uri->string($gopher_plus_string);

	return $uri->as_string;
}





#==============================================================================#

=head2 request_type()

This method returns a numeric value indicating the type of request. The number
corresponds to one of the four request type constants: C<GOPHER_REQUEST>,
C<GOPHER_PLUS_REQUEST>, C<ITEM_ATTRIBUTE_REQUEST>, or
C<DIRECTORY_ATTRIBUTE_REQUEST>. E.g.:

 if ($request->request_type == GOPHER_PLUS_REQUEST) {
 	print "It's a Gopher+ request.\n";
 } elsif ($request->request_type == ITEM_ATTRIBUTE_REQUEST) {
 	print "It's an item attribute information request.\n";
 } elsif ($request->request_type == DIRECTORY_ATTRIBUTE_REQUEST) {
 	print "It's a directory attribute information request.\n";
 } else {
 	print "It's just a Gopher request.\n";
 }

See L<Net::Gopher::Constants|Net::Gopher::Constants>

=cut

sub request_type { return shift->{'request_type'} }





#==============================================================================#

=head2 host([$hostname])

This is a get/set method for the I<Host> parameter. You can change the hostname
by supplying a new one. If you don't supply a new hostname, then the current
one will be returned to you.

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

=head2 port([$port_num])

This is a get/set method for the I<Port> parameter. You can change the port
number by supplying a new one. If you don't supply a new port number, then the
current port number will be returned to you.

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

=head2 selector([$selector])

This is a get/set method for the I<Selector> parameter. You can change the
selector string by supplying a new one. If you don't supply a new selector
string, then the current one will be returned to you.

=cut

sub selector
{
	my $self     = shift;
	my $selector = shift;

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

=head2 search_words([$words | @words])

With I<Gopher> and I<GopherPlus> type requests, this is a get/set method for
the I<SearchWords> parameter. You can supply new search words in one of two
formats: as a string containing the words or as a reference to a list
containing individual words, which will be joined together by spaces. If you
don't supply new words, then the current search words will be returned to you
as either a list containing the individual words (in list context) or a string
containing all of the words (in scalar context).

=cut

sub search_words
{
	my $self = shift;

	if (@_)
	{
		$self->{'search_words'} = _parse_words(@_);
	}
	else
	{
		return $self->{'search_words'};
	}
}





#==============================================================================#

=head2 representation([$mime_type])

With I<GopherPlus> type requests, this is a get/set method for the
I<Representation> parameter. You can change the representation by supplying a
new one. If you don't supply a new representation, then the current one will be
returned to you.

=cut

sub representation
{
	my $self = shift;

	if (@_)
	{
		$self->{'representation'} = shift;
	}
	else
	{
		return $self->{'representation'};
	}
}





#==============================================================================#

=head2 data_block([$data])

With I<GopherPlus> type requests, this is a get/set method for the
I<DataBlock> parameter. You can change the data block by supplying new data.
If you don't supply new data, then the current data block will be returned to
you.

=cut

sub data_block
{
	my $self = shift;

	if (@_)
	{
		$self->{'data_block'} = shift;
	}
	else
	{
		return $self->{'data_block'};
	}
}





#==============================================================================#

=head2 attributes([$attributes | @attributes])

With item attribute and directory attribute information requests, this is a
get/set method for the I<Attributes> parameter. You can supply new block names
in one of two formats: as a string containing the block names or as a reference
to a list containing individual block names (with optional leading pluses,
which will be added for you if you don't). If you don't supply new block names,
then the current block names will be returned to you as either a list
containing the individual names (in list context) or a string containing all of
the names (in scalar context).

=cut

sub attributes
{
	my $self = shift;

	if (@_)
	{
		$self->{'attributes'} = _parse_attributes(@_);
	}
	else
	{
		return $self->{'attributes'};
	}
}





#==============================================================================#

=head2 item_type([$type])

This is a get/set method for the I<ItemType> parameter. You can change the item
type by supplying item type. If you don't supply new type, then the current
item type character will be returned to you.

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






################################################################################

sub _parse_words
{
	my $first_arg = $_[0];

	my $search_words;
	if (ref $first_arg)
	{
		$search_words = join(' ', @$first_arg);
	}
	elsif (@_ > 1)
	{
		$search_words = join(' ', @_);
	}
	else
	{
		$search_words = $first_arg;
	}

	return $search_words;
}





################################################################################

sub _parse_attributes
{
	my $first_arg = $_[0];

	my $attributes;
	if (ref $first_arg or @_ > 1)
	{
		foreach my $attribute (ref $first_arg ? @$first_arg : @_)
		{
			# add the leading plus to our string of attributes
			# if this new attributye doesn't have one:
			$attributes .= '+' unless ($attribute =~ /^\+/);

			$attributes .= $attribute;
		}
	}
	else
	{
		$attributes = $first_arg;
	}

	return $attributes;
}

1;

__END__

=head1 FUNCTIONS

Besides C<new()>, there are several functions you can export and call to create
requests object. The functions are C<Gopher()>, C<GopherPlus()>,
C<ItemAttribute()>, C<DirectoryAttribute()>, and C<URL()>.

These functions each take the same arguments that their C<new()> counterparts
do:

 my $request = Gopher(
 	Host     => 'gopher.host.com',
 	Selector => '/',
 	ItemType => 1
 );

is the same as:

 my $request = new Net::Gopher::Request ('Gopher',
 	Host     => 'gopher.host.com',
 	Selector => '/',
 	ItemType => 1
 );

If you don't want to import each one explicitly, then you can use one of the
following export tags:

=over 4

=item :gopher

Exports C<Gopher()> and C<URL()>.

=item :gopher_plus

Exports C<GopherPlus()>, C<ItemAttribute()>, C<DirectoryAttribute()>, and
C<URL()>.

=item :all

Exports C<Gopher()>, C<GopherPlus()>, C<ItemAttribute()>,
C<DirectoryAttribute()>, and C<URL()>.

=back

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
