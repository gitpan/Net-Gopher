use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME            => 'Net::Gopher',
	VERSION_FROM    => 'lib/Net/Gopher.pm',
	PREREQ_PM       => {
		'URI'         => 1.27,
		'XML::Writer' => 0.4,
		'IO::String'  => 1.0
	},
	($] >= 5.005
		? (ABSTRACT_FROM => 'lib/Net/Gopher.pm',
		   AUTHOR        => 'William G. Davis ' .
		                    '<william_g_davis@users.sourceforge.net>')
		: ()
	),
);
