
package Net::Gopher::Response::InformationBlock;

=head1 NAME

Net::Gopher::Response::InformationBlock - Manipulate Gopher+ information blocks

=head1 SYNOPSIS

 use Net::Gopher;
 ...
 
 my $block = $response->get_block('+ADMIN');
 printf("%s: %s\n", $block->name, $block->value);
 
 # if you don't need to do anything fancy, you can just treat block
 # objects as strings, and they'll behave correctly, returning what's
 # returned by value():
 print $response->get_block('+ABSTRACT');
 
 
 
 # if a block value contains attributes, you can retrieve all of the
 # attributes within it at once in the form of a hash using
 # get_attributes():
 $block = $response->get_block('+ADMIN');
 my %attributes = $block->get_attributes;
 print(
 	"Gopherspace name: $attributes{'Site'}\n",
 	"    Organization: $attributes{'Org'}\n",
 	"        Location: $attributes{'Loc'}\n"
 );
 
 # ...or you can retrieve individual attribute values by name using
 # get_attribute():
 printf("    Adminstrator: %s\n", $block->get_attribute('Admin'));
 
 
 
 # There are also methods available to parse individual block values and
 # attributes. For example, the extract_descriptor() method parses
 # +INFO blocks and extracts their contents:
 my ($type, $display, $selector, $host, $port, $gopher_plus) =
 	$response->get_block('+INFO')->extract_descriptor;
 
 # finally, note that for all of the block and attribute parsing methods
 # in this class, there are wrappers in Net::Gopher::Response which
 # enable you call the methods directly on the Net::Gopher::Response
 # object for item attribute information requests:
 my ($admin_name, $admin_email) = $response->extract_admin;
 
 # ...is the same as:
 ($admin_name, $admin_email) =
 	$response->get_block('+ADMIN')->extract_admin;

=head1 DESCRIPTION

Both the L<Net::Gopher::Response|Net::Gopher::Response> C<get_block()> and
C<get_blocks()> methods returns one or more item/directory attribute
information blocks in the form of B<Net::Gopher::Response::InformationBlocks>
objects. This class contains methods to parse and manipulate these block
objects.

To make things as simple as possible, this class overloads stringification,
so if you don't need to do anything fancy and just want the block value, you
can treat these objects as though they're strings and they'll behave like
strings, returning what the C<value()> method does.

The first series of methods in this class retrieve block names, block values,
and attributes within block values. After that, there are methods to extract
specific bits of information from certain blocks and certain attributes within
certain blocks.

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
use Time::Local 'timegm';
use Net::Gopher::Constants ':item_types';
use Net::Gopher::Debugging;
use Net::Gopher::Exception;
use Net::Gopher::Request;
use Net::Gopher::Utility qw(
	$ITEM_PATTERN
	$NEWLINE_PATTERN
	
	get_named_params
	ceil
);

push(@ISA, qw(Net::Gopher::Debugging Net::Gopher::Exception));







