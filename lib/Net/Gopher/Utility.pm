package Net::Gopher::Utility;

=head1 NAME

Net::Gopher::Utility - Defines varaibles for Net::Gopher

=head1 SYNOPSIS

 use Net::Gopher::Utility qw(
 	$CRLF $NEWLINE %GOPHER_ITEM_TYPES %GOPHER_PLUS_ITEM_TYPES
 );
 ...

=head1 DESCRIPTION

This module defines and exports on demand several global variables used by
both the Net::Gopher and Net::Gopher::Response classes.

=head1 VARIABLES

The following varaibles are exported on demand:

=over 4

=cut

use 5.005;
use strict;
use warnings;
use base 'Exporter';
use vars qw(
	@EXPORT_OK
	$CRLF $NEWLINE %GOPHER_ITEM_TYPES %GOPHER_PLUS_ITEM_TYPES
);

@EXPORT_OK = qw(
	$CRLF
	$NEWLINE
	%GOPHER_ITEM_TYPES
	%GOPHER_PLUS_ITEM_TYPES
);






=item $CRLF

This is the line ending used by Net::Gopher and Net::Gopher::response. You can
change this to the line ending of your choosing, but I wouldn't recommend it
since the Gopher protocol mandates standard ASCII carriage return/line feed
(though most servers will accept any line ending).

=cut

$CRLF = "\15\12";



=item $NEWLINE

This is pattern used to match newlines.

=cut

$NEWLINE = qr/(?:\15\12|\15|\12)/;



=item %GOPHER_ITEM_TYPES

This hash contains all of the item types described in
I<RFC 1436 : The Internet Gopher Protocol> as well as some other types in
common usage (like 'i'). Each key is an item type and each value is a
description of that type.

=cut

%GOPHER_ITEM_TYPES = (
	0   => 'Text File',
	1   => 'Directory',
	2   => 'CCSO Phone Book Server',
	3   => 'Error',
	4   => 'BinHexed Macintosh File',
	5   => 'DOS Binary Archive',
	6   => 'UNIX uuencoded File',
	7   => 'Index-Search Server',
	8   => 'Text-based Telnet Session',
	9   => 'Binary File',
	'+' => 'Redundant Server',
	s   => 'Sound File',
	g   => 'GIF File',
	M   => 'MIME File',
	h   => 'HTML File',
	i   => 'Inline Text',
	I   => 'Image File',
	T   => 'Text-Based tn3270 Session',
);



=item %GOPHER_PLUS_ITEM_TYPES

This hash contains all of the item types described in
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol> as
well as some other types in common usage (like 'i'). Each key is an item type
and each value is a description of that type.

=cut

%GOPHER_PLUS_ITEM_TYPES = (
	0   => 'Text File',
	1   => 'Directory',
	2   => 'CCSO Phone Book Server',
	3   => 'Error',
	4   => 'BinHexed Macintosh File',
	5   => 'DOS Binary Archive',
	6   => 'UNIX uuencoded File',
	7   => 'Index-Search Server',
	8   => 'Text-based Telnet Session',
	9   => 'Binary File',
	'+' => 'Redundant Server',
	M   => 'MIME File',
	i   => 'Inline Text',
	h   => 'HTML File',
	T   => 'Text-Based tn3270 Session',
	':' => 'Bitmap Image',
	';' => 'Movie',
	'<' => 'Sound'
);

1;

__END__

=back

=head1 BUGS

Email any to me at <william_g_davis at users dot sourceforge dot net> or go
to perlmonks.com and /msg me (William G. Davis) and I'll fix 'em.

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
