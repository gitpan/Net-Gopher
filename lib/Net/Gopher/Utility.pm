package Net::Gopher::Utility;

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

# This is the line ending used by Net::Gopher. You can change this to the line
# ending of your choosing, but I wouldn't recommend it since the Gopher
# protocol mandates standard ASCII carriage return/line feed (though most
# servers will accept any line ending):
$CRLF = "\15\12";

# pattern we use to match newlines:
$NEWLINE = qr/(?:\15\12|\15|\12)/;

# Gopher item type characters and descriptions:
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

# Gopher+ item type characters and descriptions:
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
