package tox21_test

import grails.util.Holders
import groovy.sql.Sql
import net.sf.json.JSON
import org.postgresql.util.PSQLException
import org.springframework.beans.factory.InitializingBean
import org.springframework.web.servlet.ModelAndView

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

//file
import static groovy.io.FileType.FILES
import java.util.zip.ZipOutputStream
import java.util.zip.ZipEntry
import java.nio.channels.FileChannel

class AnalysisController implements InitializingBean {
    static scope = "singleton"

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
    def queueGroup = new groovyx.gpars.group.DefaultPGroup(1)

    def transactionQueue = []
    def queueDataList = []

    def queueMessenger(def transactionData) { //initial display of the queue for the user UI
        //transactionData:: 0 = context | 1 = id | 2 = queue position | 3 = params | 4 = result link | 5 = node cutoff value
        println(">>> Notifying ${transactionData[1]} of queue position!")

        def itemBox
        if (transactionData[3].analysisType == "CASRNS") {
            itemBox = transactionData[3].CASRNBox
        }
        else { //smiles
            itemBox = transactionData[3].SMILEBox
        }
        
        //put transaction data in queue
        setQueueData(transactionData)

        println(">>> Set ${transactionData[1]} in queue!")

        render(view: "form", model: [tid: transactionData[1], pos: transactionData[2], type: transactionData[3].analysisType, items: itemBox, success: transactionData[4], nodeCutoff: transactionData[5]])
    }

    def setQueueData(def transactionData) { //put item into queue (enqueue)
        queueDataList << transactionData
    }

    def getQueueData() { //update queue display as we are waiting in the queue
        for(int i = 0; i < queueDataList.size(); i++) {
            if(params.tid == queueDataList[i][1]) {
                def itemBox
                if (queueDataList[i][3].analysisType == "CASRNS") {
                    itemBox = queueDataList[i][3].CASRNBox
                }
                else { //smiles
                    itemBox = queueDataList[i][3].SMILEBox
                }
                println("| REFRESHED DATA FOR ${queueDataList[i][1]}")
                render(view: "form", model: [tid: queueDataList[i][1], pos: queueDataList[i][2], type: queueDataList[i][3].analysisType, items: itemBox, success: queueDataList[i][4], nodeCutoff: queueDataList[i][5]])
                return
            }
        }
    }

    def getQueueDataEnd(def transId) { //update queue display when enrichment is done. Send user to /enrich page which redirects to result set
        println("| REFRESHING QUEUE DATA")
        for(int i = 0; i < queueDataList.size(); i++) {
            if(transId == queueDataList[i][1]) {
                def itemBox
                if (queueDataList[i][3].analysisType == "CASRNS") {
                    itemBox = queueDataList[i][3].CASRNBox
                }
                else { //smiles
                    itemBox = queueDataList[i][3].SMILEBox
                }
                println("| REFRESHED END DATA FOR ${queueDataList[i][1]}")
                render(view: "enrich", model: [tid: queueDataList[i][1], pos: queueDataList[i][2], type: queueDataList[i][3].analysisType, items: itemBox, success: queueDataList[i][4], nodeCutoff: queueDataList[i][5]])
                return
            }
        }
    }

    def getQueueDataSuccess(def idToUpdate, def resultLink, def nodeCutoff) { //update queue display w/ result link after enrichment is done
    println("| adding result link")
        for(int i = 0; i < queueDataList.size(); i++) {
            if(idToUpdate == queueDataList[i][1]) {
                queueDataList[i][4] = resultLink
                queueDataList[i][5] = nodeCutoff
            }
        }
    }

    def decrementQueue() { //decrements queue position of each item in list and removes the most recent item that finished
        for(int i = 0; i < queueDataList.size(); i++) {
            if(queueDataList[i][2] > 0) {
                queueDataList[i][2]--
            }
        }
    }

    def deleteQueueItem(def idToDelete) { //delete finished item from queue when done
        for(int i = 0; i < queueDataList.size(); i++) {
            if(queueDataList[i][1] == idToDelete) {
                queueDataList.remove(i)
            }
        }
    }


