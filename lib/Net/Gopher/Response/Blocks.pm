# Copyright 2003, William G. Davis.
# 
# Please read the POD in Net::Gopher::Response before looking at this code.

package Net::Gopher::Response::Blocks;

use 5.005;
use strict;
use warnings;
use Carp;
use Time::Local qw(timelocal);
use Net::Gopher::Utility qw(check_params $NEWLINE);







#==============================================================================#

sub new
{
	my $invo  = shift;
	my $class = ref $invo || $invo;

	my ($name, $value) = check_params(['BlockName', 'BlockValue'], @_);

	my $self = {
		name  => $name,
		value => $value
	};

	bless($self, $class);

	return $self;
}





#==============================================================================#

sub content
{
	my $self = shift;

	my $block_value = $self->{'value'};
	   $block_value =~ s/^\s//mg;

	return $block_value;
}





#==============================================================================#

sub as_string { return shift->{'value'} };





#==============================================================================#

sub as_attributes
{
	my $self = shift;

	my %attributes = $self->_get_attributes_hash;

	return wantarray ? %attributes : \%attributes;
}





#==============================================================================#

sub as_admin
{
	my $invo = shift;

	my $self;
	if (ref $invo eq 'Net::Gopher::Response')
	{
		$self = $invo->item_blocks('ADMIN');
	}
	else
	{
		$self = $invo;
	}



	# ADMIN blocks contain at least two attributes, Admin and Mod-Date, in
	# the form of:
	# 
	#   Admin: Foo Bar <foobar@foo.com>
	#   Mod-Date: WWW MMM DD hh:mm:ss YYYY <YYYYMMDDhhmmss>
	# 
	# first, get Admin, Mod-Date, and any other attributes in the form
	# of a hash:
	my %attributes = $self->_get_attributes_hash;

	if (exists $attributes{'Admin'})
	{
		# now for the Admin attribute, get the admin name and email:
		my ($name, $email) =
			$attributes{'Admin'} =~ /(.+?)\s*<(.*?)>\s*/;


		$attributes{'Admin'} = [$name, $email];
	}

	if (exists $attributes{'Mod-Date'})
	{
		# now for the Mod-Date attribute, get the values from the
		# timestamp:
		my ($year, $month, $day, $hour, $minute, $second) =
			$attributes{'Mod-Date'} =~
				/<(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})>/x;

		foreach ($year, $month, $day, $hour, $minute, $second)
		{
			carp "Couldn't parse timestamp" unless (defined $_);
		}

		# We need to convert the year value into the  number years
		# since 1900 (i.e., 2003 -> 103), since that's the format
		# returned by localtime():
		$year -= 1900;

		# localtime() months are numbered from 0 to 11, not 1 to 12:
		$month--;

		# now that we have the second, minute, hour, day, month, and
		# year, we use them to get a corresponding time() value:
		my $time = timelocal(
			$second, $minute, $hour, $day, $month, $year
		);

		# now use the time() value to get the values we still don't
		# have (e.g., the day of the year, is it daylight savings time?
		# etc.) and store them in the Mod-Date attribute value:
		$attributes{'Mod-Date'} = [ localtime $time ];
	}

	return wantarray ? %attributes : \%attributes;
}





#==============================================================================#

sub as_ask
{
	my $invo = shift;

	my $self;
	if (ref $invo eq 'Net::Gopher::Response')
	{
		$self = $invo->item_blocks('ASK');
	}
	else
	{
		$self = $invo;
	}



	# ASK blocks contain Gopher+ queries which are to be filled out by the
	# user. Each ASK query has a type followed by a quetion and optional
	# defaults separated by tabs. For example:
	#    Ask: How many?\tone\ttwo\tthree
	#    AskP: Your password:
	#    Choose: Pick one:\tred\tgreen\tblue
	#    
	# This will store each ASK query as a hashref containing the query
	# type, the question and any defaults:
	my @ask;

	foreach my $query (split(/\n/, $self->content))
	{
		# get the query type, and the question and default values:
		my ($type, $question_and_defaults) = $query =~ /^(\S+)+:\s?(.*)/;

		# the question and any default values are all tab separated:
		my ($question, @defaults) = split(/\t/, $question_and_defaults);

		push(@ask, {
				type     => $type,
				question => $question,
				defaults => (@defaults)
						? \@defaults
						: undef
			}
		);	
	}

	return wantarray ? @ask : \@ask;
}





#==============================================================================#

sub as_info
{
	my $invo = shift;

	my $self;
	if (ref $invo eq 'Net::Gopher::Response')
	{
		$self = $invo->item_blocks('INFO');
	}
	else
	{
		$self = $invo;
	}



	# get the item type and display string, selector, host, port,
	# and Gopher+ string from the INFO block value:
	my ($type_and_display, $selector, $host, $port, $gopher_plus) =
			split(/\t/, $self->content);

	# separate the item type and the display string:
	my ($type, $display) = $type_and_display =~ /^(.)(.*)/;

	foreach ($type, $display, $selector, $host, $port)
	{
		unless (defined $_)
		{
			carp "Couldn't parse menu item";
			last;
		}
	}

	my %info = (
		type        => $type,
		display     => $display,
		selector    => $selector,
		host        => $host,
		port        => $port,
		gopher_plus => $gopher_plus
	);

	return wantarray ? %info : \%info;
}





#==============================================================================#

sub as_views
{
	my $invo = shift;

	my $self;
	if (ref $invo eq 'Net::Gopher::Response')
	{
		$self = $invo->item_blocks('VIEWS');
	}
	else
	{
		$self = $invo;
	}



	# Views blocks contain attributes in the form of
	# "MIME-type lang: <size>" (e.g., "text/plain En_US: <10K>."). This
	# array will store each view as a hashref:
	my @views;

	foreach my $view (split(/\n/, $self->content))
	{
		# separate the MIME type, language, and size:
		my ($mime_type, $language, $size) =
			$view =~ /^([^:]*?) (?: \s ([^:]{5}) )?:(.*)$/x;

		if (defined $size and $size =~ /<(\.?\d+)(?:(k)|b)?>/i)
		{
			# turn <55> into 55, <600B> into 600, <55K> into 55000,
			# and <.5K> into 500:
			$size  = $1;
			$size *= 1000 if ($2);
		}

		push(@views, {
				type     => $mime_type,
				language => $language,
				size     => $size
			}
		);
	}

	return wantarray ? @views : \@views;
}





#==============================================================================#

sub is_attributes
{
	my $self = shift;

	my $attribute = qr/\s .+: (?:\s.*)?/x;

	if ($self->{'value'} =~ /^$attribute (?:\n $attribute)* $/x)
	{
		return 1;
	}
	else
	{
		return;
	}
}





#==============================================================================#

sub parse
{
	my $self = shift;

	my %block_parsers = (
		ADMIN => sub { $self->as_admin },
		ASK   => sub { $self->as_ask },
		INFO  => sub { $self->as_info },
		VIEWS => sub { $self->as_views },
	);

	if (exists $block_parsers{$self->{'name'}})
	{
		return $block_parsers{$self->{'name'}}->();
	}
	else
	{
		carp "Can't parse $self->{'name'} block";
		return;
	}
}





#==============================================================================#

sub _get_attributes_hash
{
	my $self = shift;

	my %attributes;
	foreach my $attribute (split(/\n/, $self->content))
	{
		# get the "Name: value" attribute:
		my ($name, $value) = $attribute =~ /^(.+?):\s?(.*)/;

		$attributes{$name} = $value;
	}

	return %attributes;
}

1;
