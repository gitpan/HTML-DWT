package HTML::DWT;
#############################################################
#  HTML::DWT
#  Whyte.Wolf DreamWeaver HTML Template Module
#  Version 2.07
#
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Created 03 March 2000; Revised 04 March  2002 by SDC
#
#  A perl module designed to parse a simple HTML template file
#  generated by Macromedia Dreamweaver and replace fields in the
#  template with values from a CGI script.
#
#############################################################
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#############################################################

use Exporter;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(fillTemplate fill export);
@EXPORT_OK = qw(output param query clear_params);
%EXPORT_TAGS = (
	Template => [qw(output param query clear_params)],
	);

use strict;
use vars qw($errmsg $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $NOTICE %DWT_FIELDS %DWT_VALUES);

$VERSION = '2.07';

$NOTICE = "\n<!-- Generated using HTML::DWT version " . $VERSION . " -->\t\t\n";
$NOTICE .= "<!-- HTML::DWT Copyright (c) 2001,2002 Sean Campbell -->\t\n";
$NOTICE .= "<!-- HTML::DWT is licenced under the GNU General Public License -->\t\n";
$NOTICE .= "<!-- You can find HTML::DWT at http://www.spots.ab.ca/~whytwolf -->\t\n";
$NOTICE .= "<!-- or by going to http://www.cpan.org -->\n";

%DWT_FIELDS = ();
%DWT_VALUES = ();

$errmsg = "";

#############################################################
# new
#
#  The constructor for the class.  Requires a HTML Template
#  filename.  Returns a reference to the new object or undef
#  on error.  Errors can be retrieved from $HTML:DWT:errmsg.

sub new {
    my $class = shift;
    my %params = @_;

    my $self = {};
    
    if (!$params{filename}){    	
	$params{filename} = $_[0];
    }
    
    $$self{filename} = $params{filename};
    $$self{option} = $params{option};
    $$self{path} = $params{path};
    $$self{template} = '';
    $$self{filter} = $params{filter};
    
    if (exists($params{case_sensitive})){
    	$$self{case_sensitive} = $params{case_sensitive};
    } else {
    	$$self{case_sensitive} = 0;
    }
    
    if (exists($params{no_includes})){
    	$$self{no_includes} = $params{no_includes};
    } else {
    	$$self{no_includes} = 0;
    }
	
    if (exists($params{associate})){
	if (ref($params{associate}) ne 'ARRAY') {
    		$$self{associate} = [ $params{associate} ];
    	}
    	$$self{associate} = $params{associate};
    } else {
	$$self{associate} = undef;
    }

    unless(open(TEMPLATE_FILE, $$self{filename})){
	$errmsg = "HTML::DWT--Template File $$self{filename} not opened: $!\n";
	return undef;
    }

    while(<TEMPLATE_FILE>){
	$$self{template} .= $_;
    }

    $$self{html} = $$self{template};
    $$self{html} =~ s/<html>/_beginTemplate($$self{filename})/ie;
    $$self{html} =~ s/<\/html>/_endTemplate()/ie;
    $$self{html} =~ s/<!--\s*#BeginEditable\s*\"(\w*)\"\s*-->?/_quoteReplace($1)/ieg;
    $$self{html} =~ s/<!--\s*#BeginLibraryItem\s*\"(\w*)\"\s*-->?/_lbiquoteReplace($1)/ieg;

    bless $self, $class;
    return $self;
}

#############################################################
# clear_params
#
#  A subroutine which clears the values of all template 
#  parameters.

sub clear_params {
    my $self = shift;
    foreach my $key (keys %DWT_VALUES){
		$DWT_VALUES{$key} = undef;
	}
}


#############################################################
# fill
#
#  A subroutine for parsing and replacing key values in an
#  HTML Template.  Takes a reference to a hash containing the
#  key/value pairs.  Returns the parsed HTML.  Calls param()
#  for actual substitution as of version 2.05.

sub fill {
    my $self = shift;
    my $cont = shift;

    $self->param(%$cont);
    return $self->output();
}

#############################################################
# fillTemplate
#
#  Calls fill() for backwards compatibility with earlier versions.

sub fillTemplate {

    my $self = shift;
    my $cont = shift;
    
    $self->fill($cont);

}

#############################################################
# output
#
#  Returns the substituted HTML as generated by fill() or
#  param().  For compatibility with HTML::Template.

