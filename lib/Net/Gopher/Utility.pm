
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





=head2 $CRLF

This is the line ending used by Net::Gopher and Net::Gopher::response. You can
change this to the line ending of your choosing, but I wouldn't recommend it
since the Gopher protocol mandates standard ASCII carriage return/line feed
(though most servers will accept any line ending).

=cut

$CRLF = "\15\12";



=head2 $NEWLINE

This is pattern used to match newlines.

=cut

$NEWLINE = qr/(?:\15\12|\15|\12)/;



=head2 %GOPHER_ITEM_TYPES

This hash contains all of the item types described in
I<RFC 1436 : The Internet Gopher Protocol> as well as some other types in
common usage (like 'i'). Each key is an item type and each value is a
description of that type.

=cut

%GOPHER_ITEM_TYPES = (
	0   => 'text file',
	1   => 'directory',
	2   => 'CCSO phone book server',
	3   => 'error',
	4   => 'binhexed Macintosh file',
	5   => 'DOS binary archive',
	6   => 'UNIX uuencoded file',
	7   => 'index-search server',
	8   => 'text-based telnet session',
	9   => 'binary file',
	'+' => 'redundant server',
	s   => 'sound file',
	g   => 'GIF file',
	M   => 'MIME file',
	h   => 'HTML file',
	i   => 'inline text',
	I   => 'image file',
	T   => 'text-based tn3270 session',
);



=head2 %GOPHER_PLUS_ITEM_TYPES

This hash contains all of the item types described in
I<Gopher+: Upward Compatible Enhancements to the Internet Gopher Protocol> as
well as some other types in common usage (like 'i'). Each key is an item type
and each value is a description of that type.

=cut

%GOPHER_PLUS_ITEM_TYPES = (
	0   => 'text file',
	1   => 'directory',
	2   => 'CCSO phone book server',
	3   => 'error',
	4   => 'binhexed Macintosh file',
	5   => 'DOS binary archive',
	6   => 'UNIX uuencoded file',
	7   => 'index-search server',
	8   => 'text-based telnet session',
	9   => 'binary file',
	'+' => 'redundant server',
	M   => 'MIME file',
	h   => 'HTML file',
	i   => 'inline text',
	T   => 'text-based tn3270 session',
	':' => 'bitmap image',
	';' => 'movie',
	'<' => 'sound'
);

1;

__END__

=head1 BUGS

If you encounter bugs, you can alert me of them by emailing me at
<william_g_davis at users dot sourceforge dot net> or, if you have PerlMonks
account, you can go to perlmonks.org and /msg me (William G. Davis).

=head1 COPYRIGHT

Copyright 2003, William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut
