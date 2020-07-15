package tox21_test;
import grails.converters.*;
import groovy.sql.Sql.QueryCommand;
//import org.springframework.dao.DataIntegrityViolationException;
import groovy.cli.commons.CliBuilder;
import groovy.io.*;
import static java.lang.System.out;
class Create_David_clusterController {

public static void main(def args){
    //we need to ensure that we are using the correct
    if ((args == null) || (args.length <5))
    {
        println( "\n!ERROR: Missing parameters\n"+
            ">ThisScript.pl <DAVID Result directory> <topTermCount per file>\n"+
            "               <Sig-applying ALL or AT-LEAST-ONE data> <SigColumn> <SigCutOff> <ValueColumn>\n"+
            "				[optional part of file name]\n\n"+
            ">ThisScript.pl DNM 10 ALL BH 0.05 P\n"+
            ">ThisScript.pl DNM 20 ALO BH 0.05 BH\n\n");
        System.exit(0);
    }
    //Injecting service in controller
    def connectRService
    def createEnrichedConceptService
    def exportService
    def grailsApplication

    // -------------------------------------
    //Get the corresponding directory names
    // -------------------------------------
    //this bit here is the java regex that removes all spaces
    def baseDirName=args[0].replaceAll(" ","");
    //now we start assigning things
    //splitting the arg 0 and adding to array
    def baseNameSplit = baseDirName.split("/") as String[];
            def baseShortDirName= '';
            if (baseNameSplit[((baseNameSplit.length())-1)]==null)// last position in the array
            {
                baseShortDirName=baseNameSplit[((baseNameSplit.length())-2)];
            }
            else	{
                baseShortDirName=baseNameSplit[((baseNameSplit.length())-1)]
            }
            def baseOutputDir=args[0]+"/gct/";
            baseOutputDir.replaceAll("//","/");

            new File(baseOutputDir).mkdir();
            if (!baseOutputDir.exists()){System.exit(0);} //doesnt work? exit

            process_variable_DAVID_CHART_directories (baseDirName, baseOutputDir, '', '');
            process_variable_DAVID_CLUSTER_directories (baseDirName, baseOutputDir, '', '');

            System.exit(0);

        }