################################################################################

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my ($response, $name, $raw_value, $value);
	get_named_params({
		Response => \$response,
		Name     => \$name,
		RawValue => \$raw_value,
		Value    => \$value
		}, \@_
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

This method returns the name of the block stored in the block object (prefixed
with the leading "+" character, e.g., "+ADMIN").

=cut

sub name { return '+' . shift->{'name'} }





#==============================================================================#

=head2 value()

This method will return the content of the block value, with the leading space
at the beginning of each line removed for multiline values.

=cut

sub value { return shift->{'value'} }





#==============================================================================#

=head2 raw_value()

This method will return the unmodified block value, with the leading space
at the beginning of each line intact.

=cut

sub raw_value { return shift->{'raw_value'} };





#==============================================================================#

=head2 get_attribute(NAME)

If the block value contains a series of C<Name: value> attributes on lines by
themselves, then you can use this method to retrieve an attribute value by
name. Just supply the name of the attribute you want and this method will
return it if it exists.

=cut

sub get_attribute
{
	my ($self, $name) = @_;

	return $self->call_die(
		'The name of the attribute to retrieve was not supplied.'
	) unless ($name);

	unless (defined $self->{'attributes'})
	{
		return unless ($self->_extract_attributes);
	}

	return $self->{'attributes'}{$name}
		if (exists $self->{'attributes'}{$name});
}





#==============================================================================#

=head2 get_attributes([NAMES])

If the block value contains a series of C<Name: value> attributes on lines by
themselves, then you can use this method to retrieve multipule attribute values
at once. If you specify one or more attribute names as arguments, then this
method will return a list containing the corressponding attribute values. If
you don't specify any attribute names, them all of the attributes for the
particular block will be returned to you at once as a hash (in list context) or
as a reference to a hash (in scalar context).

=cut

sub get_attributes
{
	my $self  = shift;
	my @names = @_;

	unless (defined $self->{'attributes'})
	{
		$self->_extract_attributes or return;
	}

	if (@names)
	{
		# we go searching through $self->{'attributes'} for each name
		# rather than just using a hash slice because that would end
		# up autovivifying hash keys that don't already exist,
		# potentially corrupting has_attribute():
		my @values;
		foreach my $name (@names)
		{
			push(@values,
				(exists $self->{'attributes'}{$name})
					? $self->{'attributes'}{$name}
					: undef
			);
		}
	}
	else
	{
		# if it was called in scalar context, then rather than just
		# returning the reference to the hash in $self->{'attributes'},
		# we create a new hash with the same elements as the one in
		# $self->{'attributes'} and return a referense to that instead
		# to prevent the user from directly manipulating
		# $self->{'attributes'}:
		return wantarray
			? %{ $self->{'attributes'} }
			: { %{ $self->{'attributes'} } };
	}
}





#==============================================================================#

=head2 has_attribute()

If the block value contains a series of C<Name: value> attributes on lines by
themselves, then you can use this method to check to see if the block has a
particular attribute. Just supply the attribute name and this method will
return true if it exists; undef otherwise.

=cut

sub has_attribute
{
	my ($self, $name) = @_;

	return $self->call_die('The name of the attribute was not supplied.')
		unless ($name);

	unless (defined $self->{'attributes'})
	{
		$self->_extract_attributes or return;
	}

	return 1 if (exists $self->{'attributes'}->{$name});
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

	return 1 if ($self->raw_value =~
		/^$attribute(?:$NEWLINE_PATTERN$attribute)*$/o);
}





#==============================================================================#

=head2 is_descriptor()

This method checks to see if the block value contains an item descpriptor like
you'd find in a Gopher menu or a Gopher+ +INFO block.

=cut

sub is_descriptor
{
	my $self = shift;

	return 1 if ($self->value =~ $ITEM_PATTERN);
}

# for backwards compatibility:
sub is_description
{
	my $self = shift;

	$self->call_warn(
		'The is_description() method is depricated. Use ' .
		'is_descriptor() instead.'
	);

	return $self->is_descriptor;
}





#==============================================================================#

=head2 as_request()

If the block value contains an item descriptor, then you can use this method
to create a request object from it.

=cut

sub as_request
{
	my $self = shift;

	return new Net::Gopher::Request (URL => $self->as_url);
}





#==============================================================================#

=head2 as_url()

If the block value contains an item descriptor, then you can use this method
to create a URL from it.

=cut

sub as_url
{
	my $self = shift;

	my ($item_type, $display, $selector, $host, $port, $gopher_plus) =
		$self->extract_descriptor;

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

C<+ABSTRACT> blocks contain a short synopsis of the item, or a item description
indicating where the abstract can be downloaded from.

=head2 extract_abstract()

The C<extract_abstract()> (sorry for the name) method extracts an item
abstract, either directly from the block value if the block value contains it,
or if the block value contains an item descriptor of where the abstract can be
downloaded from, it will download the item containing the abstract. It returns
a striing containing the item abstract.

=cut

sub extract_abstract
{
	my $self = shift;

	return $self->call_warn(
		sprintf("The block object contains a %s block, not an " .
		        "+ABSTRACT block. Are you sure there's an item " .
			"abstract to extract?",
			$self->name
		)
	) unless ($self->name eq '+ABSTRACT');

	if ($self->is_descriptor)
	{
		my $ng = $self->response->ng;

		my $request = $self->as_request;

		my $response = $ng->request($request);

		return $self->call_die(
			sprintf("Couldn't retrieve abstract: %s.",
				$response->error
			)
		) if ($response->is_error);

		return $response->content;
	}
	else
	{
		return $self->value;
	}
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

	$self->call_warn(
		sprintf("Are you sure there's administrator information to " .
			"extract? The block object contains a %s block, not " .
			"an +ADMIN block.",
			$self->name
		)
	) unless ($self->name eq '+ADMIN');

	unless (defined $self->{'attributes'})
	{
		$self->_extract_attributes or return;
	}

	return $self->call_die(
		sprintf('The %s block has no Admin attribute to extract ' .
		        'item administrator information from.',
			$self->name
		)
	) unless ($self->has_attribute('Admin'));

	my $attribute = $self->get_attribute('Admin');

	my ($admin_name, $admin_email) = $attribute =~ /(.+?)\s*<(.+?)>\s*/;

	return $self->call_die(
		sprintf('The %s block contains a malformed Admin attribute.',
			$self->name
		)
	) unless (defined $admin_name and defined $admin_email);

	return($admin_name, $admin_email);
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

	$self->call_warn(
		sprintf("Are you sure there's a modification date timestamp " .
			"to extract? The block object contains a %s block, " .
			"not an +ADMIN block.",
			$self->name
		)
	) unless ($self->name eq '+ADMIN');

	unless (defined $self->{'attributes'})
	{
		$self->_extract_attributes or return;
	}

	return $self->call_die(
		sprintf('The %s block has no Mod-Date attribute to extract ' .
		        'a modification date from.',
			$self->name
		)
	) unless ($self->has_attribute('Mod-Date'));

	return $self->_extract_attribute_timestamp('Mod-Date');
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

	$self->call_warn(
		sprintf("Are you sure there's a creation date timestamp " .
			"to extract? The block object contains a %s block, " .
			"not an +ADMIN block.",
			$self->name
		)
	) unless ($self->name eq '+ADMIN');

	unless (defined $self->{'attributes'})
	{
		$self->_extract_attributes or return;
	}

	return $self->call_die(
		sprintf('The %s block has no Creation-Date attribute to ' .
		        'extract a creation date from.',
			$self->name
		)
	) unless ($self->has_attribute('Creation-Date'));

	return $self->_extract_attribute_timestamp('Creation-Date');
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

	$self->call_warn(
		sprintf("Are you sure there's an expiration date timestamp " .
			"to extract? The block object contains a %s block, " .
			"not an +ADMIN block.",
			$self->name
		)
	) unless ($self->name eq '+ADMIN');

	unless (defined $self->{'attributes'})
	{
		$self->_extract_attributes or return;
	}

	return $self->call_die(
		sprintf('The %s block has no Expiration-Date attribute to ' .
		        'extract an expiration date from.',
			$self->name
		)
	) unless ($self->has_attribute('Expiration-Date'));

	return $self->_extract_attribute_timestamp('Expiration-Date');
}






#==============================================================================#

=head1 METHODS SPECIFIC TO +ASK BLOCKS

C<+ASK> blocks contain a form to be filled out by the user, with Ask queries on
lines by themselves consisting of query type followed by the question and any
default values separated by tabs (e.g.,
"Ask: Some question?\tdefault answer 1",
"Choose: A question?choice 1\tchoice 2\tchoice3").

The following methods are available specifically for parsing C<+ASK> blocks:

=head2 extract_queries()

This method parses an C<+ASK> block and returns an array containing references
to hashes for each Ask query in the order they appeared, with each hash having
the following key=value pairs:

 type     = The type of query (e.g, Ask, AskP, Select, Choose, etc.);
 question = The question;
 value    = Any default answer;

For C<Choose> query types, the hash contains an additional "choices" element
that contains a reference to an array of strings for each possible choice.

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
		# get the query type, question, and default value or
		# choices:
		my ($type, $question_and_fields) = split(/:\s?/, $query, 2);

		return $self->call_die(
			sprintf('This %s block either does not contain any ' .
			        'queries or it contains malformed queries.',
				$self->name
			)
		) unless (defined $type and defined $question_and_fields);

		# the question and any value or choices are all tab separated:
		my ($question, @fields) = split(/\t/, $question_and_fields);

		my $query = {
			type     => $type,
			question => $question
		};

		if ($type eq 'Choose')
		{
			$query->{'choices'} = [ @fields ];
		}
		else
		{
			$query->{'value'} = shift @fields;
		}

		push(@ask, $query);
	}

	

	return @ask;
}