    def enrich() {
            

            RequestAttributes requestContext = RequestContextHolder.getRequestAttributes() //set the requestContext variable to the context of the most recent web request sent to the controller

            //to allow each thread to access its request's specific params
            def paramsThread = params
            println("PARAMS: $paramsThread")

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
                        def _transactionId = queuePos[2] //id for queue position

                        def CASRNBox
                        def casrnInput = []  //this will be a list of all CASRNs used as input (if enrichAnalysisType = CASRN) minus the set names (e.g. #Set1) for the purposes of error handling
                        def goodCasrns = []
                        def errorCasrns = []
                        casrnService.setTox21CasrnList()
                        def tox21Casrns = casrnService.getTox21CasrnList()
                        //println tox21Casrns
                        def annoSelectStr = ""
                        def groovyParams = params
                        def psqlErrorSmiles = []
                        def psqlGoodSmiles = []
                        def smiles = []
                        def smilesWithResults = []
                        def smilesNoResults = []
                        def enrichAnalysisType = "none"
                                        
                        //println("params: $params")

                        //If we're using SMILE input
                        //query psql to get our CASRNs.
                        if (params.analysisType == "SMILES" || params.analysisType == "SMILESSimilarity") {

                            //
                            if(params.analysisType == "SMILESSimilarity") {
                                params.SMILEBox = params.SMILESimilarityBox
                                params.smilesSearchType = "Similarity"
                            }
                            else {
                                params.smilesSearchType = "Substructure"
                            }



                            enrichAnalysisType = "SMILES"
                            resultSetService.setAnalysisType(enrichAnalysisType)
                            if (params.SMILEBox == "") {
                                render(view: "form", model: [isSmileErrors: true, noSmileInput: true])
                                return
                            }
                            def psqlErrorMessage
                            params.CASRNBox = "";
                            def sql = new Sql(dataSource_psql)
                            def curSet = 1
                            params.SMILEBox.eachLine { smile, lineNumber ->
                                //println "-------------|" + smile + "|-------------"
                                smiles.add(smile)
                            }

                            def setThresholdQuery
                            def threshold
                            //validate input because we can't sanitize with prepared statement because prepared statement isn't working here for some reason
                            try {
                                //println("thresholdSelectValue: ${params.thresholdSelectValue}")
                                threshold = Float.parseFloat(params.thresholdSelectValue)/100
                                setThresholdQuery = "set rdkit.tanimoto_threshold=" + threshold + ";"
                            }
                            catch (NumberFormatException e) {
                                e.printStackTrace()
                                println(e.getMessage())
                            }
                            //println("THRESHOLD QUERY: ${setThresholdQuery}")
                            //println("DATA BINDING: ${threshold}")
                            def ret = sql.execute(setThresholdQuery)
                            //println("RET: " + ret)

                            params.SMILEBox.eachLine { smile, lineNumber ->
                                //check if substructure search or similarity search
                                def query
                                if (params.smilesSearchType == "Substructure") {
                                    //println("---> analysis type: SMILES Substructure")
                                    query = "select casrn from mols where m @> CAST(? AS mol);"
                                }
                                else if (params.smilesSearchType == "Similarity") {
                                    //println("---> analysis type: SMILES Similarity")
                                    query = "select casrn from get_mfp2_neighbors('CAST(? AS mol)');"
                                } else {
                                    //something went wrong if we're here
                                    //println("Something went wrong with smilesSearchType.");
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
                                        params.CASRNBox += "#Set" + curSet + "\n"
                                        curSet++
                                        resultSet.each { result ->
                                            params.CASRNBox += result.casrn + "\n"
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
                                        println(psqlErrorMessage)
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
                            //println "PARAMS.CASRNBOX:${params.CASRNBox}:"
                            if (params.CASRNBox == "") {
                                //println "IN IF"
                                render(view: "form", model: [isCasrnErrors: true, noCasrnInput: true])
                                return
                            }
                        }

                        //println "##########################ENRICH ANALYSIS TYPE:"
                        //println enrichAnalysisType

                        //insert set name if no set name detected
                        if (!groovyParams["CASRNBox"].toString().contains("#")) {
                            groovyParams["CASRNBox"] = "#Set1\n" + groovyParams["CASRNBox"]
                            //println("Added '#Set1' to groovyParams['CASRNBox']")
                        }

                        //Enrichment now continues as it would
                        //if the user gave CASRN input.
                        params.CASRNBox = params.CASRNBox.trim();
                        //print "Input path for enrichment: $ENRICH_INPUT_PATH\n\n"
                        //print "BEGIN PARAMS:\n"
                        //print "$params\n"

                        def count = 0
                        for (i in params) {
                            count++
                            //println "Count is $count"
                            if (i.key.contains("_")) {
                                continue;
                            }
                            if (i.key == "CASRNBox") {
                                CASRNBox = i.value
                                continue;
                            }
                            //print "key = ${i.key}, value = ${i.value}\n"
                        }
                        //print "CASRNBox: $CASRNBox\n"
                        //print "END PARAMS.\n"

                        //check CASRNs for validity
                        //validity in this case being their existence in our database
                        //the obvious flaw being that if the user used SMILE input we don't really need to do this step
                        //TODO: don't do this if the user provided SMILEs as input
                        CASRNBox.eachLine {
                            casrn, lineNumber ->
                                casrn = casrn.trim()
                                println "CASRN  <" + casrn + ">"
                                casrnInput.add([index: lineNumber, casrn: casrn])
                        }

                        //println "CASRN input:"
                        //println casrnInput

                        def setNameSplit
                        def setName
                        casrnInput.each {
                            itCasrn ->
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

                        //println "GOOD CASRNS: "
                        //println goodCasrns
                        //println "ERROR CASRNS: "
                        //println errorCasrns

                        def postParamTranslationMap = [
                                meshTerm: "MESH",
                                pharmAction: "PHARMACTIONLIST",
                                activityClass: "ACTIVITY_CLASS",
                                adverseEffect: "ADVERSE_EFFECT",
                                indication: "INDICATION",
                                knownToxicity: "KNOWN_TOXICITY",
                                mechanism: "MECHANISM",
                                mechLevel1: "MECH_LEVEL_1",
                                mechLevel2: "MECH_LEVEL_2",
                                mechLevel3: "MECH_LEVEL_3",
                                meshLevel1: "MESH_LEVEL_1",
                                meshLevel2: "MESH_LEVEL_2",
                                meshLevel3: "MESH_LEVEL_3",
                                modeClass: "MODE_CLASS",
                                productClass: "PRODUCT_CLASS",
                                structureActivity: "STRUCTURE_ACTIVITY",
                                therapeuticClass: "THERAPEUTIC_CLASS",
                                tissueToxicity: "TISSUE_TOXICITY",
                                //zeroClass: "ZERO_CLASS",
                                taLevel1: "TA_LEVEL_1",
                                taLevel2: "TA_LEVEL_2",
                                taLevel3: "TA_LEVEL_3",
                                pathway: "CTD_PATHWAY",
                                chem2Disease: "CTD_CHEM2DISEASE",
                                ctdChem2Gene25: "CTD_CHEM2GENE_25",
                                goBiop: "CTD_GO_BP",
                                drugbankTargets: "DRUGBANK_TARGETS",
                                drugbankAtcCode: "DRUGBANK_ATC_CODE",
                                toxinsTargets: "TOXINS_TARGETS",
                                leadscopeToxicity: "LEADSCOPE_TOXICITY",
                                multicaseToxPrediction: "MULTICASE_TOX_PREDICTION",
                                toxRefDb: "TOXREFDB",
                                htsActive: "HTS_ACTIVE",
                                toxCast: "TOXCAST",
                                toxPrintStructure: "TOXPRINT_STRUCTURE"
                        ]

                        //Translate params to the format the perl scripts expect.
                        for (j in groovyParams) {
                            if (j.value == "on" && postParamTranslationMap.containsKey(j.key)) {
                                annoSelectStr += postParamTranslationMap[j.key.toString()] + "=checked "
                            }
                        }

                        //println("ANNO SELECT STR: $annoSelectStr")

                        def currentCacheDirString = cacheService.getNextCacheDir("$ENRICH_OUTPUT_PATH/CurrentOutputDir.txt")

                        //print "$currentCacheDirString\n"

                        //changed from incremental to UUID so each enrichment will have a unique ID
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
                        if (groovyParams.containsKey("CASRNBox")) {
                            File inputFile = null;
                            groovyParams["CASRNBox"].toString().eachLine({
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
                                                def sql = new Sql(dataSource)
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
                        //if (numSets > 1) {
                        print "Beginning gct file creation for multiple sets...\n"
                        enrichmentService.createDavidChart(currentOutputDir, params.nodeCutoff) //# of nodes to generate in network
                        print "Done creating gct files for multiple sets.\n"
                        print "Beginning heatmap image creation...\n"
                        enrichmentService.createClusteringImages("$currentOutputDir" + "/gct/")
                        print "Done creating heatmap images.\n"
                        //}

                        //generate zip file for results
                        //TODO: Hammer out zip creation (take all files inside output dir, not the dir itself)
                        def resultsZip = resultSetService.compressResultSet(CACHE_DIR)

                        //redirect to results page
                        print "Redirecting to results page...\n"                                        
                        println("[REQUEST CONTEXT QUEUE]: ${RequestContextHolder.currentRequestAttributes()}")

                        //redirect(uri: "/tox21enricher/analysis/success?resultSet=${CACHE_DIR}")

                        //pass the result set ID to the item in the queue
                        getQueueDataSuccess(_transactionId, CACHE_DIR, params.nodeCutoff)
                        getQueueDataEnd(_transactionId)

                        reply _transactionId
                        return

                    }//end of react
                }//end of loop
            }//end of enrichment process


            //queue
            def queue = queueGroup.actor {

                RequestContextHolder.setRequestAttributes(requestContext)//set HTTP request attributes
                
                def transactionId = paramsThread.transactionId
                def queueListItem = [paramsThread, dataSource, transactionId]
                
                transactionQueue << [transactionId, queueListItem[0]]


                //thread debug
                println("\n######THREAD DEBUG INFORMATION ######")
                println("Received Transaction: ${queueListItem}!")
                println("[Enrichment Process] thread pool size: ${actorGroup.getPoolSize()}")
                println("[Enrichment Queue] thread pool size: ${queueGroup.getPoolSize()}")
                println("---------------------------------------")
                println("QUEUE")
                for(int ind = 0; ind < transactionQueue.size(); ind++) {
                    println("| $ind :: ${transactionQueue[ind][0]}")
                }
                println("---------------------------------------")
                println("#####################################\n")
                //end thread debug
                
                def myQueuePosition = 0
                for(int ind2 = 0; ind2 < transactionQueue.size(); ind2++) {
                    if(transactionId == transactionQueue[ind2][0]) {
                        myQueuePosition = ind2
                    
                    }
                }
                
                def tData = [requestContext, transactionId, myQueuePosition, paramsThread, "waiting...", params.nodeCutoff]
                queueMessenger(tData)

                enrichmentProcess.send queueListItem //send item from queue
                react {resultId ->
                    println(">>> enrichment success! Freeing thread...")
                    for(int ind2 = 0; ind2 < transactionQueue.size(); ind2++) {
                        if(transactionQueue[ind2][0] == resultId){ //if we find the transaction's ID, delete it from the list
                            transactionQueue.remove(ind2)
                            
                            decrementQueue()
                        }
                    }
                    deleteQueueItem(resultId)
                }

            }//end of queue
            queue.join()                
              
    }//end of enrich


    //PSQL invalid SMILE Error
    def SET_NAME_MAX_LEN = 50

    //Inject service beans via autowiring
    def final PSQL_SMILE_ERROR = "could not create molecule from SMILES"
    def resultSetService
    def enrichmentService
    def cacheService
    def directoryCompressionService
    def errorCasrnService

    //Inject Postgresql datasource
    def casrnService

    //Where it all starts.
    def dataSource_psql

    def index() {
        render (view: "form")
    }

    def success() {
        print "Success!\n"

        println("returning result set for: ${params.resultSet} with ${params.nodeCutoff} nodes.")

        //generate list of results to display //params.resultSet --> cacheDir
        def resultList = resultSetService.generateResultList(params.resultSet)
        println "Result list: $resultList"

        //get number of sets
        def numSets = resultSetService.getNumSets(params.resultSet)
        println "PARAMS.RESULTSET-------------------------${params.resultSet}"
        println "Number of input sets: $numSets"

        println "NUM SETS: ----------------------- $numSets"

        //create map of lists for results
        //as of 6-20-17 this should include individual set heatmap images
        def resultMap = resultSetService.getMultiSetFiles(params.resultSet)
        println "Result map: $resultMap"
        def sortedResultMap = resultMap.sort { it.key }
        println "Sorted result map: $sortedResultMap"

        //create list of multi set heat map images
        def multiSetHeatMapImages = resultSetService.getMultiSetHeatMapImages(params.resultSet, params.nodeCutoff)

        def inputSetDir = resultSetService.getInputSetDir(params.resultSet)
        println "Input set dir: $inputSetDir"

        def smilesWithResults = resultSetService.getSmilesWithResults()
        def smilesNoResults = resultSetService.getSmilesNoResults()
        def enrichAnalysisType = resultSetService.getAnalysisType()
        println "%%%%%%%%%%%%%%%%%%%%%LOOK AT ALL THIS%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        println smilesWithResults
        println smilesNoResults
        println enrichAnalysisType

        def gctPerSetDir = params.resultSet + "/gct_per_set/"

        def resultSetModel = new ResultSetModel(params.resultSet, resultList, numSets, sortedResultMap, multiSetHeatMapImages, smilesWithResults, smilesNoResults, enrichAnalysisType, gctPerSetDir)

        render(view: "results", model: [resultSetModel: resultSetModel, nodeCutoff: params.nodeCutoff, currentOutputDir: params.resultSet])
    }

    @Override
    void afterPropertiesSet() throws Exception {
        this.ENRICH_INPUT_PATH = storageProperties.getInputDir()[0..-2]
        this.ENRICH_OUTPUT_PATH = storageProperties.getBaseDir()[0..-2]
        this.EXT_SCRIPT_PATH_PERL = scriptLocationProperties.getPerlScriptDir()
    }


    def getAnnoClassAsJson() {
        def sql = new Sql(dataSource)
        def rows = sql.rows("SELECT * FROM annotation_class")

        respond rows    //have to use respond instead of render
    }

}
