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
#   	v2.2	: (09/29/2016) Script to use the database files
#	v2.3	: (04/25/2018) Use R for Fisher's exact test
#	v2.4	: (12/09/2020) Updated annotations
#						   Uses Postgres database instead of files	
#	v2.5	: (12/30/2021) Fixes problem where Bonferroni, Benjamini, and FDR values were not being calculated correctly					   
#-------------------------------------------------------------------------------

use strict;
use warnings;
use Text::NSP::Measures::2D::Fisher::right;
use Parallel::ForkManager;
use DBI;
use Time::Piece;
use Data::Dumper;

# Initialization - Identify which annotations are selected in the annoselectstr
our $annotationBaseDir		= "/home/hurlab/tox21enricher/src/main/perl/Annotation/";
our %funCat2Selected		= ();
if (defined $ARGV[2])
{	for (my $i=2; $i<=$#ARGV; $i++)
	{	if ($ARGV[$i] ne "")
		{	#print STDERR "\t > ".$ARGV[$i]."\n";
			my @tmpSplit = split (/=/, $ARGV[$i]);
			if ($tmpSplit[1] eq 'checked')
			{	$funCat2Selected{$tmpSplit[0]}	= 1;
			}else
			{	$funCat2Selected{$tmpSplit[0]}	= 0;
			}
		}
	}
}else
{	%funCat2Selected		= (	
								"ACTIVITY_CLASS"=> 1, 
								"ADVERSE_EFFECT"=> 1,
								"CTD_CHEM2DISEASE"=> 1,
								"CTD_CHEM2GENE_25"=> 1,
								"CTD_GOFAT_BIOPROCESS"=> 0,
								"CTD_GOSLIM_BIOPROCESS"=> 1,
								"CTD_PATHWAY"=> 1,
								"CTD_CHEMICALS_DISEASES"=> 1,
								"CTD_CHEMICALS_GENES"=> 1,
								"CTD_CHEMICALS_GOENRICH_CELLCOMP"=> 1,
								"CTD_CHEMICALS_GOENRICH_MOLFUNCT"=> 1,
								"CTD_CHEMICALS_PATHWAYS"=> 1,
								"DRUGBANK_CARRIERS"=> 1,
								"DRUGBANK_ENZYMES"=> 1,
								"DRUGBANK_TRANSPORTERS"=> 1,
								"DRUGBANK_ATC"=> 1,
								"DRUGBANK_ATC_CODE"=> 1,
								"DRUGBANK_TARGETS"=> 1,
								"HTS_ACTIVE"=> 1,
								"INDICATION"=> 1,
								"KNOWN_TOXICITY"=> 1,
								"LEADSCOPE_TOXICITY"=> 1,
								"MECH_LEVEL_1"=> 1,
								"MECH_LEVEL_2"=> 1,
								"MECH_LEVEL_3"=> 1,
								"MECHANISM"=> 1,
								"MESH"=> 1,
								"MODE_CLASS"=> 1,
								"MULTICASE_TOX_PREDICTION"=> 1,
								"PHARMACTIONLIST"=> 1,
								"PRODUCT_CLASS"=> 1,
								"STRUCTURE_ACTIVITY"=> 1,
								"TA_LEVEL_1"=> 1,
								"TA_LEVEL_2"=> 1,
								"TA_LEVEL_3"=> 1,
								"THERAPEUTIC_CLASS"=> 1,
								"TISSUE_TOXICITY"=> 1,
								"TOXCAST_ACTIVE"=> 1,
								"TOXINS_TARGETS"=> 1,
								"TOXPRINT_STRUCTURE"=> 1,
								"TOXREFDB"=> 1,
								"TISSUE_TOXICITY"=> 1
							
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
our $outputBaseDir          = $ARGV[1] . "/";     $outputBaseDir =~ s/\/\//\//g;
print STDERR "outputBaseDir is $outputBaseDir\n";

mkdir ($outputBaseDir) || print "";
print STDERR "! ----------------------------------------------------------------\n";
print STDERR "! CASRN enrichment analysis started ... \n";
print STDERR "! ----------------------------------------------------------------\n\n";
print STDERR "! Opening annotation file at: $annotationBaseDir/Tox21_CASRN_Names.anno\n";

my $time1 = time();

open (CHEMINFO, $annotationBaseDir."Tox21_CASRN_Names.anno") || die "!ERROR! can't open the base annotation file ...\n\n";
my $annoHeaderLine		= <CHEMINFO>;	$annoHeaderLine	=~ s/\r|\n//g;
my @headerSplit			= split (/\t/, $annoHeaderLine);

my $DSSToxIndex			= get_column_index (\@headerSplit, "#DSSTox_RID");
my $nameIndex			= get_column_index (\@headerSplit, "TestSubstance_ChemicalName");
my $CASRNIndex			= get_column_index (\@headerSplit, "TestSubstance_CASRN");

while(<CHEMINFO>)
{	my $line = $_;		$line =~ s/\r|\n//g;
	#print STDERR ">>> $line\n\n";
	my @tmpSplit = split (/\t/, $line);
	
	# Load annotation data
	if ((defined $tmpSplit[$nameIndex]) && ($tmpSplit[$nameIndex] ne ""))
	{	$DSSTox2name{$tmpSplit[$DSSToxIndex]}	= $tmpSplit[$nameIndex];
		#print STDERR ">>> ".$tmpSplit[$DSSToxIndex]."\t".$tmpSplit[$nameIndex];
	}else
	{	$DSSTox2name{$tmpSplit[$DSSToxIndex]}	= '';
	}
	
	if ((defined $tmpSplit[$CASRNIndex]) && ($tmpSplit[$CASRNIndex] ne ""))
	{	$DSSTox2CASRN{$tmpSplit[$DSSToxIndex]}	= $tmpSplit[$CASRNIndex];
		$CASRN2DSSTox{$tmpSplit[$CASRNIndex]}{$tmpSplit[$DSSToxIndex]} = 1;	
	}
}	close CHEMINFO;

my $time2 = time();
my $sum1 = $time2 - $time1;
print STDERR ">>>>> Loading Base Annotations: $sum1\n";


#-------------------------------------------------------------------------------
#   Load DrugMatrix Annotation
#-------------------------------------------------------------------------------
#my @drugMatrixFiles	= glob ("Annotation/DrugMatrix_*.txt");

#$pm->run_on_finish( sub {
#    my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;
#    my $q = $data_structure_reference->{input};
#    $results{$q} = $data_structure_reference->{result};
#});

# Initiate parallel processing
#my $cpuCores    			= 4;
#my $pm = Parallel::ForkManager->new($cpuCores);
#my %results;

# Connect to tox21enricher Postgres database and fetch data from 'annotation_detail'

my $time3 = time();

my $dbConnection = DBI->connect("DBI:Pg:dbname=tox21enricher;host=localhost","username","password");

# Get CASRNs and annotations
my $queryFullAnno = $dbConnection->prepare("SELECT chemical_detail.casrn, annotation_class.annoclassname, annotation_detail.annoterm FROM term2casrn_mapping INNER JOIN chemical_detail ON term2casrn_mapping.casrnuid_id=chemical_detail.casrnuid INNER JOIN annotation_detail ON term2casrn_mapping.annotermid=annotation_detail.annotermid INNER JOIN annotation_class ON term2casrn_mapping.annoclassid=annotation_class.annoclassid;");
$queryFullAnno->execute();
while(my $refFullAnno = $queryFullAnno->fetchrow_hashref()) {
	my $tmpCasrn = $refFullAnno->{'casrn'};
	my $tmpClass = $refFullAnno->{'annoclassname'};
	my $tmpTerm = $refFullAnno->{'annoterm'};
	$CASRN2funCatTerm{$tmpCasrn}->{$tmpClass}->{$tmpTerm} 	= 1;
	$funCatTerm2CASRN{$tmpClass}->{$tmpTerm}->{$tmpCasrn} 	= 1;
	$funCat2CASRN{$tmpClass}->{$tmpCasrn} 					= 1;
	$term2funCat{$tmpTerm}{$tmpClass} 						= 1;
}

print STDERR "--done getting annotations";

my $time4 = time();
my $sum2 = $time4 - $time3;
print STDERR "Get DrugMatrix Annotations: $sum2\n";
#$dbConnection->disconnect;

# Read through each annotation file
#foreach my $drugMatrixFile (@drugMatrixFiles)
#{	#my $pid = $pm->start and next;

#	open (DRUGMATRIX, $drugMatrixFile);
#	my @tmp1 = split (/\//, $drugMatrixFile);
#	my @tmp2 = split (/\.txt/, $tmp1[$#tmp1]);
#	substr($tmp2[0], 0, 11) = '';
	
#	if (!$funCat2Selected{$tmp2[0]})
#	{	close DRUGMATRIX;
#		next;
		#$pm->finish(0, { result => "test", input => $drugMatrixFile });
		#$pm->finish;
#	}
	
#	while(<DRUGMATRIX>)
#	{	my $line = $_;
#		#print STDERR "........... $line";
#		$line =~ s/\r|\n//g;
#		my @tmpSplit = split (/\t/, $line);
#		if (not defined $tmpSplit[1]) {
#			next;
#		}
#		my @termSplit = split (/\; /, $tmpSplit[1]);
#		
#		foreach my $term (@termSplit)
#		{	
			#print STDERR "term:\t$term\n";
			#print STDERR "tmpSplit[0]:\t".$tmpSplit[0]."\n";
			#print STDERR "tmp2[0]\t".$tmp2[0]."\n";
			
			
#			$CASRN2funCatTerm{$tmpSplit[0]}->{$tmp2[0]}->{$term} 	= 1;
#			$funCatTerm2CASRN{$tmp2[0]}->{$term}->{$tmpSplit[0]} 	= 1;
#			$funCat2CASRN{$tmp2[0]}->{$tmpSplit[0]} 				= 1;
#			$term2funCat{$term}{$tmp2[0]} 							= 1;
#		}
#	}	
#	close DRUGMATRIX;

	#$pm->finish(0, { result => "test", input => $drugMatrixFile });
	#$pm->finish;
#}
#$pm->wait_all_children;



# Calculate total CASRN count
foreach my $funCat (keys %funCat2Selected)
{	if (!$funCat2Selected{$funCat})
	{	next;
	}
	
	my @tmpArray = keys %{$funCat2CASRN{$funCat}};
	$funCat2CASRNCount{$funCat} = scalar @tmpArray;
	#print STDERR "=== funCat2CASRNCount ===\n";
	#print STDERR "\t".$funCat2CASRNCount{$funCat}."\n";
	
	my @terms = keys %{$funCatTerm2CASRN{$funCat}};
	$funCat2termCount{$funCat} 	= scalar @terms;
	#print STDERR "=== funCat2termCount ===\n";
	#print STDERR "\t".$funCat2termCount{$funCat}."\n";
	
	foreach my $term (@terms)
	{	my @tmpArray = keys %{$funCatTerm2CASRN{$funCat}->{$term}};
		$funCatTerm2CASRNCount{$funCat}{$term} = scalar @tmpArray;
		#print $funCatTerm2CASRNCount{$funCat}{$term}."\n";
		#print STDERR "=== funCatTerm2CASRNCount ===\n";
		#print STDERR "\t".$funCatTerm2CASRNCount{$funCat}{$term}."\n";
	}
}


#-------------------------------------------------------------------------------
#   Load input DSSTox ID or CASRN ID sets
#-------------------------------------------------------------------------------
# Initiate parallel processing
my $cpuCores = 4;
my $pm = Parallel::ForkManager->new($cpuCores);

my @infiles			= glob ($inputBaseDir."/*.txt");

ENRICH_SET:
foreach my $infile (@infiles)
{	$pm->start and next ENRICH_SET;

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
	if (!perform_CASRN_enrichment_analysis(\@CASRNs, $outputBaseDir, $outfileBase))
	{	print STDERR "failure ...\n";
	}else
	{	print STDERR "success ...\n";
	}
	$pm->finish;
}
$pm->wait_all_children;
print STDERR "\n";




print STDERR "! ----------------------------------------------------------------\n";
print STDERR "! CASRN enrichment analysis completed ... \n";
print STDERR "! ----------------------------------------------------------------\n";
#chomp(my $finalConfirm=<>);
exit;



sub perform_CASRN_enrichment_analysis
{	my $time5 = time();
	my $CASRNRef				= shift;
	my $outputBaseDir			= shift;
	my $outfileBase				= shift;

	# Define output file names
	my $outfileChart			= $outputBaseDir.$outfileBase.'__Chart.txt';
	my $outfileSimple			= $outputBaseDir.$outfileBase.'__ChartSimple.txt';
	my $outfileCluster			= $outputBaseDir.$outfileBase.'__Cluster.txt';
	my $outfileMatrix			= $outputBaseDir.$outfileBase.'__Matrix.txt';
	
	open (OUTFILE, ">".$outfileChart) || print "";
	open (SIMPLE,  ">".$outfileSimple) || print "";
	open (CLUSTER,  ">".$outfileCluster) || print "";
	open (MATRIX,  ">".$outfileMatrix) 	|| print "";
	print OUTFILE "Category	Term	Count	%	PValue	CASRNs	List Total	Pop Hits	Pop Total	Fold Enrichment	Bonferroni	Benjamini	FDR\n";
	print SIMPLE "Category	Term	Count	%	PValue	Fold Enrichment	Benjamini\n";

	# Calculate EASE score
	my @inputCASRNs				= @{$CASRNRef};
	my $inputCASRNsCount		= scalar @inputCASRNs;
	my %term2Contents			= ();
	my %term2Pvalue				= ();
	my %sigTerm2CASRNMatrix		= ();
	my @mappedCASRNs			= @{check_mapped_CASRN(\@inputCASRNs)};		# Among the CASRN, use only those included in the full Tox21 list

	# foreach my $funCat (keys %funCat2Selected)
	# {	if ($funCat2Selected{$funCat})
		# {	# Calculate the CASRN counts for the given categories
			# my ($targetTotalCASRNInFunCatCount, $targetTotalTermCount)	= calculate_funcat_mapped_total_CASRN_count (\@mappedCASRNs, $funCat);
			
			# my @funCatTerms	= keys %{$funCatTerm2CASRN{$funCat}};
			# my %localTerm2content	= ();
			# my %localTerm2pvalue	= ();
			# my %localPvalue2term	= ();
			# foreach my $term (@funCatTerms)
			# {	if (defined $funCatTerm2CASRN{$funCat}->{$term})
				# {	
					# # This is a valid term, check if the CASRN count is more than 1
					# my ($targetCASRNsRef, $targetCASRNCount)	= calculate_funcat_mapped_CASRN_count (\@mappedCASRNs, $funCat, $term, \%sigTerm2CASRNMatrix);
					# if ($targetCASRNCount > 1)
					# {	# Calculate the EASE score
						# my $np1 = $targetTotalCASRNInFunCatCount -1;   
						# my $n11	= $targetCASRNCount - 1;
						# my $npp = $funCat2CASRNCount{$funCat};              
						# my $n1p = $funCatTerm2CASRNCount{$funCat}{$term}; 
						
						# # skip any under-represented terms
						# my $foldenrichment = ($targetCASRNCount/$targetTotalCASRNInFunCatCount)/($n1p/$npp);
													
						# my $pvalue = 1;
						# $pvalue = calculateStatistic (	n11 => $n11,
														# n1p => $n1p,
														# np1 => $np1,
														# npp => $npp);	

						# $localTerm2content{$term} =	$funCat."\t".
													# $term."\t".
													# $targetCASRNCount."\t".
													# ($targetCASRNCount/$inputCASRNsCount*100)."\t".
													# $pvalue."\t".
													# join(", ", @{$targetCASRNsRef})."\t".
													# $targetTotalCASRNInFunCatCount."\t".
													# $n1p."\t".
													# $npp."\t".
													# ($targetCASRNCount/$targetTotalCASRNInFunCatCount)/($n1p/$npp)."\t".
													# (1-(1-$pvalue)**$targetTotalTermCount);
						# $localTerm2pvalue{$term} = $pvalue; 
						# $localPvalue2term{$pvalue}->{$term} = 1;
					# }
				# }
			# }
			
			# # Calculate Benjamini-Hochberg corrected p-value (EASE)
			# my @collectedPvalues	= sort {$a <=> $b} keys %localPvalue2term;
			# my %pvalue2BHPvalue		= ();
			# my $rank				= 1;

			# foreach my $pvalue (@collectedPvalues)
			# {	$pvalue2BHPvalue{$pvalue} = $pvalue * $targetTotalTermCount / $rank;
				# if ($pvalue2BHPvalue{$pvalue} >1)
				# {	$pvalue2BHPvalue{$pvalue} = 1;
				# }
				# $rank++;
			# }

			# foreach my $term (keys %localTerm2pvalue)
			# {	$term2Contents{$funCat.'|'.$term}	= $localTerm2content{$term}."\t".$pvalue2BHPvalue{$localTerm2pvalue{$term}}.
											# "\t".$pvalue2BHPvalue{$localTerm2pvalue{$term}};
				# $term2Pvalue{$funCat.'|'.$term}		= $localTerm2pvalue{$term};
				
			# }	
		# }
	# }

	
	
	# Create two files: (1) input for R; (2) R command script
	
	my $tempRInputFileFull	= $outputBaseDir.$outfileBase.'__RInput.txt';
	my $tempROutputFileFull	= $outputBaseDir.$outfileBase.'__ROutput.txt';
	my $tempRCMDFileFull	= $outputBaseDir.$outfileBase.'__RCMD.R';
	# my $tempRInputFile		= $outfileBase.'__RInput.txt';
	# my $tempROutputFile		= $outfileBase.'__ROutput.txt';
	# my $tempRCMDFile		= $outfileBase.'__RCMD.R';
	
	open (RINPUT, ">".$tempRInputFileFull);
	open (RCMD, ">".$tempRCMDFileFull);
	
	
	my @datArray	= ();
	my @annoArray	= ();

	my $howmanytimes = 0;

	foreach my $funCat (keys %funCat2Selected)
	{	if ($funCat2Selected{$funCat})
		{	# Calculate the CASRN counts for the given categories
			my ($targetTotalCASRNInFunCatCount, $targetTotalTermCount)	= calculate_funcat_mapped_total_CASRN_count (\@mappedCASRNs, $funCat);
			my @funCatTerms	= keys %{$funCatTerm2CASRN{$funCat}};
			my %localTerm2content	= ();
			my %localTerm2pvalue	= ();
			my %localPvalue2term	= ();
			foreach my $term (@funCatTerms)
			{	
				if (defined $funCatTerm2CASRN{$funCat}->{$term})
				{	
					# This is a valid term, check if the CASRN count is more than 1
					my ($targetCASRNsRef, $targetCASRNCount)	= calculate_funcat_mapped_CASRN_count (\@mappedCASRNs, $funCat, $term, \%sigTerm2CASRNMatrix);
					$howmanytimes++;
					if ($targetCASRNCount > 1)
					{	# Calculate the EASE score
						my $np1 = $targetTotalCASRNInFunCatCount -1;   
						my $n11	= $targetCASRNCount - 1;
						my $npp = $funCat2CASRNCount{$funCat};              
						my $n1p = $funCatTerm2CASRNCount{$funCat}{$term}; 

						#print STDERR "targetCASRNCount: $targetCASRNCount\n";
						#print STDERR "> $funCat|$term\tnp1: $np1\tn11: $n11\tnpp: $npp\tn1p: $n1p\n";
						
						# skip any under-represented terms
						my $foldenrichment = ($targetCASRNCount/$targetTotalCASRNInFunCatCount)/($n1p/$npp);
													
						my $pvalue = 1;
						#$pvalue = calculateStatistic (	n11 => $n11,
						#								n1p => $n1p,
						#								np1 => $np1,
						#								npp => $npp);	

						my @datArrayLine	= ($n11, ($n1p-$n11), ($np1-$n11), ($npp-$n1p-$np1+$n11));
						my @annoArrayLine	= ($funCat, $term, $targetCASRNCount, ($targetCASRNCount/$inputCASRNsCount*100),
											1, join(", ", @{$targetCASRNsRef}), $targetTotalCASRNInFunCatCount, 
											$n1p, $npp, ($targetCASRNCount/$targetTotalCASRNInFunCatCount)/($n1p/$npp));

						push @datArray, \@datArrayLine;
						push @annoArray, \@annoArrayLine;
						
						#print STDERR "datArray\n";
						#print STDERR Dumper(@datArrayLine)."\n";
						#print STDERR "annoArray\n";
						#print STDERR Dumper(@annoArrayLine)."\n";

					}
				}
			}
		}
	}

	#print STDERR "datArray\n";
	#print STDERR Dumper(@datArray)."\n";
	#print STDERR "HOW MANY ITERATIONS: $howmanytimes\n";

	# Save the data file
	foreach my $arrayRef (@datArray) {
		print RINPUT join("\t", @{$arrayRef})."\n";
	}	close RINPUT;
	
	
	my $time6 = time();
	my $sum3 = $time6 - $time5;	
	print STDERR "Calculate ease score: $sum3\n";
	
	my $time7 = time();
	
	# create a R command file
	print RCMD "
	
data = read.table (file=\"$tempRInputFileFull\", sep=\"\\t\", header=FALSE)
p.value = apply(data, 1, function(x) {
  fisher.test (matrix(unlist(x), nrow=2))\$p.value
})
write.table (data.frame(p.value, bonferroni=p.adjust(p.value, method='bonferroni'), by=p.adjust(p.value, method='BY'), fdr=p.adjust(p.value, method='fdr')), file=\"$tempROutputFileFull\", sep=\"\\t\", row.names=FALSE, col.names=FALSE, quote=FALSE)
";
	close RCMD;
	
	
	# Run R command File
    `R --no-save --quiet < $tempRCMDFileFull`; 
	
	# Load the output file 
	open (ROUTPUT, $tempROutputFileFull);
	
	my @ROutputData = ();
	while(<ROUTPUT>) {
		my $line = $_;	 $line =~ s/\r|\n//g;
		if ($line ne "") {
			#print STDERR ">>>>>>>>> $line\n";
			my @ROutputLineSplit = split (/\t/, $line);
			push @ROutputData, \@ROutputLineSplit;
		}
	}	close ROUTPUT;

	#print STDERR Dumper(@ROutputData)."\n";
	
	# Remote three temporary R-related files
	# ToDo: Once the script is deemed to be stable, remove '#'s 
	
	unlink ($tempRInputFileFull);
	unlink ($tempROutputFileFull);
	unlink ($tempRCMDFileFull);
	
	
	# Integrate ROutput into the main hashes/arrays
	# ToDo: Error checking/handling for the case the number of lines are different between 
	#             @annoArray and @ROutputData
	
	for (my $i=0; $i <= $#annoArray; $i++) {
		# update the p-value
		$annoArray[$i][4] = $ROutputData[$i][0];
	
		# print $annoArray[$i][0]."\t".$annoArray[$i][1]."\t".$annoArray[$i][2]."\t".
				# $annoArray[$i][3]."\t".$annoArray[$i][4]."\n";
				
				# exit;
		# add bonferroni, benjamini, FDR to the array
		push @{$annoArray[$i]}, $ROutputData[$i][1], $ROutputData[$i][2], $ROutputData[$i][3];
		
		# finalize the hashes
		$term2Contents{$annoArray[$i][0].'|'.$annoArray[$i][1]}	= join("\t", @{$annoArray[$i]});
		$term2Pvalue{$annoArray[$i][0].'|'.$annoArray[$i][1]}	= $ROutputData[$i][0];
	}
	
	my $time8 = time();
	my $sum4 = $time8 - $time7;	
	print STDERR "R script: $sum4\n";
	
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

	foreach my $thing (%sigTerm2CASRNMatrix) {
		#print STDERR ">>>>>>> $thing\n";
	}
	
	# Print out the matrix file
	my @sortedHeaderTerms 	= sort keys %sigTerm2CASRNMatrix;
	my $matrixHeader 		= join ("\t", @sortedHeaderTerms);
	my $matrixOutput		= "CASRN\t".$matrixHeader."\n";
	foreach my $tmpCasrn (@mappedCASRNs)
	{	$matrixOutput		.= $tmpCasrn;
		foreach my $tmpMatrixHeader (@sortedHeaderTerms)
		{	if (defined $sigTerm2CASRNMatrix{$tmpMatrixHeader}{$tmpCasrn})
			{	$matrixOutput	.= "\t1";
			}else
			{	$matrixOutput	.= "\t0";
			}
		}	$matrixOutput	.= "\n";
	}	
	print MATRIX $matrixOutput;	close MATRIX;







	# ----------------------------------------------------------------------
	#	Perform functional term clustering
	# ----------------------------------------------------------------------
	# 	Step#1: Calculate kappa score
	# ----------------------------------------------------------------------

	my $time9 = time();

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
	
	my $time10 = time();
	my $sum5 = $time10 - $time9;	
	print STDERR "Kappa score: $sum5\n";
	
	# ----------------------------------------------------------------------
	# 	Step#2: Create qualified initial seeding groups
	# ----------------------------------------------------------------------
	#	Each term could form a initial seeding group (initial seeds) 
	#   as long as it has close relatioships (kappa > 0.35 or any designated number) 
	#   with more than > 2 or any designated number of other members. 

	my $time11 = time();
	
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
	
	my $time12 = time();
	my $sum6 = $time12 - $time11;	
	print STDERR "Create qualified initial seeding groups: $sum6\n";

	# ----------------------------------------------------------------------
	# 	Step#3: Iteratively merge qualifying seeds
	# ----------------------------------------------------------------------

	my $time13 = time();

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

	my $time14 = time();
	my $sum7 = $time14 - $time13;	
	print STDERR "Iteratively merge qualifying seeds: $sum7\n";

	# ----------------------------------------------------------------------
	# 	Step#4: Calculate enrichment score and print out the results
	# ----------------------------------------------------------------------

	my $time15 = time();

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

	my $time16 = time();
	my $sum8 = $time16 - $time15;	
	print STDERR "Calculate enrichment score: $sum8\n";

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
	{	print STDERR ")) THIS CASRN: $CASRN\n";
		if (defined $CASRN2funCatTerm{$CASRN}->{$funCat})
		{	$totalCount++;
			my @terms = keys %{$CASRN2funCatTerm{$CASRN}->{$funCat}};
			foreach my $term (@terms)
			{	$localTermHash{$term} = 1;
			}
		}
	}
	print STDERR "TOTALCOUNT:\t$totalCount\n";
	
	my @localTerms			= keys %localTermHash;
	print STDERR "LOCALTERMS\t".Dumper(@localTerms)."\n";
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
	{	#print STDERR "CHECKING:: ".$funCatTerm2CASRN{$funCat}->{$term}->{$CASRN}."\n";
		if (defined $funCatTerm2CASRN{$funCat}->{$term}->{$CASRN})
		{	$CASRNCount++;
			push @targetCASRNs, $CASRN;
			$$sigTerm2CASRNMatrixRef{$funCat."|".$term}->{$CASRN} = 1;
		}
	}
	if ($CASRNCount > 0){ 
		#print STDERR ">> CASRNCount for $funCat | $term:\t$CASRNCount <<\n";
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


