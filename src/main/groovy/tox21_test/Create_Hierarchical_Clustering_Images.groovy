package tox21_test;
import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.util.Map;
import java.util.UUID;
//import org.rosuda.REngine.*;
//import org.apache.commons.io.output.WriterOutputStream;
//import org.conceptmetab.java.*;
import javax.imageio.*;
import javax.swing.border.Border;

import grails.converters.*;
import groovy.json.JsonBuilder;

//import org.compass.core.converter.mapping.osem.ClassMappingConverter.IdsAliasesObjectKey;
//import org.springframework.dao.DataIntegrityViolationException

class Create_Hierarchical_Clustering_ImagesController {
    // --------------------------------------------------------------------
    //
    //	Automatic_Hierarchical_Clustering.pl
    //
    // --------------------------------------------------------------------
    // This script will perform hierarchical clustering based on the
    // given parameters (pre-defined in the script)
    // --------------------------------------------------------------------
    //
    // v2.	* this version now process any sub-directories as well
    //		* can specify if column/row clustering is used or not
    // --------------------------------------------------------------------
    public static void main(def args) {
            if (args.length == 0)
            {
                println("\n!ERROR: Missing directory\n ThisScript.pl <Summarized DAVID Result directory containg .gct files> -f=[output format] [-rdm=0] [-cdm=0]\n\n");
                System.exit(0);
            }


                // --------------------------------------
                // Define required variables - Clustering
                // --------------------------------------
                def  dirName					= args[0];
                dirName.replaceAll("/","");
                def  dirNameSplit				= dirName.split("/") as String[];
                def  dirTypeTag					= '';
                if (dirNameSplit[0].contains("CLUSTER"))
                {
                    dirTypeTag					= 'CLUSTER__';
                }
                else if (dirNameSplit[0].contains("CHART"))
                {
                    dirTypeTag					= 'CHART__';
                }
                else if (dirNameSplit[0].contains("PRESELECTED"))
                {
                    dirTypeTag					= 'PRESELECTED__';
                }

                def  outputBaseDir				= args[0];
                //def  libDir					= abspath."HClusterLibrary/";
                def  libDir						= "HClusterLibrary/";
                def  path_separator				= ';';

                def  log_transform				= "no";
                def  row_center					= "no";
                def  row_normalize				= "no";
                def  column_center				= "no";
                def  column_normalize			= "no";
                def  column_distance_measure	= "2";	//pearson correlation
                def  row_distance_measure		= "2";	//pearson correlation
                def  clustering_method			= "m";	//pairwise complete-linkage
                def  color_scheme				= "global";	// or "row normalized"
                def  color_palette				= "";


            // -------------------------
            // Handle additional options
            // -------------------------
            def  output_format			= "jpeg";
            //-.jpeg, .png, .tiff, .bmp, .eps
                if ((args.length > 0)) //&& (args[1]=~/jpeg(i?)|png(i?)|tiff(i?)|bmp(i?)|eps(i?)/))
                {
                    output_format			= args[1];
                    output_format			= output_format.toLowerCase();
                }
            def i =0;
            if (args.length>0)
            {

                for (i=1; i<=args.size(); i++)
                {

                    def m = args[i];
                    if (m =~ /^\-f\=(\w+)$/)
                    {
                        def match=m.group(1);
                        output_format = "$match";
                    }

                    else if (args[i] =~ /^\-rdm\=(\d+)$/)

                    {
                        def  tmpValue = 1;
                        if ((tmpValue < 0) || (tmpValue > 8))
                        {
                        println( "!ERROR! -rdm value out of range\nrow_distance_measure:	0=No column clustering; 1=Uncentered correlation; 2=Pearson correlation; 3=Uncentered correlation, absolute value; 4=Pearson correlation, absolute value; 5=Spearman's rank correlation; 6=Kendall's tau; 7=Euclidean distance; 8=City-block distance\n\n");
                            System.exit(0);
                        }
                        else
                        {
                            row_distance_measure		= tmpValue;
                        }
                    }


                    else if (args[i]=~ /^\-cdm\=(\d+)$/)
                    {
                        def  tmpValue = 1;
                        if ((tmpValue < 0) || (tmpValue > 8))
                        {
                            println( "!ERROR! -rdm value out of range\n"+
                                "column_distance_measure:	0=No column clustering; 1=Uncentered correlation; 2=Pearson correlation; 3=Uncentered correlation, absolute value; 4=Pearson correlation, absolute value; 5=Spearman's rank correlation; 6=Kendall's tau; 7=Euclidean distance; 8=City-block distance\n\n");
                            System.exit(0);
                        }
                        else
                        {
                            column_distance_measure		= tmpValue;
                        }
                    }


                    else if (args[1]=~ /\-color\=BR/)
                    {
                        color_palette	= libDir+"colorSchemeBlackRed.txt";
                    }
                }
            }

            if ((column_distance_measure == 0) && (row_distance_measure == 0))
            {	println( "! No clustering is necessary with no row-column clustering selected ...\n\n");
                System.exit(0);
            }


            //print row_distance_measure,"\n";
            //print column_distance_measure."\n";
            //exit;

            // column_distance_measure:	0=No column clustering; 1=Uncentered correlation; 2=Pearson correlation; 3=Uncentered correlation, absolute value; 4=Pearson correlation, absolute value; 5=Spearman's rank correlation; 6=Kendall's tau; 7=Euclidean distance; 8=City-block distance
            // row_distance_measure:		0=No column clustering; 1=Uncentered correlation; 2=Pearson correlation; 3=Uncentered correlation, absolute value; 4=Pearson correlation, absolute value; 5=Spearman's rank correlation; 6=Kendall's tau; 7=Euclidean distance; 8=City-block distance
            // clustering_method:		m=Pairwise complete-linkage; s=Pairwise single-linkage; c=Pairwise centroid-linkage; a=Pairwise average-linkage




            // ---------------------------------------------
            // Define required variables - Clustering Images
            // ---------------------------------------------
            def  java_flags				= "-Djava.awt.headless=true -Xmx512m";
            //def  output_format			= "jpeg";
            def  row_size				= "16";
            def  column_size			= "16";
            def  show_grid				= "yes";
            def  grid_color				= "0:0:0";
            def  show_row_description		= "yes";
            def  show_row_names			= "yes";
            def  row_to_highlight			= "";
            def  row_highlight_color		= "";
            def  use_color_gradient			= "no";




            // ---------------------------
            // Check OS and define program
            // ---------------------------
            def archname = System.getProperty("os.name").toLowerCase();
            def  cluster_program			= '';
            if (archname.contains("linux"))
            {
                if (archname.contains("64"))
                {
                    cluster_program	= "clusterLinux64";
                }
                else
                {
                    cluster_program	= "clusterLinux";
                }
            }
            else if (archname.contains("MSWin"))
            {
                cluster_program	= "cluster.exe";
            }


            // ------------------------------------------
            // Load directory list
            // ------------------------------------------
            def  baseSubDirs			= [];
            def  baseNameSplit			= dirName.split("/");
            def  baseShortDirName			= '';
            if (baseNameSplit[baseNameSplit.size()-1].equals(""))
            {
                baseShortDirName		= baseNameSplit[baseNameSplit.size() - 2]+'/';
            }
            else
            {
                baseShortDirName		= baseNameSplit[baseNameSplit.size()-1]+'/';
            }

            def  tmpDirs = [];
            def dir=new File(dirName);
                dir.eachFileRecurse(){
                    tmpDirs.add(it)}

            for(i=0;i<tmpDirs.size();i++)
            {
                if ((!tmpDirs[i].equals('.')) && (!tmpDirs[i].equals('..')))
                {
                    baseSubDirs.push(tmpDirs[i]);
                }
            }


            // ------------------------------------------
            // Perform HClustering
            // ------------------------------------------
            perform_hclustering_per_directory (dirName, '');
            println(baseSubDirs+"\n");



            if (baseSubDirs[0]!=null)
            {
                for(def z=0; z<baseSubDirs.size();z++)
                {
                    perform_hclustering_per_directory (dirName+'/'+baseSubDirs[z], baseShortDirName+'/');
                }
            }


            print "\n! COMPLETE ...\n";
            return;



    }


