package tox21_test

import grails.converters.*;
import groovy.sql.Sql.QueryCommand;
//import org.springframework.dao.DataIntegrityViolationException;
import groovy.cli.commons.CliBuilder;
import groovy.io.*;
import static java.lang.System.out;

//-------------------------------------------------------------------------------
//					Perform_Tox21_PubChem_Enrichment
//
//									by Junguk Hur (junguk.hur @ med.und.edu)
//
//-------------------------------------------------------------------------------
//
// This script has been developed by Junguk Hur and Dakota Krout and is not open to
// the public. The use of this script is limited only to those who have received
// written permission from Junguk Hur, until released to the public.
//
//-------------------------------------------------------------------------------
//
//	This script performs enrichment analysis of Tox21 data
//
//	v1.0	: (05/10/2013) Initial release
//	v2.1	: (07/21/2015) Additional annotations
//             (10/05/2015) NOCAS_00000 ID handling
//
//-------------------------------------------------------------------------------

class Perform_Tox21_PubChem_Enrichment_v2 {
        public static void main(def args) {
            def  annotationBaseDir = "Annotation/";
            def  funCat2Selected = [:];
            if (args.length>0) {
				for (def i = 1; i <= args.size()-1; i++) {
					if (!args[i].equals("")) {
                        def  tmpSplit = args[i].split("=");
                        if (tmpSplit[1].equals('checked')) {
                            funCat2Selected[tmpSplit[0]]	= 1;
                        }
                        else {
                            funCat2Selected[tmpSplit[0]]	= 0;
                        }
                    }
                }
            }
            else {
                funCat2Selected	= [
                    "MeSH" 						: 1,
                    "PharmActionList" 			: 1,
                    "THERAPEUTIC_CLASS"			: 1,
                    "INDICATION"				: 1,
                    "PRODUCT_CLASS"				: 1,
                    "THERAPEUTIC_CLASS"			: 1,
                    "STRUCTURE_ACTIVITY"		: 1,
                    "MODE_CLASS"				: 1,
                    "MECHANISM"					: 1,
                    "ADVERSE_EFFECT"			: 1,
                    "KNOWN_TOXICITY"			: 1,
                    "TISSUE_TOXICITY"			: 1,
                    "MECH_LEVEL_3"				: 1,
                    "MESH_LEVEL_1"				: 1,
                    "MESH_LEVEL_3"				: 1,
                    "MESH_LEVEL_2"				: 1,
                    "MECH_LEVEL_2"				: 1,
                    "ACTIVITY_CLASS"			: 1,
                    "ZERO_CLASS"				: 1,
                    "MECH_LEVEL_1"				: 1,
                    "TA_LEVEL_3"				: 1,
                    "TA_LEVEL_2"				: 1,
                    "TA_LEVEL_1"				: 1,
                    "CTD_PATHWAY"				: 1,
                    "CTD_GO-BP"					: 0,
                    "CTD_SF"					: 0,
                    "CTD_Chem2Disease"			: 1,
                    "CTD_Chem2Gene_25"			: 1,
                    "DrugBank_Targets"			: 1,
                    "DrugBank_ATC_Code"			: 1,
                    "Toxins_Targets"			: 1,
                    "Leadscope_Toxicity"		: 1,
                    "MultiCase_Tox_Prediction"	: 1,
                    "ToxRefDB"					: 1,
                    "HTS_Active"				: 1,
                    "ToxCast"					: 1,
                    "ToxPrint_Structure"		: 1
				];
            }


            // DSSTox Chart
            def pvalueThresholdToDisplay = 0.2;		// p-value < 0.1 to be printed

            // DSSTox Clustering
            def similarityTermOverlap = 3;
            def similarityThreshold = 0.50;
            def initialGroupMembership = 3;
            def finalGroupMembership = 3;
            def multipleLingkageThreshold = 0.50;
            def EASEThreshold = 1.0;


            //-------------------------------------------------------------------------------
            //   Load base annotation
            //-------------------------------------------------------------------------------
            def DSSTox2name = [], DSSTox2CASRN = [], CASRN2DSSTox = [];
            def CASRN2funCatTerm = [], funCatTerm2CASRN = [], funCat2CASRN = [], funCatTerm2CASRNCount = [],
                funCat2CASRNCount = [], funCat2termCount = [], term2funCat = [];

            if (args.length < 0) { //was args[0]==null
                println("! Input directory name is not specified ...\n");
                println "! Continuing anyway..."
                //System.exit(0);
            }

            def inputBaseDir = args[0];
            inputBaseDir.replaceAll("//","/");
            def tmpDirSplit = inputBaseDir.split("/");
            def outputBaseDir = 'Output/' + tmpDirSplit[tmpDirSplit.size()-1] + '/';



            new File(outputBaseDir).mkdir(); //makes the directory outputBaseDir
            System.err << "! ----------------------------------------------------------------\n"; //this prints to STDERR
            System.err << "! CASRN enrichment analysis started ... \n";
            System.err << "! ----------------------------------------------------------------\n\n";

            def ANNO = new File("./Annotation/" + "Tox21_PubChemCID_Mapped.txt"); //annotationBaseDir + "Tox21_PubChemCID_Mapped.txt"
            def annoHeaderLine
            ANNO.withReader { reader -> annoHeaderLine = reader.readLine() }
            annoHeaderLine.replaceAll("\r|\n","");
            println "annoHeaderLine:\n" + annoHeaderLine
            println ""

            List<String>  headerSplit = annoHeaderLine.split("\t");
            println "headerSplit:\n" + headerSplit
            println ""
            println "headerSplit class:" + headerSplit.getClass()
            println "headerSplit[0] class:" + headerSplit.getClass()
            println""

            def  DSSToxIndex		= get_column_index (headerSplit, "#DSSTox_RID");
            def  nameIndex			= get_column_index (headerSplit, "TestSubstance_ChemicalName");
            def  CASRNIndex			= get_column_index (headerSplit, "TestSubstance_CASRN");
            def  meshListIndex		= get_column_index (headerSplit, "MeSHTermList");
            def  pharmActListIndex		= get_column_index (headerSplit, "PharmActionList");

            println "DSSToxIndex: " + DSSToxIndex
            println "nameIndex: " + nameIndex
            println "CASRNIndex: " + CASRNIndex
            println "meshListIndex: " + meshListIndex
            println "pharmActListIndex: " + pharmActListIndex
            println ""

            ANNO.withReader('UTF-8') { reader ->
                reader.readLine()
                def line
                while ((line = reader.readLine()) != null) { //was reader.readLines
                    println "line:\n" + line
                    line.replaceAll("\r|\n","");
                    def tmpSplit = line.split("\t");
                    // Load annotation data
                    if ((tmpSplit[nameIndex]!=null) && (!tmpSplit[nameIndex].equals(""))) {
                        println "tmpSplit[DSSToxIndex]: " + tmpSplit[DSSToxIndex]
                        println "tmpSplit[nameIndex]: " + tmpSplit[nameIndex]
                        println "DSSTox2name: " + DSSTox2name
                        //DSSTox2name[tmpSplit[DSSToxIndex]]	= tmpSplit[nameIndex];
                        DSSTox2name[tmpSplit[DSSToxIndex]] = -1
                    }
                    else
                    {
                        DSSTox2name[tmpSplit[DSSToxIndex]]	= '';
                    }

                    if ((tmpSplit[CASRNIndex]!=null) && (!tmpSplit[CASRNIndex].equals("")))
                    {
                        DSSTox2CASRN[tmpSplit[DSSToxIndex]]	= tmpSplit[CASRNIndex];
                        CASRN2DSSTox[tmpSplit[CASRNIndex]][tmpSplit[DSSToxIndex]] = 1;
                        // Update functional category information - PharmActionList
                        if ((tmpSplit[pharmActListIndex]!=null) && (!tmpSplit[pharmActListIndex].equals("")))
                        {
                            def termSplit	= tmpSplit[pharmActListIndex].split(";");
                            termSplit.each
                            {

                            CASRN2funCatTerm[tmpSplit[CASRNIndex]]."PharmActionList".it.value 	= 1;
                            funCatTerm2CASRN."PharmActionList".it.tmpSplit[CASRNIndex] 	= 1;
                            funCat2CASRN."PharmActionList".tmpSplit[CASRNIndex] 		= 1;
                            term2funCat.it."PharmActionList"				= 1;
                                //got this from http://stackoverflow.com/questions/4769111/java-equivalent-of-perls-hash
                            }
                        }

                    }
                }
            }


            //-------------------------------------------------------------------------------
            //  Load MeSH mapping
            //-------------------------------------------------------------------------------
            def MeSH = new File(annotationBaseDir+"Tox21_MeSH_TermHeading_Mapping.txt");
            def CASRN2MeSHMHMapping	= [:];


            MeSH.withReader('UTF-8') { reader ->
                while ((line = reader.readLines())!=null)
                {
                    line.replaceAll("\r|\n","");
                    def tmpSplit = line.split("\t");
                    // Load annotation data
                    if (tmpSplit[1]!=null)
                    {
                        def termSplits	= tmpSplit[1].split(";");
                        CASRN2MeSHMHMapping[tmpSplit[0]]	= termSplits;
                    }
                }
            }
                for(i in CASRN2DSSTox)
                {
                    if (CASRN2MeSHMHMapping["${i}"]!=null)
                    {

                        CASRN2MeSHMHMapping["${i}"].each
                        {
                        CASRN2funCatTerm."${i}"."MeSH".it.value	= 1;
                        funCatTerm2CASRN."MeSH".it."${i}" 	= 1;
                        funCat2CASRN."MeSH"."${i}" 		= 1;
                        term2funCat.it."MeSH"			= 1;
                        }
                    }
                }




            //-------------------------------------------------------------------------------
            //  Load DrugMatrix Annotation
            //-------------------------------------------------------------------------------
            def drugMatrixFiles	= []; //glob ("Annotation/DrugMatrix_*.txt");


            def dir=new File('/web/html/tox21enricher/Annotation');
                dir.eachFileRecurse(FileType.FILES){
                    if (it.getName.contains('DrugMatrix_') && it.getName().contains('.txt'))
                        { drugMatrixFiles.add(it)}
                }



            for( drugMatrixFile in drugMatrixFiles)
            {
                def DRUGMATRIX=new File(drugMatrixFile);
                def tmp1 = drugMatrixFile.split("/");
                def tmp2 = tmp1[tmp1.size()-1].split(".txt");
                tmp2[0]=tmp2[0].drop(12); //removes first twelve chars in tmp2
                if (!funCat2Selected[tmp2[0]])
                {
                    return;
                }



                DRUGMATRIX.withReader('UTF-8') { reader ->
                while ((line = reader.readLines())!=null)
                {
                    line.replaceAll("\r|\n","");
                    def tmpSplit = line.split("\t");
                    def termSplit = tmpSplit[1].split(";");

                    termSplit.each  //make sure this .equals() lol
                    {	CASRN2funCatTerm[tmpSplit[0]].tmp2[0].it.value	= 1;
                        funCatTerm2CASRN[tmp2[0]].it.tmpSplit[0] 	= 1;
                        funCat2CASRN[tmp2[0]].tmpSplit[0] 		= 1;
                        term2funCat[term][tmp2[0]] 			= 1;
                    }
                }
                }

            }


            // Calculate total CASRN count
            for(funCat in funCat2Selected)
            {
                if (!funCat2Selected[funCat])
                {
                    return;
                }
                //****It is likely that this will need work. is funCat a number?
                def tmpArray = funCat2CASRN[funCat].keySet() as String[];
                funCat2CASRNCount[funCat] = tmpArray.size();

                def terms =funCatTerm2CASRN[funCat].keySet() as String[];
                funCat2termCount[funCat] 	= terms.size();

                for(term in terms)
                {
                     tmpArray = funCatTerm2CASRN[funCat].term;
                    funCatTerm2CASRNCount[funCat][term] = tmpArray.size();
                }
            }








            //-------------------------------------------------------------------------------
            //   Load input DSSTox ID or CASRN ID sets
            //-------------------------------------------------------------------------------

            def infiles=[];

             dir=new File(inputBaseDir+"/");
                dir.eachFileRecurse(FileType.FILES){
                    if (it.getName.contains('.txt'))
                        {
                             infiles.add(it);}
                        }

            infiles.each
            {
                def tmp1 = it.split("/");
                def tmp2 = tmp1[tmp1.size()-1].split(".txt");
                System.err << "! Processing file 'tmp2[0]' ...\t";
                def outfileBase = tmp2[0];
                // Check the input file (either using CASRN or DSSTox_RID)
                def  (inputFileType, originalInputIDListHashRef)	= load_input_file_type (infile);
                def  inputIDListHash	= [:];

                // Convert DSSTox_RID to CASRN
                if (inputFileType.contains('DSSTox_RID'))
                {
                    def tempKeyArray = originalInputIDListHashRef.keySet() as String[];
                    originalInputIDListHashRef.each{
                        if ((DSSTox2CASRN[it]!=null) && (!DSSTox2CASRN[it].equals(""))) //ok this is a bit funky. but should work
                        {
                            inputIDListHash.DSSTox2CASRN[it] = 1;
                        }
                    }
                }
                else if (inputFileType.equals('Unknown'))
                {
                    println( "!ERROR! Can't determine the input ID type of infile ...\n\n");
                    System.exit(0);
                }
                else
                {
                    inputIDListHash	= originalInputIDListHashRef;
                }

                // Perform EASE calculation
                def  CASRNs	= inputIDListHash.keySet() as String[];
                if (!perform_CASRN_enrichment_analysis(CASRNs, outputBaseDir, outfileBase))
                {
                    System.err <<  "failure ...\n";
                }
                else
                {
                    System.err << "success ...\n";
                }
            }
            System.err <<  "\n";



            System.err <<  "! ----------------------------------------------------------------\n";
            System.err <<  "! CASRN enrichment analysis completed ... \n";
            System.err <<  "! ----------------------------------------------------------------\n";

            return;

}