#==============================================================================#

=head1 METHODS SPECIFIC TO +INFO BLOCKS

C<+INFO> blocks contain tab delimited item information like that which you'd
find in a Gopher menu.

The following methods are available specifically for parsing C<+INFO> blocks:

=head2 extract_descriptor()

This method parses C<+INFO> blocks and returns the item type, display string,
selector string, host, port, and Gopher+ string:

 my ($type, $display, $selector, $host, $port) =
 	$block->extract_descriptor;
 
 print "$type     $display ($selector at $host:$port")\n";

Note that this method is inherited by B<Net::Gopher::Response>. You can call
this method directly on a B<Net::Gopher::Response> object, in which case
this method will call C<$response-E<gt>get_block('+INFO')> and use that
block object. Thus this:

 my ($type, $display, $selector, $host, $port) =
 	$response->extract_descriptor;

is the same as this:

 my ($type, $display, $selector, $host, $port) =
 	$response->get_block('+INFO')->extract_descriptor;

=cut

sub extract_descriptor
{
	my $self = shift;

	# get the item type and display string, selector, host, port,
	# and Gopher+ string from the block value:
	my ($type_and_display, $selector, $host, $port, $gopher_plus) =
			split(/\t/, $self->value);

	return $self->call_die(
		sprintf('The %s block either does not contain an item ' .
		        'descriptor or it contains a malformed one.',
			$self->name
		)
	) unless (defined $type_and_display
		and defined $selector
		and defined $host
		and defined $port);

	# separate the item type and the display string:
	my ($type, $display) =
		(substr($type_and_display, 0, 1), substr($type_and_display, 1));

	return($type, $display, $selector, $host, $port, $gopher_plus);
}

