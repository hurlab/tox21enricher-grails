package tox21_test

import grails.util.Holders
import grails.rest.*
import groovy.sql.Sql
import groovy.transform.CompileStatic
import net.sf.json.JSON
import org.postgresql.util.PSQLException
import org.springframework.beans.factory.InitializingBean

//for concurrency/async
import static groovyx.gpars.actor.Actors.actor
//import static groovyx.gpars.group.DefaultPGroup
//import static groovyx.gpars.*
//import static groovyx.gpars.GParsPool
import static grails.async.Promises.*
import static grails.async.web.WebPromises.*
import grails.http.client.*
import grails.async.*
import grails.events.*
import java.util.concurrent.*
import java.util.*
import org.grails.web.util.WebUtils
import java.lang.management.ManagementFactory
import groovyx.net.http.*

import org.springframework.web.context.request.RequestContextHolder
import org.springframework.web.context.request.RequestAttributes

//files
import static groovy.io.FileType.FILES
import java.util.zip.ZipOutputStream
import java.util.zip.ZipEntry
import java.nio.channels.FileChannel

//does the same thing as AnalysisController, but:
// 1) accepts JSON from a POST message
// 2) performs enrichment analysis as normal
// 3) responds with a link to download the .zip of the enrichment results
class ApiAnalysisController extends RestfulController<ApiAnalysis> implements InitializingBean, EventPublisher {
    static responseFormats = ['json','html', 'xml']
    static scope = "singleton"


    ApiAnalysisController() {
        super(ApiAnalysis)
    }
    ApiAnalysisService apiAnalysisService

    def storageProperties
    def scriptLocationProperties
    def dataSource

    def config = Holders.getGrailsApplication().config
    def EXT_SCRIPT_PATH_PERL
    def EXT_SCRIPT_PATH_GROOVY = config.constants.paths.scripts.groovy
    def ENRICH_INPUT_PATH
    def ENRICH_OUTPUT_PATH
    def DEBUG = 1
    def TEST_GROOVY = 0
    def TEST_PERL = 0
    def GROOVY_PERL_KVP = 0

    def actorGroup = new groovyx.gpars.group.DefaultPGroup(5)//change value to allow different #s of concurrent enrichment processes

    boolean loadExternalBeans() {
        true
    }   
    