            //Sub module #1 ***************************************************************************************************meow
            def perform_CASRN_enrichment_analysis(CasRef, dasOutput, dasBase)
            {	def  CASRNRef				= CasRef;
                def  outputBaseDir			= dasOutput;
                def  outfileBase			= dasBase;

                // Define output file names
                def  outfileChart			= outputBaseDir+outfileBase+'__Chart.txt';
                def  outfileSimple			= outputBaseDir+outfileBase+'__ChartSimple.txt';
                def  outfileCluster			= outputBaseDir+outfileBase+'__Cluster.txt';
                def OUTFILE= new File(outfileChart);
                def SIMPLE= new File(outfileSimple);
                def CLUSTER= new File(outfileCluster);
                OUTFILE.append( "Category	Term	Count	%	PValue	CASRNs	List Total	Pop Hits	Pop Total	Fold Enrichment	Bonferroni	Benjamini	FDR\n");
                SIMPLE.append( "Category	Term	Count	%	PValue	Fold Enrichment	Benjamini\n");
                // Calculate EASE score
                def  inputCASRNs		= CASRNRef;
                def  inputCASRNsCount		= inputCASRNs.size();
                def  term2Contents		= [:];
                def  term2Pvalue		= [:];
                def  sigTerm2CASRNMatrix	= [:];
                def  mappedCASRNs		= check_mapped_CASRN(inputCASRNs);
                // Among the CASRN, use only those included in the full Tox21 list

                funCat2Selected.each{
                    if (funCat2Selected[it])
                    {
                        // Calculate the CASRN counts for the given categories
                        def  (targetTotalCASRNInFunCatCount, targetTotalTermCount)= calculate_funcat_mapped_total_CASRN_count (mappedCASRNs, it);

                        def  funCatTerms	= funCatTerm2CASRN[it].keySet() as String[];
                        def  localTerm2content	= [:];
                        def  localTerm2pvalue	= [:];
                        def  localPvalue2term	= [:];
                        funCatTerms.each{term,valueO ->
                            if (funCatTerm2CASRN[it].term!=null)
                            {
                                // This is a valid term, check if the CASRN count is more than 1
                                def  (targetCASRNsRef, targetCASRNCount)= calculate_funcat_mapped_CASRN_count (mappedCASRNs, it, term, sigTerm2CASRNMatrix);
                                if (targetCASRNCount > 1)
                                {	// Calculate the EASE score
                                    def  np1 	= targetTotalCASRNInFunCatCount -1;
                                    def  n11	= targetCASRNCount - 1;
                                    def  npp 	= funCat2CASRNCount.it.value;
                                    def  n1p 	= funCatTerm2CASRNCount.it.term;

                                    // skip any under-represented terms
                                    def  foldenrichment = (targetCASRNCount/targetTotalCASRNInFunCatCount)/(n1p/npp);

                                    def  pvalue = 1;
                                    /*pvalue = calculateStatistic (
                                            n11 => n11,
                                            n1p => n1p,
                                            np1 => np1,
                                            npp => npp);	*/
            //check
                                    localTerm2content[term] =	it.key+"\t"+
                                                    term+"\t"+
                                                    targetCASRNCount+"\t"+
                                                    (targetCASRNCount/inputCASRNsCount*100)+"\t"+
                                                    pvalue+"\t"+targetCASRNsRef.collect{"'$it'"}.join(", ")+"\t"+
                                                    targetTotalCASRNInFunCatCount+"\t"+
                                                    n1p+"\t"+
                                                    npp+"\t"+
                                                    (targetCASRNCount/targetTotalCASRNInFunCatCount)/(n1p/npp)+"\t"+
                                                            (1-(1-pvalue)**targetTotalTermCount);
                                    localTerm2pvalue[term] = pvalue;
                                    localPvalue2term.pvalue.term=1;
                                }
                            }
                        }



                    // Calculate Benjamini-Hochberg corrected p-value (EASE)
                        def  collectedPvalues		= localPvalue2term.sort();
                        def  pvalue2BHPvalue		= [:];
                        def  rank			= 1;

                        for(i=0;i<collectedPvalues.size();i++)
                        {	pvalue2BHPvalue[collectedPvalues[i]] = collectedPvalues[i] * targetTotalTermCount / rank;
                            if (pvalue2BHPvalue[collectedPvalues[i]] >1)
                            {
                                pvalue2BHPvalue[collectedPvalues[i]] = 1;
                            }
                            rank++;
                        }

                        localTerm2pvalue.each{
                term2Contents[it.key+'|'+it.key]	= localTerm2content[it.key]+"\t"+pvalue2BHPvalue[localTerm2pvalue[it.key]]+"\t"+pvalue2BHPvalue[localTerm2pvalue[it.key]];
                            term2Pvalue[it+'|'+it.key]		= localTerm2pvalue[it.value];
                        }
                    }
                }

                //Sort by the p-values across multiple funCat
                def sortedFunCatTerms		= term2Pvalue.keySet() as String[];
                sortedFunCatTerms= sortedFunCatTerms.sort()
                def sortedFunCatTermsCount	= sortedFunCatTerms.size();
                def simpleFunCatTermCount	= [:];
                def funCatSimpleContent		= [:];
                for(funCatTerm in sortedFunCatTerms)
                {	if (term2Pvalue.funCatTerm > pvalueThresholdToDisplay)
                    {
                        return;
                    }

                    OUTFILE.append(term2Contents[funCatTerm]+"\n");

                    def toSimple = 0;
                    def tmpSplit = term2Contents[funCatTerm].split("\t");
                    if (tmpSplit[9] > 1)
                    {
                        def localFunCat		= get_funCat_from_funCatTerm (funCatTerm);
                        if (simpleFunCatTermCount[localFunCat]==null)
                        {
                            simpleFunCatTermCount[localFunCat] = 1;
                            toSimple = 1;
                        }
                        else if (simpleFunCatTermCount[localFunCat] < 10)
                        {
                            simpleFunCatTermCount[localFunCat]++;
                            toSimple = 1;
                        }

                        if (toSimple)
                        {
                            funCatSimpleContent[localFunCat] =funCatSimpleContent[localFunCat]+ tmpSplit[0]+"\t"+tmpSplit[1]+"\t"+
                            tmpSplit[2]+"\t"+tmpSplit[3]+"\t"+tmpSplit[4]+"\t"+tmpSplit[9]+"\t"+tmpSplit[11]+"\n";
                        }
                    }
                }

                for(funCat in funCatSimpleContent)
                {
                    SIMPLE.append(funCatSimpleContent[funCat]+"\n");
                }




                // ----------------------------------------------------------------------
                //	Perform functional term clustering
                // ----------------------------------------------------------------------
                // 	Step//1: Calculate kappa score
                // ----------------------------------------------------------------------
                def  mappedCASRNCheck		= [:]
                def  mappedCASRNIDs		= [];
                def  posTermCASRNCount		= [:];
                for(funCatTerm in sortedFunCatTerms)
                {
                    def  localCASRNIDs	= sigTerm2CASRNMatrix[funCatTerm].keySet() as String[];
                    posTermCASRNCount.add(funCatTerm : localCASRNIDs.size());//eh..........

                    localCASRNIDs.each
                    {
                        mappedCASRNCheck.add(CASRNID : 1);
                    }
                }

                mappedCASRNIDs			= mappedCASRNCheck.keySet() as String[];
                def  totalMappedCASRNIDCount	= mappedCASRNIDs.size();

                // Calculate kappa score for each term pair
                def  termpair2kappa					=[:];
                def  termpair2kappaOverThresholdCount			=[:];
                def  termpair2kappaOverThreshold			=[:];
                for ( i=0; i < sortedFunCatTermsCount-1; i++)
                {
                    for (j=i+1; j < sortedFunCatTermsCount; j++)
                    {	//calculate_kappa_statistics (
                        def  term1term2		= 0;
                        def  term1only			= 0;
                        def  term2only			= 0;
                        def  term1term2Non		= 0;

                        def  posTerm1Total		= posTermCASRNCount[sortedFunCatTerms[i]];
                        def  posTerm2Total		= posTermCASRNCount[sortedFunCatTerms[j]];
                        def  negTerm1Total		= inputCASRNsCount - posTerm1Total;			// note that the total is inputCASRNsCount not the mapped total
                        def  negTerm2Total		= inputCASRNsCount - posTerm2Total;			// note that the total is inputCASRNsCount not the mapped total
                        //def  $negTerm1Total		= $totalMappedCASRNIDCount - $posTerm1Total;
                        //def  $negTerm2Total		= $totalMappedCASRNIDCount - $posTerm2Total;


                    for(CASRN1 in sigTerm2CASRNMatrix[sortedFunCatTerms[i]].keySet()) //ugh
                        {	if (sigTerm2CASRNMatrix[sortedFunCatTerms[j]]."${CASRN1}"!=null)
                            {
                                term1term2++;
                            }
                            else
                            {
                                term1only++;
                            }
                        }
                        for(CASRN2 in sigTerm2CASRNMatrix[sortedFunCatTerms[j]].keySet())
                        {
                            if (sigTerm2CASRNMatrix[sortedFunCatTerms[i]]."${CASRN2}"==null)
                            {
                                term2only++;
                            }
                        }

                        term1term2Non			= inputCASRNsCount - term1term2 - term1only - term2only;
                        //$term1term2Non			= $totalMappedCASRNIDCount - $term1term2 - $term1only - $term2only;
                        // Calculate the kappa score
                        // http://david.abcc.ncifcrf.gov/content.jsp?file=linear_search.html
                        def Oab			= (term1term2 + term1term2Non)/inputCASRNsCount;
                        def Aab			= (posTerm1Total$posTerm2Total + negTerm1Total*negTerm2Total)/(inputCASRNsCount*inputCASRNsCount);
                        //my $Oab					= ($term1term2 + $term1term2Non)/$totalMappedCASRNIDCount;
                        //my $Aab					= ($posTerm1Total*$posTerm2Total + $negTerm1Total*$negTerm2Total)/($totalMappedCASRNIDCount*$totalMappedCASRNIDCount);

                        if (Aab ==1)
                        {
                            return;
                        }
                        def Kappa		= sprintf("%.2f",(Oab - Aab)/(1-Aab)); //sprintf is ok to use

                        termpair2kappa[sortedFunCatTerms[i]][sortedFunCatTerms[j]] = Kappa;
                        termpair2kappa[sortedFunCatTerms[j]][sortedFunCatTerms[i]] = Kappa;

                        if (Kappa > similarityThreshold)
                        {	termpair2kappaOverThresholdCount[sortedFunCatTerms[i]]			+=1;
                            termpair2kappaOverThresholdCount[sortedFunCatTerms[j]]			+=1;
                            termpair2kappaOverThreshold[sortedFunCatTerms[i]][sortedFunCatTerms[j]] 	= 1;
                            termpair2kappaOverThreshold[sortedFunCatTerms[j]][sortedFunCatTerms[i]] = 1;
                        }


                    }
                }


            // ----------------------------------------------------------------------
                // 	Step//2: Create qualified initial seeding groups
                // ----------------------------------------------------------------------
                //	Each term could form a initial seeding group (initial seeds)
                //   as long as it has close relatioships (kappa > 0.35 or any designated number)
                //   with more than > 2 or any designated number of other members.

                def  qualifiedSeeds	= [];
                for (i=0; i < sortedFunCatTermsCount; i++)
                {	// Seed condition//1: intial group membership
                    if (( termpair2kappaOverThresholdCount[sortedFunCatTerms[i]]!=null) && (termpair2kappaOverThresholdCount[sortedFunCatTerms[i]] >= (initialGroupMembership-1)))
                    {	// Seed condition#2: majority of the members
                        def  (over_percentage, term2sRef) = calculate_percentage_of_membership_over_threshold (termpair2kappaOverThreshold, sortedFunCatTerms[i]);

                        if (over_percentage > multipleLingkageThreshold)
                        {	// this seed group is quialified
                            qualifiedSeeds.push(term2sRef);
                        }
                    }
                }


                // ----------------------------------------------------------------------
                // 	Step//3: Iteratively merge qualifying seeds
                // ----------------------------------------------------------------------
                def  finalGroups	= [];
                def  remainingSeeds	= qualifiedSeeds;

                while(remainingSeeds[0]!=null)
                {	// take the first two of the remaining seeds
                    def  currentSeedRef		= remainingSeeds.take(1);//return first element
                    remainingSeeds.drop(1);	 // shift on an array deletes the first element of the array in perl. in groovy "drop" gets it

                    def  newSeeds			=[];
                    while(get_the_best_seed (currentSeedRef, remainingSeeds, newSeeds))
                    {	// update the current reference seed ref with new seeds
                        currentSeedRef = newSeeds;
                    }

                    // if there in more merge possible, add the current seeds to the final groups
                    finalGroups.push(currentSeedRef);
                }


                // ----------------------------------------------------------------------
                 //	Step#4: Calculate enrichment score and print out the results
                // ----------------------------------------------------------------------
                def clusterHeader = "Category	Term	Count	%	PValue	CASRNs	List Total	Pop Hits	Pop Total	Fold Enrichment	Bonferroni	Benjamini	FDR\n";
                def EASEScore	= [:];
                for (i=0; i <=finalGroups.size(); i++)
                {	EASEScore[i] = calculate_Enrichment_Score (finalGroups[i], term2Pvalue);
                }
                def sortedIndex =	EASEScore.sort({a, b -> a.value <=> b.value}).keySet()​; //This gives you a sorted by value keyset
                def clusterNumber	= 1;
                for(myIndex in sortedIndex)
                {	CLUSTER.append( "Annotation Cluster "+(clusterNumber++)+"\t"+"Enrichment Score: "+EASEScore[myIndex]+"\n");
                    CLUSTER.append( clusterHeader);

                    // sort terms again by p-value
                    sortedFunCatTerms	= finalGroups[myIndex].sort({a, b -> a.value <=> b.value})​;
                    for( myTerm in sortedFunCatTerms)
                    {
                        CLUSTER.append(term2Contents[myTerm]+"\n");
                    }
                    CLUSTER.append("\n");
                }


                return (1);
            }



