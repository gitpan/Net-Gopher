use warnings;
use strict;
use Socket;
use Test;

# make sure that we're connected to the net:
BEGIN
{
	if (gethostbyname('www.cpan.org'))
	{
		plan(tests => 24);
	}
	else
	{
		plan(tests => 0);
		exit;
	}
}





use Net::Gopher;

{
	my $ng = new Net::Gopher;

	my $response = $ng->gopher(Host => 'gopher.floodgap.com');

	ok(!$response->is_error);       # 1
	ok($response->is_success);      # 2
	ok(!$response->is_blocks);      # 3
	ok(!$response->is_gopher_plus); # 4
	ok($response->is_menu);         # 5
	ok($response->is_terminated);   # 6
}

{
	my $ng = new Net::Gopher;

	my $response = $ng->gopher_plus(Host => 'gopher.quux.org');

	ok(!$response->is_error);      # 7
	ok($response->is_success);     # 8
	ok(!$response->is_blocks);     # 9
	ok($response->is_gopher_plus); # 10
	ok($response->is_menu);        # 11
	ok(!$response->is_terminated); # 12
}

{
	my $ng = new Net::Gopher;

	my $response = $ng->item_attribute(Host => 'gopher.quux.org');

	ok(!$response->is_error);      # 13
	ok($response->is_success);     # 14
	ok($response->is_blocks);      # 15
	ok($response->is_gopher_plus); # 16
	ok(!$response->is_menu);       # 17
	ok(!$response->is_terminated); # 18
}

{
	my $ng = new Net::Gopher;

	my $response = $ng->directory_attribute(Host => 'gopher.quux.org');

	ok(!$response->is_error);      # 19
	ok($response->is_success);     # 20
	ok($response->is_blocks);      # 21
	ok($response->is_gopher_plus); # 22
	ok(!$response->is_menu);       # 23
	ok(!$response->is_terminated); # 24
}
