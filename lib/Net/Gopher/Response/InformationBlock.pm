
package Net::Gopher::Response::InformationBlock;

=head1 NAME

Net::Gopher::Response::InformationBlock - Manipulate Gopher+ information blocks

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 
 my $block = $response->get_blocks(Blocks => '+ADMIN');
 printf("%s: %s\n", $block->name, $block->value);
 
 # if you don't need to do anything fancy, you can just treat block
 # objects as strings, and they'll behave correctly, returning what's
 # returned by value():
 print $response->get_blocks(Blocks => '+ABSTRACT');
 
 
 
 # if a block value contains attributes, you can retrieve all of the
 # attributes within it at once in the form of a hash using
 # attributes_as_hash():
 my %attributes = $block->attributes_as_hash;
 print(
 	"Gopherspace name: $attributes{'Site'}\n",
 	"    Organization: $attributes{'Org'}\n",
 	"        Location: $attributes{'Loc'}\n"
 );
 
 # ...or you retrieve one or more individual attribute values by name
 # using get_attributes():
 printf("    Adminstrator: %s\n", $block->get_attributes('Admin'));
 
 
 
 # There are also methods available to parse individual block values and
 # attributes. For example, the extract_description() method parses
 # +INFO blocks and extracts their contents:
 my ($type, $display, $selector, $host, $port, $gopher_plus) =
 	$response->get_blocks(Blocks => '+INFO')->extract_description;
 
 # finally, note that for all of the block and attribute parsing methods
 # in this class, there are wrappers in Net::Gopher::Response which
 # enable you call the methods directly on the Net::Gopher::Response
 # object for item attribute information requests:
 my ($admin_name, $admin_email) = $response->extract_admin;
 
 # ...is the same as:
 ($admin_name, $admin_email) =
 	$response->get_blocks(Blocks => '+ADMIN')->extract_admin;

=head1 DESCRIPTION

The L<Net::Gopher::Response|Net::Gopher::Response> C<get_blocks()> method
returns one or more item/directory attribute information blocks in the form of
B<Net::Gopher::Response::InformationBlocks> objects. This class contains
methods to parse and manipulate these block objects.

To make things as simple as possible, this class overloads stringification,
so if you don't need to do anything fancy and just want the block value, you
can treat these objects as though they're strings and they'll behave like
strings, returning what the C<value()> method does.

The first series of methods in this class retrieve block names, block values,
and attributes within block values. After that, there are methods to extract
specific bits of information from certain blocks.

=head1 METHODS

The following methods are available:

=cut

use 5.005;
use strict;
use warnings;
use vars qw(@ISA);
use overload (
	'""'     => sub { shift->value },
	fallback => 1,
);
use Carp;
use Time::Local 'timelocal';
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

	my ($response, $name, $raw_value, $value) =
		check_params([qw(
			Response
			Name
			RawValue
			Value
			)], \@_
		);

	my $self = {
		# the Net::Gopher::Response object:
		response   => $response,

		# the block name, minus the leading "+" (e.g., "ADMIN," "INFO,"
		# "VIEWS," etc.):
		name       => $name,

		# the raw block value, with the leading space at the beginning
		# of each line still intact:
		raw_value  => $raw_value,

		# the cleaned up block value, with the leading spaces removed:
		value      => $value,

		# if the block contains " AttributeName: attribute value" pairs
		# of attributes on each line, then this will contain a
		# reference to a hash with the attribute names and their
		# corresponding attribute values:
		attributes => undef
	};

	bless($self, $class);

	return $self;
}





#==============================================================================#

sub response { return shift->{'response'}; }





#==============================================================================#

=head2 name()

This method returns the block name (prefixed with a leading "+" character,
e.g., "+ADMIN").

=cut

sub name { return '+' . shift->{'name'} }





#==============================================================================#

=head2 value()

This method will return the content of the block value, with the leading space
at the beginning of each line removed.

=cut

sub value { return shift->{'value'} }





#==============================================================================#

=head2 raw_value()

This method will return the unmodified block value, with the leading space
at the beginning of each line intact.

=cut

sub raw_value { return shift->{'raw_value'} };





