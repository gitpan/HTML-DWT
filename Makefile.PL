use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::DWT',
    'VERSION_FROM'	=> 'DWT.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    			    Carp => 0.0,
    			    Test::More => 0.18,
			    }, 
    'AUTHOR'		=> 'Sean Campbell <whytwolf@spots.ab.ca>',
    'realclean' 	=> {FILES => 'pod2html-*'}
);
