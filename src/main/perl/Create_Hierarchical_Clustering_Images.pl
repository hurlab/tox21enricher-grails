#!/usr/bin/perl -w
# --------------------------------------------------------------------
#
#	Automatic_Hierarchical_Clustering.pl
#
# --------------------------------------------------------------------
# This script will perform hierarchical clustering based on the 
# given parameters (pre-defined in the script)
# --------------------------------------------------------------------
#
# v2.	* this version now process any sub-directories as well
#		* can specify if column/row clustering is used or not
# --------------------------------------------------------------------


use warnings;
use strict;
use Cwd 'abs_path';     # aka realpath()
use Config;
use File::Copy;


#my $abspath = abs_path($ENV{'PWD'}).'/';

#print "!!!!!!!!".$abspath."<BR>\n";
if (not defined $ARGV[0])
{	die "\n!ERROR: Missing directory\n".
		">ThisScript.pl <Summarized DAVID Result directory containg .gct files> -f=[output format] [-rdm=0] [-cdm=0]\n\n";
}



# --------------------------------------
# Define required variables - Clustering
# --------------------------------------
our $dirName					= $ARGV[0];
$dirName						=~ s/\\/\//g;
my @dirNameSplit				= split (/\//, $dirName);
my $dirTypeTag					= '';
if ($dirNameSplit[0] =~ /CLUSTER/i)
{	$dirTypeTag					= 'CLUSTER__';
}elsif ($dirNameSplit[0] =~ /CHART/i)
{	$dirTypeTag					= 'CHART__';
}elsif ($dirNameSplit[0] =~ /PRESELECTED/i)
{	$dirTypeTag					= 'PRESELECTED__';
}

our $outputBaseDir				= $ARGV[0];
#our $libDir						= $abspath."HClusterLibrary/";
our $libDir						= "HClusterLibrary/";
our $path_separator				= ';';

our $log_transform				= "no";
our $row_center					= "no";
our $row_normalize				= "no";
our $column_center				= "no";
our $column_normalize			= "no";
our $column_distance_measure	= "2";	#pearson correlation
our $row_distance_measure		= "2";	#pearson correlation
our $clustering_method			= "m";	#pairwise complete-linkage
our $color_scheme				= "global";	# or "row normalized"
our $color_palette				= "";


# -------------------------
# Handle additional options
# -------------------------
our $output_format			= "jpeg";
#-.jpeg, .png, .tiff, .bmp, .eps
if ((defined $ARGV[1]) && (lc($ARGV[1]) =~ /(jpeg|png|tiff|bmp|eps)/i))
{	$output_format			= lc($ARGV[1]);
}

if (defined $ARGV[1])
{	for (my $i=1; $i <= $#ARGV; $i++)
	{	if ($ARGV[$i] =~ /^\-f\=(\w+)$/)
		{	$output_format = lc($1);
		}elsif ($ARGV[$i] =~ /^\-rdm\=(\d+)$/)
		{	my $tmpValue = $1;
			if (($tmpValue < 0) || ($tmpValue > 8))
			{	die "!ERROR! -rdm value out of range\n".
					"row_distance_measure:		0=No column clustering; 1=Uncentered correlation; 2=Pearson correlation; 3=Uncentered correlation, absolute value; 4=Pearson correlation, absolute value; 5=Spearman's rank correlation; 6=Kendall's tau; 7=Euclidean distance; 8=City-block distance\n\n";
			}else
			{	$row_distance_measure		= $tmpValue;
			}
		}elsif ($ARGV[$i] =~ /^\-cdm\=(\d+)$/)
		{	my $tmpValue = $1;
			if (($tmpValue < 0) || ($tmpValue > 8))
			{	die "!ERROR! -rdm value out of range\n".
					"column_distance_measure:	0=No column clustering; 1=Uncentered correlation; 2=Pearson correlation; 3=Uncentered correlation, absolute value; 4=Pearson correlation, absolute value; 5=Spearman's rank correlation; 6=Kendall's tau; 7=Euclidean distance; 8=City-block distance\n\n";
			}else
			{	$column_distance_measure		= $tmpValue;
			}
		}elsif ($ARGV[$i] =~ /\-color\=BR/)
		{	$color_palette	= $libDir."colorSchemeBlackRed.txt";
		}
	}
}
$color_palette	= $libDir."colorSchemeBlackRed.txt";

if (($column_distance_measure == 0) && ($row_distance_measure == 0))
{	die "! No clustering is necessary with no row-column clustering selected ...\n\n";
}

#print $row_distance_measure,"\n";
#print $column_distance_measure."\n";
#exit;

# column_distance_measure:	0=No column clustering; 1=Uncentered correlation; 2=Pearson correlation; 3=Uncentered correlation, absolute value; 4=Pearson correlation, absolute value; 5=Spearman's rank correlation; 6=Kendall's tau; 7=Euclidean distance; 8=City-block distance
# row_distance_measure:		0=No column clustering; 1=Uncentered correlation; 2=Pearson correlation; 3=Uncentered correlation, absolute value; 4=Pearson correlation, absolute value; 5=Spearman's rank correlation; 6=Kendall's tau; 7=Euclidean distance; 8=City-block distance
# clustering_method:		m=Pairwise complete-linkage; s=Pairwise single-linkage; c=Pairwise centroid-linkage; a=Pairwise average-linkage




# ---------------------------------------------
# Define required variables - Clustering Images
# ---------------------------------------------
our $java_flags				= "-Djava.awt.headless=true -Xmx1024m";
#my $output_format			= "jpeg";
our $row_size				= "16";
our $column_size			= "16";
our $show_grid				= "yes";
our $grid_color				= "0:0:0";
our $show_row_description	= "yes";
our $show_row_names			= "yes";
our $row_to_highlight		= "";
our $row_highlight_color		= "";
our $use_color_gradient		= "no";



# ---------------------------
# Check OS and define program
# ---------------------------
our $cluster_program			= '';
if ($Config{archname} =~ /linux/)
{	if ($Config{archname} =~ /64/)
	{	$cluster_program	= "clusterLinux64";
	}else
	{	$cluster_program	= "clusterLinux";
	}
}elsif ($Config{archname} =~ /MSWin/)
{	$cluster_program	= "cluster.exe";
}



# ------------------------------------------
# Load directory list
# ------------------------------------------
our @baseSubDirs			= ();
my @baseNameSplit			= split (/\//, $dirName);
our $baseShortDirName		= '';
if ($baseNameSplit[$#baseNameSplit] eq "")
{	$baseShortDirName		= $baseNameSplit[$#baseNameSplit - 1].'/';
}else
{	$baseShortDirName		= $baseNameSplit[$#baseNameSplit].'/';
}

opendir DIR, $dirName or die "Cannot open the current directory: $dirName";
my @tmpDirs = readdir DIR;
closedir DIR;

foreach (@tmpDirs)
{	if (($_ ne '.') && ($_ ne '..'))
	{	push @baseSubDirs, $_;
	}
}



# ------------------------------------------
# Perform HClustering
# ------------------------------------------
perform_hclustering_per_directory ($dirName, '');
print @baseSubDirs."\n";

exit;

if (defined $baseSubDirs[0])
{	foreach (@baseSubDirs)
	{	perform_hclustering_per_directory ($dirName.'/'.$_, $baseShortDirName.'/');
	}
}


print "\n! COMPLETE ...\n";
exit;







sub perform_hclustering_per_directory
{	my $givenDirName		= shift;
	my $additionalDirName	= shift;


	# ------------------------------------------------------------------
	# Load GCT files for hierarchical clustering, in the given directory
	# ------------------------------------------------------------------
	my @gctFiles		= glob ($givenDirName."/"."*.gct");
	my @tmp1			= split (/\//, $givenDirName);
	my $baseDirName		= $tmp1[$#tmp1];
	my $outputDir		= $outputBaseDir.'/';
	create_sub_directory ($outputDir);
	
	foreach my $infile (@gctFiles) 
	{	my @tmp1		= split (/\//, $infile);
		my @tmp2		= split (/\.gct/, $tmp1[$#tmp1]);
	
		# Check gct file content and skip if there is less than 2 entries
		if(!check_gct_contains_more_than_two_lines($infile))
		{	next;
		}
		
		my $output_base_name		= $outputDir.$dirTypeTag.$tmp2[0];	#$outputDir.$dirTypeTag.$baseDirName.'__'.$tmp2[0];
		my $shorter_base_name		= $outputDir.$dirTypeTag.$tmp2[0];
		my $cluster_input_file		= $shorter_base_name.'.txt';
		
		if (convert_gct_to_cluster_input_file ($infile ,$cluster_input_file))
		{	print "! clustering $infile\n";

			system("$libDir$cluster_program -f $cluster_input_file -g $row_distance_measure -e $column_distance_measure -m $clustering_method");
			my $cdtFile	= $output_base_name.".cdt";
			my $gtrFile	= $output_base_name.".gtr";
			my $atrFile	= $output_base_name.".atr";
	
			my $atrCmd	= '';
			my $gtrCmd	= '';

			if ($row_distance_measure != 0)
			{	$gtrCmd = " -x\"$gtrFile\"";
			}

			if ($column_distance_measure != 0)
			{	$atrCmd = " -y\"$atrFile\"";
			}




			# my $command	= "java $java_flags -DlibDir=$libDir -jar $libDir"."hclimage-o.jar \"$cdtFile\" \"$output_base_name\" $output_format -c$column_size -r$row_size -g$show_grid -l$grid_color -a$show_row_description -s$show_row_names -f$row_to_highlight -h$row_highlight_color -n$color_scheme -m$color_palette".$gtrCmd.$atrCmd." -u$use_color_gradient";

			# Create heatmap image using Java TreeView
			my $command = "java -jar TreeView-1.1.6r4-bin/TreeView.jar -r $cdtFile -x Dendrogram -- -o $output_base_name.png -f png -a 0 -g 1 -s 20x20 -b";
			print "$command\n";
			system ($command);


			# Create shorter-named files
#			copy ($output_base_name.'.txt', $shorter_base_name.'.txt');
#			copy ($output_base_name.'.cdt', $shorter_base_name.'.cdt');
#			copy ($output_base_name.'.gtr', $shorter_base_name.'.gtr');
#			copy ($output_base_name.'.atr', $shorter_base_name.'.atr');
#			copy ($output_base_name.'.'.$output_format, $shorter_base_name.'.'.$output_format);
		}else
		{	print "conversion failed for $infile\n";
		}
	}
}



sub convert_gct_to_cluster_input_file
{	my $gctFile				= shift;
	my $clusterInputFile	= shift;

	open (GCTFILE, $gctFile) || return (0);
	open (CLUSTER, ">".$clusterInputFile ) || return (0);

	# process header lines
	my $line = <GCTFILE>;
	if ($line !~ /^\#1\.2/)
	{	return (0);
	}
	$line = <GCTFILE>;
	$line = <GCTFILE>;
	$line =~ s/\r|\n//g;
	my @headerSplit = split (/\t/, $line);
	my $newHeader	= "UNIQID\tNAME\tGWEIGHT\tGORDER";
	for (my $i=2; $i <= $#headerSplit; $i++)
	{	$newHeader .= "\t".$headerSplit[$i];
	}	
	$newHeader .= "\nEWEIGHT\t\t\t";
	for (my $i=2; $i <= $#headerSplit; $i++)
	{	$newHeader .= "\t1"
	}	
	$newHeader .= "\n";
	
	my $GORDER	= 1;
	my $newContent	= "";
	while(<GCTFILE>)
	{	$line = $_;
		$line =~ s/\r|\n//g; 
		my @tmpSplit = split (/\t/, $line);
		if ((defined $tmpSplit[0]) && ($tmpSplit[0] ne ""))
		{	$newContent .= shift(@tmpSplit)."\t".shift(@tmpSplit)."\t"."1\t".($GORDER++)."\t".join("\t",@tmpSplit)."\n";
		}
	}	close GCTFILE;

	print CLUSTER $newHeader.$newContent;
	return(1);
}



sub create_sub_directory
{	my $outputDir	= shift;
	my @tmp1		= split (/\//, $outputDir);
	my $dirName		= '';
	foreach my $dirShort (@tmp1)
	{	$dirName .= $dirShort.'/';
		mkdir ($dirName) || print "";
	}
}

sub check_gct_contains_more_than_two_lines
{	my $infile		= shift;
	open (INFILE, $infile);
	my $lineCount	= 0;
	while(<INFILE>)
	{	my $line = $_;
		$line =~ s/\r|\n//g;
		if ($line eq "")
		{	next;
		}	
		$lineCount++;
	}	close INFILE;
	
	if ($lineCount >=5)
	{	return(1);
	}else
	{	return(0);
	}
}
