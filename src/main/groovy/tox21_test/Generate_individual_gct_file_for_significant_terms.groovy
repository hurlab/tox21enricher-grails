package tox21_test;
import grails.converters.*;
import groovy.sql.Sql.QueryCommand;
//import org.springframework.dao.DataIntegrityViolationException;
import groovy.cli.commons.CliBuilder;
import groovy.io.*;
import static java.lang.System.out;
    //This on ie done-ish.. will need work later.
    //public class Generate_individual_gct_file_for_significant_terms {


    //#!/usr/bin/groovy;
//	import grails.converters.*;
    import groovy.lang.Binding;
    import java.io.BufferedReader;
    import java.io.File;
    import java.io.FileReader;
    //import org.compass.needle.gigaspaces.service.SearchResults;
    //import org.springframework.dao.DataIntegrityViolationException;

    class Generate_individual_gct_file_for_significant_terms{

     public static void main(def args) {
        if (args.length < 6) { System.exit(0); }
        def exportService; //??
        //---------------------------------------
        // Get the corresponding directory names
        //---------------------------------------
        def cleanedArg0= args[0];
        cleanedArg0=cleanedArg0.replaceAll("//","/"); // this should replace // with /

        def cleanedArg1= args[1];
        cleanedArg1=cleanedArg1.replaceAll("//","/");

        def baseinputDirName = cleanedArg0;
        def baseDirName = cleanedArg1;
        //now make an array using these
        def baseShortDirName= '';
        def baseNameSplit = baseDirName.split("/") as String[];// this is how java/groovy splits
        if (baseNameSplit[baseNameSplit.size()-1].isEmpty()){ //if the last position is empty
            baseShortDirName=baseNameSplit.get(baseNameSplit.size()-2)+'/';//grabs the second to last
        }
        else
        {
            baseShortDirName= baseNameSplit.get(baseNameSplit.size()-1)+'/';//grabs last position
        }
        def baseOutputDir = cleanedArg1+'/gct_per_set';
        baseOutputDir= baseOutputDir.replaceAll("//","/");

        //*****************see if we can use database instead
        new File(baseOutputDir).mkdir();
        //******************


        //-----------------
        //Load CASRN name
        //------------------ A CAS is a key/value mapping where small-ish keys are determined from large-ish data but no two pieces of data will ever end up with the same key, thanks to astronomical probabilities. You can then use the small-ish key as a reference to the large chunk of data, as a sort of compression technique. but in this cas it is just a file handle :) see what i did there?

    //here is where we start the database usage, after we make sure current system works
        String CAS =new File("Annotation/Tox21_CASRN_Names.anno");
        def CASRN2Name=[:]; //this should allow us to go ahead and map "hash". Should.
        CAS.withReader('UTF-8') { reader ->
                    while ((line = reader.readLines())!=null)
                        {
                            line.replaceAll("\r|\n","");//gets rid of all newline feeds
                            def tempSplit = line.split("\t") as String[];


                            CASRN2Name.put(tempSplit[0],tempSplit[1]); //this should give us our data, keep an eye on me when running
                        }}
    //----------------
    //Enumerate all possible directories
    //-----------------
    process_variable_DAVID_CHART_directories_individual_file (baseinputDirName, baseDirName, baseOutputDir, '', '');
            System.exit(0);


    } //end of main
    //now making the modules for testing
    def process_variable_DAVID_CHART_directories_individual_file(String baseinputDirName, String baseDirName, String baseOutputDir, String extTag1, String additionalFileName1 ){

        def inputDirName	=	baseinputDirName;
        def dirName		=	baseDirName;
        def outputDir		=	baseOutputDir;
        def extTag		=	extTag1;
        def additionalFileName	=	additionalFileName1;
        //now we load up the input  file
        //This replaces the glob function in perl, new keep eye on when running

    /*	List<String> inFiles= new ArrayList<String>();
        File[] tempFiles=new File(dirName).listFiles();
        for (File file :tempFiles){
        if (file.isFile()&& file.getName().equals("*_Chart.txt")){
                inFiles.add(file.getName());
            }
        }
    */
//*******************************************************************Not sure if this GLOB works
        def pattern = "*_Chart.txt";
        def inFiles = [];
        new File(${dirInputName}).eachDirRecurse{  //"$"is here on purpose!!!!!!
            dir-> dir.eachFileMatch(${pattern}){ myfile-> inFiles.add(${myfile})}
        }


        if (inFiles[0]==null){return;}//nothing there, continue on

        def sigCutOff		=args[5];
        def sigColumnName	= args[4];
           sigColumnName=sigColumnName.toUpperCase();

        def sigColumnIndex	= get_column_index(sigColumnName);
        // 4=p-value, 11=BH p-value, 12=FDR
        def valueColumnName	= args[6];
           valueColumnName=valueColumnName.toUpperCase();
        def valueColumnIndex	= get_column_index(valueColumnName);
        int i;
        for(i=0; i<inFiles.length(); i++){ //foreach
            def temp0=inFiles[i].split("/");
            def temp1= temp0[1].split(".txt") as String[];

            def term2pvalue=[:];
            def CASRN2TermMatrix=[:];
            // Reading contents of files to an array:
            def DATA=new File(inFile).readLines();
            BufferedReader lineIn=new BufferedReader(new FileReader(DATA));
            while ((temp=lineIn.readLine())!=null)
                {
                temp=temp.replaceAll("\r|\n","");//gets rid of all newline
                def tempSplit= temp.split("\t") as String[];

                if ((tmpSplit[sigColumnIndex]==null) || (tmpSplit[sigColumnIndex] >= sigCutOff) ||(tmpSplit[9]<1)){return;}//or continue

                def tmpTermKey			= tmpSplit[1]+' | '+tmpSplit[0];
                term2pvalue[tmpTermKey]	= tmpSplit[sigColumnIndex]; //im worried about this assignment statement, not a groovy way of doing things**now it is
                def CASRNs =tmpSplit[5].split("/" ) as String[]; // splits at "/\ or /"
                for(i=0;i<CASRNs.length();i++)
                    {
                    CASRN2TermMatrix[CASRN][tmpTermKey] = 1;//this is the way. pretty sure.
                    }
                }

            //now create new output files
            def OUTFILE 		= new File(outputDir+tmp2[0]+'.gct');
            def CASRNs		= CASRN2TermMatrix.keySet() as String[];
            def tmpTermKeys 	= term2pvalue.keySet() as String[];
            def CASRNCount		= CASRNs.size();
            def tmpTermKeyCount	= tmpTermKeys.size();
            def outputContent	= "#1.2\n"+"CASRNCount\ttmpTermKeyCount\n"+"CASRN\tName";

            for(i=0;i<tmpTermKeys.size();i++)
            {
                outputContent	= outputContent+"\t"+tmpTermKey+" | "+sprintf("%.2e", term2pvalue[tmpTermKey]);
            }
            outputContent	= outputContent+"\n";
            int y=0;
            for( i=0;i<CASRNs.size();i++)
            {
                outputContent	= outputContent+CASRN+"\t";
                if (CASRN2Name[CASRN]!=null)
                {
                    outputContent	=	outputContent+CASRN2Name[CASRN];
                }

                for(y=0;y<tmpTermKeys.size();y++)
                {	if (CASRN2TermMatrix[CASRN][tmpTermKey]!=null)
                    {
                        outputContent	= outputContent+"\t1";
                    }
                    else
                    {
                        outputContent	= outputContent+"\t0";
                    }
                }
                outputContent	=outputContent+"\n";
            }
            OUTFILE << outputContent;
            //no need to close file. Groovy does it.

        }

    }
        def get_up_down_counts(double incoming1, double incoming2){
            def expressionDataFCRef		 =  incoming1;
            def geneIDString		 =  incoming2;
            def geneIDS 	=  geneIDString.split(",") as String[];
            def upCnt	= 0;
            def dnCount	= 0;
            int i;
        //ok, this one is a bit wild.  The data coming in was a scalar ref in perl, but groovy keeps all data as a ref, which means we should be able to use the original assignment name instead of making a ref object.

            for( i=0;i<geneIDs.size();i++)
            {
                if (expressionDataFCRef[geneID]) //came in as if (defined expressionDataFCRef{geneID})
                {	//for.. reference.
                    if (expressionDataFCRef[geneID] > 0)
                    {
                        upCnt++;
                    }
                    else{
                        dnCount++;
                        }
                }
            }
            def finalCount= (upCnt/dnCount);
            return (finalCount);// this should be fine, may need to make into a number
        }

        def get_column_index(String type){
            def columnType = type;
            if (columnType==~"(?i)P")  // this says if = P ignoring case
                {return 4;}
            else if (columnType==~"(?i)BH")
                {return 11;}
            else if (columnType==~"(?i)BF")
                {return 12;}
            else	{System.exit(0);}//"!ERROR! Wrong Signficance type. Use P, BH, or BF
                        //lets make this print later
            System.exit(0);
        }

        def process_go_kegg_id_term_for_filename(String anID, String someTerm)
        {
            def ID		= anID;
            def term	= someTerm;

            if ((ID==null) || (term==null))
            {
                return("!ERROR! ID or Term is not defined...\n");
            }
            //.replaceAll(~/replaceMe/, "withMe" )
            ID.replaceAll(~/:/,"");  //drop ":"
            term.replaceAll(~/[^a-zA-Z0-9]+/, "");//drop special chars
            term.replaceAll(~/"  "/," "); // get rid of double spaces
            term.replaceAll(~/[\s]/," "); //drop any white space turns it into a single space
        // use only the first 50 characters
            if (term.size()>50)
            {
                return(ID+'_'+term.substr(0,50));
            }
            return(ID+'_'+term);
        }

        //  -----------------------------------------------------------------------------
        // sub is_number
        // -----------------------------------------------------------------------------
        // sub is_number is a moidifed version of getNum()
        // Checking Whether a String Is a Valid Number
        // http://www.unix.org.ua/orelly/perl/cookbook/ch02_02.htm
        // -----------------------------------------------------------------------------
            def is_number(String checkMe)
        {  // use POSIX qw(strtod);
                def stringy = checkMe;
            if (stringy.isNumber()==1)
            {
                return 1;
            }
            return 0;
        }
        def load_gct_file_as_profile(String fileName, String Reference )
        {
            def inFile			= fileName;
            def geneID2ExpProfileRef	= Reference;
            if (!inFile.exists()){return 0;}
            def INFILE 			= inFile.readLines();
            def header = INFILE;
        //if (header !~ /^\#1/)
    //	{	# this is not a gct file
    //		return(0);
    //	}
        header.replaceAll("\r | \n",""); // get rid of line feeds
        def headerSplit = header.split("\t") as String[];
        def maxValue	= 0;
        def lineCount	= 0;
        int i=0;
        int y=0;
        String strLine;
        FileInputStream fstream = new FileInputStream(INFILE);
        BufferedReader br = new BufferedReader(new InputStreamReader(fstream));

        while((strLine =br.readLine())!=null) // while there are still lines
        {
            def line =strLine ;
            line.replaceAll("\r | \n","");
            def tmpSplit = line.split("\t") as String[];
            if (tmpSplit[0].contains("_at")) //double check me
            {
                tmpSplit[0].replaceAll("_at","");
            }
            //geneID2ExpProfileRef{tmpSplit[0]} = join ("\t", @tmpSplit);
            geneID2ExpProfileRef[tmpSplit[0]]+tmpSplit.collect{"'$it'"}.join("\t" );//REALLY double check me-- join func?
            if (lineCount < 10)
            {	for (i=2; i <= tmpSplit.size(); i++)
                {
                    if (tmpSplit[i] > maxValue)
                    {
                        maxValue = tmpSplit[i];
                    }
                }
            }
            lineCount++;
        }
        def useThese =  geneID2ExpProfileRef.keySet() as String[];
        // check if the gct file is not log-transformed
        if (maxValue > 20)
        {	for (i=0;i<useThese.size();i++)
            {
                def tmpSplit = geneID2ExpProfileRef[i].split("\t") as String[];
                for (y=2; y <=tmpSplit.size(); y++)
                    {
                        tmpSplit[i] = Math.log(tmpSplit[y])/Math.log(2);
                    }
                geneID2ExpProfileRef[i] = geneID2ExpProfileRef[i]+tmpSplit.collect{"'$it'"}.join("\t");
            }
        }
        return [1, header];
    }
    def sort_by_file_number(anArray)//just found i dont need to declare type
    {
        def originalArrayRef	= anArray;
        def originalArray	= originalArrayRef;
        def originalCount	= originalArray.size();
        def sortedArray 	= [];
        def number2original= [];
        int y=0;
        if ((originalArray[0]!=null) && (originalArray[0]!=""))
        {
            for(y=0;y<originalArray.size();y++)
            {
                if (name!=null &&!name.equals(""))
                {
                    number2original[1]	= name; //hmmmmmmmmmm need to find translation
                }//**************
            }

            def sortedNumbers	= number2original.sort();
            if (sortedNumbers != originalArray)
            {
                return (originalArray);
            }
            else
            {
                for(y=0;y<sortedNumbers.size();y++)
                {
                    sortedArray.push(number2original[y]);
                }
                return sortedArray;
            }
        }
        return originalArray;
    }
    }