sub output {
    my $self = shift;
	my %params = @_;

    if ($$self{associate}){
       	foreach my $query ($$self{associate}){
		foreach my $param ($query->param) {
			$self->param($param => $query->param($param));
   		}
    	}
    }

    if ($$self{case_sensitive} == 1){
    	foreach my $key (keys %DWT_VALUES) {
		$$self{html}=~s/<!--\s*#BeginEditable\s*($key)\s*-->?(.*?)<?!--\s*#EndEditable\s*-->/_keyReplace($DWT_VALUES{$key},$1)/egs;
    	}
    } else {
    	foreach my $key (keys %DWT_VALUES) {
		$$self{html}=~s/<!--\s*#BeginEditable\s*($key)\s*-->?(.*?)<?!--\s*#EndEditable\s*-->/_keyReplace($DWT_VALUES{$key},$1)/iegs;
    	}
    }

    if($$self{no_includes} == 0) {
    	$$self{html} =~ s/<!--\s*#BeginLibraryItem\s*(\w*)\s*-->?(.*?)<?!--\s*#EndLibraryItem\s*-->/_lbiInclude($1)/ieg;
    }
    
    if ($params{'print_to'}){
		my $print_to = $params{'print_to'};
	    print $print_to $$self{html};
		return undef;
	} else {	
    	return $$self{html};
	}
}

#############################################################
# param
#
#  Take a hash of one or more key/value pairs and substitutes
#  the HTML value in the key's spot in the template.  For
#  compatibility with HTML::Template.

sub param {

    my $self = shift;
        
    if (scalar(@_) == 0) {
    	return keys %DWT_FIELDS; 
    } elsif (scalar(@_) == 1){
    	my $field = shift;
    	return $DWT_VALUES{$field};
    } else {
		my %params = @_;   
    	foreach my $key (keys %params) {
		if ($key eq 'doctitle' && !($params{$key}=~/<title>(\w*)<\/title>/i)){
		    $DWT_VALUES{'doctitle'} = "<title>" . $params{$key} . "</title>";
		} else {
		    $DWT_VALUES{$key} = $params{$key};
		}
	}
    }

}

#############################################################
# query
#
#  Allows for querying of template parameters.  For
#  compatibility with HTML::Template.  

sub query {

    my $self = shift;
        
    if (scalar(@_) == 0) {
    	return keys %DWT_FIELDS; 
    } elsif (scalar(@_) == 1){
    	my $field = shift;
    	return $DWT_FIELDS{$field};
    } else {    
    	my %params = @_;
		my $cmd = shift;
		my $field = shift;
	
		if ($cmd eq 'name') {
			return $DWT_FIELDS{$field};
		} else {
			return undef;
		}
    }
	
}

#############################################################
# export
#
#  Allows for export of field values to Dreamweaver XML format
#  or another standardized XML format (see Dreamweaver 4
#  documents for more details).  

sub export {

    my $self = shift;
    my %params = @_;
    my $type = $params{'type'};
    my $output = $params{'output'};
	my $print_to = $params{'print_to'};
    my $xmlcont = '';
    my $filename = '';
    
    $self->output();
		
    if ($type eq 'er') {
    	$xmlcont = _xmler($$self{filename});
    } else {
    	$xmlcont = _xmldw($$self{filename});
    } 
    
    if ($output eq 'file') {
    	my $filename = $params{'filename'};
		unless(open(XML_FILE,">$filename")) {
			$errmsg = "HTML::DWT--XML File $filename not opened: $!\n";
			return undef;
		}
		print XML_FILE $xmlcont;
		close(XML_FILE);
		return $filename;
    } elsif ($output eq 'FH') {
		print $print_to "Content-type: text/xml\n\n" . $xmlcont;
		return undef;
	} else {
        return $xmlcont;
    }
}

#############################################################
# _keyReplace
#
#  An internal subroutine that does the actual key/value
#  replacement.  Takes the contents scalar and returns a
#  HTML string.

sub _keyReplace {
    my $cont = shift;
    my $key = shift;

    return "<!-- \#BeginEditable \"$key\" -->\n" . $cont . "\n<!-- \#EndEditable -->\n";
}

#############################################################
# _beginTemplate
#
#  Returns the begin template string and file name back into
#  the parsed HTML.

sub _beginTemplate {
    my $filename = shift;
    return "<html>\n<!-- \#BeginTemplate \"$filename\" -->\n" . $NOTICE;
}

#############################################################
# _endTemplate
#
#  Returns the end template string back into the parsed HTML.

sub _endTemplate {
    return "<!-- \#EndTemplate -->\n</html>";
}

#############################################################
# _quoteReplace
#
#  An internal subroutine that removes quotes from around
#  the editable region name (fixes recursive loop bug).
#  As of version 2.06 also builds %DWT_FIELDS and %DWT_VALUES

