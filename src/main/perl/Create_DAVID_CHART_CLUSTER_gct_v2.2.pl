#!/usr/bin/perl -w

use warnings;
use strict;

# --------------------------------------------------------------------
#
#				Create_DAVID_CHART_CLUSTER_gct.pl
#
# Version 2.2:	(10/03/2016) Create an additional file for network
#
# --------------------------------------------------------------------


if (not defined $ARGV[5])
{	die "\n!ERROR: Missing parameters\n".
		">ThisScript.pl <DAVID Result directory> <topTermCount per file>\n".
		"               <Sig-applying ALL or AT-LEAST-ONE data> <SigColumn> <SigCutOff> <ValueColumn>\n".
		"				[optional part of file name]\n\n".
		">ThisScript.pl DNM 10 ALL BH 0.05 P\n".
		">ThisScript.pl DNM 20 ALO BH 0.05 BH\n\n";
}


# -------------------------------------
# Get the corresponding directory names
# -------------------------------------
$ARGV[0] =~ s/\\/\//g;
our $baseDirName			= $ARGV[0];
my @baseNameSplit			= split (/\//, $baseDirName);
our $baseShortDirName		= '';
if ($baseNameSplit[$#baseNameSplit] eq "")
{	$baseShortDirName		= $baseNameSplit[$#baseNameSplit - 1].'/';
}else
{	$baseShortDirName		= $baseNameSplit[$#baseNameSplit].'/';
}
our $annotationBaseDir		= "Annotation/";
our $baseOutputDir			= $ARGV[0].'/gct/';
$baseOutputDir				=~ s/\/\//\//g;

if (-d $baseOutputDir) {
	# do nothing if directory already exists (i.e., we are regenerating the network)
	print "Found existing directory: $baseOutputDir";
}
else {
	# else create the directory if this is the first time we are dealing with this data set
	print "No directory found for $baseOutputDir. Making...";
	mkdir ($baseOutputDir)	|| print "";
}
opendir DIR, $baseOutputDir or die "Cannot open the current directory: $baseOutputDir";
my @tmpDirs = readdir DIR;
closedir DIR;



# -------------------------------------
# Load term annotation data
# -------------------------------------
my %className2classID	= ();
my %classID2className	= ();
open (ANNOSET, $annotationBaseDir."table_annotation_class.txt");
while(<ANNOSET>)
{	my $line = $_;
	my @tmpSplit = split (/\t/, $line);
	if ($tmpSplit[0] =~ /^\d/)
	{	$className2classID{$tmpSplit[1]} = $tmpSplit[0];
		$classID2className{$tmpSplit[0]} = $tmpSplit[1];
	}
}	close ANNOSET;

my %classID2annotationTerm2termUniqueID	= ();
open (ANNOTERM, $annotationBaseDir."table_annotation_detail.txt");
while(<ANNOTERM>)
{	my $line = $_;	$line =~ s/\r|\n//g;
	my @tmpSplit = split (/\t/, $line);
	if ($tmpSplit[0] =~ /^\d/)
	{	$classID2annotationTerm2termUniqueID{$tmpSplit[1]}->{$tmpSplit[2]} = $tmpSplit[0];
		#print STDERR $tmpSplit[1]."\t".$tmpSplit[2]."\t".$tmpSplit[0]."\t<BR>\n";
	}
}	close ANNOTERM;







# -------------------------------------
# Enumerate all possible directories
# -------------------------------------

process_variable_DAVID_CHART_directories ($baseDirName, $baseOutputDir, '', '');
process_variable_DAVID_CLUSTER_directories ($baseDirName, $baseOutputDir, '', '');


exit;





sub process_variable_DAVID_CLUSTER_directories
{	my $dirName					= shift;
	my $outputDir				= shift;
	my $extTag					= shift;
	my $additionalFileName		= shift;
	
	# Check the direcory for any file
	print "! Processing $dirName ...\n";
	my @infiles			= glob ("$dirName"."/"."*_Cluster.txt");
	if (not defined $infiles[0])
	{	return();
	}
	
	# Define number of top cluters
	mkdir ($outputDir) || print "";
	my $dirInputName			= $dirName;
	my $dirInputExpression		= $dirInputName.'/ExpressionData/';
	my $topTermLimit			= $ARGV[1];
	my $mode					= uc($ARGV[2]);
	my $sigCutOff				= $ARGV[4];
	my $sigColumnName			= uc($ARGV[3]);
	my $sigColumnIndex			= get_column_index ($sigColumnName);			# 4=p-value, 11=BH p-value, 12=FDR
	my $valueColumnName			= uc($ARGV[5]);
	my $valueColumnIndex		= get_column_index ($valueColumnName);
	my $summaryFileNameBase		= $additionalFileName;
	my $summaryFileNameExt		= $extTag;
	my @dirNameSplit			= split (/\//, $dirName);
	if (defined $dirNameSplit[$#dirNameSplit])
	{	#$summaryFileNameBase 	= $dirNameSplit[$#dirNameSplit]."__Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
		$summaryFileNameBase 	.= "Cluster_Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
		$summaryFileNameExt		.= "Cluster_Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
	}else
	{	#$summaryFileNameBase 	= $dirName."__Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
		$summaryFileNameBase 	.= "Cluster_Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
		$summaryFileNameExt		.= "Cluster_Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
	}

	
	# -----------------------------------------------------------------------------
	# Load DAVID cluster files
	$summaryFileNameBase =~ s/\///;
#	mkdir ($outputDir) || print "";
#	my $outputDetailDir	= $outputDir.'/Detail/';
#	mkdir ($outputDetailDir) || print "";
#	$outputDetailDir	.= $summaryFileNameBase.'/';
#	mkdir ($outputDetailDir) || print "";

	my %ID2Term			= ();
	my %ID2Class		= ();
	my @fileHeaderNames = ();
	my %pvalueMatrix	= ();
	my %fcMatrix		= ();
	my %upDownMatrix	= ();
	
	# Additional variables/hashes/arrays for expression details
	my %geneID2expDetails	= ();
	#my %file2ExpDetailCnt	= ();
	# my %termID2geneContent	= ();
	my %geneID2Description	= ();
	my @allBaseFileNames	= ();
	my $gctFileHeader		= '';
	my %geneID2ExpProfile	= ();
	my $gctFileStatus		= 0;
	
	# Load gct file, if availalbe
	# check gct file
	my @gctFiles = glob ($dirInputName.'/'."*.gct");
	if (defined $gctFiles[0])
	{	($gctFileStatus, $gctFileHeader) = load_gct_file_as_profile ($gctFiles[0], \%geneID2ExpProfile);
	}

	# Step1. Get the list of significant terms
	foreach my $infile (@infiles) 
	{	my @tmp1 = split (/\//, $infile);
		my @tmpNameSplit = split (/\_\_Cluster\.txt/, $tmp1[$#tmp1]);		
		my $shortFileBaseName	= $tmpNameSplit[0];
		my $originalSourceFile = $dirInputName.'/'.$shortFileBaseName.'.txt';
		
		# if (not defined $file2ExpDetailCnt{$shortFileBaseName})
		# {	$file2ExpDetailCnt{$shortFileBaseName} = 0;
		# }
		
					
		open (DATA, $infile);
		my $termCount	= 1;
		my @lines = <DATA>;
		for (my $i=0; $i <= $#lines; $i++)
		{	$lines[$i] =~ s/\r|\n//g;
			if ($lines[$i] =~ /^Annotation Cluster (\d+)\s+Enrichment Score: (\S+)/)
			{	# skip the next line 
				$i = $i + 2;
	
				# process the first term
				my @tmpSplit = split (/\t/, $lines[$i]);
	
				if (($tmpSplit[$sigColumnIndex] =~ /^\D/) || ($tmpSplit[$sigColumnIndex] >= $sigCutOff) || 
				($tmpSplit[9]<1))
				{	next;
				}
	
				if ($termCount <= $topTermLimit)
				{	my $tmpID	= $tmpSplit[0].' | '.$tmpSplit[1];
					$ID2Term{$tmpID}	= $tmpSplit[1];
					$ID2Class{$tmpID}	= $tmpSplit[0];
					$termCount++;
				}
			}
		}	close DATA; 
	}
						
	
	my @IDs = keys %ID2Term;
	foreach my $infile (@infiles) 
	{	my @tmp1 = split (/\//, $infile);
		my @tmpNameSplit = split (/\_\_Cluster\.txt/, $tmp1[$#tmp1]);
		my $shortFileBaseName	= $tmpNameSplit[0];
	
		my @tmp2 = split (/\.xls/, $tmp1[$#tmp1]);
		if (length($tmp2[0]) == length($tmp1[$#tmp1]))
		{	@tmp2 = split (/\.txt/, $tmp1[$#tmp1]);
		}
	
		my @tmp3 = split (/__Cluster/, $tmp2[0]);
		push @fileHeaderNames, $tmp3[0];
		
	
		# ------------------------------------------------------------
		# Load expression data if any
		my $expressionDataExist = 0;
		my %expressionData		= ();
		my %expressionDataFC	= ();
		my $expressionHeader = "";
	
	
		# ------------------------------------------------------------
		# Check term file and load
		open (DATA, $infile);
		while(<DATA>)
		{	my $line = $_;
			$line =~ s/\r|\n//g;
			my @tmpSplit = split (/\t/, $line);
			
			if ((not defined $tmpSplit[$sigColumnIndex]) ||
				(not defined $tmpSplit[9]) ||
				($tmpSplit[$sigColumnIndex] =~ /^\D/) || 
				(($mode eq 'ALL') && ($tmpSplit[$sigColumnIndex] >= $sigCutOff)) || 
				($tmpSplit[9]<1))
			{	next;
			}
			
			my $tmpID	= $tmpSplit[0].' | '.$tmpSplit[1];
			if (defined $ID2Term{$tmpID})
			{	$pvalueMatrix{$tmpID}->{$tmp3[0]} = -1*log10($tmpSplit[$valueColumnIndex]);
				$fcMatrix{$tmpID}->{$tmp3[0]} = $tmpSplit[9];
			}
		}	close DATA;
	}
	
	
	
	# Create a summary file
	my $summaryFileName = $summaryFileNameBase.'__ValueMatrix.txt';
	open (SUMMARY, ">".$outputDir.$summaryFileName);
	@fileHeaderNames = sort_by_file_number (\@fileHeaderNames);
	print SUMMARY "GROUP\tID\tTerms\t".join("\t",@fileHeaderNames)."\n";
	
	foreach my $ID (@IDs)
	{	print SUMMARY $ID2Class{$ID}."\t".$ID."\t";
		foreach my $header (@fileHeaderNames)
		{	if (defined $pvalueMatrix{$ID}->{$header})
			{	print SUMMARY "\t".$pvalueMatrix{$ID}->{$header};
			}else
			{	print SUMMARY "\t";
			}
		}
		print SUMMARY "\n";
	}	close SUMMARY;
	
	
	
	# Create a network summary file for Chart
	my $ForNetworkFile = $summaryFileNameBase.'__ValueMatrix.ForNet';
	open (NETWORK, ">".$outputDir.$ForNetworkFile);
	print NETWORK "GROUPID\tUID\tTerms\t".join("\t",@fileHeaderNames)."\n";
	
	
	foreach my $ID (@IDs)
	{	my @idTermSplits = split (/ \| /, $ID);
		my $tmpHashRef	= $classID2annotationTerm2termUniqueID{$className2classID{$idTermSplits[0]}};
		
		print NETWORK $className2classID{$idTermSplits[0]}."\t".$$tmpHashRef{$idTermSplits[1]}."\t".$idTermSplits[1];
		foreach my $header (@fileHeaderNames)
		{	if (defined $pvalueMatrix{$ID}->{$header})
			{	print NETWORK "\t".$pvalueMatrix{$ID}->{$header};
			}else
			{	print NETWORK "\t";
			}
		}
		print NETWORK "\n";
	}	close NETWORK;
	
	

	# Create a gct file from ValueMatrix
	open (INFILE, $outputDir.$summaryFileNameBase.'__ValueMatrix.txt');
	open (OUTFILE, ">".$outputDir.$summaryFileNameBase.'__ValueMatrix.gct');
	
	my $headerLine	= <INFILE>;
	$headerLine		=~ s/\r|\n//g;
	my @headerSplit	= split (/\t/, $headerLine);
	my $sampleCnt	= (scalar @headerSplit) - 3;
	shift @headerSplit;
	my $geneCnt		= 0;
	my $content		= '';
	while(<INFILE>)
	{	my $line = $_;
		$line =~ s/\r|\n//g;
		if ($line eq "")
		{	next;
		}
	
		my @tmpSplit = split (/\t/, $line);
		for (my $i=3; $i < ($sampleCnt+3); $i++)
		{	if ((not defined $tmpSplit[$i]) || ($tmpSplit[$i] eq ""))
			{	$tmpSplit[$i] = 0;
			}
		}
		shift @tmpSplit;
		$content .= join ("\t", @tmpSplit)."\n";
		$geneCnt++;
	}	close INFILE;
	
	print OUTFILE	"#1.2\n".
					"$geneCnt\t$sampleCnt\n".
					join("\t", @headerSplit)."\n".
					$content;
	close OUTFILE;
}	
	
	



sub process_variable_DAVID_CHART_directories
{	my $dirName					= shift;
	my $outputDir				= shift;
	my $extTag					= shift;
	my $additionalFileName		= shift;
	
	# Check the direcory for any file
	print "! Processing $dirName ...\n";
	my @infiles			= glob ("$dirName"."/"."*_Chart.txt");
	if (not defined $infiles[0])
	{	return;
	}
	
	# Define number of top cluters
	mkdir ($outputDir) || print "";
	my $dirInputName			= $dirName;
	my $dirInputExpression		= $dirInputName.'/ExpressionData/';
	
	my $topTermLimit			= $ARGV[1];
	my $mode					= uc($ARGV[2]);
	my $sigCutOff				= $ARGV[4];
	my $sigColumnName			= uc($ARGV[3]);
	my $sigColumnIndex			= get_column_index ($sigColumnName);			# 4=p-value, 11=BH p-value, 12=FDR
	my $valueColumnName			= uc($ARGV[5]);
	my $valueColumnIndex		= get_column_index ($valueColumnName);
	my $summaryFileNameBase		= $additionalFileName;
	my $summaryFileNameExt		= $extTag;
	my @dirNameSplit			= split (/\//, $dirName);
	if (defined $dirNameSplit[$#dirNameSplit])
	{	#$summaryFileNameBase 	= $dirNameSplit[$#dirNameSplit]."__Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
		$summaryFileNameBase 	.= "Chart_Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
		$summaryFileNameExt		.= "Chart_Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
	}else
	{	#$summaryFileNameBase 	= $dirName."__Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
		$summaryFileNameBase 	.= "Chart_Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
		$summaryFileNameExt		.= "Chart_Top$topTermLimit".'_'.$mode.'__'.$sigColumnName.'_'.$sigCutOff.'_'.$valueColumnName;
	}

	$summaryFileNameBase =~ s/\///;
#	mkdir ($outputDir) || print "";
#	my $outputDetailDir	= $outputDir.'/Detail/';
#	mkdir ($outputDetailDir) || print "";
#	$outputDetailDir	.= $summaryFileNameBase.'/';
#	mkdir ($outputDetailDir) || print "";

	# -----------------------------------------------------------------------------
	# Load DAVID Chart files
	
	my %ID2Term			= ();
	my %ID2Class		= ();
	my @fileHeaderNames = ();
	my %pvalueMatrix	= ();
	my %fcMatrix		= ();
	my %upDownMatrix	= ();
	
	my %geneID2expDetails	= ();
	#my %file2ExpDetailCnt	= ();
	#my %termID2geneContent	= ();
	my %geneID2Description	= ();
	my @allBaseFileNames	= ();
	
	my $gctFileHeader		= '';
	my %geneID2ExpProfile	= ();
	my $gctFileStatus		= 0;
	
	# Load gct file, if availalbe
	# check gct file
	my @gctFiles = glob ($dirInputName.'/'."*.gct");
	if (defined $gctFiles[0])
	{	($gctFileStatus, $gctFileHeader) = load_gct_file_as_profile ($gctFiles[0], \%geneID2ExpProfile);
	}
	
	
	# Step1. Get the list of significant terms
	foreach my $infile (@infiles) 
	{	my @tmp1 = split (/\//, $infile);
		my @tmpNameSplit = split (/\_\_Chart\.txt/, $tmp1[$#tmp1]);		
		my $shortFileBaseName	= $tmpNameSplit[0];
		my $originalSourceFile = $dirInputName.'/'.$shortFileBaseName.'.txt';
		
		push @allBaseFileNames, $shortFileBaseName;
	
		# if (not defined $file2ExpDetailCnt{$shortFileBaseName})
		# {	$file2ExpDetailCnt{$shortFileBaseName} = 0;
		# }
		
					
		open (DATA, $infile);
		my $termCount	= 1;

		while(<DATA>)
		{	my $line = $_;
			$line =~ s/\r|\n//g;
			my @tmpSplit = split (/\t/, $line);
			#print $line."\n";
			if (($tmpSplit[$sigColumnIndex] =~ /^\D/) || ($tmpSplit[$sigColumnIndex] >= $sigCutOff) || 
				($tmpSplit[9]<1))
			{	next;
			}
	
			if ($termCount <= $topTermLimit)
			{	my $tmpID	= $tmpSplit[0].' | '.$tmpSplit[1];
				$ID2Term{$tmpID}	= $tmpSplit[1];
				$ID2Class{$tmpID}	= $tmpSplit[0];
				$termCount++;
			}
		}	close DATA;
	}
						
	
	my @IDs = keys %ID2Term;
	foreach my $infile (@infiles) 
	{	my @tmp1 = split (/\//, $infile);
		my @tmpNameSplit = split (/\_\_Chart\.txt/, $tmp1[$#tmp1]);
		my $shortFileBaseName	= $tmpNameSplit[0];
	
		my @tmp2 = split (/\.xls/, $tmp1[$#tmp1]);
		if (length($tmp2[0]) == length($tmp1[$#tmp1]))
		{	@tmp2 = split (/\.txt/, $tmp1[$#tmp1]);
		}
	
		my @tmp3 = split (/__Chart/, $tmp2[0]);
		push @fileHeaderNames, $tmp3[0];
		
	
		# ------------------------------------------------------------
		# Load expression data if any
		my $expressionDataExist = 0;
		my %expressionData		= ();
		my %expressionDataFC	= ();
		my $expressionHeader = "";
	
	
		# ------------------------------------------------------------
		# Check term file and load
		open (DATA, $infile);
		while(<DATA>)
		{	my $line = $_;
			$line =~ s/\r|\n//g;
			my @tmpSplit = split (/\t/, $line);
			
			if ((not defined $tmpSplit[$sigColumnIndex]) ||
				(not defined $tmpSplit[9]) ||
				($tmpSplit[$sigColumnIndex] =~ /^\D/) || 
				(($mode eq 'ALL') && ($tmpSplit[$sigColumnIndex] >= $sigCutOff)) || 
				($tmpSplit[9]<1))
			{	next;
			}
	
			my $tmpID	= $tmpSplit[0].' | '.$tmpSplit[1];
			#print $tmpID."\n\n";
			if (defined $ID2Term{$tmpID})
			{	$pvalueMatrix{$tmpID}->{$tmp3[0]} = -1*log10($tmpSplit[$valueColumnIndex]);
				$fcMatrix{$tmpID}->{$tmp3[0]} = $tmpSplit[9];
				#$ID2Class{$tmpSplit[1]} = $tmpSplit[0];
				# if ($expressionDataExist)
				# {	$upDownMatrix{$tmpSplit[1]}->{$tmp3[0]} = get_up_down_counts (\%expressionDataFC, $tmpSplit[5]);
				# }
				#$termID2geneContent{$tmpSplit[1]}->{$shortFileBaseName} = $tmpSplit[5];
			}
		}	close DATA;
	}
	
	
	
	# Create a summary file
	my $summaryFileName = $summaryFileNameBase.'__ValueMatrix.txt';
	open (SUMMARY, ">".$outputDir.$summaryFileName);
	@fileHeaderNames = sort_by_file_number (\@fileHeaderNames);
	print SUMMARY "GROUP\tID\tTerms\t".join("\t",@fileHeaderNames)."\n";

	foreach my $ID (@IDs)
	{	print SUMMARY $ID2Class{$ID}."\t".$ID2Term{$ID}."\t";
		foreach my $header (@fileHeaderNames)
		{	if (defined $pvalueMatrix{$ID}->{$header})
			{	print SUMMARY "\t".$pvalueMatrix{$ID}->{$header};
			}else
			{	print SUMMARY "\t";
			}
		}
		print SUMMARY "\n";
	}	close SUMMARY;
	
	
	# Create a network summary file for Chart
	my $ForNetworkFile = $summaryFileNameBase.'__ValueMatrix.ForNet';
	open (NETWORK, ">".$outputDir.$ForNetworkFile);
	print NETWORK "GROUPID\tUID\tTerms\t".join("\t",@fileHeaderNames)."\n";
	
	
	foreach my $ID (@IDs)
	{	my @idTermSplits = split (/ \| /, $ID);
		my $tmpHashRef	= $classID2annotationTerm2termUniqueID{$className2classID{$idTermSplits[0]}};
		
		print NETWORK $className2classID{$idTermSplits[0]}."\t".$$tmpHashRef{$idTermSplits[1]}."\t".$idTermSplits[1];
		foreach my $header (@fileHeaderNames)
		{	if (defined $pvalueMatrix{$ID}->{$header})
			{	print NETWORK "\t".$pvalueMatrix{$ID}->{$header};
			}else
			{	print NETWORK "\t";
			}
		}
		print NETWORK "\n";
	}	close NETWORK;
	
	
	
	
	
	# Create a gct file from ValueMatrix
	open (INFILE, $outputDir.$summaryFileNameBase.'__ValueMatrix.txt');
	open (OUTFILE, ">".$outputDir.$summaryFileNameBase.'__ValueMatrix.gct');
	
	my $headerLine	= <INFILE>;
	$headerLine		=~ s/\r|\n//g;
	my @headerSplit	= split (/\t/, $headerLine);
	my $sampleCnt	= (scalar @headerSplit) - 3;
	shift @headerSplit;
	my $geneCnt		= 0;
	my $content		= '';
	while(<INFILE>)
	{	my $line = $_;
		$line =~ s/\r|\n//g;
		if ($line eq "")
		{	next;
		}
	
		my @tmpSplit = split (/\t/, $line);
		for (my $i=3; $i < ($sampleCnt+3); $i++)
		{	if ((not defined $tmpSplit[$i]) || ($tmpSplit[$i] eq ""))
			{	$tmpSplit[$i] = 0;
			}
		}
		shift @tmpSplit;
		$content .= join ("\t", @tmpSplit)."\n";
		$geneCnt++;
	}	close INFILE;
	
	print OUTFILE	"#1.2\n".
					"$geneCnt\t$sampleCnt\n".
					join("\t", @headerSplit)."\n".
					$content;
	close OUTFILE;
}	
	
	








sub log10 {
	my $n = shift;
	if (($n == 0) || ($n == 0.00e+000))
	{	return -16;
	}
	return log($n)/log(10);
}

sub get_up_down_counts 
{	my $expressionDataFCRef	= shift;
	my $geneIDString		= shift;

	my @geneIDs = split (/\, /, $geneIDString);
	my $upCnt	= 0;
	my $dnCount	= 0;
	foreach my $geneID (@geneIDs)
	{	if (defined $$expressionDataFCRef{$geneID})
		{	if ($$expressionDataFCRef{$geneID} > 0)
			{	$upCnt++;
			}else
			{	$dnCount++;
			}
		}
	}
	
	return ("($upCnt/$dnCount)");
}

sub get_column_index 
{	my $columnType	= shift;
	
	if ($columnType =~ /P/i) 
	{	return (4);
	}elsif($columnType =~ /BH/i) 
	{	return (11)
	}elsif($columnType =~ /BF/i) 
	{	return (12)
	}else
	{	die "!ERROR! Wrong Signficance type. Use P, BH, or BF\n\n";
	}
}


sub process_go_kegg_id_term_for_filename
{	my $ID		= shift;
	my $term	= shift;

	if ((not defined $ID) || (not defined $term))
	{	return("!ERROR! ID or Term is not defined...\n");
	}

	$ID		=~ s/\://g;
	$term	=~ s/\+|\-|\,|\'|\"|\/|\\//g;
	$term	=~ s/\s+/ /g;

	# use only the first 50 characters
	if (length($term)>50)
	{	return($ID.'_'.substr($term,0,50));	
	}
	return($ID.'_'.$term);
}

#  -----------------------------------------------------------------------------
#  sub is_number
#  -----------------------------------------------------------------------------
#  sub is_number is a moidifed version of getNum() 
#  Checking Whether a String Is a Valid Number
#  http://www.unix.org.ua/orelly/perl/cookbook/ch02_02.htm
#  -----------------------------------------------------------------------------
sub is_number 
{   use POSIX qw(strtod);
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $! = 0;
    my($num, $unparsed) = strtod($str);
    if (($str eq '') || ($unparsed != 0) || $!)
    {   return (0);
    } else
    {   return (1);
    }
}

sub load_gct_file_as_profile
{	my $infile					= shift;
	my $geneID2ExpProfileRef	= shift;
	open (INFILE, $infile) || return (0);
	my $header = <INFILE>;
	if ($header !~ /^\#1/)
	{	# this is not a gct file
		return(0);
	}
	$header = <INFILE>;		$header = <INFILE>;	$header =~ s/\r|\n//g;
	my @headerSplit = split (/\t/, $header);
	my $maxValue	= 0;
	my $lineCount	= 0;
	while(<INFILE>)
	{	my $line = $_;
		$line =~ s/\r|\n//g;
		my @tmpSplit = split (/\t/, $line);
		if ($tmpSplit[0] =~ /\_at/)
		{	$tmpSplit[0] =~ s/\_at//g;
		}
		$$geneID2ExpProfileRef{$tmpSplit[0]} = join ("\t", @tmpSplit);
		if ($lineCount < 10)
		{	for (my $i=2; $i <= $#tmpSplit; $i++)
			{	if ($tmpSplit[$i] > $maxValue)
				{	$maxValue = $tmpSplit[$i];
				}
			}
		}
		$lineCount++;		
	}	close INFILE;

	# check if the gct file is not log-transformed
	if ($maxValue > 20)
	{	foreach my $geneID (keys %{$geneID2ExpProfileRef})
		{	my @tmpSplit = split (/\t/, $$geneID2ExpProfileRef{$geneID});
			for (my $i=2; $i <= $#tmpSplit; $i++)
			{	$tmpSplit[$i] = log($tmpSplit[$i])/log(2);
			}
			$$geneID2ExpProfileRef{$geneID} = join ("\t", @tmpSplit);
		}
	}
	return (1, $header);
}


sub sort_by_file_number
{	my $originalArrayRef	= shift;
	my @originalArray		= @{$originalArrayRef};
	my $originalCount		= scalar @originalArray;
	my @sortedArray 		= ();
	my %number2original		= ();

	if ((defined $originalArray[0]) && ($originalArray[0] =~ /\w\d+$/))
	{	foreach my $name (@originalArray)
		{	if ($name =~ /\w(\d+)$/)
			{	$number2original{$1}	= $name;
			}
		}
		
		my @sortedNumbers	= sort {$a <=> $b} keys %number2original;
		if ($#sortedNumbers != $#originalArray)
		{	return (@originalArray);
		}else
		{	foreach my $num (@sortedNumbers)
			{	push @sortedArray, $number2original{$num};
			}
			return @sortedArray;
		}
	}
	return @originalArray;
}