#==============================================================================#

=head2 attributes_as_hash()

If the block value contains a series of C<Name: value> attributes on lines by
themselves, then you can use this method to retrieve them all as a hash. This
method will return a hash (in list context) or a reference to a hash (in scalar
context) containing the attribute names and values.

=cut

sub attributes_as_hash
{
	my $self = shift;

	$self->_parse_attributes unless (defined $self->{'attributes'});

	# if it was called in list context, then rather than just returning the
	# hash in $self->{'attributes'}, we return a copy of it, to prevent the
	# user from directly manipulating $self->{'attributes'}:
	return wantarray
		? %{$self->{'attributes'}}
		: { %{$self->{'attributes'}} };
}





#==============================================================================#

=head2 get_attributes(@names)

If the block value contains a series of C<Name: value> attributes on lines by
themselves, then you can use this method to retrieve one or more attribute
values by name. Just supply the names of the attributes you want, and this
method will return them.

=cut

sub get_attributes
{
	my ($self, @names) = @_;

	return $self->call_die(
		'The names of the attributes to get were not supplied.'
	) unless (@names);

	unless (defined $self->{'attributes'})
	{
		return unless ($self->_parse_attributes);
	}

	my @values = @{ $self->{'attributes'} }{@names};

	return wantarray ? @values : shift @values;
}





#==============================================================================#

=head2 is_attributes()

This method checks to see if the block value contains C<Name: value> attributes
on lines by themselves. If it does, then this method will return true; undef
otherwise.

=cut

sub is_attributes
{
	my $self = shift;

	my $attribute = qr/ .+?:(?: .*)?/o;

	if ($self->raw_value =~ /^$attribute(?:\n$attribute)*$/o)
	{
		return 1;
	}
}





#==============================================================================#

=head2 as_request()

Documentation.

=cut

sub as_request
{
	my $self = shift;

	return new Net::Gopher::Request (URL => $self->as_url);
}





#==============================================================================#

=head2 as_url()

Documentation.

=cut

sub as_url
{
	my $self = shift;

	my ($item_type, $display, $selector, $host, $port, $gopher_plus) =
		$self->extract_description;

	my $uri = new URI (undef, 'gopher');
	   $uri->scheme('gopher');
	   $uri->host($host);
	   $uri->port($port);
	   $uri->gopher_type($item_type);
	   $uri->selector($selector);
	   $uri->string($gopher_plus);

	return $uri->as_string;
}





#==============================================================================#

=head1 METHODS SPECIFIC TO +ABSTRACT BLOCKS

C<+ABSTRACT> blocks contain a short synopsis of the item. 

=head2 extract_abstract()

=cut

sub extract_abstract
{
	my $self = shift;

	
}





#==============================================================================#

=head1 METHODS SPECIFIC TO +ADMIN BLOCKS

C<+ADMIN> blocks contain attributes detailing information about a particular
item including who the administrator of it is and when it was last modified.
C<+ADMIN> blocks have at least two attributes: I<Admin> and I<Mod-Date>, though
they can (and often do) contain many more.

The following methods are available specifically for parsing C<+ADMIN> blocks
and their attribute:

=head2 extract_admin()

This method can be used to parse the I<Admin> attribute of an C<+ADMIN> block.
The I<Admin> attribute contains the name of the administrator and his or her
email address (e.g., "John Doe <jdoe@notreal.email>").

This method returns the the administrator name and the adminstrator email from
the I<Admin> attribute.

=cut

sub extract_admin
{
	my $self = shift;

	if (my $attribute = $self->get_attributes('Admin'))
	{
		my ($name, $email) = $attribute =~ /(.+?)\s*<(.*?)>\s*/;

		return($name, $email);
	}
}





#==============================================================================#

=head2 extract_date_modified()

This method can be used to parse the I<Mod-Date> attribute of an C<+ADMIN>
block. The I<Mod-Date> attribute contains a timestamp of when the item was last
modified.

This method returns an integer in the same format of the one returned by Perl's
built-in C<time()> function corresponding to the timestamp, which you can
supply to the built in C<localtime()> function (see <perldoc -f localtime>).

=cut