sub _quoteReplace {
    my $key = shift;
    $DWT_FIELDS{$key} = 'VAR';
    $DWT_VALUES{$key} = undef;
    
    return "<!-- \#BeginEditable $key -->";
}

#############################################################
# _lbiquoteReplace
#
#  An internal subroutine that removes quotes from around
#  the library file name

sub _lbiquoteReplace {
    my $key = shift;
        
    return "<!-- \#BeginLibraryItem $key -->";
}

#############################################################
# _lbiInclude
#
#  An internal subroutine that opens a Dreamweaver .lbi file
#  and returns its contents.

sub _lbiInclude {
    my $file = shift;
    my $lbi = "<!-- #BeginLibraryItem \"$file\" -->\n";
    
    unless(open(LBI_FILE, $file)){
	$errmsg = "HTML::DWT--Included Library File $file not opened: $!\n";
	return $errmsg;
    }

    while(<LBI_FILE>){
	$lbi .= $_;
    }
    
    $lbi .= "\n<!-- #EndLibraryItem -->";
    
    return $lbi;
}


#############################################################
# _xmldw
#
#  An internal subroutine that generates a Dreamweaver XML
#  document for export.

sub _xmldw {
    my $filename = shift;
    my $xmlcont = "<?xml version=\"1.0\"?>\n<templateItems template=\"$filename\">\n";
    
    foreach my $key (keys %DWT_FIELDS){
    	$xmlcont .= "<item name=\"$key\"><![CDATA[$DWT_VALUES{$key}]]></item>\n";
    }
    
    $xmlcont .= "</templateItems>";
            
    return $xmlcont;
}

#############################################################
# _xmler
#
#  An internal subroutine that generates a XML export document

sub _xmler {
    my $filename = shift;
	my $name = 'TEST';
    my $xmlcont = "<?xml version=\"1.0\"?>\n<$name template=\"$filename\">\n";
    
    foreach my $key (keys %DWT_VALUES){
    	$xmlcont .= "<$key><![CDATA[$DWT_VALUES{$key}]]></$key>";
    }
    
    $xmlcont .= "</$name>";
            
    return $xmlcont;
}

1;
__END__

=head1 NAME

HTML::DWT - DreamWeaver HTML Template Module

=head1 INSTALLATION

=head2 Unzip/tar the archive:

  tar xvfz HTML-DWT-2.07

=head2 Create the makefile

  perl Makefile.PL

=head2 Make the module (must have root access to install)

  make
  make test
  make install

=head1 SYNOPSIS

  use HTML::DWT;
  
  $template = new HTML::DWT(filename => "file.dwt");    
  %dataHash = (
  		doctitle => 'DWT Generated',
  	       	leftcont => 'some HTML content here'	
		);  
  $html = $template->fill(\%dataHash);
  
  or
  
  use HTML::DWT qw(:Template);
  
  $template = new HTML::DWT(filename => "file.dwt");
  $template->param(
		   doctitle => '<title>DWT Generated</title>',
		   leftcont => 'Some HTML content here'
		   );
  $html = $template->output();

=head1 DESCRIPTION

A perl module designed to parse a simple HTML template file
generated by Macromedia Dreamweaver and replace fields in the
template with values from a CGI script.  

=head1 METHODS

=head2 Options

  use HTML::DWT qw(:Template);

Using the Template option allows for built in support in HTML::DWT
for the HTML::Template invocation syntax (param(), output() etc.) See
HTML::Template for more details.  It is best to require a version of 
2.05 for HTML::DWT to support this option.


=head2 new()

  new HTML::DWT("file.dwt");

  new HTML::DWT(
  		filename => "file.dwt",
		associate => $q,
		case_sensitive => 1,
		no_includes => 1,
		);

Creates and returns a new HTML::DWT object based on the Dreamweaver
template 'file.dwt' (can specify a relative or absolute path).  The
Second instance is recommended, although the first style is still 
supported for backwards compatability with versions before 2.05.

The associate option allows the template to inherit parameter
values from other objects.  The object associated with the template
must have a param() method which works like HTML::DWT's param().
Both CGI and HTML::Template fit this profile.  To associate another 
object, create it and pass the reference scalar to HTML::DWT's new() 
method under the associate option (see above).

The case_sensitive option allows HTML::DWT to treat template fields 
in a case-sensitive manner.  HTML::DWT's default behavior is to match 
all fields in a case-insensitive manner (i.e. doctitle is considered
the same as DOCTITLE or DocTitle). Set case_sensitive to 1 to over-
ride this default behavior.

HTML::DWT will by default look for any included Dreamweaver library
item files (.lbi files) that may be specified in the template using 
the <!-- #BeginLibraryItem "file.lbi" -> field.  The module will open
the specified library file and will include the file's contents in 
the generated HTML.  Setting no_includes to 1 will over-ride this 
default behavior.

