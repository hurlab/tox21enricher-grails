#!/usr/bin/perl -w

use warnings;
use strict;

# --------------------------------------------------------------------
#
#				Generate_individual_gct_file_for_significant_terms.pl
#
# --------------------------------------------------------------------


if (not defined $ARGV[6])
{	die "\n!ERROR: Missing parameters\n".
		">ThisScript.pl <Input Dir> <DAVID Result directory> <topTermCount per file>\n".
		"               <Sig-applying ALL or AT-LEAST-ONE data> <SigColumn> <SigCutOff> <ValueColumn>\n".
		"				[optional part of file name]\n\n".
		">ThisScript.pl Input/ Output/ 10 ALL BH 0.05 P\n\n";
}


# -------------------------------------
# Get the corresponding directory names
# -------------------------------------
$ARGV[0] =~ s/\\/\//g;
$ARGV[1] =~ s/\\/\//g;
our $baseinputDirName		= $ARGV[0];
our $baseDirName			= $ARGV[1];
my @baseNameSplit			= split (/\//, $baseDirName);
our $baseShortDirName		= '';
if ($baseNameSplit[$#baseNameSplit] eq "")
{	$baseShortDirName		= $baseNameSplit[$#baseNameSplit - 1].'/';
}else
{	$baseShortDirName		= $baseNameSplit[$#baseNameSplit].'/';
}

our $baseOutputDir			= $ARGV[1].'/gct_per_set/';
$baseOutputDir				=~ s/\/\//\//g;
mkdir ($baseOutputDir)	|| print "";
opendir DIR, $baseOutputDir or die "Cannot open the current directory: $baseOutputDir";
my @tmpDirs = readdir DIR;
closedir DIR;



# -------------------------------------
# Load CASRN name
# -------------------------------------
open (CAS, "Annotation/Tox21_CASRN_Names.anno");
my %CASRN2Name	= ();
while(<CAS>)
{	my $line = $_;		$line =~ s/\r|\n//g;
	my @tmpSplit = split (/\t/, $line);
	if ((defined $tmpSplit[1]) && ($tmpSplit[1] ne ""))
	{	$CASRN2Name{$tmpSplit[1]} = $tmpSplit[0];		# note that the last name for multiple entries will be used
	}
}	close CAS;


# -------------------------------------
# Enumerate all possible directories
# -------------------------------------

process_variable_DAVID_CHART_directories_individual_file ($baseinputDirName, $baseDirName, $baseOutputDir, '', '');



exit;




sub process_variable_DAVID_CHART_directories_individual_file
{	my $inputDirName			= shift;
	my $dirName					= shift;
	my $outputDir				= shift;
	my $extTag					= shift;
	my $additionalFileName		= shift;
	
	# Load the input file *******************************************************************Not sure if this GLOB works
	print "! Loading $inputDirName input files ...\n";
	my @setInputFiles			= glob ("$inputDirName"."/"."*.txt");
	
	# TODO -----------------------------------------------------
	# In case Scott want to include all CASRN in the input list, 
	# We need to reac the original input files
	
	# Check the direcory for any file
	print "! Processing $dirName ...\n";
	my @infiles			= glob ("$dirName"."/"."*_Chart.txt");
	if (not defined $infiles[0])
	{	return;
	}

	my $sigCutOff				= $ARGV[5];
	my $sigColumnName			= uc($ARGV[4]);
	my $sigColumnIndex			= get_column_index ($sigColumnName);			# 4=p-value, 11=BH p-value, 12=FDR
	my $valueColumnName			= uc($ARGV[6]);
	my $valueColumnIndex		= get_column_index ($valueColumnName);
	
	# Step1. Get the list of significant terms
	foreach my $infile (@infiles) 
	{	my @tmp1 = split (/\//, $infile);
		my @tmp2 = split (/\.txt/, $tmp1[$#tmp1]);
		
		my (%term2pvalue, %CASRN2TermMatrix);
		open (DATA, $infile);
		while(<DATA>)
		{	my $line = $_;
			$line =~ s/\r|\n//g;
			my @tmpSplit = split (/\t/, $line);
			if (($tmpSplit[$sigColumnIndex] =~ /^\D/) || ($tmpSplit[$sigColumnIndex] >= $sigCutOff) || 
				($tmpSplit[9]<1))
			{	next;
			}
	
			my $tmpTermKey				= $tmpSplit[1].' | '.$tmpSplit[0];
			$term2pvalue{$tmpTermKey}	= $tmpSplit[$sigColumnIndex];
			my @CASRNs = split (/\, /, $tmpSplit[5]);
			foreach my $CASRN (@CASRNs)
			{	$CASRN2TermMatrix{$CASRN}{$tmpTermKey} = 1;
			}
		}	close DATA;
		

		# Now create new output files
		open (OUTFILE, ">".$outputDir.$tmp2[0].'.gct');
		my @CASRNs			= keys %CASRN2TermMatrix;
		my @tmpTermKeys 	= keys %term2pvalue;
		my $CASRNCount		= scalar @CASRNs;
		my $tmpTermKeyCount	= scalar @tmpTermKeys;
		my $outputContent	= 	"#1.2\n".
								"$CASRNCount\t$tmpTermKeyCount\n"."CASRN\tName";
		foreach my $tmpTermKey (@tmpTermKeys)
		{	$outputContent	.= "\t".$tmpTermKey." | ".sprintf("%.2e", $term2pvalue{$tmpTermKey});
		}	$outputContent	.= "\n";
		
		foreach my $CASRN (@CASRNs)
		{	$outputContent	.= $CASRN."\t";
			if (defined $CASRN2Name{$CASRN})
			{	$outputContent	.= $CASRN2Name{$CASRN};
			}
			
			foreach my $tmpTermKey (@tmpTermKeys)
			{	if (defined $CASRN2TermMatrix{$CASRN}{$tmpTermKey})
				{	$outputContent	.= "\t1";
				}else
				{	$outputContent	.= "\t0";
				}
			}	$outputContent	.= "\n";
		}
		
		print OUTFILE $outputContent;
		close OUTFILE;
	}
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
