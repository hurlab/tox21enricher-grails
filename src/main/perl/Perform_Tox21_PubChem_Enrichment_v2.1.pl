#!/usr/bin/perl
#-------------------------------------------------------------------------------
#					Perform_Tox21_PubChem_Enrichment
#
#									by Junguk Hur (junguk.hur @ med.und.edu)
#
#-------------------------------------------------------------------------------
# 
# This script has been solely developed by Junguk Hur and is not open to 
# the public. The use of this script is limited only to those who have received 
# written permission from Junguk Hur, until released to the public. 
#	
#-------------------------------------------------------------------------------
# 	
#	This script performs enrichment analysis of Tox21 data
#
#	v1.0	: (05/10/2013) Initial release
#	v2.1	: (07/21/2015) Additional annotations
#             (10/05/2015) NOCAS_00000 ID handling
#-------------------------------------------------------------------------------
use Cwd;

use strict;
use warnings;
use Text::NSP::Measures::2D::Fisher::right;

# Initialization
our $annotationBaseDir		= "Annotation/";
our %funCat2Selected		= ();
if (defined $ARGV[2])
{	for (my $i=2; $i<=$#ARGV; $i++)
	{	if ($ARGV[$i] ne "")
		{	my @tmpSplit = split (/=/, $ARGV[$i]);
			if ($tmpSplit[1] eq 'checked')
			{	$funCat2Selected{$tmpSplit[0]}	= 1;
			}else
			{	$funCat2Selected{$tmpSplit[0]}	= 0;
			}
		}
	}
}else
{	%funCat2Selected		= (	
								"MeSH" 						=> 1, 
								"PharmActionList" 			=> 1,
								"THERAPEUTIC_CLASS"			=> 1,
								"INDICATION"				=> 1,
								"PRODUCT_CLASS"				=> 1,
								"THERAPEUTIC_CLASS"			=> 1,
								"STRUCTURE_ACTIVITY"		=> 1,
								"MODE_CLASS"				=> 1,
								"MECHANISM"					=> 1,
								"ADVERSE_EFFECT"			=> 1,
								"KNOWN_TOXICITY"			=> 1,
								"TISSUE_TOXICITY"			=> 1,
								"MECH_LEVEL_3"				=> 1,
								"MESH_LEVEL_1"				=> 1,
								"MESH_LEVEL_3"				=> 1,
								"MESH_LEVEL_2"				=> 1,
								"MECH_LEVEL_2"				=> 1,
								"ACTIVITY_CLASS"			=> 1,
								"ZERO_CLASS"				=> 1,
								"MECH_LEVEL_1"				=> 1,
								"TA_LEVEL_3"				=> 1,
								"TA_LEVEL_2"				=> 1,
								"TA_LEVEL_1"				=> 1, 
								"CTD_PATHWAY"				=> 1, 
								"CTD_GO-BP"					=> 0, 
								"CTD_SF"					=> 0,
								"CTD_Chem2Disease"			=> 1, 
								"CTD_Chem2Gene_25"			=> 1,
								"DrugBank_Targets"			=> 1,
								"DrugBank_ATC_Code"			=> 1,
								"Toxins_Targets"			=> 1,
								"Leadscope_Toxicity"		=> 1,
								"MultiCase_Tox_Prediction"	=> 1,
								"ToxRefDB"					=> 1,
								"HTS_Active"				=> 1,
								"ToxCast"					=> 1,
								"ToxPrint_Structure"		=> 1
							
							   );
}


# DSSTox Chart
our $pvalueThresholdToDisplay	= 0.2;		# p-value < 0.1 to be printed

# DSSTox Clustering
our $similarityTermOverlap		= 3;
our $similarityThreshold		= 0.50;
our $initialGroupMembership		= 3;
our $finalGroupMembership		= 3;
our $multipleLingkageThreshold	= 0.50;
our $EASEThreshold				= 1.0;


#-------------------------------------------------------------------------------
#   Load base annotation
#-------------------------------------------------------------------------------
our (%DSSTox2name, %DSSTox2CASRN, %CASRN2DSSTox);
our (%CASRN2funCatTerm, %funCatTerm2CASRN, %funCat2CASRN, %funCatTerm2CASRNCount, 
	%funCat2CASRNCount, %funCat2termCount, %term2funCat);

if (not defined $ARGV[0])
{	die "! Input directory name is not specified ...\n";
}
if (not defined $ARGV[1])
{   die "! Output directory name is not specified ...\n";
}

our $inputBaseDir			= $ARGV[0];		$inputBaseDir =~ s/\/\//\//g;
my @tmpDirSplit				= split (/\//, $inputBaseDir);
#our $outputBaseDir			= 'Output/'.$tmpDirSplit[$#tmpDirSplit].'/';
#our $outputBaseDir         = $inputBaseDir . "/../../Output/";
our $outputBaseDir          = $ARGV[1] . "/";     $outputBaseDir =~ s/\/\//\//g;
print STDERR "outputBaseDir is $outputBaseDir";
mkdir ($outputBaseDir) || print "";
print STDERR "! ----------------------------------------------------------------\n";
print STDERR "! CASRN enrichment analysis started ... \n";
print STDERR "! ----------------------------------------------------------------\n\n";

open (ANNO, $annotationBaseDir."Tox21_PubChemCID_Mapped.txt") || die "!ERROR! can't open the base annotation file ...\n\n";
my $annoHeaderLine		= <ANNO>;	$annoHeaderLine	=~ s/\r|\n//g;
my @headerSplit			= split (/\t/, $annoHeaderLine);
my $DSSToxIndex			= get_column_index (\@headerSplit, "#DSSTox_RID");
my $nameIndex			= get_column_index (\@headerSplit, "TestSubstance_ChemicalName");
my $CASRNIndex			= get_column_index (\@headerSplit, "TestSubstance_CASRN");
my $meshListIndex		= get_column_index (\@headerSplit, "MeSHTermList");
my $pharmActListIndex	= get_column_index (\@headerSplit, "PharmActionList");

while(<ANNO>)
{	my $line = $_;		$line =~ s/\r|\n//g;
	my @tmpSplit = split (/\t/, $line);

	#print ("We made it into the while. <ANNO> exists.\n");
	
	# Load annotation data
	if ((defined $tmpSplit[$nameIndex]) && ($tmpSplit[$nameIndex] ne ""))
	{	$DSSTox2name{$tmpSplit[$DSSToxIndex]}	= $tmpSplit[$nameIndex];
	}else
	{	$DSSTox2name{$tmpSplit[$DSSToxIndex]}	= '';
	}
	
	if ((defined $tmpSplit[$CASRNIndex]) && ($tmpSplit[$CASRNIndex] ne ""))
	{	$DSSTox2CASRN{$tmpSplit[$DSSToxIndex]}	= $tmpSplit[$CASRNIndex];
		$CASRN2DSSTox{$tmpSplit[$CASRNIndex]}{$tmpSplit[$DSSToxIndex]} = 1;	
		
		# Update functional category information - MeSHTermList
#		if ((defined $tmpSplit[$meshListIndex]) && ($tmpSplit[$meshListIndex] ne ""))
#		{	my @termSplit	= split (/; /, $tmpSplit[$meshListIndex]);
#			foreach my $term (@termSplit)
#			{	$CASRN2funCatTerm{$tmpSplit[$CASRNIndex]}->{"MeSHTermList"}->{$term} 	= 1;
#				$funCatTerm2CASRN{"MeSHTermList"}->{$term}->{$tmpSplit[$CASRNIndex]} 	= 1;
#				$funCat2CASRN{"MeSHTermList"}->{$tmpSplit[$CASRNIndex]} 				= 1;
#				$term2funCat{$term} = "MeSHTermList";
#			}
#		}
		
		# Update functional category information - PharmActionList
		if ((defined $tmpSplit[$pharmActListIndex]) && ($tmpSplit[$pharmActListIndex] ne ""))
		{	my @termSplit	= split (/; /, $tmpSplit[$pharmActListIndex]);
			foreach my $term (@termSplit)
			{	$CASRN2funCatTerm{$tmpSplit[$CASRNIndex]}->{"PharmActionList"}->{$term} 	= 1;
				$funCatTerm2CASRN{"PharmActionList"}->{$term}->{$tmpSplit[$CASRNIndex]} 	= 1;
				$funCat2CASRN{"PharmActionList"}->{$tmpSplit[$CASRNIndex]} 					= 1;
				$term2funCat{$term}{"PharmActionList"} = 1;
			}
		}
	}
}	close ANNO;


print STDERR ("Closed ANNO.\n");


#-------------------------------------------------------------------------------
#   Load MeSH mapping
#-------------------------------------------------------------------------------
open (MeSH, $annotationBaseDir."Tox21_MeSH_TermHeading_Mapping.txt") || die "!ERROR! can't open the MeSH mapping annotation file ...\n\n";
my %CASRN2MeSHMHMapping	= ();
while(<MeSH>)
{	my $line = $_;		$line =~ s/\r|\n//g;
	my @tmpSplit = split (/\t/, $line);
	
	# Load annotation data
	if (defined $tmpSplit[1])
	{	my @termSplits	= split (/\; /, $tmpSplit[1]);
		$CASRN2MeSHMHMapping{$tmpSplit[0]}	= \@termSplits;
	}
}	close MeSH;

foreach my $CASRN (keys %CASRN2DSSTox)

{
	if (defined $CASRN2MeSHMHMapping{$CASRN})
	{	foreach my $term (@{$CASRN2MeSHMHMapping{$CASRN}})
		{	$CASRN2funCatTerm{$CASRN}->{"MeSH"}->{$term} 	= 1;
			$funCatTerm2CASRN{"MeSH"}->{$term}->{$CASRN} 	= 1;
			$funCat2CASRN{"MeSH"}->{$CASRN} 				= 1;
			$term2funCat{$term}{"MeSH"} = 1;
		}
	}
}






#-------------------------------------------------------------------------------
#   Load DrugMatrix Annotation
#-------------------------------------------------------------------------------
my @drugMatrixFiles	= glob ("Annotation/DrugMatrix_*.txt");
foreach my $drugMatrixFile (@drugMatrixFiles)
{	open (DRUGMATRIX, $drugMatrixFile);
	my @tmp1 = split (/\//, $drugMatrixFile);
	my @tmp2 = split (/\.txt/, $tmp1[$#tmp1]);
	substr($tmp2[0], 0, 11) = '';
	if (!$funCat2Selected{$tmp2[0]})
	{	close DRUGMATRIX;
		next;
	}
	
	while(<DRUGMATRIX>)
	{	my $line = $_;
		$line =~ s/\r|\n//g;
		my @tmpSplit = split (/\t/, $line);
		my @termSplit = split (/\; /, $tmpSplit[1]);
		
		foreach my $term (@termSplit)
		{	$CASRN2funCatTerm{$tmpSplit[0]}->{$tmp2[0]}->{$term} 	= 1;
			$funCatTerm2CASRN{$tmp2[0]}->{$term}->{$tmpSplit[0]} 	= 1;
			$funCat2CASRN{$tmp2[0]}->{$tmpSplit[0]} 				= 1;
			$term2funCat{$term}{$tmp2[0]} 							= 1;
		}
	}	close DRUGMATRIX;
}




# Calculate total CASRN count
foreach my $funCat (keys %funCat2Selected)
{	if (!$funCat2Selected{$funCat})
	{	next;
	}
	
	my @tmpArray = keys %{$funCat2CASRN{$funCat}};
	$funCat2CASRNCount{$funCat} = scalar @tmpArray;
	
	my @terms = keys %{$funCatTerm2CASRN{$funCat}};
	$funCat2termCount{$funCat} 	= scalar @terms;
	
	foreach my $term (@terms)
	{	my @tmpArray = keys %{$funCatTerm2CASRN{$funCat}->{$term}};
		$funCatTerm2CASRNCount{$funCat}{$term} = scalar @tmpArray;
	}
}



#-------------------------------------------------------------------------------
#   Load input DSSTox ID or CASRN ID sets
#-------------------------------------------------------------------------------
my @infiles			= glob ($inputBaseDir."/*.txt");
#Perl's wd is C:/Users/Larson/IdeaProjects/IdeaProjects/tox21
my $cwd = getcwd;
print "Working directory: $cwd\n";
print "inputBaseDir: $inputBaseDir\n";
print "Infiles: @infiles\n";
foreach my $infile (@infiles)
{	print "$infile";
    my @tmp1 = split (/\//, $infile);
	my @tmp2 = split (/\.txt/, $tmp1[$#tmp1]);
	print STDERR "! Processing file '$tmp2[0]' ...\t";
	my $outfileBase = $tmp2[0];
	
	# Check the input file (either using CASRN or DSSTox_RID)
	my ($inputFileType, $originalInputIDListHashRef)	= load_input_file_type ($infile);
	my %inputIDListHash	= ();
	
	# Convert DSSTox_RID to CASRN
	if ($inputFileType eq 'DSSTox_RID')
	{	foreach my $inputID (keys %{$originalInputIDListHashRef})
		{	if ((defined $DSSTox2CASRN{$inputID}) && ($DSSTox2CASRN{$inputID} ne ""))
			{	$inputIDListHash{$DSSTox2CASRN{$inputID}}	= 1;
			}
		}
	}elsif ($inputFileType eq 'Unknown')
	{	die "!ERROR! Can't determine the input ID type of $infile ...\n\n";
	}else
	{	%inputIDListHash	= %{$originalInputIDListHashRef};
	}
	
	# Perform EASE calculation
	my @CASRNs	= keys %inputIDListHash;
	print STDERR ("Almost to the subroutine...");
	if (!perform_CASRN_enrichment_analysis(\@CASRNs, $outputBaseDir, $outfileBase))
	{	print STDERR "failure ...\n";
	}else
	{	print STDERR "success ...\n";
	}
}
print STDERR "\n";




print STDERR "! ----------------------------------------------------------------\n";
print STDERR "! CASRN enrichment analysis completed ... \n";
print STDERR "! ----------------------------------------------------------------\n";
#chomp(my $finalConfirm=<>);
exit;



sub perform_CASRN_enrichment_analysis
{	my $CASRNRef				= shift;
	my $outputBaseDir			= shift;
	my $outfileBase				= shift;
	print STDERR "Welcome to the subroutine!\n";

	# Define output file names
	my $outfileChart			= $outputBaseDir.$outfileBase.'__Chart.txt';
	my $outfileSimple			= $outputBaseDir.$outfileBase.'__ChartSimple.txt';
	my $outfileCluster			= $outputBaseDir.$outfileBase.'__Cluster.txt';
	print STDERR $outfileChart;

	open (OUTFILE, ">".$outfileChart) || print "";
	open (SIMPLE,  ">".$outfileSimple) || print "";
	open (CLUSTER,  ">".$outfileCluster) || print "";
	print OUTFILE "Category	Term	Count	%	PValue	CASRNs	List Total	Pop Hits	Pop Total	Fold Enrichment	Bonferroni	Benjamini	FDR\n";
	print SIMPLE "Category	Term	Count	%	PValue	Fold Enrichment	Benjamini\n";

	# Calculate EASE score
	my @inputCASRNs				= @{$CASRNRef};
	my $inputCASRNsCount		= scalar @inputCASRNs;
	my %term2Contents			= ();
	my %term2Pvalue				= ();
	my %sigTerm2CASRNMatrix		= ();
	my @mappedCASRNs			= @{check_mapped_CASRN(\@inputCASRNs)};		# Among the CASRN, use only those included in the full Tox21 list
	
	foreach my $funCat (keys %funCat2Selected)
	{	if ($funCat2Selected{$funCat})
		{	
			# Calculate the CASRN counts for the given categories
			my ($targetTotalCASRNInFunCatCount, $targetTotalTermCount)	= calculate_funcat_mapped_total_CASRN_count (\@mappedCASRNs, $funCat);
			
			my @funCatTerms	= keys %{$funCatTerm2CASRN{$funCat}};
			my %localTerm2content	= ();
			my %localTerm2pvalue	= ();
			my %localPvalue2term	= ();
			foreach my $term (@funCatTerms)
			{	if (defined $funCatTerm2CASRN{$funCat}->{$term})
				{	
					# This is a valid term, check if the CASRN count is more than 1
					my ($targetCASRNsRef, $targetCASRNCount)	= calculate_funcat_mapped_CASRN_count (\@mappedCASRNs, $funCat, $term, \%sigTerm2CASRNMatrix);
					if ($targetCASRNCount > 1)
					{	# Calculate the EASE score
						my $np1 = $targetTotalCASRNInFunCatCount -1;   
						my $n11	= $targetCASRNCount - 1;
						my $npp = $funCat2CASRNCount{$funCat};              
						my $n1p = $funCatTerm2CASRNCount{$funCat}{$term}; 
						
						# skip any under-represented terms
						my $foldenrichment = ($targetCASRNCount/$targetTotalCASRNInFunCatCount)/($n1p/$npp);
													
						my $pvalue = 1;
						$pvalue = calculateStatistic (	n11 => $n11,
														n1p => $n1p,
														np1 => $np1,
														npp => $npp);	

						$localTerm2content{$term} =	$funCat."\t".
													$term."\t".
													$targetCASRNCount."\t".
													($targetCASRNCount/$inputCASRNsCount*100)."\t".
													$pvalue."\t".
													join(", ", @{$targetCASRNsRef})."\t".
													$targetTotalCASRNInFunCatCount."\t".
													$n1p."\t".
													$npp."\t".
													($targetCASRNCount/$targetTotalCASRNInFunCatCount)/($n1p/$npp)."\t".
													(1-(1-$pvalue)**$targetTotalTermCount);
						$localTerm2pvalue{$term} = $pvalue; 
						$localPvalue2term{$pvalue}->{$term} = 1;
					}
				}
			}
			
			# Calculate Benjamini-Hochberg corrected p-value (EASE)
			my @collectedPvalues	= sort {$a <=> $b} keys %localPvalue2term;
			my %pvalue2BHPvalue		= ();
			my $rank				= 1;

			foreach my $pvalue (@collectedPvalues)
			{	$pvalue2BHPvalue{$pvalue} = $pvalue * $targetTotalTermCount / $rank;
				if ($pvalue2BHPvalue{$pvalue} >1)
				{	$pvalue2BHPvalue{$pvalue} = 1;
				}
				$rank++;
			}

			foreach my $term (keys %localTerm2pvalue)
			{	$term2Contents{$funCat.'|'.$term}	= $localTerm2content{$term}."\t".$pvalue2BHPvalue{$localTerm2pvalue{$term}}.
											"\t".$pvalue2BHPvalue{$localTerm2pvalue{$term}};
				$term2Pvalue{$funCat.'|'.$term}		= $localTerm2pvalue{$term};
			}	
		}
	}


	# Sort by the p-values across multiple funCat
	my @sortedFunCatTerms		= sort {$term2Pvalue{$a} <=> $term2Pvalue{$b}} keys %term2Pvalue;
	my $sortedFunCatTermsCount	= scalar @sortedFunCatTerms;
	my %simpleFunCatTermCount	= ();
	my %funCatSimpleContent		= ();
	foreach my $funCatTerm (@sortedFunCatTerms)
	{	if ($term2Pvalue{$funCatTerm} > $pvalueThresholdToDisplay)
		{	next;
		}
		
		print OUTFILE $term2Contents{$funCatTerm}."\n";
		
		my $toSimple = 0;
		my @tmpSplit = split (/\t/, $term2Contents{$funCatTerm});
		if ($tmpSplit[9] > 1)
		{	my $localFunCat		= get_funCat_from_funCatTerm ($funCatTerm);
			if (not defined $simpleFunCatTermCount{$localFunCat})
			{	$simpleFunCatTermCount{$localFunCat} = 1;
				$toSimple = 1;
			}elsif ($simpleFunCatTermCount{$localFunCat} < 10)
			{	$simpleFunCatTermCount{$localFunCat}++;
				$toSimple = 1;
			}

			if ($toSimple)
			{	$funCatSimpleContent{$localFunCat} .= $tmpSplit[0]."\t".$tmpSplit[1]."\t".
					$tmpSplit[2]."\t".$tmpSplit[3]."\t".$tmpSplit[4]."\t".$tmpSplit[9]."\t".$tmpSplit[11]."\n";
			}
		}
	}

	foreach my $funCat (keys %funCatSimpleContent)
	{	print SIMPLE $funCatSimpleContent{$funCat}."\n";
	}
	close OUTFILE;	close SIMPLE;
	







	# ----------------------------------------------------------------------
	#	Perform functional term clustering
	# ----------------------------------------------------------------------
	# 	Step#1: Calculate kappa score
	# ----------------------------------------------------------------------
	my %mappedCASRNCheck	= ();
	my @mappedCASRNIDs		= ();
	my %posTermCASRNCount	= ();
	foreach my $funCatTerm (@sortedFunCatTerms)
	{	my @localCASRNIDs	= keys %{$sigTerm2CASRNMatrix{$funCatTerm}};
		$posTermCASRNCount{$funCatTerm}	= scalar @localCASRNIDs;
		
		foreach my $CASRNID (@localCASRNIDs)
		{	$mappedCASRNCheck{$CASRNID} = 1;
		}
	}	
	
	@mappedCASRNIDs				= keys %mappedCASRNCheck;
	my $totalMappedCASRNIDCount	= scalar @mappedCASRNIDs;
	
	# Calculate kappa score for each term pair
	my %termpair2kappa						= ();
	my %termpair2kappaOverThresholdCount	= ();
	my %termpair2kappaOverThreshold			= ();
	for (my $i=0; $i < $sortedFunCatTermsCount-1; $i++)
	{	for (my $j=$i+1; $j < $sortedFunCatTermsCount; $j++)
		{	#calculate_kappa_statistics (
			my $term1term2			= 0;
			my $term1only			= 0;
			my $term2only			= 0;
			my $term1term2Non		= 0;

			my $posTerm1Total		= $posTermCASRNCount{$sortedFunCatTerms[$i]};
			my $posTerm2Total		= $posTermCASRNCount{$sortedFunCatTerms[$j]};
			my $negTerm1Total		= $inputCASRNsCount - $posTerm1Total;			# note that the total is inputCASRNsCount not the mapped total
			my $negTerm2Total		= $inputCASRNsCount - $posTerm2Total;			# note that the total is inputCASRNsCount not the mapped total
			#my $negTerm1Total		= $totalMappedCASRNIDCount - $posTerm1Total;	
			#my $negTerm2Total		= $totalMappedCASRNIDCount - $posTerm2Total;
			
			foreach my $CASRN1 (keys %{$sigTerm2CASRNMatrix{$sortedFunCatTerms[$i]}})
			{	if (defined $sigTerm2CASRNMatrix{$sortedFunCatTerms[$j]}->{$CASRN1})
				{	$term1term2++;
				}else
				{	$term1only++;
				}
			}
			foreach my $CASRN2 (keys %{$sigTerm2CASRNMatrix{$sortedFunCatTerms[$j]}})
			{	if (not defined $sigTerm2CASRNMatrix{$sortedFunCatTerms[$i]}->{$CASRN2})
				{	$term2only++;
				}
			}
			$term1term2Non			= $inputCASRNsCount - $term1term2 - $term1only - $term2only;
			#$term1term2Non			= $totalMappedCASRNIDCount - $term1term2 - $term1only - $term2only;

			# Calculate the kappa score 
			# http://david.abcc.ncifcrf.gov/content.jsp?file=linear_search.html
			my $Oab					= ($term1term2 + $term1term2Non)/$inputCASRNsCount;
			my $Aab					= ($posTerm1Total*$posTerm2Total + $negTerm1Total*$negTerm2Total)/($inputCASRNsCount*$inputCASRNsCount);
			#my $Oab					= ($term1term2 + $term1term2Non)/$totalMappedCASRNIDCount;
			#my $Aab					= ($posTerm1Total*$posTerm2Total + $negTerm1Total*$negTerm2Total)/($totalMappedCASRNIDCount*$totalMappedCASRNIDCount);
			
			if ($Aab ==1)
			{	next;
			}
			my $Kappa				= sprintf("%.2f",($Oab - $Aab)/(1-$Aab));
		
			$termpair2kappa{$sortedFunCatTerms[$i]}->{$sortedFunCatTerms[$j]} = $Kappa;
			$termpair2kappa{$sortedFunCatTerms[$j]}->{$sortedFunCatTerms[$i]} = $Kappa;
			
			if ($Kappa > $similarityThreshold)
			{	$termpair2kappaOverThresholdCount{$sortedFunCatTerms[$i]}++;
				$termpair2kappaOverThresholdCount{$sortedFunCatTerms[$j]}++;
				$termpair2kappaOverThreshold{$sortedFunCatTerms[$i]}->{$sortedFunCatTerms[$j]} = 1;
				$termpair2kappaOverThreshold{$sortedFunCatTerms[$j]}->{$sortedFunCatTerms[$i]} = 1;
			}
			
			#print $sortedTerms[$i]."\t".$sortedTerms[$j]."\t".$term1term2."\t".$term1only."\t".$term2only."\t".$term1term2Non."\t".$posTerm1Total."\t".$posTerm2Total."\t".$negTerm1Total."\t".$negTerm2Total."\t".$Oab."\t".$Aab."\t".$Kappa."\n";
		}
	}
	
	
	
	# ----------------------------------------------------------------------
	# 	Step#2: Create qualified initial seeding groups
	# ----------------------------------------------------------------------
	#	Each term could form a initial seeding group (initial seeds) 
	#   as long as it has close relatioships (kappa > 0.35 or any designated number) 
	#   with more than > 2 or any designated number of other members. 
	
	my @qualifiedSeeds	= ();
	for (my $i=0; $i < $sortedFunCatTermsCount; $i++)
	{	# Seed condition#1: intial group membership
		if ((defined $termpair2kappaOverThresholdCount{$sortedFunCatTerms[$i]}) && ($termpair2kappaOverThresholdCount{$sortedFunCatTerms[$i]} >= ($initialGroupMembership-1)))
		{	# Seed condition#2: majority of the members 
			my ($over_percentage, $term2sRef) = calculate_percentage_of_membership_over_threshold (\%termpair2kappaOverThreshold, $sortedFunCatTerms[$i]);
			
			if ($over_percentage > $multipleLingkageThreshold)
			{	# this seed group is quialified
				push @qualifiedSeeds, $term2sRef;
			}
		}
	}
	
	
	# ----------------------------------------------------------------------
	# 	Step#3: Iteratively merge qualifying seeds
	# ----------------------------------------------------------------------
	my @finalGroups	= ();
	my @remainingSeeds	= @qualifiedSeeds;
	
	while(defined $remainingSeeds[0])
	{	# take the first two of the remaining seeds
		my $currentSeedRef		= shift @remainingSeeds;
		my @newSeeds			= ();
		while(get_the_best_seed ($currentSeedRef, \@remainingSeeds, \@newSeeds))
		{	# update the current reference seed ref with new seeds
			$currentSeedRef = \@newSeeds;
		}
		
		# if there in more merge possible, add the current seeds to the final groups
		push @finalGroups, $currentSeedRef;
	}


	# ----------------------------------------------------------------------
	# 	Step#4: Calculate enrichment score and print out the results
	# ----------------------------------------------------------------------
	my $clusterHeader = "Category	Term	Count	%	PValue	CASRNs	List Total	Pop Hits	Pop Total	Fold Enrichment	Bonferroni	Benjamini	FDR\n";
	my %EASEScore	= ();
	for (my $i=0; $i <= $#finalGroups; $i++)
	{	$EASEScore{$i} = calculate_Enrichment_Score ($finalGroups[$i], \%term2Pvalue);
	}
	my @sortedIndex = sort {$EASEScore{$b} <=> $EASEScore{$a}} keys %EASEScore;
	my $clusterNumber	= 1;
	foreach my $myIndex (@sortedIndex)
	{	print CLUSTER "Annotation Cluster ".($clusterNumber++)."\t"."Enrichment Score: ".$EASEScore{$myIndex}."\n";
		print CLUSTER $clusterHeader;
		
		# sort terms again by p-value
		my @sortedFunCatTerms	= sort {$term2Pvalue{$a} <=> $term2Pvalue{$b}} @{$finalGroups[$myIndex]};
		foreach my $myTerm (@sortedFunCatTerms)
		{	print CLUSTER $term2Contents{$myTerm}."\n";
		}	print CLUSTER "\n";
	}


	close CLUSTER;
	return (1);
}





sub get_funCat_from_funCatTerm
{	my $funCatTerm	= shift;
	my @tmpSplit = split (/\|/, $funCatTerm);
	return($tmpSplit[0]);
}


sub calculate_Enrichment_Score
{	my $groupRef		= shift;
	my $term2PvalueRef	= shift;
	
	my $EASESum			= 0;
	foreach my $term (@{$groupRef})
	{	if ($$term2PvalueRef{$term} == 0)
		{	$EASESum		+= 16;			# 
		}else
		{	$EASESum		+= -log($$term2PvalueRef{$term})/log(10);
		}
	}
	my $enrichmentScore = $EASESum / scalar (@{$groupRef});
}


sub get_the_best_seed 
{	my $currentSeedRef			= shift;
	my $remainingSeedsRef		= shift;
	my $newSeedRef				= shift;
	
	my $bestOverlapping			= 0;
	my $bestSeedIndex			= '';
	my @currentSeedTerms		= @{$currentSeedRef};
	my $currentSeedTermCount	= scalar @currentSeedTerms;
	my %currentSeedTermHash		= ();
	foreach my $term (@currentSeedTerms)
	{	$currentSeedTermHash{$term} = 1;
	}
	
	for (my $i=0; $i < $#$remainingSeedsRef; $i++)
	{	# calculate the overlapping
		my @secondSeedTerms	= @{$$remainingSeedsRef[$i]};
		my $commonCount		= 0;
		my $totalCount		= scalar @secondSeedTerms;
		
		foreach my $term (@secondSeedTerms)
		{	if (defined $currentSeedTermHash{$term})
			{	$commonCount++;
			}
		}
		
		my $overlapping	= 2*$commonCount / ($currentSeedTermCount + $totalCount);
		#my $overlapping	= $commonCount / ($currentSeedTermCount + $totalCount - $commonCount);
		# !CHECK! '>' or '>='
		#if ($overlapping >= $multipleLingkageThreshold)
		if ($overlapping > $multipleLingkageThreshold)
		{	if ($bestOverlapping < $overlapping)
			{	$bestOverlapping 	= $overlapping;
				$bestSeedIndex		= $i;
			}
		}
	}

	if ($bestOverlapping == 0)
	{	# no more merging is possible
		return (0);
	}else
	{	# best mergable seed found
		my %newSeedTermsHash = ();
		foreach my $term (@currentSeedTerms)
		{	$newSeedTermsHash{$term} = 1;
		}
		foreach my $term (@{$$remainingSeedsRef[$bestSeedIndex]})
		{	$newSeedTermsHash{$term} = 1;
		}
		
		@{$newSeedRef}		= keys %newSeedTermsHash;
		splice(@{$remainingSeedsRef}, $bestSeedIndex, 1);
		return (1);
	}
}


sub calculate_percentage_of_membership_over_threshold
{	my $termpair2kappaOverThresholdRef		= shift;
	my $currentTerm							= shift;
	
	my @term2s	= keys %{$$termpair2kappaOverThresholdRef{$currentTerm}};
	unshift @term2s, $currentTerm;
	
	# calculate 
	my $totalPairs	= 0;
	my $passedPair	= 0;

	for (my $i=0; $i < $#term2s; $i++)
	{	for (my $j=$i+1; $j <= $#term2s; $j++)
		{	$totalPairs++;
			if (defined $$termpair2kappaOverThresholdRef{$term2s[$i]}->{$term2s[$j]})
			{	$passedPair++;
			}
		}
	}
	
	return($passedPair/$totalPairs, \@term2s);
}	


sub check_mapped_CASRN
{	my $CASRNsRef			= shift;
	my %mappedCASRNHash		= ();
	foreach my $CASRN (@{$CASRNsRef})
	{	if (defined $CASRN2DSSTox{$CASRN})
		{	$mappedCASRNHash{$CASRN} = 1;
		}
	}
	my @mappedCASRNs	= keys %mappedCASRNHash;
	return (\@mappedCASRNs);
}


sub calculate_funcat_mapped_total_CASRN_count
{	my $mappedCASRNsRef		= shift;
	my $funCat				= shift;

	my $totalCount			= 0;
	my %localTermHash		= ();
	foreach my $CASRN (@{$mappedCASRNsRef})
	{	if (defined $CASRN2funCatTerm{$CASRN}->{$funCat})
		{	$totalCount++;
			my @terms = keys %{$CASRN2funCatTerm{$CASRN}->{$funCat}};
			foreach my $term (@terms)
			{	$localTermHash{$term} = 1;
			}
		}
	}
	my @localTerms			= keys %localTermHash;
	return ($totalCount, scalar @localTerms);
}


sub calculate_funcat_mapped_CASRN_count
{	my $mappedCASRNsRef			= shift;
	my $funCat					= shift;
	my $term					= shift;
	my $sigTerm2CASRNMatrixRef	= shift;

	my $CASRNCount		= 0;
	my @targetCASRNs	= ();
	foreach my $CASRN (@{$mappedCASRNsRef})
	{	if (defined $funCatTerm2CASRN{$funCat}->{$term}->{$CASRN})
		{	$CASRNCount++;
			push @targetCASRNs, $CASRN;
			$$sigTerm2CASRNMatrixRef{$funCat."|".$term}->{$CASRN} = 1;
		}
	}
	return (\@targetCASRNs, $CASRNCount);
}


sub get_column_index
{	my $headerRef		= shift;
	my $term			= shift;
	my $status			= 0;
	
	my $pubchemIndex	= '';
	if ((not defined $term) || ($term eq ""))
	{	return ($status);
	}
	
	# Check exact match
	for (my $i=0; $i < scalar (@{$headerRef}); $i++)
	{	if ($$headerRef[$i] eq $term)
		{	return ($i);
		}
	}
	
	if (! $pubchemIndex)
	{	for (my $i=0; $i < scalar (@{$headerRef}); $i++)
		{	if ($$headerRef[$i] =~ /$term/i)
			{	return ($i);
			}
		}
	}
	return ($status);
}


sub load_input_file_type
{
	my $infile		= shift;
	my $fileType	= '';
	my %inputIDHash	= ();
	
	open (INFILE, $infile);
	my $line		= <INFILE>;
	$line 			=~ s/\r|\n//g;
	my @tmpSplit	= split (/\t/, $line);
	
	if (($tmpSplit[0] =~ /(\d{2,7}-\d\d-\d)/) || ($tmpSplit[0] =~ /NOCAS_\d+/))
	{	$fileType	= 'CASRN';
		$inputIDHash{$tmpSplit[0]}		= 1;
	}elsif ($tmpSplit[0] !~ /\D/)
	{	$fileType	= 'DSSTox_RID';
		$inputIDHash{$tmpSplit[0]}		= 1;
	}else
	{	$fileType	= 'Unknown';
	}
	
	if ($fileType ne "Unknown")
	{	while(<INFILE>)
		{	my $line		= $_;
			$line 			=~ s/\r|\n//g;
			my @tmpSplit	= split (/\t/, $line);
			$inputIDHash{$tmpSplit[0]}		= 1;
		}
	}
	close INFILE;
	return ($fileType, \%inputIDHash);
}


