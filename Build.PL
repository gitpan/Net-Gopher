#!/usr/bin/perl -w
use strict;
use Module::Build;

my $mb = new Module::Build (
	module_name => 'Net::Gopher',
	license     => 'GPL',
	requires    => {
		'IO::String'       => 1.0,
		'IO::Socket'       => 1.26,
		'IO::Socket::INET' => 1.25,
		'URI'              => 1.27,
		'XML::Writer'      => 0.4,
	}
)->create_build_script;
