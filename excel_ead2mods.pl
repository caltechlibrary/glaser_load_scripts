#!/usr/bin/perl -w
#
# excel_ead2mods.pl - B. Coles.
#
# Last modified 11/1/2017 
#
# GLASER COLLECTION PROJECT
#  
# Creates MODS records from the Archives spreadsheet data in tsv format.  Output is one
# MODS file per archival item (normally a folder, since spreadsheet metadata is at folder
# level.
#
# The Archives creates spreadsheets when processing collections; the spreadsheets are in
# a particular format that is used to generate EADs.  For purposes of creating MODS, the
# spreadsheet data undergoes some modification in Excel and with OpenRefine,
#
#      (detail here) FIXME
#
# and is saved in tab-delimited format (.tsv or just .txt)
#
# Expected input format:
#
# First row is column headers.  FIXME
# Col 1		Series number
# Col 2		Subseries number
# Col 3		Box number
# Col 4		Folder number
# Col 5		Caltech/Berkeley
# Col 6		Title
# Col 7		Number of items (page images)
# Col 8		Date(s)
# Col 9 	PhysDesc
# Col 10	Notes
#
# Input mapping to MODS:
#
# See code below.
#
# Note that the current version of this script is hard-coded for the Glaser
# Collection.  Ideally, there would be a configuration file specifying 
# constant values and mappings so that the script could be used for any
# collection.
#
#############################################################################

use Data::Dumper;
use strict;

# my $debug = 1;
my $debug = 0;
my $line = 1;
my $records_read = 0;
my $records_created = 0;

my %records;

my $series_number;
my $subseries_number;
my $box_number;
my $folder_number;
my $caltech_or_berkeley;
my $title;
my $number_of_items;
my $date;
my $lists;
my $phys_desc;
my $notes;

my $xml_decl = qq {<?xml version="1.0" encoding="UTF-8"?>\n};