    def perform_hclustering_per_directory(incomingDir,incomingName)
    {
        def  givenDirName		= incomingDir;
        def  additionalDirName		= incomingName;


        // ------------------------------------------------------------------
        // Load GCT files for hierarchical clustering, in the given directory
        // ------------------------------------------------------------------
                //gctFiles= glob (givenDirName."/"."*.gct");

        def gctFiles = [];

        def dir=new File(givenDirName);
        dir.eachFileRecurse(FileType.FILES){  //Cant check in term, watch at runtime
            if (it.getName().endsWith('.gct"')){ gctFiles.add(it)}
        }


        def  tmp1			= givenDirName.split("/");
        def  baseDirName		= tmp1[tmp1.size()-1];
        def  outputDir			= outputBaseDir+'/';
        create_sub_directory(outputDir);
        for(i=0;i<gctFiles.size();i++)
        {
              tmp1		=infile.split("/");
            def  tmp2		= tmp1[tmp1.size()-1].split(".gct");

            // Check gct file content and skip if there is less than 2 entries
            if(!check_gct_contains_more_than_two_lines(infile))
            {
                return;
            }

            def  output_base_name		= outputDir+dirTypeTag+tmp2[0];	//outputDir.dirTypeTag.baseDirName.'__'.tmp2[0];
            def  shorter_base_name		= outputDir+dirTypeTag+tmp2[0];
            def  cluster_input_file		= shorter_base_name+'.txt';

            if (convert_gct_to_cluster_input_file (infile ,cluster_input_file))
            {	println( "! clustering infile\n");
                def doTheseCommands="libDircluster_program -f cluster_input_file -g row_distance_measure -e column_distance_measure -m clustering_method";
                doTheseCommands.execute(); //********************NOT SURE***********************
                def  cdtFile	= output_base_name+".cdt";
                def  gtrFile	= output_base_name+".gtr";
                def  atrFile	= output_base_name+".atr";

                def  atrCmd	= '';
                def  gtrCmd	= '';

                if (row_distance_measure != 0)
                {
                    gtrCmd = " -x "+ gtrFile;
                }

                if (column_distance_measure != 0)
                {
                    atrCmd = " -y "+atrFile;
                }

                def  command	= "java java_flags -DlibDir=libDir -jar libDir"."hclimage-o.jar \"cdtFile\" \"output_base_name\" output_format -ccolumn_size -rrow_size -gshow_grid -lgrid_color -ashow_row_description -sshow_row_names -frow_to_highlight -hrow_highlight_color -ncolor_scheme -mcolor_palette"+gtrCmd+atrCmd+" -uuse_color_gradient";
                command.execute();//********************NOT SURE***********************


                // Create shorter-named files
    //			copy (output_base_name.'.txt', shorter_base_name.'.txt');
    //			copy (output_base_name.'.cdt', shorter_base_name.'.cdt');
    //			copy (output_base_name.'.gtr', shorter_base_name.'.gtr');
    //			copy (output_base_name.'.atr', shorter_base_name.'.atr');
    //			copy (output_base_name.'.'.output_format, shorter_base_name.'.'.output_format);
            }
            else
            {
                println "conversion failed for "+ infile+"\n";
            }
        }
    }