            //BEGINNING OF modules


            def get_funCat_from_funCatTerm(aFunKitty)
            {	def funCatTerm	= aFunKitty;
                def tmpSplit = funCatTerm.split("|");
                return(tmpSplit[0]);
            }


            def calculate_Enrichment_Score(first, second)
            {	def groupRef		= first;
                def term2PvalueRef	= second;

                def EASESum			= 0;
                for(term in groupRef)
                {	if (term2PvalueRef[term] == 0)
                    {
                        EASESum		+= 16;
                    }
                    else
                    {
                        EASESum		+= -1*(Math.log(term2PvalueRef[term]))/Math.log(10);
                    }
                }
                def enrichmentScore = EASESum / groupRef.size();
                return enrichmentScore;
            }


            def get_the_best_seed(first,second,third)
            {	def  currentSeedRef			= first;
                def  remainingSeedsRef			= second;
                def  newSeedRef			= third;

                def  bestOverlapping			= 0;
                def  bestSeedIndex			= '';
                def  currentSeedTerms			= currentSeedRef;
                def  currentSeedTermCount		= currentSeedTerms.size();
                def  currentSeedTermHash		= [];
                for( term in currentSeedTerms)
                {
                    currentSeedTermHash[term] = 1;
                }

                for (i=0; i < remainingSeedsRef.size(); i++)
                {	// calculate the overlapping
                    def  secondSeedTerms	= remainingSeedsRef[i];
                    def  commonCount	= 0;
                    def  totalCount		= secondSeedTerms.size();

                    for(term in secondSeedTerms)
                    {	if (currentSeedTermHash[term]!=null)
                        {
                            commonCount++;
                        }
                    }

                    def  overlapping	= 2*commonCount / (currentSeedTermCount + totalCount);
                    //my $overlapping	= $commonCount / ($currentSeedTermCount + $totalCount - $commonCount);
                    // !CHECK! '>' or '>='
                    //if ($overlapping >= $multipleLingkageThreshold)
                    if (overlapping > multipleLingkageThreshold)
                    {	if (bestOverlapping < overlapping)
                        {	bestOverlapping 	= overlapping;
                            bestSeedIndex		= i;
                        }
                    }
                }

                if (bestOverlapping == 0)
                {	// no more merging is possible
                    return (0);
                }
                else
                {	// best mergable seed found
                    def  newSeedTermsHash = [:];
                    for(term in currentSeedTerms)
                    {
                        newSeedTermsHash[term] = 1;
                    }
                    for(term in remainingSeedsRef[bestSeedIndex])
                    {
                        newSeedTermsHash[term] = 1;
                    }

                    newSeedRef	= newSeedTermsHash.keySet();
                    remainingSeedsRef[bestSeedIndex..1]; // this was a splice function
                    return (1);
                }
            }