            def process_variable_DAVID_CLUSTER_directories(baseDirName, baseOutputDir, anExTag, anAddFileName )
            {
                def dirName		=	baseDirName;
                def outputDir		=	baseOutputDir;
                def extTag		=	anExTag;
                def additionalFileName	=	anAddFileName;

                //check for any file
                //This replaces the glob function in perl, new keep eye on when running
                /* List<String> inFiles= new ArrayList<String>();
        File tempFiles=new File(dirName).listFiles();
        tempFiles.each(){
            if (it.isFile()&& it.getName().contains("*_Cluster.txt"))
            {
                inFiles.add(it.getName());
            }
        } */
                def infiles = [];

                def dir=new File(dirName);
                dir.eachFileRecurse(FileType.FILES){  //Cant check in term, watch at runtime
                    if (it.getName().endsWith('_Cluster.txt')){ infiles.add(it)}
                }


                if (infiles[0]==null){return 0;} //no files

                //Define number of top cluters
                new File(outputDir).mkdir();
                if (!outputDir.exists()){System.exit(0);}

                def dirInputName		= dirName;
                def dirInputExpression		= dirInputName+'/ExpressionData/';
                def topTermLimit		= args[1].toUpperCase();
                def mode			= args[2].toUpperCase();
                def sigCutOff			= args[4];
                def sigColumnName		= args[3].toUpperCase();
                def sigColumnIndex		= get_column_index(sigColumnName);
                // 4=p-value, 11=BH p-value, 12=FDR
                def valueColumnName		= args[5].toUpperCase();
                def valueColumnIndex		= get_column_index(valueColumnName);
                def summaryFileNameBase		= additionalFileName;
                def summaryFileNameExt		= extTag;
                def dirNameSplit		= dirName.split("/") as String[];
                if (dirNameSplit[dirNameSplit.size()-1]!=null && !dirNameSplit[dirNameSplit.size()].trim().isEmpty())
                {  //this concatonates the data if the last array element is not empty
                    summaryFileNameBase 	= summaryFileNameBase+"Cluster_ToptopTermLimit"+'_'+mode+'__'+sigColumnName+'_'+sigCutOff+'_'+valueColumnName;
                    summaryFileNameExt	= summaryFileNameExt+"Cluster_ToptopTermLimit"+'_'+mode+'__'+sigColumnName+'_'+sigCutOff.'_'+valueColumnName;
                }
                else
                {	//this concatonates the data if the last array element is empty
                    summaryFileNameBase = summaryFileNameBase+"Cluster_ToptopTermLimit"+'_'+mode+'__'+sigColumnName.'_'+sigCutOff+'_'+valueColumnName;
                    summaryFileNameExt  = summaryFileNameExt+"Cluster_ToptopTermLimit"+'_'+mode.'__'+sigColumnName+'_'+sigCutOff+'_'+valueColumnName;
                }
                // -----------------------------------------------------------------------------
                // Load DAVID cluster files

                summaryFileNameBase.replace("/","");//gets rid of ONLY FIRST "/"
                def ID2Term		= [:];
                def ID2Class		= [:];
                def fileHeaderNames 	= [];
                def pvalueMatrix	= [:];
                def fcMatrix		= [:];
                def upDownMatrix	= [:];

                // Additional variables/hashes/arrays for expression details
                def geneID2expDetails	= [:];
                def file2ExpDetailCnt	= [:];
                def termID2geneContent	= [:];
                def geneID2Description	= [:];
                def allBaseFileNames	= [];
                def gctFileHeader	= '';
                def geneID2ExpProfile	= [:];
                def gctFileStatus	= 0;

                // Load gct file, if availalbe
                // check gct file
                def gctFiles=[];
                dir=new File(dirInputName);
                dir.eachFileRecurse(FileType.FILES){

                    if (it.getName().endsWith('_Cluster.txt')){ gctFiles.add(it)}
                }



                if (gctFiles[0]==null){return 0;} //no files
                else{
                    (gctFileStatus, gctFileHeader) = load_gct_file_as_profile(gctFiles[0], geneID2ExpProfile);
                }

                // Step1. Get the list of significant terms
                int i;
                for(i=0;i<infiles.size();i++) //foreach
                {
                    def tmp1 = infiles[i].split("/");
                    def tmpNameSplit = tmp1[tmp1.size()-1].split("__Cluster.txt");
                    def shortFileBaseName	= tmpNameSplit[0];
                    def originalSourceFile = dirInputName+'/'+shortFileBaseName+'.txt';
                    if (file2ExpDetailCnt[shortFileBaseName] ==null)
                    {
                        file2ExpDetailCnt[shortFileBaseName] = 0;
                    }
                    //open the file
                    def DATA = new File(infile);
                    def termCount	= 1;
                    def lines = DATA.readLines();
                    int y;
                    for (y=0; y <= lines.size(); y++)
                    {	lines[y].replaceAll("\r | \n","");
                        if (lines[y].contains("Annotation Cluster")||lines[y].contains("Enrichment Score"))
                            {	// skip the next line
                                y = y + 2;

                            // process the first term
                            def tmpSplit = lines[y].split("\t") as String[];

                            if ((tmpSplit[sigColumnIndex].isNumber()) || (tmpSplit[sigColumnIndex] >= sigCutOff) || (tmpSplit[9]<1))
                            {
                                return;
                            }

                            if (termCount <= topTermLimit)
                            {
                                ID2Term[tmpSplit[1]]	= tmpSplit[1];
                                ID2Class[tmpSplit[1]]	= tmpSplit[0];
                                termCount++;
                            }
                        }
                    }

                }
                def IDs =ID2Term.keySet() as String[];
                for(i=0;i<infiles.size();i++)
                {
                    def tmp1 		= infiles[i].split("/") as String[];
                    def tmpNameSplit	= tmp1[tmp1.size()-1].split("__Cluster.txt" ) as String[];
                    def shortFileBaseName	= tmpNameSplit[0];

                    def tmp2 = tmp1[tmp1.size()-1].split(".xls") as String[];
                    if (tmp2[0].size() == tmp1[tmp1.size()-1])
                    {
                        tmp2 = tmp1[tmp1.size()-1].split(".txt") as String[];
                    }
                    def expressFile= '';
                    def tmp3 = tmp2[0].split.("__Cluster");

                    if (tmp3[0].matches("__"))
                            {
                        def tmp4	 = tmp3[0].split("__") as String[];

                        def tmpExpFile	 = dirInputExpression+tmp4[0]+'__ExpressionData.txt';
                        if (tmpExpFile.exists())
                        {
                            expressFile = tmpExpFile;
                        }
                        else
                        {
                            expressFile = dirName+"/"+tmp4[0]+'__ExpressionData.txt';
                        }
                            }

                    else
                    {
                        def tmpExpFile	 = dirInputExpression+tmp3[0]+'__ExpressionData.txt';

                        if (tmpExpFile.exists())
                        {
                            expressFile = tmpExpFile;
                        }
                        else
                        {
                            expressFile = dirName+"/"+tmp3[0]+'__ExpressionData.txt';
                        }
                    }

                    fileHeaderNames.push(tmp3[0]); // this adds tmp3 to the array fileHeaderNames


                    // ------------------------------------------------------------
                    // Load expression data if any

                    def expressionDataExist 	= 0;
                    def expressionData		= [:];
                    def expressionDataFC		= [:];
                    def expressionHeader 		= "";
                    if (expressFile.exists())
                    {
                        expressionDataExist = 1;
                        File EXP = new File(expressFile);//opens the file

                        expressionHeader = EXP;
                        //print expressionHeader."\n";
                        expressionHeader.replaceAll("\r|\n","");//remove all linefeeds
                        def temp= "";
                        def lineNo = 1;
                        def line;
                        EXP.withReader('UTF-8') { reader ->
                        while ((line = reader.readLines())!=null)
                        {
                            line.replaceAll("\r|\n","");
                            def tmpSplit = line.split("\t");
                            if ((tmpSplit[0]==null) || (tmpSplit[0].trim().isEmpty()))
                            {
                                return;
                            }
                            expressionData[tmpSplit[0]] = line;
                            expressionDataFC[tmpSplit[0]] = tmpSplit[2];
                            lineNo++;

                        }
                        }
                    }
                    else{} //nothing yet
                    // ------------------------------------------------------------
                    // Check term file and load
                    // ------------------------------------------------------------

                    def DATA = new File(infile);
                    def line;
                    DATA.withReader('UTF-8') { reader ->
                    while ((line = reader.readLines())!=null)
                    {

                        line.replaceAll("\r|\n","");
                        def tmpSplit = line.split("\t");

                        if ((tmpSplit[sigColumnIndex]==null) ||	(tmpSplit[9]==null) ||(tmpSplit[sigColumnIndex].isNumber()) || ((mode.equals('ALL')) && (tmpSplit[sigColumnIndex] >= sigCutOff)) ||(tmpSplit[9]<1))
                        {
                            return;
                        }

                        if (ID2Term[tmpSplit[1]]!=null)
                        {
                            pvalueMatrix[tmpSplit[1]][tmp3[0]] = -1*Math.log(tmpSplit[valueColumnIndex]);
                            fcMatrix[tmpSplit[1]][tmp3[0]] = tmpSplit[9]; //2d array
                            ID2Class[tmpSplit[1]] = tmpSplit[0];
                            if (expressionDataExist.exists())
                            {
                                upDownMatrix[tmpSplit[1]][tmp3[0]] = get_up_down_counts(expressionDataFC, tmpSplit[5]);
                            }
                            termID2geneContent[tmpSplit[1]][shortFileBaseName] = tmpSplit[5];
                        }

                    }
                    }
                }
                // ----------------------
                // Create a summary file
                // ----------------------
                def summaryFileName = summaryFileNameBase+'__ValueMatrix.txt';
                def SUMMARY= new File(outputDir+summaryFileName);

                fileHeaderNames = sort_by_file_number(fileHeaderNames);
                SUMMARY.append("GROUP\tID\tTerms\t"+fileHeaderNames.collect{"'$it'"}.join("\t")+"\n");

                IDs.each(){
                    SUMMARY.append(ID2Class[ID]+"\t"+ID+"\t"); //this writes to the file
                    fileHeaderNames.each()
                    {
                        if (pvalueMatrix[ID][header] != null)
                        {
                            SUMMARY.append("\t"+pvalueMatrix[ID][header]);
                        }
                        else
                        {
                            SUMMARY.append("\t");
                        }
                    }
                    SUMMARY.append("\n");
                }


                // Create a gct file from ValueMatrix
                def INFILE	=	new File(outputDir+summaryFileNameBase+'__ValueMatrix.txt'); //open a file
                def OUTFILE	=	new File(outputDir+summaryFileNameBase+'__ValueMatrix.gct');

                def headerLine	= INFILE.readLines();
                headerLine.replaceAll("\r|\n","");
                def headerSplit	= headerLine.split("\t");
                def sampleCnt	= (headerSplit.size() - 3);
                headerSplit.drop(1); // this removes the first element in the array
                def geneCnt		= 0;
                def content		= '';

                INFILE.withReader('UTF-8') { reader ->
                while ((line = reader.readLines())!=null)
                {
                    line.replaceAll("\r|\n","");
                    if (line.equals(""))
                    {return;}
                    def tmpSplit = line.split("\t");
                    for (i=3; i < (sampleCnt+3); i++)
                    {
                        if ((tmpSplit[i]!=null) || (!tmpSplit[i].isEmpty()))
                        {tmpSplit[i] = 0;}
                    }
                    tmpSplit.drop(1);
                    content =content+tmpSplit.collect{"'$it'"}.join("\t")."\n";
                    geneCnt++;
                }
                }
                OUTFILE.append( "#1.2\n"+geneCnt+"\t"+sampleCnt+"\n"+ headerSplit.collect{"'$it'"}.join("\t")+"\n"+content);

            }


