#!/usr/bin/perl -w 
#############################################################
#  HTML::DWT
#  Whyte.Wolf DreamWeaver HTML Template Module
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Last modified 05/03/2002
#
#  Test scripts to test that the HTML::DWT module has been
#  installed correctly.  See Test::More for more information.
#
#############################################################

use Carp;
use Test::More tests => 21;

#  Check to see if we can use and/or require the module

BEGIN { 
	use_ok('HTML::DWT');
	use_ok('HTML::DWT', qw(:Template));
	}
	
require_ok('HTML::DWT');

#  Create a new HTML::DWT object and test to see if it's a 
#  properly blessed reference.  Die if the file isn't found.

my $t = new HTML::DWT(filename => 'tmp/temp.dwt') or die $HTML::DWT::errmsg;
isa_ok($t, 'HTML::DWT');

#  Grab a list of the parameters from the template and test to see if
#  they're what we were expecting

@test = $t->param();
foreach $field(@test){
	my $msg = "Searching field names: found $field";
	like($field, qr/doctitle|leftcont|centercont|rightcont/, $msg);
}


#  Create a data hash and fill the template with it

my %data = (
	doctitle => 'fill title',
	leftcont => 'fill left',
	centercont => 'fill center',
	rightcont => 'fill right'
	);
	
my $fillhtml = $t->fill(\%data);

#  Test each parameter to see if the field was filled properly by fill()

is($t->param('doctitle'), '<title>fill title</title>', 'fill() doctype value correct');
is($t->param('leftcont'), 'fill left', 'fill() leftcont value correct');
is($t->param('centercont'),'fill center', 'fill() centercont value correct');
is($t->param('rightcont'),'fill right', 'fill() rightcont value correct');

#  Load the paramters from the template with new values and then test to 
#  see if those values have been stored properly

$t->param(doctitle=>'test');
$t->param(leftcont=>'Left Cont');
$t->param(centercont=>'Center Cont');
$t->param(rightcont=>'Right Cont');

is($t->param('doctitle'), '<title>test</title>', 'param() doctype value correct');
is($t->param('leftcont'), 'Left Cont', 'param() leftcont value correct');
is($t->param('centercont'),'Center Cont', 'param() centercont value correct');
is($t->param('rightcont'),'Right Cont', 'param() rightcont value correct');

#  Query each field from the template to ensure they are all of type VAR

is($t->query('doctitle'), 'VAR', 'doctype type: VAR');
is($t->query('leftcont'), 'VAR', 'leftcont type: VAR');
is($t->query('centercont'),'VAR', 'centercont type: VAR');
is($t->query('rightcont'),'VAR', 'rightcont type: VAR');

#  Load the template with data from the datahash through param() and
#  test to see if output() generates the same HTML output as fill()

$t->param(%data);

my $outhtml = $t->output();

is($outhtml, $fillhtml, 'Similar output from hash');
