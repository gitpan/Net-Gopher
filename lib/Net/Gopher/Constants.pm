
package Net::Gopher::Constants;

=head1 NAME

Net::Gopher::Constants - Exports constants on demand for Net::Gopher scripts

=head1 SYNOPSIS

 use Net::Gopher::Constants qw(:request);
 ...
 if ($request->request_type == GOPHER_PLUS_REQUEST) {
 ...
 
 # and/or:
 use Net::Gopher::Constants qw(:response);
 ...
 if ($response->status eq OK) {
 ...
 
 # and/or
 use Net::Gopher::Constants qw(:item_types);
 ...
 if ($request->item_type eq TEXT_FILE_TYPE
 	or $request->item_type eq GOPHER_MENU_TYPE
 	or $request->item_type eq INDEX_SEARCH_SERVER_TYPE) {
 ...

=head1 DESCRIPTION

This class defines and exports on demand numerous constants used internally by
B<Net::Gopher>. You may find use of these symbols in place of there numeric or
string counterparts makes your program more readable.

=cut

use 5.005;
use warnings;
use strict;
use vars qw(@EXPORT_OK %EXPORT_TAGS);
use base 'Exporter';





# we use these arrays to make exporting easier:
my @request_constants   = qw(
	GOPHER_REQUEST
	GOPHER_PLUS_REQUEST
	ITEM_ATTRIBUTE_REQUEST
	DIRECTORY_ATTRIBUTE_REQUEST
);
my @response_constants  = qw(OK NOT_OK);
my @item_type_constants = qw(
	TEXT_FILE_TYPE
	GOPHER_MENU_TYPE
	CCSO_NAMESERVER_TYPE
	ERROR_TYPE
	BINHEXED_MACINTOSH_FILE_TYPE
	DOS_BINARY_FILE_TYPE
	UNIX_UUENCODED_FILE_TYPE
	INDEX_SEARCH_SERVER_TYPE
	TELNET_SESSION_TYPE
	BINARY_FILE_TYPE
	GIF_IMAGE_TYPE
	IMAGE_FILE_TYPE
	TN3270_SESSION_TYPE
	BITMAP_IMAGE_TYPE
	MOVIE_TYPE
	SOUND_TYPE
	HTML_FILE_TYPE
	INLINE_TEXT_TYPE
	MIME_FILE_TYPE
	MULAW_AUDIO_TYPE
);



@EXPORT_OK = (@request_constants, @response_constants, @item_type_constants);

%EXPORT_TAGS = (
	all        => [
		@request_constants, @response_constants, @item_type_constants
	],
	request    => \@request_constants,
	response   => \@response_constants,
	item_types => \@item_type_constants
);







=head1 REQUEST CONSTANTS

If you specify I<:request>, then four request type constants will be exported.
These constants can be compared against the value returned by the
B<Net::Gopher::Request> C<request_type()> method.

=over 4

=item GOPHER_REQUEST

Is equal to the value returned by C<request_type()> if the request is a
I<Gopher> request.

=item GOPHER_PLUS_REQUEST

Is equal to the value returned by C<request_type()> if the request is a
I<GopherPlus> request.

=item ITEM_ATTRIBUTE_REQUEST

Is equal to the value returned by C<request_type()> if the request is a
I<ItemAttribute> request.

=item DIRECTORY_ATTRIBUTE_REQUEST

Is equal to the value returned by C<request_type()> if the request is a
I<DirectoryAttribute> request.

=back

There is of course no C<URL_REQUEST> constant since URL requests evaluate to
one of the four types of requests enumerated above.

See L<request_type()|Net::Gopher::Request/request_type()>.

=cut

sub GOPHER_REQUEST              () { return 1 }
sub GOPHER_PLUS_REQUEST         () { return 2 }
sub ITEM_ATTRIBUTE_REQUEST      () { return 3 }
sub DIRECTORY_ATTRIBUTE_REQUEST () { return 4 }





=head1 RESPONSE CONSTANTS

If you specify I<:response>, then two constants will be exported. These
constants can be compared against the value returned by the
B<Net::Gopher::Response> C<status()> method.

 OK     = Evaluates to "+";
 NOT_OK = Evaluates to "-";

See L<status()|Net::Gopher::Response/status()>.

=cut

sub OK ()     { return '+' }
sub NOT_OK () { return '-' }





=head1 ITEM TYPE CONSTANTS

Finally, there are also constants for every known item type. These constants
can be compared against the values returned by the various C<item_type()>
methods, as well as used in place of character or string literals when
specifying the attributes you want from an item attribute information request
or directory attribute information request.

=over 4

=item Gopher Item Types

 TEXT_FILE_TYPE               = Evaluates to "0";
 GOPHER_MENU_TYPE             = Evaluates to "1";
 CCSO_NAMESERVER_TYPE         = Evaluates to "2";
 ERROR_TYPE                   = Evaluates to "3";
 BINHEXED_MACINTOSH_FILE_TYPE = Evaluates to "4";
 DOS_BINARY_FILE_TYPE         = Evaluates to "5";
 UNIX_UUENCODED_FILE_TYPE     = Evaluates to "6";
 INDEX_SEARCH_SERVER_TYPE     = Evaluates to "7";
 TELNET_SESSION_TYPE          = Evaluates to "8";
 BINARY_FILE_TYPE             = Evaluates to "9";
 GIF_IMAGE_TYPE               = Evaluates to "g";
 IMAGE_FILE_TYPE              = Evaluates to "I";
 TN3270_SESSION_TYPE          = Evaluates to "T";

=item Gopher+ Item Types

 BITMAP_IMAGE_TYPE = Evaluates to ":";
 MOVIE_TYPE        = Evaluates to ";";
 SOUND_TYPE        = Evaluates to "<";

=item Common but Unofficial Item Types

 HTML_FILE_TYPE   = Evaluates to "h";
 INLINE_TEXT_TYPE = Evaluates to "i";
 MIME_FILE_TYPE   = Evaluates to "M";
 MULAW_AUDIO_TYPE = Evaluates to "s";

=back

=cut

# Gopher item type constants:
sub TEXT_FILE_TYPE               () { return 0 }
sub GOPHER_MENU_TYPE             () { return 1 }
sub CCSO_NAMESERVER_TYPE         () { return 2 }
sub ERROR_TYPE                   () { return 3 }
sub BINHEXED_MACINTOSH_FILE_TYPE () { return 4 }
sub DOS_BINARY_FILE_TYPE         () { return 5 }
sub UNIX_UUENCODED_FILE_TYPE     () { return 6 }
sub INDEX_SEARCH_SERVER_TYPE     () { return 7 }
sub TELNET_SESSION_TYPE          () { return 8 }
sub BINARY_FILE_TYPE             () { return 9 }
sub GIF_IMAGE_TYPE               () { return 'g' }
sub IMAGE_FILE_TYPE              () { return 'I' }
sub TN3270_SESSION_TYPE          () { return 'T' }

# Gopher+ item type constants:
sub BITMAP_IMAGE_TYPE () { return ':' }
sub MOVIE_TYPE        () { return ';' }
sub SOUND_TYPE        () { return '<' }

# constants for common but unofficial item types:
sub HTML_FILE_TYPE   () { return 'h' }
sub INLINE_TEXT_TYPE () { return 'i' }
sub MIME_FILE_TYPE   () { return 'M' }
sub MULAW_AUDIO_TYPE () { return 's' }

1;

__END__

=head1 BUGS

Bugs in this package can reported and monitored using CPAN's request
tracker: rt.cpan.org.

If you wish to report bugs to me directly, you can reach me via email at
<william_g_davis at users dot sourceforge dot net>.

=head1 SEE ALSO

L<Net::Gopher|Net::Gopher>,
L<Net::Gopher::Request|Net::Gopher::Request>,
L<Net::Gopher::Response|Net::Gopher::Response>

=head1 COPYRIGHT

Copyright 2003 by William G. Davis.

This code is free software released under the GNU General Public License, the
full terms of which can be found in the "COPYING" file that came with the
distribution of the module.

=cut