            def calculate_percentage_of_membership_over_threshold(first,second)
            {	def termpair2kappaOverThresholdRef		= first;
                def currentTerm					= second;

                def term2s	= termpair2kappaOverThresholdRef[currentTerm].keySet();
                second=second.reverse()
                for (u in second)	//gives each item in the list
                {
                    term2s.add(0,u); // we reversed it, now we add it to front of array
                }
                        //unshift @term2s, $currentTerm; <--ORIGINAL

                // calculate
                def totalPairs	= 0;
                def passedPair	= 0;

                for (i=0; i < term2s.size(); i++)
                {	for (j=i+1; j <= term2s.size(); j++)
                    {	totalPairs++;
                        if (termpair2kappaOverThresholdRef[term2s[i]][term2s[j]]!=null)
                        {
                            passedPair++;
                        }
                    }
                }

                return[passedPair/totalPairs, term2s];
            }


            def check_mapped_CASRN(oneItem)
            {	def CASRNsRef			= oneItem;
                def mappedCASRNHash		= [:];
                for(CASRN in CASRNsRef)
                {	if (CASRN2DSSTox[CASRN]!=null)
                    {
                        mappedCASRNHash[CASRN] = 1;
                    }
                }
                def mappedCASRNs	= mappedCASRNHash.keySet();
                return (mappedCASRNs);
            }