sub extract_date_modified
{
	my $self = shift;

	if (my $attribute = $self->get_attributes('Mod-Date'))
	{
		return $self->_parse_timestamp($attribute);
	}
}





#==============================================================================#

=head2 extract_date_created()

This method can be used to parse the I<Creation-Date> attribute of an +ADMIN
block. The I<Creation-Date> attribute contains a timestamp of when the item
was last modified.

This method returns an integer in the same format of the one returned by Perl's
built-in C<time()> function corresponding to the timestamp, which you can
supply to the built in C<localtime()> function (see <perldoc -f localtime>).

=cut

sub extract_date_created
{
	my $self = shift;

	if (my $attribute = $self->get_attributes('Creation-Date'))
	{
		return $self->_parse_timestamp($attribute);
	}
}





#==============================================================================#

=head2 extract_date_expires()

This method can be used to parse the I<Expiration-Date> attribute of an +ADMIN
block. The I<Expiration-Date> attribute (if present) contains a timestamp of
when the item is set to expire and should be rerequested.

This method returns an integer in the same format of the one returned by Perl's
built-in C<time()> function corresponding to the timestamp, which you can
supply to the built in C<localtime()> function (see <perldoc -f localtime>).

=cut

sub extract_date_expires
{
	my $self = shift;

	if (my $attribute = $self->get_attributes('Expiration-Date'))
	{
		return $self->_parse_timestamp($attribute);
	}
}





#==============================================================================#

=head1 METHODS SPECIFIC TO +ASK BLOCKS

C<+ASK> blocks contain a form to be filled out by the user, with Ask queries on
lines by themselves consisting of query type followed by the question and any
default values separated by tabs (e.g.,
"Ask: Some question?\tdefault answer 1\tdefault answer 2",
"Choose: A question?choice 1\tchoice 2\tchoice3").

The following methods are available specifically for parsing C<+ASK> blocks:

=head2 extract_queries()

This method parses the C<+ASK> block and returns an array containing references
to hashes for each Ask query in the order they appeared, with each hash having
the following key=value pairs:

 type     = The type of query (e.g, Ask, AskP, Select, Choose, etc.);
 question = The question;
 defaults = A reference to an array containing the default answers;

=cut

sub extract_queries
{
	my $self = shift;

	$self->call_warn(
		sprintf('Are you sure there are queries to extract? The block '.
		        'object contains a %s block, not an +ASK block.',
			$self->name
		)
	) unless ($self->name eq '+ASK');



	# This will store each Ask query as a hashref containing the query
	# type, the question, and any defaults:
	my @ask;

	foreach my $query (split(/\n/, $self->value))
	{
		# get the query type and the question and default values:
		my ($type, $question_and_defaults) = $query =~ /^(\S+)+:\s?(.*)/;

		# the question and any default values are all tab separated:
		my ($question, @defaults) = split(/\t/, $question_and_defaults);

		push(@ask, {
				type     => $type,
				question => $question,
				defaults => \@defaults
			}
		);
	}

	return @ask;
}





#==============================================================================#

=head1 METHODS SPECIFIC TO +INFO BLOCKS

C<+INFO> blocks contain tab delimited item information like that which you'd
find in a Gopher menu.

The following methods are available specifically for parsing C<+INFO> blocks:

=head2 extract_description()

This method parses C<+INFO> blocks and returns the item type, display string,
selector string, host, port, and Gopher+ string:

 my ($type, $display, $selector, $host, $port) =
 	$block->extract_description;
 
 print "$type     $display ($selector at $host:$port")\n";

Note that this method is inherited by B<Net::Gopher::Response>. You can call
this method directly on a B<Net::Gopher::Response> object, in which case
this method will call C<$response-E<gt>get_blocks('+INFO')> and use that
block object. Thus this:

 my ($type, $display, $selector, $host, $port) =
 	$response->extract_description;

is the same as this:

 my ($type, $display, $selector, $host, $port) =
 	$response->get_blocks(Blocks => '+INFO')->extract_description;

=cut