            def process_variable_DAVID_CHART_directories(directoryName, outputDirectory, tag, other)
            {	def  dirName				= directoryName;
            def  outputDir				= outputDirectory;
            def  extTag				= tag;
            def  additionalFileName			= other;

            // Check the direcory for any file
            println "! Processing dirName ...\n";

            //This replaces the glob function in perl, new keep eye on when running

            def infiles = [];

            def dir=new File(dirName);
            dir.eachFileRecurse(FileType.FILES){
                if (it.getName().endsWith('_Chart.txt')){ infiles.add(it)}
            }


            /*	List<String> inFiles= new ArrayList<String>();
        File tempFiles=new File(dirName).listFiles();
        tempFiles.each()
        {
            if (it.isFile()&& it.getName().contains("_Chart.txt"))
            {
                inFiles.add(it.getName());
            }
        }
             */

            if (infiles[0]==null)
            {return;}

            // Define number of top cluters
            new File(outputDir).mkdir() || println("");
            def  dirInputName		= dirName;
            def  dirInputExpression		= dirInputName+'/ExpressionData/';
            def  topTermLimit		= args[1];
            def  mode			= args[2].toUpperCase();
            def  sigCutOff			= args[4];
            def  sigColumnName		= args[3].toUpperCase();
            def  sigColumnIndex		= get_column_index (sigColumnName);// 4=p-value, 11=BH p-value, 12=FDR
            def  valueColumnName		= args[5]toUpperCase();
            def  valueColumnIndex		= get_column_index (valueColumnName);
            def  summaryFileNameBase	= additionalFileName;
            def  summaryFileNameExt		= extTag;
            def  dirNameSplit		= dirName.split("/");
            if (dirNameSplit[dirNameSplit.length()]!=null)
            {	//#summaryFileNameBase 	= dirNameSplit[#dirNameSplit]."__ToptopTermLimit".'_'.mode.'__'.sigColumnName.'_'.sigCutOff.'_'.valueColumnName;
                summaryFileNameBase 	=summaryFileNameBase+ "Chart_ToptopTermLimit"+'_'+mode+'__'+sigColumnName.'_'+sigCutOff+'_'+valueColumnName;
                summaryFileNameExt	=summaryFileNameExt+ "Chart_ToptopTermLimit"+'_'+mode+'__'+sigColumnName+'_'+sigCutOff+'_'+valueColumnName;
            }
            else
            {	//summaryFileNameBase 	= dirName+"__ToptopTermLimit"+'_'+mode+'__'+sigColumnName+'_'+sigCutOff+'_'+valueColumnName;
                summaryFileNameBase 	=summaryFileNameBase+ "Chart_ToptopTermLimit"+'_'+mode+'__'+sigColumnName+'_'+sigCutOff+'_'+valueColumnName;
                summaryFileNameExt	=summaryFileNameBase+ "Chart_ToptopTermLimit"+'_'+mode+'__'+sigColumnName+'_'+sigCutOff+'_'+valueColumnName;
            }
            summaryFileNameBase.replaceAll("/","");
            // -----------------------------------------------------------------------------
            // Load DAVID Chart files
            // -----------------------------------------------------------------------------


            def  ID2Term		= [:];
            def  ID2Class		= [:];
            def  fileHeaderNames 	= [];
            def  pvalueMatrix	= [:];
            def  fcMatrix		= [:];
            def  upDownMatrix	= [:];

            def  geneID2expDetails	= [:];
            def  file2ExpDetailCnt	= [:];
            def  termID2geneContent = [:];
            def  geneID2Description = [:];
            def  allBaseFileNames	= [];
            def  gctFileHeader	= '';
            def  geneID2ExpProfile	= [:];
            def  gctFileStatus	= 0;
            def i=0;
            // Load gct file, if availalbe
            // check gct file
            //********************************************************************use this for globbing. go back and fix in morning

            def gctFiles = [];
            dir=new File(dirInputName);
            dir.eachFileRecurse(FileType.FILES){  //Cant check in term, watch at runtime

                if (it.getName().endsWith('.gct')){ gctFiles.add(it)}
            }

            if (gctFiles[0]!=null) //so if gct is defined, run this function
            {
                (gctFileStatus, gctFileHeader) = load_gct_file_as_profile (gctFiles[0], geneID2ExpProfile);
            }


            // Step1. Get the list of significant terms
            for(i=0;i<infiles.size();i++) //foreach
            {

                def tmp1 = infiles[i].split("/")
                        def tmpNameSplit =tmp1[tmp1.size()-1].split("__Cluster.txt");
                def shortFileBaseName	= tmpNameSplit[0];
                def originalSourceFile = dirInputName+'/'+shortFileBaseName+'.txt';

                if (file2ExpDetailCnt[shortFileBaseName]==null)
                {
                    file2ExpDetailCnt[shortFileBaseName] = 0;
                }


                def DATA	=	new File(infile)
                        def termCount	= 1;
                def lines 	= DATA.readLines();
                def lines2 	=lines.size() //count the lines in a file

                        def y=0;
                for (y=0; y <= lines.size(); y++)
                {	lines[y].replaceAll("\r | \n","");

                if (lines[y].contains("Annotation Cluster")||lines[y].contains( "Enrichment Score"))
                {	// skip the next line
                    y = y + 2;
                    // process the first term
                    def tmpSplit =lines[y].split("\t");
                    if ((tmpSplit[sigColumnIndex].isNumber() || (tmpSplit[sigColumnIndex] >= sigCutOff) || (tmpSplit[9]<1)))
                            {
                        return;
                            }

                    if (termCount <= topTermLimit)
                    {	ID2Term[tmpSplit[1]]	= tmpSplit[1];
                    ID2Class[tmpSplit[1]]	= tmpSplit[0];
                    termCount++;
                    }
                }
                }
            }


            def IDs = ID2Term.keySet() as String[]; //this gives the keys as an array
            for(i=0;i<infiles.size();i++)
            {	def tmp1 = infiles[i].split("/");
            def tmpNameSplit = tmp1[tmp1.size()-1].split("__Chart.txt");
            def shortFileBaseName	= tmpNameSplit[0];
            def tmp2 = tmp1[tmp1.size()-1].split(".xls");
            if (tmp2[0] == tmp1[tmp1.size()-1])
                    {
                        tmp2 = tmp1[tmp1.size()-1].split(".txt");
                    }

                    def expressFile = '';
                    def tmp3 = tmp2[0].split("__Chart");
                    if (tmp3[0].matches("__"))
                    {	def tmp4 = tmp3[0].split("__");
                    def tmpExpFile	 = dirInputExpression+tmp4[0]+'__ExpressionData.txt';
                    if (tmpExpFile.exists())
                    {
                        expressFile = tmpExpFile;
                    }
                    else
                    {
                        expressFile = dirName+"/"+tmp4[0]+'__ExpressionData.txt';
                    }
                    }
                    else
                    {	def tmpExpFile	 = dirInputExpression+tmp3[0]+'__ExpressionData.txt';
                    if (tmpExpFile.exists())
                    {
                        expressFile = tmpExpFile;
                    }
                    else
                    {
                        expressFile = dirName"/"+tmp3[0]+'__ExpressionData.txt';
                    }
                    }

                    fileHeaderNames.drop(tmp3[0]);     //***************keep an eye on me

                    // ------------------------------------------------------------
                    // Load expression data if any
                    def  expressionDataExist  	= 0;
                    def  expressionData		= [:];
                    def  expressionDataFC		= [:];
                    def  expressionHeader 		= "";

                    if (expressFile.exists())
                    {	expressionDataExist = 1;
                    def EXP	=new File(expressFile);

                    expressionHeader = EXP.readLines();;
                    //print expressionHeader."\n";
                    expressionHeader.replaceAll("\r | \n","");

                    EXP.withReader('UTF-8') { reader ->
                    while ((line = reader.readLines())!=null)
                    {
                        line.replaceAll("\r|\n","");
                        def tmpSplit = line.split("\t");

                        if ((tmpSplit[0]==null) || (tmpSplit[0].equals("")))
                        {
                            return;
                        }
                        expressionData[tmpSplit[0]] = line;
                        expressionDataFC[tmpSplit[0]] = tmpSplit[1];
                    }}
                    }
                    else{}	//print "!    No expression data file for $tmp2[0] exists...\n";

                    // ------------------------------------------------------------
                    // Check term file and load

                    def DATA	=new File(infile);
                    DATA.withReader('UTF-8') { reader ->
                    while ((line = reader.readLines())!=null)
                    {
                        line.replaceAll("\r|\n","");
                        def tmpSplit = line.split("\t");

                        if ((tmpSplit[sigColumnIndex]==null) ||	(tmpSplit[9]==null) ||(tmpSplit[sigColumnIndex] =~ /^\D/) || ((mode.matches('ALL') && (tmpSplit[sigColumnIndex] >= sigCutOff)) ||
                                (tmpSplit[9]<1)))
                                {
                            return;
                                }

                        if (ID2Term[tmpSplit[1]]!=null)
                        {	pvalueMatrix[tmpSplit[1]][tmp3[0]] = -1*Math.log(tmpSplit[valueColumnIndex]);
                        fcMatrix[tmpSplit[1]][tmp3[0]] = tmpSplit[9];
                        ID2Class[tmpSplit[1]] = tmpSplit[0];
                        if (expressionDataExist==1)
                        {
                            upDownMatrix[tmpSplit[1]][tmp3[0]] = get_up_down_counts (expressionDataFC, tmpSplit[5]);
                        }
                        termID2geneContent[tmpSplit[1]][shortFileBaseName] = tmpSplit[5];
                        }
                    }}
            }

            // Create a summary file
            def summaryFileName = summaryFileNameBase+'__ValueMatrix.txt';
            def SUMMARY         = new File(outputDir+summaryFileName);
            fileHeaderNames = sort_by_file_number(fileHeaderNames);
            SUMMARY.append("GROUP\tID\tTerms\t"+fileHeaderNames.collect{"'$it'"}.join("\t")+"\n");

            for (i=0; i<IDs.size();i++)
            {	SUMMARY.append(ID2Class[ID]+"\t"+ID+"\t");
            for(y=0;y<fileHeaderNames.size();y++)
            {	if (pvalueMatrix[ID][y]!=null)
            {
            SUMMARY.append("\t"+pvalueMatrix[ID][header]);
            }
            else
            {
                SUMMARY.append("\t");
            }
            }
            SUMMARY.append("\n");
            }


            // Create a gct file from ValueMatrix
            def INFILE= new File(outputDir+summaryFileNameBase+'__ValueMatrix.txt');
            def OUTFILE= new File(outputDir+summaryFileNameBase+'__ValueMatrix.gct');

            def headerLine	= INFILE.readLines();
            headerLine.replaceAll("\r|\n","");
            def headerSplit	= headerLine.split("\t");
            def sampleCnt	= (headerSplit.size() - 3);
            headerSplit.take(1); //return first element
            headerSplit.drop(1); // shift on an array deletes the first element of the array in perl. in groovy "drop" gets it
            def geneCnt		= 0;
            def content		= '';
            INFILE.withReader('UTF-8') { reader ->
            while ((line = reader.readLines())!=null)
            {
                line.replaceAll("\r|\n","");
                def tmpSplit = line.split("\t");
                if (line.equals(""))
                {
                    return;
                }


                for (i=3; i < (sampleCnt+3); i++)
                {
                    if ((tmpSplit[i]==null) || (tmpSplit[i].equals("")))
                    {
                        tmpSplit[i] = 0;
                    }
                }
                tmpSplit.take(1); //return first element
                tmpSplit.remove(0)
                content = content.join("\t", tmpSplit.each())+"\n";
                geneCnt++;
            }
            OUTFILE.append("#1+2\n"+"geneCnt\tsampleCnt\n"+headerSplit.collect{"'$it'"}.join("\t")+"\n"+content);
            }
            }
            def get_up_down_counts(someData, arrayElement)
            {
                def expressionDataFCRef	= someData;
                def geneIDString	= arrayElement;

                def geneIDs =geneIDString.split(",");
                def upCnt	= 0;
                def dnCount	= 0;
                def i=0;
                for(i=0;i<geneIDs.size();i++)
                {	if (expressionDataFCRef[i]!=null)
                {
                    if (expressionDataFCRef[geneID] > 0)
                    {
                        upCnt++;
                    }
                    else
                    {
                        dnCount++;
                    }
                }
                }
                def returnMe =upCnt/dnCount;

                return (returnMe);
            }