            def calculate_funcat_mapped_total_CASRN_count(first, second)
            {	def mappedCASRNsRef		= first;
                def funCat			= second;

                def totalCount			= 0;
                def localTermHash		= [:];
                for(CASRN in mappedCASRNsRef)
                {	if (CASRN2funCatTerm[CASRN][funCat]!=null)
                    {	totalCount++;
                        def terms = (CASRN2funCatTerm[CASRN][funCat]).keySet();
                        for(term in terms)
                        {
                            localTermHash[term] = 1;
                        }
                    }
                }
                def localTerms			= localTermHash.keySet();
                return [totalCount, localTerms.size()];
            }


            def calculate_funcat_mapped_CASRN_count(first, second, third,fourth)
            {	def mappedCASRNsRef		= first;
                def funCat			= second;
                def  term			= third;
                def  sigTerm2CASRNMatrixRef	= fourth;

                def  CASRNCount		= 0;
                def  targetCASRNs	= [];
                for(CASRN in mappedCASRNsRef)
                {	if (funCatTerm2CASRN[funCat][term][CASRN]!=null)
                    {	CASRNCount++;
                        targetCASRNs.push(CASRN);
                        sigTerm2CASRNMatrixRef[funCat+"|"+term][CASRN] = 1;
                    }
                }
                return [targetCASRNs, CASRNCount];
            }