    def enrich() {         
            //render "This needs to be here for it to work correctly for some reason\n"
            //respond(["I AM HERE"])
            
            RequestAttributes requestContext = RequestContextHolder.getRequestAttributes() //set the requestContext variable to the context of the most recent web request sent to the controller
            
            //to allow each thread to access its request's specific params
            def paramsThread = params

            

            //listens for a new request, if a thread is free, then starts enrichment process for that dataset
            def enrichmentProcess = actorGroup.actor { 
                loop {
                    react { queuePos -> //grab queue item
                        RequestContextHolder.setRequestAttributes(requestContext)//set HTTP request attributes
                        //do enrichment after we're done waiting in the queue
                        println("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
                        println("Transaction $queuePos is beginning enrichment...")
                        println("[REQUEST CONTEXT QUEUE]: ${RequestContextHolder.currentRequestAttributes()}")
                        println("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")

                        def _params = queuePos[0]   //this will grab the parameters from the item popped from the queue, really just need it to get the transaction id
                        dataSource = queuePos[1]    //this will grab the dataSource from the item popped from the queue, probably an easier way to do this

                        //println("_params: ${_params}")
                        //println("_params id: ${_params.apiAnalysisId}")

                        def CASRNBox
                        def casrnInput = []  //need this from json //this will be a list of all CASRNs used as input (if enrichAnalysisType = CASRN) minus the set names (e.g. #Set1) for the purposes of error handling
                        def goodCasrns = []
                        def errorCasrns = []
                        casrnService.setTox21CasrnList()
                        def tox21Casrns = casrnService.getTox21CasrnList()
                        //println tox21Casrns
                        def annoSelectStr = "" //need this from json
                        def groovyParams// = params
                        def psqlErrorSmiles = []
                        def psqlGoodSmiles = []
                        def smiles = [] //need this from json
                        def smilesWithResults = []
                        def smilesNoResults = []
                        def enrichAnalysisType = "none" //need this from json


                        //initialize datasource and fetch db entry to enrich from db
                        def initSql = new Sql(dataSource_psql)
                        def paramsDb = initSql.firstRow("SELECT * FROM api_analysis WHERE id = $_params.apiAnalysisId")

                        groovyParams = paramsDb

                        smiles = paramsDb.smiles
                        annoSelectStr = paramsDb.anno_select_str
                        //casrnInput = paramsDb.casrn_input
                        enrichAnalysisType = paramsDb.enrich_analysis_type
                        

                        //If we're using SMILE input
                        //query psql to get our CASRNs.
                        if (paramsDb.analysis_type == "SMILES") {
                            enrichAnalysisType = "SMILES"
                            resultSetService.setAnalysisType(enrichAnalysisType)
                            if (paramsDb.smile_box == "" || paramsDb.smile_box == null) {
                                render(view: "form", model: [isSmileErrors: true, noSmileInput: true])
                                return
                            }
                            def psqlErrorMessage
                            paramsDb.casrn_box = "";
                            def sql = new Sql(dataSource_psql)
                            def curSet = 1
                            paramsDb.smile_box.eachLine { smile, lineNumber ->
                                println "-------------|" + smile + "|-------------"
                                smiles + smile
                            }

                            def setThresholdQuery
                            def threshold
                            //validate input because we can't sanitize with prepared statement because prepared statement isn't working here for some reason
                            try {
                                threshold = Float.parseFloat(paramsDb.threshold_select_value)
                                setThresholdQuery = "set rdkit.tanimoto_threshold=" + threshold
                            }
                            catch (NumberFormatException e) {
                                e.printStackTrace()
                                println(e.getMessage())
                            }
                            //println("THRESHOLD QUERY: ${setThresholdQuery}")
                            //println("DATA BINDING: ${threshold}")
                            def ret = sql.execute(setThresholdQuery)
                            //println("RET: " + ret)

                            

                            paramsDb.smile_box.eachLine { smile, lineNumber ->
                                //check if substructure search or similarity search
                                def query
                                if (paramsDb.smiles_search_type == "Substructure") {
                                    query = "select casrn from mols where m @> CAST(? AS mol)"
                                }
                                else if (paramsDb.smiles_search_type == "Similarity") {

                                    query = "select casrn from get_mfp2_neighbors('CAST(? AS mol)');"
                                } else {
                                    //something went wrong if we're here
                                    println("Something went wrong with smilesSearchType.");
                                }
                                
                                //Try/catch block to catch invalid SMILEs
                                try {
                                    def resultSet
                                    if (params.smilesSearchType == "Substructure") {
                                        resultSet = sql.rows("select casrn from mols where m @> '$smile';")
                                    }
                                    else if (params.smilesSearchType == "Similarity") {
                                        resultSet = sql.rows("select casrn from get_mfp2_neighbors('$smile');")
                                    }

                                    psqlGoodSmiles.add([index: lineNumber, smile: smile])
                                    if (resultSet.size() > 0) {
                                        paramsDb.casrn_box += "#Set" + curSet + "\n"
                                        curSet++
                                        resultSet.each { result ->
                                            paramsDb.casrn_box += result.casrn + "\n"
                                        }
                                        smilesWithResults.add(smile)
                                    }
                                }
                                catch (PSQLException e) {
                                    
                                    psqlErrorMessage = e.getMessage()
                                    if (psqlErrorMessage.contains(PSQL_SMILE_ERROR)) {
                                        //Add the smile and the line in the input set it occurred on.
                                        //This will allow us to give a useful message such as:
                                        //"SMILE on line 5 is invalid."
                                        psqlErrorSmiles.add([index: lineNumber, smile: smile])
                                    } else {
                                        //TODO: "Unknown database error"
                                    }
                                }
                            }

                            

                            resultSetService.setSmilesWithResults(smilesWithResults)

                            //get list of SMILES that did not yield CASRN results
                            smiles.each { itSmiles ->
                                if (!smilesWithResults.contains(itSmiles)) {
                                    smilesNoResults.add(itSmiles)
                                }
                            }

                            

                            resultSetService.setSmilesNoResults(smilesNoResults)

                            //println "----------------------------------PSQL ERROR SMILES:"
                            //println psqlErrorSmiles
                            //println "----------------------------------PSQLERRORSMILES.EMPTY:"
                            //println psqlErrorSmiles.empty
                            if (!psqlErrorSmiles.empty) {
                                render(view: "form", model: [isSmileErrors: true, psqlErrorSmiles: psqlErrorSmiles, psqlGoodSmiles: psqlGoodSmiles])
                                return
                            }
                            //println "----------------------------------SMILES LIST:"
                            //println smiles
                            //println "----------------------------------SMILES WITH RESULTS LIST:"
                            //println smilesWithResults
                            //println "----------------------------------SMILES NO RESULTS LIST:"
                            //println smilesNoResults
                        }

                        //set enrichAnalysisType = CASRNS if it wasn't SMILES
                        //this will then be passed to our view which
                        //will in turn allow us to display results based on input type
                        else {
                            enrichAnalysisType = "CASRNS"
                            resultSetService.setAnalysisType(enrichAnalysisType)
                            println "PARAMSDB.CASRN_BOX:${paramsDb.casrn_box}:"
                            if (paramsDb.casrn_box == "") {
                                println "IN IF"
                                render(view: "form", model: [isCasrnErrors: true, noCasrnInput: true])
                                return
                            }
                        }

                        println "##########################ENRICH ANALYSIS TYPE: $enrichAnalysisType"

                        //insert set name if no set name detected
                        if (!groovyParams["casrn_box"].toString().contains("#")) {
                            groovyParams["casrn_box"] = "#Set1\n" + groovyParams["casrn_box"]
                            println("Added '#Set1' to groovyParams['casrn_box']")
                        }

                        //Enrichment now continues as it would
                        //if the user gave CASRN input.
                        paramsDb.casrn_box = paramsDb.casrn_box.trim();
                        print "Input path for enrichment: $ENRICH_INPUT_PATH\n\n"
                        print "BEGIN PARAMS:\n"
                        print "$paramsDb\n"

                        def count = 0
                        for (i in paramsDb) {
                            count++
                            println "Count is $count"
                            if (i.key.contains("_")) {
                                //continue;
                            }
                            if (i.key == "casrn_box") {
                            println("I am putting the casrns into the box here.")
                                println(">[casrn]> $i.value")
                                CASRNBox = i.value
                                continue;
                            }
                            print "key = ${i.key}, value = ${i.value}\n"
                        }
                        print "CASRNBox: $CASRNBox\n"
                        print "END PARAMS.\n"

                        //check CASRNs for validity
                        //validity in this case being their existence in our database
                        if (enrichAnalysisType == "CASRNS") {
                            CASRNBox.eachLine {casrn, lineNumber ->
                                    casrn = casrn.trim()
                                    println "CASRN  <" + casrn + ">"
                                    casrnInput.add([index: lineNumber, casrn: casrn])
                            }
                        }


                        println "CASRN input:"
                        println casrnInput


                        def setNameSplit
                        def setName
                        casrnInput.each {itCasrn ->
                                println("--->dealing with $itCasrn")
                                if (tox21Casrns.contains(itCasrn.casrn)) {
                                    goodCasrns.add(itCasrn.casrn)
                                } else if (itCasrn.casrn == "") {
                                    return
                                } else {
                                    if (itCasrn.casrn.startsWith('#')) {
                                        setNameSplit = itCasrn.casrn.split('#')
                                        setName = setNameSplit[1].replaceAll("\\s", "")
                                        goodCasrns.add(itCasrn.casrn)
                                        return
                                    }
                                    errorCasrns.add([index: itCasrn.index, casrn: itCasrn.casrn, set: setName])
                                }
                        }

                        println "GOOD CASRNS: "
                        println goodCasrns
                        println "ERROR CASRNS: "
                        println errorCasrns

                        def postParamTranslationMap = [
                                mesh_term: "MESH",
                                pharm_action: "PHARMACTIONLIST",
                                activity_class: "ACTIVITY_CLASS",
                                adverse_effect: "ADVERSE_EFFECT",
                                indication: "INDICATION",
                                known_toxicity: "KNOWN_TOXICITY",
                                mechanism: "MECHANISM",
                                mech_level1: "MECH_LEVEL_1",
                                mech_level2: "MECH_LEVEL_2",
                                mech_level3: "MECH_LEVEL_3",
                                mesh_level1: "MESH_LEVEL_1",
                                mesh_level2: "MESH_LEVEL_2",
                                mesh_level3: "MESH_LEVEL_3",
                                mode_class: "MODE_CLASS",
                                product_class: "PRODUCT_CLASS",
                                structure_activity: "STRUCTURE_ACTIVITY",
                                therapeutic_class: "THERAPEUTIC_CLASS",
                                tissue_toxicity: "TISSUE_TOXICITY",
                                //zero_class: "ZERO_CLASS",
                                ta_level1: "TA_LEVEL_1",
                                ta_level2: "TA_LEVEL_2",
                                ta_level3: "TA_LEVEL_3",
                                pathway: "CTD_PATHWAY",
                                chem2disease: "CTD_CHEM2DISEASE",
                                ctd_chem2gene25: "CTD_CHEM2GENE_25",
                                go_biop: "CTD_GO_BP",
                                drugbank_targets: "DRUGBANK_TARGETS",
                                drugbank_atc_code: "DRUGBANK_ATC_CODE",
                                toxins_targets: "TOXINS_TARGETS",
                                leadscope_toxicity: "LEADSCOPE_TOXICITY",
                                multicase_tox_prediction: "MULTICASE_TOX_PREDICTION",
                                tox_ref_db: "TOXREFDB",
                                hts_active: "HTS_ACTIVE",
                                tox_cast: "TOXCAST",
                                tox_print_structure: "TOXPRINT_STRUCTURE"
                        ]

                        //Translate _params to the format the perl scripts expect.
                        for (j in groovyParams) {
                            if (j.value == "on" && postParamTranslationMap.containsKey(j.key)) {
                                annoSelectStr += postParamTranslationMap[j.key.toString()] + "=checked "
                            }
                        }

                        //println("ANNO SELECT STR: $annoSelectStr")

                        //print "$currentCacheDirString\n"

                        //change from incremental to UUID
                        def final CACHE_DIR = UUID.randomUUID().toString()

                        def currentInputDir = ENRICH_INPUT_PATH + "/" + CACHE_DIR
                        def currentOutputDir = ENRICH_OUTPUT_PATH + "/" + CACHE_DIR

                        //Don't try to add any files to output before this happens. The directory gets deleted if it already exists.
                        def numSets = 0
                        def outDir = new File(currentOutputDir)
                        if (outDir.exists()) {
                            outDir.deleteDir()
                            outDir.mkdirs()
                        } else {
                            outDir.mkdirs()
                        }

                        def inputDir = new File(currentInputDir);
                        if (inputDir.exists()) {
                            inputDir.deleteDir()
                            inputDir.mkdirs()
                        } else {
                            inputDir.mkdirs()
                        }

                        //Create errorCasrns.txt to serve on results page
                        //errorCasrns can't have any items with null sets, which may have happened during errorCasrn generation
                        errorCasrnService.writeErrorCasrnsToFile(currentOutputDir, errorCasrns)

                        def invalidCharacters = "[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_]"

                        //TODO: Migrate code into service(?)
                        //Create input files
                        //Needs errorCasrns to be created and populated
                        if (groovyParams.containsKey("casrn_box")) {
                            File inputFile = null;
                            groovyParams["casrn_box"].toString().eachLine({
                                line ->
                                    //new set name
                                    if (line.startsWith("#")) {
                                        numSets++
                                        //sanitize for filename
                                        line = line.replaceAll(invalidCharacters, "")
                                        //TODO: Figure this guy out...
                                        line = line.replaceAll("\\^", "")
                                        if (line.length() > SET_NAME_MAX_LEN) {
                                            line = line.take(SET_NAME_MAX_LEN);
                                        }
                                        inputFile = new File(currentInputDir, line + ".txt")
                                    } else {
                                        //trim empty lines
                                        //check if line is invalid casrn - if so, don't put in input file
                                        //TODO: this is not efficient
                                        //TODO: try just using errorCasrns.contains(line.trim())
                                        if (line.trim().length() != 0) {
                                            def errorCasrn = false
                                            errorCasrns.each {
                                                if (it.casrn == line.trim()) {
                                                errorCasrn = true
                                                }
                                                else { return }
                                            }
                                            if (errorCasrn) {
                                                return
                                            }
                                            else {
                                                //TODO: move to somewhere before here
                                                //Better yet, make it its own method
                                                //FYI: sql.rows() returns a list of maps
                                                //where each map is field names and values for a given record
                                                def sql = new Sql(dataSource_psql)
                                                def rows = sql.rows("SELECT TestSubstance_ChemName FROM chemical_detail WHERE CASRN LIKE '" + line + "'")
                                                //println("Line: " + line)
                                                //println("Rows: " + rows)
                                                inputFile << line
                                                inputFile << "\t"
                                                //get the first -- and only -- row
                                                def ret = rows[0]
                                                //get the chemical name from the first -- and only -- key/value pair
                                                def chemicalName = ret["TestSubstance_ChemName"]
                                                inputFile << chemicalName
                                                inputFile << "\n"
                                            }
                                        }
                                    }
                            })
                        }

                        //enrichment analysis
                        //print "Path to enrichment input: $ENRICH_INPUT_PATH\n"
                        //println "Current input dir: $currentInputDir"
                        //println "Current output dir: $currentOutputDir"
                        //println "Annotation selection string: $annoSelectStr"
                        //print "Calling enrichment analysis perl script...\n"
                        enrichmentService.performEnrichment(currentInputDir, currentOutputDir, annoSelectStr)
                        //print "Enrichment completed.\n"

                        //create .xls files
                        new File(currentOutputDir).eachFileRecurse(FILES) {
                            if (it.name.endsWith('__Chart.txt') || it.name.endsWith('__ChartSimple.txt') || it.name.endsWith('__Cluster.txt')) {
                                def txtFileName = it.name
                                def tmp = txtFileName.tokenize(".")
                                def xlsFileName = tmp[0] + ".xls"
                                def src = new File("$currentOutputDir" + "/" + "$txtFileName")
                                def dst = new File("$currentOutputDir" + "/" + "$xlsFileName")
                                dst << src.text
                                //print "Copied $txtFileName to $xlsFileName\n"
                            }
                        }

                        //gct file creation and heatmap generation
                        print "Beginning gct file creation for single set...\n"
                        enrichmentService.createIndividualGCT(currentInputDir, currentOutputDir)
                        print "Beginning heatmap image creation...\n"
                        enrichmentService.createClusteringImages("$currentOutputDir" + "/gct_per_set/ -color=BR")
                        print "Done creating heatmap images for single set.\n"

                        //multi set heatmap creation
                        if (numSets > 1) {
                            print "Beginning gct file creation for multiple sets...\n"
                            enrichmentService.createDavidChart(currentOutputDir)
                            print "Done creating gct files for multiple sets.\n"
                            print "Beginning heatmap image creation...\n"
                            enrichmentService.createClusteringImages("$currentOutputDir" + "/gct/")
                            print "Done creating heatmap images.\n"
                        }

                        //generate zip file for results
                        //TODO: Hammer out zip creation (take all files inside output dir, not the dir itself)
                        def resultsZip = resultSetService.compressResultSet(CACHE_DIR)

                        //redirect to results page
                        //this will have to be different depending on API or web app. will have to render results to user differently.
                        def responseMsg = ["curl -O /localhost:8080/tox21enricher/analysisResults/downloadFile/resultSet=${CACHE_DIR}&filename=tox21enricher.zip"]
                        respond responseMsg, [model: [responseMsg : responseMsg]]
                        //reply threadBoundActor()
                        reply "success"
                    } //end react
                } //end loop

            }//end of enrichmentProcess

                

            //queue
            def queue = actor {
                def queueListItem = [paramsThread, dataSource_psql]

                //thread debug
                println("\n######THREAD DEBUG INFORMATION ######")
                println("Received Transaction ID: ${queueListItem}!")
                println("[Enrichment Process] thread pool size: ${actorGroup.getPoolSize()}")
                println("#####################################\n")
                //end thread debug
                
                enrichmentProcess.send queueListItem //send item from queue
                react {actorid ->
                    println(">>> enrichment success! Freeing thread for actor: $actorid")
                }
        }//end of queue
        queue.join()    
                

    }//end of enrichment method 

    //PSQL invalid SMILE Error
    def SET_NAME_MAX_LEN = 50

    //Inject service beans via autowiring
    def final PSQL_SMILE_ERROR = "could not create molecule from SMILES"
    def resultSetService
    def enrichmentService
    def directoryCompressionService
    def errorCasrnService

    //Inject Postgresql datasource
    def casrnService

    //Where it all starts.
    def dataSource_psql

    def index() {
        //render (view: "form")
    }

    @Override
    void afterPropertiesSet() throws Exception {
        this.ENRICH_INPUT_PATH = storageProperties.getInputDir()[0..-2]
        this.ENRICH_OUTPUT_PATH = storageProperties.getBaseDir()[0..-2]
        this.EXT_SCRIPT_PATH_PERL = scriptLocationProperties.getPerlScriptDir()
    }


}