my $mods_begin = qq {<mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\nxsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd"\nxmlns="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3"\nxmlns:xlink="http://www.w3.org/1999/xlink">\n};

my $mods_end = "</mods>";

my $typeOfResource_element_still = qq {<typeOfResource>still image</typeOfResource>};
my $typeOfResource_element_moving = qq {<typeOfResource>moving image</typeOfResource>};
my $typeOfResource_element_text = qq {<typeOfResource>text</typeOfResource>};
my $typeOfResource_element_audio = qq {<typeOfResource>sound recording</typeOfResource>};
my $typeOfResource_element_notated_music = qq {<typeOfResource>notated music</typeOfResource>};
my $typeOfResource_element_mixed = qq {<typeOfResource>mixed material</typeOfResource>};
my $typeOfResource_element_software = qq {<typeOfResource>software, multimedia</typeOfResource>};

my $physicalDescription_form_element_npg = qq {<form authority="marcform">nonprojected graphic</form>};
my $physicalDescription_form_element_pg = qq {<form authority="marcform">projected graphic</form>};
my $physicalDescription_form_element_video = qq {<form authority="marcform">videorecording</form>};
my $physicalDescription_form_element_mp = qq {<form authority="marcform">motion picture</form>};
my $physicalDescription_form_element_text = qq {<form authority="marcform">text</form>};
my $physicalDescription_form_element_audio = qq {<form authority="marcform">sound recording</form>};
my $physicalDescription_form_element_notated_music = qq {<form authority="marcform">notated music</form>};
my $physicalDescription_form_element_elec = qq {<form authority="marcform">electronic resource</form>};
my $physicalDescription_form_element_unspec = qq {<form authority="marcform">unspecified</form>};

my $originInfo_element_begin = qq {<originInfo><dateIssued keyDate="yes">};
my $originInfo_element_end   = qq {</dateIssued></originInfo>};
 
my $rights_element = qq {<accessCondition type="use and reproduction">Materials from the Caltech Archives are made available online for research purposes. Permission for reproduction, distribution, public display, performance, or publication must be obtained in writing from the Head of Archives. The Caltech Archives makes no representation that it is the copyright owner in all of its holdings. It is the responsibility of the user to obtain all necessary rights and clearances for use of materials. For questions, contact Head of Archives.</accessCondition>};

my $rights_element_berkeley = qq {<accessCondition type="user and reproduction">All requests to reproduce, publish, quote from, or otherwise use collection materials must be submitted in writing to the Head of Public Services, The Bancroft Library, University of California, Berkeley 94720-6000. See: http://bancroft.berkeley.edu/reference/permissions.html.</accessCondition>};

my $ownership_element = qq {<note type="ownership">Owned by the Caltech Archives.</note>};

my $ownership_element_berkeley = qq {<note type="ownership">Owned by The Bancroft Library, University of California, Berkeley. On indefinite loan to the California Institute of Technology Archives.</note>};

my $location_element = qq {<location><physicalLocation>California Institute of Technology Archives.</physicalLocation></Location>};
  
my $language_element = qq {<language><languageTerm authority="iso639-2b" type="code">eng</languageTerm></language>};

my $relatedItem_element_begin = qq {<relatedItem type="host">};
my $relatedItem_element_end   = qq {</relatedItem>};
my $recordInfo_element = qq {<recordInfo><languageOfCataloging><languageTerm type="code" authority="iso639-2b">eng</languageTerm></languageOfCataloging></recordInfo>};

# Assign strings to hashes of Series and Subseries
my %series_text;
$series_text{'1'} = "Biographical and Personal";
$series_text{'2'} = "Education";
$series_text{'3'} = "University of Michigan";
$series_text{'4'} = "University of California at Berkeley";
$series_text{'5'} = "Bubble Chamber (Ann Arbor)";
$series_text{'6'} = "Molecular Biology";
$series_text{'7'} = "Neuroscience";
$series_text{'8'} = "Audio Visual";

my %subseries_text;
$subseries_text{'1'}{'1'} = "Family material";
$subseries_text{'1'}{'2'} = "Journal entries and notes";
$subseries_text{'1'}{'3'} = "Job search and appointments";
$subseries_text{'1'}{'4'} = "Biographical write ups and interviews";
$subseries_text{'1'}{'5'} = "Correspondence";
$subseries_text{'1'}{'6'} = "Nobel Prize";
$subseries_text{'1'}{'7'} = "Other awards and honors";
$subseries_text{'1'}{'8'} = "Photographs";
$subseries_text{'1'}{'9'} = "Miscellaneous material";
$subseries_text{'1'}{'10'} = "Oversize material";
$subseries_text{'2'}{'1'} = "Case Institute of Technology";
$subseries_text{'2'}{'2'} = "California Institute of Technology";
$subseries_text{'3'}{'1'} = "Administrative material";
$subseries_text{'3'}{'2'} = "Scientific projects and research";
$subseries_text{'3'}{'3'} = "Student dissertations";
$subseries_text{'3'}{'4'} = "Teaching";
$subseries_text{'3'}{'5'} = "Miscellaneous"; 
$subseries_text{'4'}{'1'} = "Administrative material";
$subseries_text{'4'}{'2'} = "Student dissertations";
$subseries_text{'4'}{'3'} = "Teaching - Course material";
$subseries_text{'4'}{'4'} = "Miscellaneous";
$subseries_text{'5'}{'1'} = "Notebooks";
$subseries_text{'5'}{'2'} = "Projects and technical papers";
$subseries_text{'5'}{'3'} = "Publications";
$subseries_text{'5'}{'4'} = "Conferences and talks";
$subseries_text{'5'}{'5'} = "Miscellaneous material";
$subseries_text{'6'}{'1'} = "Notes, lectures, and talks";
$subseries_text{'6'}{'2'} = "Publications by others";
$subseries_text{'6'}{'3'} = "Publications by Glaser";
$subseries_text{'6'}{'4'} = "Scientific and technical document";
$subseries_text{'6'}{'5'} = "Biotechnology";
$subseries_text{'6'}{'6'} = "Miscellaneous material";
$subseries_text{'6'}{'7'} = "Oversize material";
$subseries_text{'6'}{'8'} = "UC Berkeley Virus Lab and departmental material";
$subseries_text{'7'}{'1'} = "Notes";
$subseries_text{'7'}{'2'} = "Writings and talks";
$subseries_text{'7'}{'3'} = "Technical, administrative, and other papers";
$subseries_text{'7'}{'4'} = "Born-digital material";
$subseries_text{'8'}{'1'} = "Photographic glass slides";
$subseries_text{'8'}{'2'} = "35mm slides";
$subseries_text{'8'}{'3'} = "Photographic negatives";
$subseries_text{'8'}{'4'} = "Audio";
$subseries_text{'8'}{'5'} = "Film and video";

my $output_file_name;

# input and output files hardcoded for now
open(IN, "<:encoding(UTF-8)", "../Glaser_Metadata_final_10242017.txt") or die "*** Cannot open Glaser_Metadata_final_10242017.txt for input - terminating\n";
# open(IN, "<", "../Glaser_Metadata_sample_10242017.txt") or die "*** Cannot open Glaser_Metadata_sample_10242017.txt for input - terminating\n";
# open(IN, "<", "../Glaser_Metadata_small_sample_10242017.txt") or die "*** Cannot open Glaser_Metadata_small_sample_10242017.txt for input - terminating\n";

while(<IN>)	# loop through input records

{
	if($debug)
	{
		print $_ . "\n";
	}

    $_ =~ s/(.*)\r\n$/$1/;      # Remove carriage return at the end of the line

    if($_ !~ m/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
	{
        	die "*** Line $line is invalid: $_\n";
	}
	else
	{
                $series_number = $1;
                $subseries_number = $2;
                $box_number = $3;
                $folder_number = $4;
		$caltech_or_berkeley = $5;
                $title = $6;
                $number_of_items = $7;
                $date = $8;
                $phys_desc = $9;
                $notes = $10;
	}

	# Do some cleanup and sanity checking
	# We must have title, date, series, box, and folder.
	if($title eq "")
	{
		die "*** Line $line is missing required title: $_\n";
	}
        if($date eq "")
        {
                die "*** Line $line is missing required date: $_\n";
        }
        if($series_number eq "")
        {
                die "*** Line $line is missing required series_number: $_\n";
        }
        if($box_number eq "")
        {
                die "*** Line $line is missing required box_number: $_\n";
        }
        if($folder_number eq "")
        {
                die "*** Line $line is missing required folder_number: $_\n";
        }
        if($caltech_or_berkeley eq "")
        {
                die "*** Line $line is missing required caltech_or_berkeley: $_\n";
        }

	# Box number is in form "Series.Box".  Remove the series number and period.
       if ($debug)
        {
                print "Box Number = " . $box_number . "\n";
        }
	$box_number =~ s/\d*\.//;
	if ($debug) 
        {       
                print "Box Number = " . $box_number . "\n";
	}
	# Remove quotes around title, date, $phys_desc, and notes, if they are present
	# (They may get added by the save from excel to tsv format). Encode ampersands.
	$title =~ s/^\"//;
	$title =~ s/\"$//;
	$title =~ s/\&/\&amp\;/;
	$date =~ s/^\"//;
	$date =~ s/\"$//;
	$phys_desc =~ s/^\"//;
	$phys_desc =~ s/\"$//;
	# also remove double quotes in $phys_desc or in titles
	$phys_desc =~ s/\"\"/\"/g;
	$title =~ s/\"\"/\"/g;
	$notes =~ s/^\"//;
	$notes =~ s/\"$//;
	# also remove double quotes in $phys_desc (inches) or in titles (escaped quotes)
	$phys_desc =~ s/\"\"/\"/g;
	$title =~ s/\"\"/\"/g;
	# remove trailing blanks from notes field
	$notes =~ s/\s$//;
	# if there's a period on the end of the notes field, remove it.
	$notes =~ s/\.$//;

	
	if($debug)
	{
		print "Title = " . $title . "\n";
		if($notes ne "")
		{
			print "Notes = " . $notes . "\n\n";
		}
	}

	# Process the data into MODS output here
	#
	if($line > 1)
	{
		$records_read++;
 
		my $output_record = $xml_decl;
	
		# build opening <mods> element
		$output_record .= $mods_begin;
	
		# build title element
		$output_record .= "<titleInfo><title>" . $title;
		if($number_of_items)
		{
			if(substr($number_of_items,0,3) eq "DAG")   # some recs have a filename in this field
			{
				$output_record .= " (" . $number_of_items . ")";
			}
			elsif($number_of_items eq "1")
			{
				$output_record .= " (" . $number_of_items . " item)";
			}
			else
			{
				$output_record .= " (" . $number_of_items . " items)";
			}
		}
		$output_record .= "</title></titleInfo>\n";
		
		# build typeOfResource element, based on series/subseries
		if($series_number eq "1" && $subseries_number eq "8")	#photographic
		{
			$output_record .= $typeOfResource_element_still . "\n";
		}
                elsif($series_number eq "7" && $subseries_number eq "4") # born digital
                {
                        $output_record .= $typeOfResource_element_software . "\n";
                }
		elsif($series_number eq "8")
		{
			if($subseries_number eq "1" || $subseries_number eq "2" ||
			   $subseries_number eq "3")
			{
				$output_record .= $typeOfResource_element_still . "\n";
			}
			elsif($subseries_number eq "4")
			{
				$output_record .= $typeOfResource_element_audio . "\n";
			}
			else  # subseries 5 -- film & video
			{
				$output_record .= $typeOfResource_element_moving . "\n";
			}
		}
		else   # default for everything else: mixed
		{
			$output_record .= $typeOfResource_element_mixed . "\n";
		} 

                # build originInfo/date element
                $output_record .= $originInfo_element_begin . $date . $originInfo_element_end;

		# build language element (constant "eng", at least for now)
		$output_record .= $language_element . "\n";

                # build abstract element. Include date and a "part of" statement with
                #  series, subseries, box, and folder numbers
                $output_record .= "<abstract>" . $date . ". ";
                $output_record .= "Part of: Donald A Glaser Papers. Series " . $series_number . ": " . $series_text{$series_number} . "; ";
                if($subseries_number ne "" && $subseries_number ne "0")
                {
                	$output_record .= "Subseries " . $subseries_number . ": " . $subseries_text{$series_number}{$subseries_number} . "; ";
                }
                $output_record .= "Box " . $box_number . ", Folder " . $folder_number;
                $output_record .= "</abstract>\n";
	
		# build the local identifier
		# We assign the first part of the identifier "DAG"/"DAGB" depending on whether
		# it is from the Caltech or the Berkeley collection. Default to "DAG".
		if($caltech_or_berkeley eq "Berkeley") {
			$output_record .= "<identifier type=\"local\">" . "DAGB_" . $series_number . "_" . $box_number . "_" . $folder_number . "</identifier>\n";
		}
		else {   # it's Caltech
                        $output_record .= "<identifier type=\"local\">" . "DAG_" . $series_number . "_" . $box_number . "_" . $folder_number . "</identifier>\n";
		}

		# build the physicalDescription form element based on series/subseries; add extent element if present - FIXME for Glaser categories!
		$output_record .= "<physicalDescription>\n";
		if($series_number eq "1" && $subseries_number eq "8")	# photographs
		{
			$output_record .= $physicalDescription_form_element_npg . "\n";
		}
		elsif($series_number eq "7" && $subseries_number eq "4")  # born digital
		{
			$output_record .= $physicalDescription_form_element_elec . "\n";
		}
		elsif($series_number eq "8") {
			if($subseries_number eq "1" || $subseries_number eq "2") # slides
			{
				$output_record .= $physicalDescription_form_element_pg . "\n";
			}
                        elsif($subseries_number eq "3")       # Photographic negatives
                        {
                                $output_record .= $physicalDescription_form_element_npg . "\n";
                        }
                        elsif($subseries_number eq "4")       # Audio
                        {
                                $output_record .= $physicalDescription_form_element_audio . "\n";
                        }
                        else				# Subseries 5 is video
                        {
                                $output_record .= $physicalDescription_form_element_video . "\n";
                        }
		}
		else		# default - mixed material, use unspecified
		{
			$output_record .= $physicalDescription_form_element_unspec . "\n";
		}

		# add the physicalDescription extent element if needed
		if($phys_desc ne "")
		{
			$output_record .= "<extent>" . $phys_desc . "</extent>\n";
		}

		# add the physicalDescription digitalOrigin element (required) - FIXME need option born digital
		if($series_number eq "7" && $subseries_number eq "4")  # born digital
		{
			$output_record .= "<digitalOrigin>born digital</digitalOrigin>\n";
		}
		else   # default for everything else
		{
			$output_record .= "<digitalOrigin>digitized other analog</digitalOrigin>\n";
		}
		
		# finally, close the physicalDescription container
		$output_record .= "</physicalDescription>\n";


		# build the note element. These are also included in abstract, above, so they'll get into the DC.
		if($notes)
		{	
			$output_record .= "<note>" . $notes . "</note>\n";
		}
 
		# build relatedItem, using series and subseries
		$output_record .= $relatedItem_element_begin . "<note>Part of Series " . $series_number . ": " . $series_text{$series_number};
		if($subseries_number ne "" && $subseries_number ne "0")
		{
			$output_record .= "; Subseries " . $subseries_number . ": " . $subseries_text{$series_number}{$subseries_number};
		}
		$output_record .=  ".</note>" . $relatedItem_element_end . "\n";

                # add accessCondition (rights), constant defined above
                if($caltech_or_berkeley eq "Berkeley")
		{
			$output_record .= $rights_element_berkeley . "\n";
		}
		else    # it's Caltech
		{
                	$output_record .= $rights_element . "\n";
		}

		# add the Note - ownership element  
		if($caltech_or_berkeley eq "Berkeley")
		{
			$output_record .= $ownership_element_berkeley . "\n";
		}
		else   # it's Caltech
		{
			$output_record .= $ownership_element . "\n";
		}
		
#		Location element suggested by Peter, but seems unnecessary/confusing 
#		(Berkeley stuff is actually at Iron Mountain!
#		# add the Location element (Caltech only???) FIXME
#		$output_record .= "<Location><physicalLocation>California Institute of Technology Archives.</physicalLocation></Location>\n";

		# add the recordInfo/languageOfCataloging element
		$output_record .= $recordInfo_element . "\n";;

		# add the </mods> end tag
		$output_record .= $mods_end . "\n";

		
		$records_created++;
	 
		# Write the MODS record
		# Calculate output file name
		# if Caltech, file name begins with DAG_, if Berkeley it
		# begins with DAGB_.
		if($caltech_or_berkeley eq "Berkeley")
		{
			$output_file_name = "DAGB_" . $series_number . "_" . $box_number . "_" . $folder_number . ".xml";
		}
 		else   # it's Caltech
		{
			$output_file_name = "DAG_" . $series_number . "_" . $box_number . "_" . $folder_number . ".xml";
		}
 
		if($debug)	# just print to STDOUT
		{
			print $output_record . "\n\n\n";
		}
		else		# write the MODS files
		{
			# Open output file for writing
			open(MODS_OUT, ">", "../MODS/" . $output_file_name) or die "***Cannot open " . $output_file_name . " for writing.\n\n"; 
		
			# Write MODS XML file
			print MODS_OUT $output_record;
		
			# Close output file
			close(MODS_OUT);
		}
	}

	$line++;

}

close(IN);
 
print "Number of records processed:	$records_read\n\n";
print "Number of MODS records created:	$records_created\n";
		