# for backwards compatibility:
sub extract_description
{
	my $self = shift;

	$self->call_warn(
		'The extract_description() method is depricated. Use ' .
		'extract_descriptor() instead.'
	);

	return $self->extract_descriptor(@_);
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
40960, <.4K> becomes 410, <400B> becomes 400):

 my @views = $response->get_block('+VIEWS')->extract_views;
 
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
		        'object contains a %s block, not a +VIEWS block.',
			$self->name
		)
	) unless ($self->name eq '+VIEWS');



	# This array will store each view as a hashref:
	my @views;

	foreach my $view (split(/\n/, $self->value))
	{
		# separate the MIME type, language/country codes, and size:
		my ($mime_type, $language_and_country, $size) =
			$view =~ /^([^:]*?) (?: \s ([^:]{5}) )?:(.*)$/x;

		return $self->call_die(
			sprintf("This %s block either does not contain any " .
			        "views or it contains malformed views.",
				$self->name
			)
		) unless (defined $mime_type);

		# get the size in bytes:
		my $size_in_bytes;
		if (defined $size and $size =~ /<([\.\-0-9]+)(kb|k|b)?>/i)
		{
			# turn <55> into 55, <600B> into 600, <55K> into 56320,
			# <.5K> into 512:
			$size_in_bytes = $1;

			if ($2 and lc $2 eq 'kb' || lc $2 eq 'k')
			{
				$size_in_bytes *= 1024;

				# round up to nearest whole byte:
				$size_in_bytes = ceil($size_in_bytes);
			}
		}

		# extract the ISO-639 language code and the ISO-3166 country
		# code:
		my ($language, $country);
		($language, $country) = split(/_/, $language_and_country)
			if (defined $language_and_country);

		push(@views, {
			type     => $mime_type,
			language => $language,
			country  => $country,
			size     => $size_in_bytes
		});
	}

	return @views;
}





sub _extract_attributes
{
	my $self = shift;

	my %attributes;
	foreach my $attribute (split(/\n/, $self->value))
	{
		# parse the "AttributeName: attribute value" string:
		my ($name, $value) = $attribute =~ /^(.+?): ?(.*)/;

		return $self->call_die(
			sprintf('This %s block either does not contain ' .
				'attributes or contains malformed attributes.',
				$self->name
			)
		) unless ($name);

		$attributes{$name} = $value;
	}
	

	$self->{'attributes'} = \%attributes;
}





sub _extract_attribute_timestamp
{
	my ($self, $attribute) = @_;

	my $timestamp = $self->get_attribute($attribute);

	# get the values from the timestamp:
	my ($year, $month, $day, $hour, $minute, $second) =
		$timestamp =~ /<(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})>/;

	return $self->call_die(
		"The $attribute attribute either does not contain a " .
		"timestamp or contains a malformed one."
	) unless (defined $year and defined $month and defined $day
		and defined $hour and defined $minute and defined $second);

	# we need to convert the year value into the  number years since 1900
	# (i.e., 2003 -> 103), since that's the format returned by localtime():
	$year -= 1900;

	# localtime() months are numbered from 0 to 11, not 1 to 12:
	$month--;

	# now that we have the second, minute, hour, day, month, and year, we
	# use them to get a corresponding time() value:
	return timegm($second, $minute, $hour, $day, $month, $year);
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
