# Copyright 2003-2004 by William G. Davis.
#
# This module is free software released under the GNU General Public License,
# the full terms of which can be found in the "COPYING" file that comes with
# the distribution.
#
# This class contains methods for defining and calling warning and fatal error
# exception handlers. You really don't need to be looking in here unless you
# plan on hacking Net::Gopher. See the POD for Net::Gopher new(),
# warn_handler(), die_handler(), and silent().

package Net::Gopher::Exception;

use 5.005;
use strict;
use warnings;
use vars qw(
	$DEFAULT_WARN_HANDLER $WARN_HANDLER
	$DEFAULT_DIE_HANDLER $DIE_HANDLER
	$SILENT
);
use Carp ();



# the default warn handler (used if the user supplies none):
$DEFAULT_WARN_HANDLER = sub {
	my @warnings = @_;

	# save the old Carp level to prevent overriding any user-defined level:
	my $old_level = $Carp::CarpLevel;

	# we need to go up one level because the carp() function is being
	# called from a sub which is being called from another sub:
	$Carp::CarpLevel = -1;

	foreach my $warning (@warnings)
	{
		$warning = "Warning: $warning Raised" if (defined $warning);
	}

	Carp::carp(@warnings);

	# restore the Carp level:
	$Carp::CarpLevel = $old_level;
};

# this stores the sub that will be called by the call_warn() method below
# (either the default handler above or a user defined one):
$WARN_HANDLER = $DEFAULT_WARN_HANDLER;

# the default die handler (used if the user supplies none):
$DEFAULT_DIE_HANDLER = sub {
	my @fatal_errors = @_;

	# save the old Carp level to prevent overriding any user-defined level:
	my $old_level = $Croak::CarpLevel;

	# we need to go up one level because the croak() function is being
	# called from a sub which is being called from another sub:
	$Carp::CarpLevel = -1;

	foreach my $fatal_error (@fatal_errors)
	{
		$fatal_error = "$fatal_error Stopped" if (defined $fatal_error);
	}

	Carp::croak(@fatal_errors);

	# restore the Carp level
	$Carp::CarpLevel = $old_level;
};

# this stores the sub that will be called by the call_die() method below
# (either the default handler above or a user defined one):
$DIE_HANDLER = $DEFAULT_DIE_HANDLER;

# should carp() and croak() not invoke their respective handlers when called?
$SILENT = 0;





sub call_warn
{
	my $self = shift;

	return if ($SILENT);

	$WARN_HANDLER->(@_);

	return;
}





sub call_die
{
	my $self = shift;

	return if ($SILENT);

	$DIE_HANDLER->(@_);

	return;
}





sub warn_handler
{
	my $self = shift;

	if (@_)
	{
		my $handler = shift;

		$WARN_HANDLER = (ref $handler eq 'CODE')
					? $handler
					: $DEFAULT_WARN_HANDLER;
	}
	else
	{
		return $WARN_HANDLER;
	}
}





sub die_handler
{
	my $self = shift;

	if (@_)
	{
		my $handler = shift;

		$DIE_HANDLER = (ref $handler eq 'CODE')
					? $handler
					: $DEFAULT_DIE_HANDLER;
	}
	else
	{
		return $DIE_HANDLER;
	}
}





sub silent
{
	my $self = shift;

	if (@_)
	{
		$SILENT = (shift @_) ? 1 : 0;
	}
	else
	{
		return $SILENT;
	}
}

1;