    def convert_gct_to_cluster_input_file(thingOne, thingTwo)
    {	def  gctFile			= thingOne;
        def  clusterInputFile		= thingTwo;

        GCTfile=new File(GCTFILE);
        gctFILE= new File(gctfile);

        //process header lines
        def line= "";
            GCTfile.withReader('UTF-8') { reader ->
            while ((line = reader.readLines())!=null)
                    {

                if (!line.contains("#1.2"))
                    {return (0);}
                line.replaceAll("\r|\n","");
                def headerSplit = line.split("\t");
                def  newHeader	= "UNIQID\tNAME\tGWEIGHT\tGORDER";
                for (i=2; i <= headerSplit.size(); i++)
                    {
                    newHeader =newHeader+ "\t"+headerSplit[i];
                    }
                newHeader =newHeader+ "\nEWEIGHT\t\t\t";
                for (i=2; i <= headerSplit.size(); i++)
                    {
                    newHeader =newHeader+ "\t1";
                    }
                newHeader =newHeader+ "\n";
                    }
            }
        def  GORDER	= 1;
        def  newContent	= "";
        GCTfile.withReader('UTF-8') { reader ->
            while ((line = reader.readLines())!=null)
                {
                line.replaceAll("\r|\n","");
                def  tmpSplit = line.split("\t");
                if ((tmpSplit[0]!=null) && (!tmpSplit[0].equals("")))
                {
                    newContent =newContent+ tmpSplit.take(1)
                    tmpSplit.remove(0);
                    newContent=newContent+"\t"+tmpSplit.take(1)+"\t"+"1\t"+(GORDER+1)+"\t";
                    tmpSplit.remove(0);
                    newContent.join("\t", tmpSplit.each())+"\n";
                }
                }
            }
            CLUSTER.append(newHeader+newContent);
        return(1);
    }


    def create_sub_directory(outputIncoming)
    {	def  outputDir		= outputIncoming;
        def  tmp1		= outputDir.split("/");
        def  dirName		= '';
        for(i=0;i<tmp1.size();i++)
        {	dirName = dirName+tmp1[i]+'/';
            new File(dirName).mkdir();
        }
    }

    def check_gct_contains_more_than_two_lines(inFILE)
    {	def  infile		= inFILE;
        def INFILE = new File(infile);
        def  lineCount	= 0;
        INFILE.withReader('UTF-8') { reader ->
            while ((line = reader.readLines())!=null)
            {
                line.replaceAll("\r|\n","");
                if (line.equals(""))
                {return;}
                lineCount++;
        }
        if (lineCount >=5)
        {
            return(1);
        }
        else
        {
            return(0);
        }
            }
    }

}