Additional options may be passed to the constructor to emulate 
HTML::Template behavior (see that module's documentation) although
only filename, associate, case_sensitive and no_includes are supported 
as of HTML::DWT version 2.07.


=head2 fill()

  $template->fill(\%dataHash);

  $template->fillTemplate(\%dataHash);

Takes a hash reference where the keys are the named areas of the
template and the associated values are HTML content for those 
areas.  This method returns a complete HTML document, which can 
then be sent to STDOUT (the browser).  The fill() method is the 
prefered means of accessing this functionality; fillTemplate()
is implemented only to support versions of HTML::DWT earlier than
version 2.05.

=head2 param()

  $template->param();

  $template->param('doctitle');

  $template->param(
                  doctitle => '<title>DWT Generated</title>',
                  leftcont => 'Some HTML content here'
                  );

Takes a hash of one or more key/value pairs, where each key is a named
area of the template, and the associated value is the HTML content for
that area.  This method returns void (HTML substitiutions are stored
within the object awaiting output()).

If called with a single paramter--this parameter must be a valid field
name--param() returns the value currently set for the field, or undef
if no value has been set.

If called with no parameters, param() returns a list of all field names.

NOTE: All Dreamweaver templates store the HTML page's title in a field
named 'doctitle'.  HTML::DWT will accept a raw title (without <title>
tags) and will add the appropriate tags if the content of the 'doctitle'
field should require them.

This is a HTML::Template compatible method.

=head2 clear_params()

  $template->clear_params();

Clears all field values from the template's parameter list and sets each
parameter to an undefined value.

This is a HTML::Template compatible method.

=head2 output()

  $template->output();
  
  $template->output(print_to => \*STDOUT);

Returns the parsed template and its substituted HTML for output.
The template must be filled using either fill() or param() before
calling output().

Alternativly, by passing a filehandle reference to output()'s 
B<print_to> option you may output the template content directly to
that filehandle.  In this case output() returns an undefined value.

This is a HTML::Template compatible method.

=head2 export()

  $template->export(
                    type  => 'dw',
		    output => 'file',
		    filename => 'dwt.xml',
		    print_to => \*STDOUT
		    );

This method exports the filled template data to an XML file format.
Dreamweaver supports two XML styles for templates, the Dreamweaver style,
and another standardized style.  'dw', the type flag for the Dreamweaver
style is the default setting for export(), although you may change that by
using the B<type> option and passing it either 'dw' or 'er'.

If no output style is indicated, export() will return the XML document. 
Output may be sent to a file, in which case the B<output> option is passed
the value 'file', or output may be sent to an open filehandle, in which case 
B<output> is passed a 'FH' value.

If sending output to a file, the B<filename> option musst be included with
a valid filename (absolute or relative paths are acceptable).  Export will 
return the filename, or undefined on an error.  Error messages are stored in
$HTML::DWT::errmsg.

If sending output to a filehandle instead of using the B<filename> option
, pass a reference to a filehandle to the B<print_to> option.  For convienience
of use with CGI scripts, export() will include a 'Content-type: text/xml' 
header before the XML document when outputting to a filehandle.  When sending
output to a filehandle export() returns undefined.

=head2 query()

  $template->query();

  $template->query('doctitle');

  $template->query(name => 'doctitle');

Returns the 'type' of the template field specified.  For all 
HTML::DWT fields the type is 'VAR' (HTML::DWT doesn't support
HTML::Template's idea of LOOPs or IFs).  If called with no
parameters, query() returns a list of all field names.

This is a HTML::Template compatible method.

=head1 DIAGNOSTICS

=over 4

=item Template File $file not opened:

(F) The template file was not opened properly.  
This message is stored in $HTML::DWT::errmsg

=back

=head1 BUGS

No known bugs, but if you find any please contact the author.

=head1 COMPATABILITY NOTES

HTML:DWT is moving towards supporting much, if not all of the
functionality of HTML::Template for Dreamweaver templates.  Not
All HTML::Template functionality is fully supported yet, and 
while the HTML::Template documentation should be the reference
source for all HTML::Template compatible methods and functions, 
only those methods documented as being supported, and the manner 
of their support as documented in HTML::DWT are actually supported 
by this module.

In plain english--RT(HTML:DWT)M and use it. :)

If you would like to assist in the development of this module, please
contact the author.

=head1 AUTHOR

S.D. Campbell, whytwolf@spots.ab.ca

=head1 SEE ALSO

perl(1), HTML::Template, HTML::LBI.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