            def static get_column_index(ArrayList first, String second)
            {	def  headerRef = first;
                def  term = second;
                def  status = -1;

                def  pubchemIndex = '';
                if ((term==null) || (term.equals(""))) {
                    println "Returning status"
                    return (status);
                }

                // Check exact match
                for (def i = 0; i < headerRef.size(); i++) {
                    if(headerRef[i].equals(term)) {
                        println "${headerRef[i]} = ${term}"
                        println "Returning ${first.indexOf(second)}"
                        return (i);
                    }
                }
                /*
                if (!pubchemIndex)
                {	for ( i=0; i < headerRef.size(); i++)
                    {
                        if (headerRef[i] =~ /term(i?)/)
                        {
                            return (i);
                        }
                    }
                }
                */
                return (status);
            }


            def load_input_file_type(first)
            {
                def  infile		= first;
                def  fileType		= '';
                def  inputIDHash	= [:];
                def INFILE = new File(infile);

                INFILE.withReader('UTF-8') { reader ->
                    while ((line = reader.readLines())!=null)
                    {
                        line.replaceAll("\r|\n","");
                        def tmpSplit = line.split("\t");

                        if (( tmpSplit[0] ==~ /(\d{2,7}-\d\d-\d)/) || ( tmpSplit[0] ==~ /NOCAS_\d+/)) //this regex work?
                        {
                            fileType	= 'CASRN';
                            inputIDHash[tmpSplit[0]]		= 1;
                        }
                        else if (tmpSplit[0] !=~ /\D/)
                        {
                            fileType	= 'DSSTox_RID';
                            inputIDHash[tmpSplit[0]]		= 1;
                        }
                        else
                        {
                            fileType	= 'Unknown';
                        }
                }}
                if (!fileType.equals("Unknown")){
                INFILE.withReader('UTF-8') { reader ->
                    while ((line = reader.readLines())!=null)
                    {
                        line.replaceAll("\r|\n","");
                        def tmpSplit = line.split("\t");
                        inputIDHash[tmpSplit[0]]		= 1;
                    }
                         }
                }

                return [fileType, inputIDHash];
            }










            }