sub extract_description
{
	my $self = shift;



	# get the item type and display string, selector, host, port,
	# and Gopher+ string from the +INFO block value:
	my ($type_and_display, $selector, $host, $port, $gopher_plus) =
			split(/\t/, $self->value);

	# separate the item type and the display string:
	my ($type, $display) = $type_and_display =~ /^(.)(.*)/;

	return($type, $display, $selector, $host, $port, $gopher_plus);
}





#==============================================================================#

=head1 METHODS SPECIFIC TO +VIEWS BLOCKS

C<+VIEWS> blocks contain a list of available formats for a single item,
allowing clients to select formats based on size, MIME type, and language.

The following methods are available specifically for parsing C<+VIEWS> blocks:

=head2 extract_views()

This method parses C<+VIEWS> blocks and returns an array containing references
to hashes for each view with the following key=value pairs:

 type     = The MIME type (e.g., text/plain, application/gopher+-menu, etc.);
 language = The ISO-639 language code (e.g., En, De, etc.);
 country  = The ISO-3166 country code (e.g., US, UK, JP, etc.);
 size     = The size in bytes;

Note that this method will convert the <\dk?> size format used in Gopher+ to
an integer; the total size in bytes (e.g., <80> becomes 80, <40K> becomes
40000, <.4K> becomes 400, <400B> becomes 400):

 my @views = $response->get_blocks(Blocks => '+VIEWS')->as_views;
 
 foreach my $view (@views) {
 	print "$view->{'type'} ($view->{'size'} bytes)\n";
 ...
 	my $another_response = $ng->request(
		new Net::Gopher::Request (
 			Gopher => {
				Host           => $host,
 				Selector       => $selector,
 				Representation => $view->{'type'}
 			}
		)
 	);
 ...
 }

=cut

sub extract_views
{
	my $self = shift;

	$self->call_warn(
		sprintf('Are you sure there are views to extract? The block '.
		        'object contains a %s block, not an +VIEWS block.',
			$self->name
		)
	) unless ($self->name eq '+VIEWS');



	# This array will store each view as a hashref:
	my @views;

	foreach my $view (split(/\n/, $self->value))
	{
		# separate the MIME type, language/country, and size:
		my ($mime_type, $language_and_country, $size) =
			$view =~ /^([^:]*?) (?: \s ([^:]{5}) )?:(.*)$/x;

		# get the size in bytes:
		my $size_in_bytes;
		if (defined $size and $size =~ /<(\.?\d+) (?: (k)|b )?>/ix)
		{
			# turn <55> into 55, <600B> into 600, <55K> into 55000,
			# and <.5K> into 500:
			$size_in_bytes  = $1;
			$size_in_bytes *= 1000 if ($2);
		}

		# get the ISO-639 language code and the ISO-3166 country code:
		my ($language, $country);
		if (defined $language_and_country)
		{
			($language, $country) =
				split(/_/, $language_and_country);
		}

		push(@views, {
				type     => $mime_type,
				language => $language,
				country  => $country,
				size     => $size_in_bytes
			}
		);
	}

	return @views;
}





sub _parse_attributes
{
	my $self = shift;

	my %attributes;
	foreach my $attribute (split(/\n/, $self->value))
	{
		# parse the "AttributeName: attribute value" string:
		my ($name, $value) = $attribute =~ /^(.+?):\s?(.*)/;

		$attributes{$name} = $value;
	}

	$self->{'attributes'} = \%attributes;
}





sub _parse_timestamp
{
	my ($self, $timestamp) = @_;

	return unless (defined $timestamp);

	# get the values from the timestamp:
	my ($year, $month, $day, $hour, $minute, $second) =
		$timestamp =~ /<(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})>/x;

	unless (defined $year and defined $month and defined $day
		and defined $hour and defined $minute and defined $second)
	{
		return;
	}

	# we need to convert the year value into the  number years since 1900
	# (i.e., 2003 -> 103), since that's the format returned by localtime():
	$year -= 1900;

	# localtime() months are numbered from 0 to 11, not 1 to 12:
	$month--;

	# now that we have the second, minute, hour, day, month, and year, we
	# use them to get a corresponding time() value:
	return timelocal($second, $minute, $hour, $day, $month, $year);
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

Copyright 2003 by William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