            def get_column_index(incomingValue_FearMe)
            {
                def columnType	= incomingValue_FearMe;

                if (columnType =~ /P(i?)/)
                {
                    return (4);
                }
                else if(columnType =~ /BH(i?)/)
                {
                    return (11)
                }
                else if($columnType =~ /BF(i?)/)
                {
                    return (12)
                }
                else
                {
                    println ("!ERROR! Wrong Signficance type. Use P, BH, or BF\n\n");
                    System.exit(0);
                }
            }

            def process_go_kegg_id_term_for_filename(someID, someTerm)// not used in this program ?called from another?
            {	def ID		= someID;
            def term	= someTerm;

            if ((ID==null) || (term==null))
            {
                return("!ERROR! ID or Term is not defined...\n");
            }

            ID.replaceAll(":","");
            term.replaceAll("+ | - | , | ' | /", ""); //gets rid of those special chars
                    term.replaceAll('"',""); //gets rid of quotation
                    term.replaceAll(/\s+/," "); //replace whitespace with a space. go with it.

                    // use only the first 50 characters
                    if (term.size()>50)
                    {
                        return(ID+'_'+term[0..49]);
                    }
                    return(ID+'_'+term);
            }
            //the is_number function is not used



            def load_gct_file_as_profile(someFileName, someGene)
            {
                def infile			= someFileName;
                def geneID2ExpProfileRef	= someGene;

                def INFILE	=new File(infile);
                def header = INFILE.readLine();
                if (!header.contains('#1'))
                {	// this is not a gct file
                    println("check david_cluster line 730, Not a GCT file")  //checking to ensure it is a gct file
                    return(0);
                }
                INFILE.withReader('UTF-8') { reader ->
                while (( header = reader.readLines())!=null)
                {
                    header.replaceAll("\r|\n","");
                    def headerSplit = header.split("\t") as String[];
                    def maxValue	= 0;
                    def lineCount	= 0;
                }}
                INFILE.withReader('UTF-8') { reader ->
                while ((line = reader.readLines())!=null)
                {

                    line.replaceAll("\r|\n","");
                    def tmpSplit = line.split("\t") as String[];
                    if (tmpSplit[0].contains("_at"))
                            {
                        tmpSplit[0].replaceAll("_at","");
                            }
                    geneID2ExpProfileRef[tmpSplit[0]] =tmpSplit.collect{"'$it'"}.join("\t");
                    if (lineCount < 10)
                    {	for (int i=2; i <= tmpSplit.size(); i++)  //was this the correct interpretation?
                    {
                        if (tmpSplit[i] > maxValue)
                        {
                            maxValue = tmpSplit[i];
                        }
                    }
                    }
                    lineCount++;
                }
                }
                // check if the gct file is not log-transformed
                if (maxValue > 20)
                {	//foreach my $geneID (keys %{$geneID2ExpProfileRef})
                    for(int i=0;i<infiles.size();i++)
                    {
                        def tmpSplit = geneID2ExpProfileRef[geneID].split("\t");
                        for (y=2; y <= tmpSplit.size(); y++)
                            {
                                tmpSplit[y] = Math.log(tmpSplit[i])/Math.log(2);
                            }
                        geneID2ExpProfileRef[geneID] = tmpSplit.collect{"'$it'"}.join("\t");
                    }
                }
                return [1, header];
            }



            def sort_by_file_number(anArrayGoesHere)
            {	def originalArrayRef	= anArrayGoesHere;
            def originalArray	= originalArrayRef;
            def originalCount	= originalArray.size();
            def sortedArray 	= [];
            def number2original	= [];

            if ((originalArray[0]!=null) && (!originalArray[0].isEmpty()))
            {	for (i=0; i<originalArray.size();i++)
            {	if (!name.isEmpty())
            {
                number2original[1]	= name;
            }
            }

            def sortedNumbers	= number2original.sort();
            if (sortedNumbers.size() != originalArray.size())
            {
                return (originalArray);
            }
            else
            {	for(y=0; y<sortedNumbers.size();y++)
            {
                sortedArray.push(number2original[num]);
            }
            return sortedArray;
            }
            }
            return originalArray;


            }


}

