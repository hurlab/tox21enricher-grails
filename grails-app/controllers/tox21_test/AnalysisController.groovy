/****************************************************************************
*   This is the controller for Tox21Enricher's main enrichment function.    *
*                                                                           *
****************************************************************************/

package tox21_test

import grails.util.Holders
import groovy.sql.Sql
import groovy.json.JsonSlurper
import net.sf.json.JSON
import org.postgresql.util.PSQLException
import org.springframework.beans.factory.InitializingBean
import org.springframework.web.servlet.ModelAndView

//for concurrency/async
import static groovyx.gpars.actor.Actors.actor
import grails.http.client.*
import grails.events.*
import java.util.concurrent.*
import java.util.*
import org.grails.web.util.WebUtils
import java.lang.management.ManagementFactory
import groovyx.net.http.*
import org.springframework.web.context.request.RequestContextHolder
import org.springframework.web.context.request.RequestAttributes

//for file processing
import static groovy.io.FileType.FILES
import java.util.zip.ZipOutputStream
import java.util.zip.ZipEntry
import java.nio.channels.FileChannel

class AnalysisController implements InitializingBean {
    static scope = "singleton"

    def storageProperties
    def scriptLocationProperties
    def config = Holders.getGrailsApplication().config
    def EXT_SCRIPT_PATH_PERL
    def EXT_SCRIPT_PATH_PYTHON 
    def EXT_SCRIPT_PATH_GROOVY = config.constants.paths.scripts.groovy
    def ENRICH_INPUT_PATH
    def ENRICH_OUTPUT_PATH
    def DEBUG = 1
    def TEST_GROOVY = 0
    def TEST_PERL = 0
    def GROOVY_PERL_KVP = 0
    def dataSource //this is now only postgresql


    //******These PGroups define the pools for each group of actors******//

        //this group is for the actors that handle the enrichment process. Each actor can handle 1 enrichment at a time
        //change value to allow different #s of concurrent enrichment processes (this is the upper limit of threads)
        def actorGroup = new groovyx.gpars.group.NonDaemonPGroup(5)
        //this group is for the actor that handles the queue
        //this should always be 1
        def queueGroup = new groovyx.gpars.group.DefaultPGroup(1)  

    def transactionQueue = []
    def queueDataList = []

    //******The following methods define functionality for how the queue outputs to the webapp's UI******//
    //******                        They also define queue behavior                                ******//

        //initial display of the queue for the user UI
        def queueMessenger(def transactionData) { 
            //transactionData: 0 = context | 1 = id | 2 = queue position | 3 = params | 4 = result link | 5 = node cutoff value
            println(">>> Notifying ${transactionData[1]} of queue position!")

            def itemBox

            if (transactionData[3].analysisType == "CASRNSReenrich") {  //if re-enriching
                if (transactionData[3].CASRNBox == null) {
                    def tmpBox = transactionData[3]
                    transactionData[3].CASRNBox = convertCheckedCasrns(tmpBox)
                }
                itemBox = transactionData[3].CASRNBox
                //println "ITEMBOX IS: $itemBox"
            } 
            else {
                if (transactionData[3].analysisType == "CASRNS") {
                    itemBox = transactionData[3].CASRNBox
                }
                else if (transactionData[3].analysisType == "InChI" || transactionData[3].analysisType == "InChISimilarity") {
                    itemBox = transactionData[3].InChIBox
                }
                else if (transactionData[3].analysisType == "Annotation") {
                    itemBox = transactionData[3].AnnoBox
                }
                else { //smiles
                    itemBox = transactionData[3].SMILEBox
                }     
            }
                   
            //put transaction data in queue
            setQueueData(transactionData)

            println(">>> Set ${transactionData[1]} in queue!")

            render(view: "form", model: [tid: transactionData[1], pos: transactionData[2], type: transactionData[3].analysisType, items: itemBox, success: transactionData[4], nodeCutoff: transactionData[5]])
        }

        //fetch position in queue of a given transaction
        def getQueuePosition(def transactionData) { 
            //transactionData: 0 = context | 1 = id | 2 = queue position | 3 = params | 4 = result link | 5 = node cutoff value
            println(">>> Notifying ${transactionData[1]} of queue position!")
            for(int i = 0; i < queueDataList.size(); i++) {
                if(transactionData[1] == queueDataList[i][1]) {
                    return transactionData[2]
                }
            }
        }

        //put item into queue (enqueue)
        def setQueueData(def transactionData) { 
            queueDataList << transactionData
        }

        //update queue display as we are waiting in the queue
        def getQueueData() { 
            for(int i = 0; i < queueDataList.size(); i++) {
                if(params.tid == queueDataList[i][1]) {
                    def itemBox
                    if (queueDataList[i][3].analysisType == "CASRNSReenrich") {  //if re-enriching
                        if (queueDataList[i][3].CASRNBox == null) {
                            def tmpBox = queueDataList[i][3]
                            queueDataList[i][3].CASRNBox = convertCheckedCasrns(tmpBox)
                        }
                        itemBox = queueDataList[i][3].CASRNBox
                    } 
                    else {
                        if (queueDataList[i][3].analysisType == "CASRNS") {
                        itemBox = queueDataList[i][3].CASRNBox
                        }
                        else if (queueDataList[i][3].analysisType == "InChI" || queueDataList[i][3].analysisType == "InChISimilarity") {
                            itemBox = queueDataList[i][3].InChIBox
                        }
                        else if (queueDataList[i][3].analysisType == "Annotation") {
                            itemBox = queueDataList[i][3].AnnoBox
                        }
                        else { //smiles
                            itemBox = queueDataList[i][3].SMILEBox
                        }
                    }
                    //add newline character after each line in itemBox to make formatting look good on waiting page
                    def itemBoxTmp = ""
                    itemBox.eachLine {itemName ->
                        itemBoxTmp += itemName+"\n"
                    }
                    itemBox = itemBoxTmp.trim()
                    //println("| REFRESHED DATA FOR ${queueDataList[i][1]}")
                    render(view: "form", model: [tid: queueDataList[i][1], pos: queueDataList[i][2], type: queueDataList[i][3].analysisType, items: itemBox, success: queueDataList[i][4], nodeCutoff: queueDataList[i][5]])
                    return
                }
            }
        }

        //update queue display when enrichment is done. Send user to enrich page, which in turn redirects to result set
        def getQueueDataEnd(def transId) { 
            println("| REFRESHING QUEUE DATA")
            for(int i = 0; i < queueDataList.size(); i++) {
                if(transId == queueDataList[i][1]) {
                    def itemBox
                    if (queueDataList[i][3].analysisType == "CASRNSReenrich") {  //if re-enriching
                        if (queueDataList[i][3].CASRNBox == null) {
                            def tmpBox = queueDataList[i][3]
                            queueDataList[i][3].CASRNBox = convertCheckedCasrns(tmpBox)
                        }
                        itemBox = queueDataList[i][3].CASRNBox
                    } 
                    else {
                        if (queueDataList[i][3].analysisType == "CASRNS") {
                            itemBox = queueDataList[i][3].CASRNBox
                        }
                        else if (queueDataList[i][3].analysisType == "InChI" || queueDataList[i][3].analysisType == "InChISimilarity") {
                            itemBox = queueDataList[i][3].InChIBox
                        }
                        else if (queueDataList[i][3].analysisType == "Annotation") {
                            itemBox = queueDataList[i][3].AnnoBox
                        }
                        else { //smiles
                            itemBox = queueDataList[i][3].SMILEBox
                        }    
                    }
                    
                    println "TEST >> ${queueDataList[i][4]}"

                    println("| REFRESHED END DATA FOR ${queueDataList[i][1]}")
                    render(view: "enrich", model: [tid: queueDataList[i][1], pos: queueDataList[i][2], type: queueDataList[i][3].analysisType, items: itemBox, success: queueDataList[i][4], nodeCutoff: queueDataList[i][5]])
                    return
                }
            }
        }

        //update queue display w/ result link after enrichment is done. We shouldn't really need this, but this is just in case it doesn't redirect for whatever reason
        def getQueueDataSuccess(def idToUpdate, def resultLink, def nodeCutoff) { 
            for(int i = 0; i < queueDataList.size(); i++) {
                if(idToUpdate == queueDataList[i][1]) {
                    queueDataList[i][4] = resultLink
                    queueDataList[i][5] = nodeCutoff
                }
            }
        }

        //decrements queue position of each item in list and removes the most recent item that finished
        def decrementQueue() { 
            for(int i = 0; i < queueDataList.size(); i++) {
                if(queueDataList[i][2] > 0) {
                    queueDataList[i][2]--
                }
            }
        }

        //delete finished item from queue when done
        def deleteQueueItem(def idToDelete) { 
            for(int i = 0; i < queueDataList.size(); i++) {
                if(queueDataList[i][1] == idToDelete) {
                    queueDataList.remove(i)
                }
            }
        }

        //convert checked CASRNs from re-enrichment to the CASRNBox so we can process the same way we do with a regular CASRNs enrichment
        def convertCheckedCasrns (def queueItemToConvert) {
            def casrnsChecklist = queueItemToConvert.CASRNSChecked.toString().tokenize(',[]')
            //convert list of checked chemicals and set information to a format we can work with in Groovy
            def setsFromResults = [:]
            for (int m = 0; m < queueItemToConvert.setName.size(); m++) {
                def jsonSlurper = new JsonSlurper().parseText(queueItemToConvert.setName[m].toString()) as Map
                def slurpedList
                def convertedJson
                jsonSlurper.each {jsonKey, jsonValue ->
                    def splitList = jsonValue.tokenize(',[]')
                    convertedJson = ["${jsonKey}":splitList]
                }
                setsFromResults << convertedJson
            }
            //put only the checked items into each set in params.CASRNBox (so we can perform enrichment the same way as if we did a regular CASRNs enrichment)
            setsFromResults.each {nameKey, listValue -> 
                queueItemToConvert.CASRNBox += nameKey.trim() + "\n"
                for (int k = 0; k < listValue.size(); k++) {
                    for (int j = 0; j < casrnsChecklist.size(); j++ ) {
                        if (listValue[k] == casrnsChecklist[j]) {
                            queueItemToConvert.CASRNBox += listValue[k].trim() + "\n"
                        }
                    }
                }
            }
            return queueItemToConvert.CASRNBox
        }

        //render failure view in case no input is specified
        def renderFailure (def status) {
            if (status == "failurecasrn") render(view: "form", model: [isCasrnErrors: true, noCasrnInput: true])
            else if (status == "failuresmiles") render(view: "form", model: [isSmileErrors: true, noSmileInput: true])
            else if (status == "failuresmilessim") render(view: "form", model: [isSmileSimErrors: true, noSmileInput: true])
            else if (status == "failureinchi") render(view: "form", model: [isInChIErrors: true, noSmileInput: true])
            else if (status == "failureinchisim") render(view: "form", model: [isInChISimErrors: true, noSmileInput: true])
            else if (status == "failureanno") render(view: "form", model: [isAnnoErrors: true, noAnnoInput: true])
            return
        }

        //TODO: this will work, but I need to clean it up and figure out a more efficient way to do this.
        def renderFailureErrors (def status, def errorSmiles, def goodSmiles) {
            println "errorSmiles >> " + errorSmiles
            def errorSmilesList = errorSmiles.split("~")
            def errorSmilesListOutput = []
            println " << errorSmilesList >> " 
            if (errorSmilesList != "") {
                for (errorSmilesItem in errorSmilesList) {
                    if (errorSmilesItem != "") {
                        println "| " + errorSmilesItem
                        errorSmilesItem = errorSmilesItem.trim()
                        def tmpSmilesSplit = []
                        tmpSmilesSplit = errorSmilesItem.split("_")
                        if(tmpSmilesSplit != [] && tmpSmilesSplit != null) errorSmilesListOutput += [index:(tmpSmilesSplit[0]).toInteger(), smile:(tmpSmilesSplit[1])]
                    }
                }
            }

            println "goodSmiles >> " + goodSmiles            
            def goodSmilesList = goodSmiles.split("~")
            def goodSmilesListOutput = ""
            println " << goodSmilesList >> " 
            if (goodSmilesList != "") {
                //for (goodSmilesItem in goodSmilesList) {
                for (int i=0; i < goodSmilesList.length; i++) {
                    if (goodSmilesList[i] != "") {
                        println "| " + goodSmilesList[i]
                        goodSmilesList[i] = goodSmilesList[i].trim()
                        def tmpSmilesSplit = []
                        tmpSmilesSplit = goodSmilesList[i].split("_")
                        if (tmpSmilesSplit != [] && tmpSmilesSplit != null) {
                            goodSmilesListOutput += tmpSmilesSplit[1]
                            if (i != goodSmilesList.length-1) goodSmilesListOutput += "\n"
                        }
                    }
                }
            }
            
            if (status == "failuresmileserror") render(view: "form", model: [isSmileErrors: true, psqlErrorSmiles: errorSmilesListOutput, psqlGoodSmiles: goodSmilesListOutput])
            else if (status == "failuresmilessimerror") render(view: "form", model: [isSmileSimErrors: true, psqlErrorSmiles: errorSmilesListOutput, psqlGoodSmiles: goodSmilesListOutput])
            else if (status == "failureinchierror") render(view: "form", model: [isInChIErrors: true, psqlErrorSmiles: errorSmilesListOutput, psqlGoodSmiles: goodSmilesListOutput])
            else if (status == "failureinchisimerror") render(view: "form", model: [isInChISimErrors: true, psqlErrorSmiles: errorSmilesListOutput, psqlGoodSmiles: goodSmilesListOutput])
            return
        }

    //******        This is the method for performing the enrichment process        ******//
        def enrich() {
            RequestAttributes requestContext = RequestContextHolder.getRequestAttributes() //set the requestContext variable to the context of the most recent web request sent to the controller
                                                                                           //this is so we know where to send the results back to
            def paramsThread = params //to allow each thread to access its request's specific params
            //println("PARAMS: $paramsThread")

            //The actor that handles enrichment accepts the request parameters from the request queue and performs the enrichment
            def enrichmentProcess = actorGroup.actor { 
                react { queuePos -> //grab queue item
                    RequestContextHolder.setRequestAttributes(requestContext) //set HTTP request attributes so the program knows who sent this request
                    //do enrichment after we're done waiting in the queue
                    println("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
                    println("Transaction $queuePos is beginning enrichment...")
                    println("[REQUEST CONTEXT QUEUE]: ${RequestContextHolder.currentRequestAttributes()}")
                    println("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")

                    def _params = queuePos[0]   //this will grab the parameters from the item popped from the queue, really just need it to get the transaction id
                    //println "_params:: ${_params}"
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
                    def groovyParams = _params
                    def psqlErrorSmiles = []
                    def psqlGoodSmiles = []
                    def smiles = []
                    //def inchis = []
                    def smilesWithResults = []
                    def smilesNoResults = []
                    def enrichAnalysisType = "none"
                    def casrnResultsData = [:]
                    def tmpCasrnNameList = []
                    def tmpSmilesNameList = []
                    def threshold
                    def annoSelectSaved = [:]
                    def reactiveList = []   //list of maps of chemicals that contain reactive groups
                    def invalidCharactersError = "[,_]" //characters to remove from error input

                    //If we're using SMILE input or InChI input
                    //query psql to get our CASRNs.
                    if (params.analysisType == "SMILES" || params.analysisType == "SMILESSimilarity" || params.analysisType == "InChI" || params.analysisType == "InChISimilarity") {
                        //we are just consolidating everything into the SMILEBox regardless of enrichment type.
                        //if user picked SMILES similarity, put contents of that input box into SMILEBox
                        if(params.analysisType == "SMILESSimilarity") {
                            params.SMILEBox = params.SMILESimilarityBox
                            params.smilesSearchType = "Similarity"
                        }
                        //and do the same if user picked InChI similarity
                        else if (params.analysisType == "InChISimilarity") {
                            params.InChIBox = params.InChISimilarityBox
                            params.smilesSearchType = "Similarity"
                        }
                        //don't need to consolidate if user picked SMILES or InChI substructure since the substructure searches use the SMILEBox/InChiBox, respectively
                        //SMILEBox is really SMILESubstructureBox and InChIBox is really InChiSubstructureBox
                        else {
                            params.smilesSearchType = "Substructure"
                        }

                        enrichAnalysisType = params.analysisType
                        resultSetService.setAnalysisType(enrichAnalysisType)

                        //detect if the user submitted SMILES or InChi. They are both handled almost identically internally.
                        //the only difference is that InChI is fist converted to SMILES and then they are handled the same.
                        if(enrichAnalysisType == "SMILES" || enrichAnalysisType == "SMILESSimilarity") {
                            println("| I think it's SMILES")
                            println "THIS: >> $params.SMILEBox"
                        }
                        else if (enrichAnalysisType == "InChI" || enrichAnalysisType == "InChISimilarity") {
                            println("| I think it's InChI")
                            println "THIS: >> $params.InChIBox"
                        }

                        
                        //error checking if no input
                        if (params.SMILEBox == "") {
                            println "blank smiles error"
                            if (enrichAnalysisType == "SMILES") {
                                reply "$_transactionId\tfailuresmiles"
                                return
                            } else if (enrichAnalysisType == "SMILESSimilarity") {
                                reply "$_transactionId\tfailuresmilessim"
                                return
                            }                            
                        }
                        if (params.InChIBox == ""){
                            if (enrichAnalysisType == "InChI") {
                                reply "$_transactionId\tfailureinchi"
                                return
                            } else if (enrichAnalysisType == "InChISimilarity") {
                                reply "$_transactionId\tfailureinchisim"
                                return
                            }

                        } 

                        def psqlErrorMessage
                        params.CASRNBox = "";
                        def sql = new Sql(dataSource_psql)
                        def curSet = 1
                        
                        def setThresholdQuery
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
                        //set tanimoto threshold
                        def ret = sql.execute(setThresholdQuery)
                        //println("RET: " + ret)

                        def dataBox

                        if(enrichAnalysisType == "SMILES" || enrichAnalysisType == "SMILESSimilarity") {
                            println("| I think it's SMILES")
                            dataBox = params.SMILEBox
                        }
                        else if (enrichAnalysisType == "InChI" || enrichAnalysisType == "InChISimilarity") {
                            println("| I think it's InChI")
                            dataBox = params.InChIBox
                        }
                        
                        //TODO: try not to use exception to control flow if possible
                        dataBox.eachLine { itemFromBox, lineNumber ->
                            def tmpInChI
                            if (enrichAnalysisType == "InChI" || enrichAnalysisType == "InChISimilarity") {
                                tmpInChI = itemFromBox
                                //This calls a Python script that uses rdkit to convert InChI strings to SMILES strings
                                //after this, InChI strings are processed the same as SMILES
                                def inchiToAdd = enrichmentService.convertInchiToSmiles(itemFromBox.trim()) //strip trailing whitespace (newlines)
                                //def inchiToAdd = sql.rows("select smiles from chemical_detail where inchis='${itemFromBox.trim()}';") //strip trailing whitespace (newlines)
                                if (inchiToAdd != null) {
                                    itemFromBox = inchiToAdd
                                }
                                else {
                                    println "error converting: $itemFromBox on $lineNumber. Not a valid InChI string?"
                                    psqlErrorSmiles.add("${lineNumber}_${itemFromBox.replaceAll(invalidCharactersError, "").trim()}")
                                    return
                                }
                            }


                            //set list of all smiles
                            smiles += itemFromBox
                            //Try/catch block to catch invalid SMILEs/InChI
                            try {
                                def resultSet = []
                                def rowResultSet
                                if (params.smilesSearchType == "Substructure") {
                                    //get both casrns and smiles from database. we need smiles to find the mismatch structures
                                    //def tmpRows = sql.rows("select * from mols where m @> CAST(${itemFromBox} AS mol);")
                                    def tmpRows = sql.rows("select * from mols_2 where m @> CAST(${itemFromBox} AS mol);")
                                    if (tmpRows != []) {
                                        tmpRows.each { tmpRow ->
                                            tmpRow["similarity"] = 0.5
                                        }
                                        rowResultSet = tmpRows
                                        //convert from GroovyRowResult to Map so it's easier to work with
                                        rowResultSet.each { result ->
                                            def tmpSet =[:]
                                            tmpSet["casrn"] = result.casrn
                                            tmpSet["m"] = result.m
                                            tmpSet["similarity"] = result.similarity
                                            tmpSet["cyanide"] = result.cyanide
                                            tmpSet["isocyanate"] = result.isocyanate
                                            tmpSet["aldehyde"] = result.aldehyde
                                            tmpSet["epoxide"] = result.epoxide 
                                            resultSet += tmpSet
                                        }
                                    }
                                    else {
                                        rowResultSet = []
                                        resultSet = []
                                    }
                                }
                                else if (params.smilesSearchType == "Similarity") {
                                    //first, check if the item on this line is actually valid SMILES, TODO: make this easier:
                                    def SmilesValidCheck = enrichmentService.checkSmilesValid(itemFromBox)
                                    println ">>> SmilesValidCheck >>> $SmilesValidCheck"
                                    if (SmilesValidCheck.contains("None")) {
                                        throw new IllegalArgumentException("Invalid SMILES: ${itemFromBox}")
                                    }
                                    //get both casrns and smiles from database. we need smiles to find the mismatch structures
                                    rowResultSet = sql.rows("select * from get_mfp2_neighbors(${itemFromBox});")   
                                    //convert from GroovyRowResult to Map so it's easier to work with 
                                    rowResultSet.each { result ->
                                        def tmpSet =[:]
                                        tmpSet["casrn"] = result.casrn
                                        tmpSet["m"] = result.m
                                        tmpSet["similarity"] = result.similarity 
                                        tmpSet["cyanide"] = result.cyanide
                                        tmpSet["isocyanate"] = result.isocyanate
                                        tmpSet["aldehyde"] = result.aldehyde
                                        tmpSet["epoxide"] = result.epoxide
                                        resultSet += tmpSet
                                    }
                                    println "got results: $resultSet"  
                                }

                                //Preliminary check: check the itemFromBox to see if it contains a reactiveGroup
                                def boxReactiveGroups = enrichmentService.calcReactiveGroups(itemFromBox.toString().trim())
                                println "submitting: " + itemFromBox.toString().trim()
                                def boxReactiveGroupsList = []
                                if (boxReactiveGroups != null) {
                                    boxReactiveGroupsList = boxReactiveGroups.split(",")
                                    //clean box by stripping newlines, probably change this to be less silly later
                                    for(int i = 0; i < boxReactiveGroupsList.size(); i++) {
                                        if (boxReactiveGroupsList[i].contains("\n")) {
                                            boxReactiveGroupsList = boxReactiveGroupsList - boxReactiveGroupsList[i]
                                        }
                                    }
                                }
                                println "=================| " + boxReactiveGroupsList

                                //Here, we check if any reactive structures only appear in one of the lists and keep track of those.
                                println ">> COMPARING FOR: $itemFromBox"
                                resultSet.each { moleculeAfter ->
                                    def reactiveGroups = enrichmentService.calcCasrnReactiveGroups(moleculeAfter, boxReactiveGroupsList)
                                    if (reactiveGroups != []) {
                                        reactiveList += [smiles:itemFromBox, casrn:moleculeAfter.casrn, warn:reactiveGroups]
                                    }
                                    
                                }

                                println "reactiveList:: " + reactiveList
                                //casrnResultsData.put(itemFromBox,resultSet)
                                casrnResultsData.put("#Set$curSet",resultSet)
                                //println "PUT: ${casrnResultsData}"
                                
                                if (enrichAnalysisType == "SMILES" || enrichAnalysisType == "SMILESSimilarity") {
                                    psqlGoodSmiles.add("${lineNumber}_${itemFromBox}")
                                }
                                else {
                                    psqlGoodSmiles.add("${lineNumber}_${tmpInChI}")
                                }

                                if (resultSet.size() > 0) {
                                    params.CASRNBox += "#Set" + curSet + "\n"
                                    curSet++
                                    resultSet.each { result ->
                                        //just grab the CASRN, not the similarity here
                                        params.CASRNBox += result["casrn"] + "\n"
                                    }
                                    smilesWithResults.add(itemFromBox)
                                }
                            }
                            catch (PSQLException | IllegalArgumentException e) {
                                println "smiles error"
                                psqlErrorMessage = e.getMessage()
                                if (psqlErrorMessage.contains(PSQL_SMILE_ERROR)) {
                                    //Add the smile and the line in the input set it occurred on.
                                    //This will allow us to give a useful message such as:
                                    //"SMILE on line 5 is invalid."
                                    psqlErrorSmiles.add("${lineNumber}_${itemFromBox.replaceAll(invalidCharactersError, "")}")
                                }
                                else if (psqlErrorMessage.contains("Invalid SMILES:")) {
                                    psqlErrorSmiles.add("${lineNumber}_${itemFromBox.replaceAll(invalidCharactersError, "")}")
                                }
                                else {
                                    //TODO: "Unknown database error"
                                    println(psqlErrorMessage)
                                }
                            }
                        }

                        //TODO: Make this cleaner
                        def casrnName
                        if (casrnResultsData != null) {    
                            casrnResultsData.each { casrnKey, casrnValues ->
                                for (int i = 0; i < casrnValues.size(); i++) {
                                    casrnValues[i].each { casrnInsideKey, casrnInsideValue ->
                                        if(casrnInsideKey == "casrn") { //grab casrn names
                                            //vvv probably should grab this earlier? This may introduce a performance overhead vvv
                                            casrnName = sql.rows("SELECT testsubstance_chemname,cid,iupac_name,inchis,inchikey,mol_formula,mol_weight,dtxsid FROM chemical_detail WHERE CASRN LIKE '" + casrnInsideValue + "'")
                                            println "casrnName: $casrnName"
                                            tmpCasrnNameList += casrnName
                                            
                                        }
                                        else if(casrnInsideKey == "m") { //grab smiles names
                                            tmpSmilesNameList += casrnInsideValue
                                        }
                                    }
                                }
                            }
                        }

                        resultSetService.setSmilesWithResults(smilesWithResults)

                        //get list of SMILES that did not yield CASRN results
                        smiles.each { itSmiles ->
                            println "itSmiles $itSmiles"
                            if (!smilesWithResults.contains(itSmiles)) {
                                smilesNoResults.add(itSmiles)
                            }
                        }

                        resultSetService.setSmilesNoResults(smilesNoResults)

                        println "----------------------------------PSQL ERROR SMILES:"
                        println psqlErrorSmiles
                        println "----------------------------------PSQLERRORSMILES.EMPTY:"
                        println psqlErrorSmiles.empty
                        if (!psqlErrorSmiles.empty) {

                            def psqlErrorSmilesString = "~"
                            for (def i=0; i < psqlErrorSmiles.size; i++) {
                                psqlErrorSmilesString += psqlErrorSmiles[i]
                                if (i != psqlErrorSmiles.size-1) psqlErrorSmilesString += "~"
                            }
                            def psqlGoodSmilesString = "~"
                            for (def i=0; i < psqlGoodSmiles.size; i++) {
                                psqlGoodSmilesString += psqlGoodSmiles[i]
                                if (i != psqlGoodSmiles.size-1) psqlGoodSmilesString += "~"
                            }

                            println "errorSmiles: $psqlErrorSmilesString"
                            println "goodSmiles: $psqlGoodSmilesString"

                            if (enrichAnalysisType == "SMILES") reply "$_transactionId\tfailuresmileserror\t$psqlErrorSmilesString\t$psqlGoodSmilesString"
                            else if (enrichAnalysisType == "SMILESSimilarity") reply "$_transactionId\tfailuresmilessimerror\t$psqlErrorSmilesString\t$psqlGoodSmilesString"
                            else if (enrichAnalysisType == "InChI") reply "$_transactionId\tfailureinchierror\t$psqlErrorSmilesString\t$psqlGoodSmilesString"
                            else if (enrichAnalysisType == "InChISimilarity") reply "$_transactionId\tfailureinchisimerror\t$psqlErrorSmilesString\t$psqlGoodSmilesString"
                            return
                        }
                        println "----------------------------------SMILES LIST:"
                        println smiles
                        println "----------------------------------SMILES WITH RESULTS LIST:"
                        println smilesWithResults
                        println "----------------------------------SMILES NO RESULTS LIST:"
                        println smilesNoResults
                    }

                    //Get all annotations for a user-supplied chemical (CASRNs)
                    else if (params.analysisType == "Annotation") {
                        println params.AnnoBox

                        //changed from incremental to UUID so each enrichment will have a unique ID, DIFFERENT than the transaction ID!
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

                        File annotationsFileFull
                        def sql = new Sql(dataSource_psql)
                        def annoBox = params.AnnoBox

                        //if no chemicals are entered
                        if (annoBox == "") {
                            reply "$_transactionId\tfailureanno"
                            return
                        }

                        annoBox.eachLine { annoBoxLine, annoBoxLineNumber ->
                            annotationsFileFull = new File(currentOutputDir + '/' + annoBoxLine.strip() + '__Annotations.txt')
                            def annoDetails = sql.rows("SELECT annotation FROM annotation_matrix WHERE casrn = '" + annoBoxLine.strip().toString() + "';")
                            if (annoDetails == null || annoDetails == []) {
                                println "here"
                                errorCasrns.add([index: annoBoxLineNumber, casrn: annoBoxLine.strip().toString(), set: annoBoxLine.strip().toString()])
                            }
                            else {
                                def annoTmp = annoDetails["annotation"]
                                def annoList = annoTmp[0].split('\\|')
                                annoList.each { annoId ->
                                    def annotationNames = sql.rows("SELECT term FROM annotation_matrix_terms WHERE id = " + annoId + ";")
                                    //println annotationNames
                                    annotationNames.each { annotationName ->
                                        annotationsFileFull.append("${annotationName["term"]}\n")
                                    }
                                }
                            }
                        }

                        //Write any chemicals that aren't in the database
                        errorCasrnService.writeErrorCasrnsToFile(currentOutputDir, errorCasrns)

                        //Make zip to download
                        def resultsZip = resultSetService.compressResultSet(CACHE_DIR)

                        //pass the result set ID to the item in the queue
                        getQueueDataSuccess(_transactionId, CACHE_DIR, params.nodeCutoff)
                        getQueueDataEnd(_transactionId)
                        reply "$_transactionId\tsuccess"
                        return
                        
                    }

                    //set enrichAnalysisType = CASRNS if it wasn't SMILES
                    //this will then be passed to our view which
                    //will in turn allow us to display results based on input type
                    else {
                        //set up CASRNBox if we are re-enriching selected CASRNs after a SMILES/InChI search
                        def reenrichSetsMap = [:]
                        if (params.analysisType == "CASRNSReenrich") {
                            //count how many sets we have
                            int numberOfResubmitSets = 0
                            for (int k = 0; k < params.setName.toString().size(); k++) {
                                if (params.setName.toString().charAt(k) == '#') {
                                    numberOfResubmitSets++
                                }
                            }
                            //println ("WE HAVE: ${numberOfResubmitSets} FOR RESUBMISSION")

                            def resubmitList = []
                            if (numberOfResubmitSets == 1) {    //if only one set, add to this list
                                //println "ONLY ONE SET"
                                resubmitList += params.setName.toString()
                            }
                            else {                              //if multiple sets, just set this variable equal to the list
                                //println "$numberOfResubmitSets SETS"
                                resubmitList = params.setName
                            }

                            //println "| >>> DATA SETS: " + resubmitList
                            def casrnsChecklist = params.CASRNSChecked.toString().tokenize(',[]')
                            //println "| >>> SELECTED CASRNS: " + casrnsChecklist

                            //convert list of checked chemicals and set information to a format we can work with in Groovy
                            def setsFromResults = [:]
                            //for (int m = 0; m < params.setName.size(); m++) {
                            for (int m = 0; m < resubmitList.size(); m++) {
                                //def jsonSlurper = new JsonSlurper().parseText(params.setName[m].toString()) as Map
                                def jsonSlurper = new JsonSlurper().parseText(resubmitList[m].toString()) as Map
                                def slurpedList
                                def convertedJson
                                jsonSlurper.each {jsonKey, jsonValue ->
                                    def splitList = jsonValue.tokenize(',[]')
                                    convertedJson = ["${jsonKey}":splitList]
                                }
                                setsFromResults << convertedJson
                            }

                            //put only the checked items into each set in params.CASRNBox (so we can perform enrichment the same way as if we did a regular CASRNs enrichment)
                            setsFromResults.each {nameKey, listValue -> 
                                for (int j = 0; j < casrnsChecklist.size(); j++ ) {
                                    def tmpCheckSplit = casrnsChecklist[j].trim().split("__")  //0 = casrn, 1 = set name
                                    //println "ITEM: ${tmpCheckSplit[0]}\tSET: ${tmpCheckSplit[1]}"
                                    for (int i = 0; i < listValue.size(); i++) {
                                        if (listValue[i].trim() == tmpCheckSplit[0] && tmpCheckSplit[1] == nameKey) {
                                            if(reenrichSetsMap.containsKey(tmpCheckSplit[1]) == false) {
                                                reenrichSetsMap.put(tmpCheckSplit[1], [])
                                            }
                                            reenrichSetsMap[tmpCheckSplit[1]] += tmpCheckSplit[0]
                                        }
                                    }
                                }
                            }                            
                        }

                        //re-populate CASRNBox based on which chemicals were checked for re-enrichment for each set
                        reenrichSetsMap.each { rsmKey, rsmVal ->
                            println "MAP:::: ${rsmKey}\t\t${rsmVal}"
                            params.CASRNBox += rsmKey  + "\n"
                            rsmVal.each{rsmValCasrn ->
                                params.CASRNBox += rsmValCasrn + "\n"
                            }
                        }
                        

                        def originalAnalysisType = enrichAnalysisType
                        println ">>>>>> $originalAnalysisType"
                        enrichAnalysisType = "CASRNS"
                        resultSetService.setAnalysisType(enrichAnalysisType)
                        println "PARAMS.CASRNBOX:${params.CASRNBox}:"
                        if (params.CASRNBox == "" && originalAnalysisType == "none") {
                            println ">>>problem with enrichment!"
                            reply "$_transactionId\tfailurecasrn"
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

                    //Enrichment now continues as it would if the user gave CASRN input.
                    params.CASRNBox = params.CASRNBox.trim();
                    //print "Input path for enrichment: $ENRICH_INPUT_PATH\n\n"
                    //print "BEGIN PARAMS:\n"
                    //print "$params\n"

                    def count = 0
                    for (i in _params) {
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
                    CASRNBox.eachLine { casrn, lineNumber ->
                            casrn = casrn.trim()
                            println "CASRN  <" + casrn + ">"
                            casrnInput.add([index: lineNumber, casrn: casrn])
                    }

                    //println "CASRN input:"
                    //println casrnInput

                    def setNameSplit
                    def setName
                    casrnInput.each { itCasrn ->
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

                    //will have to expand this once database is updated
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
                            modeClass: "MODE_CLASS",
                            productClass: "PRODUCT_CLASS",
                            structureActivity: "STRUCTURE_ACTIVITY",
                            therapeuticClass: "THERAPEUTIC_CLASS",
                            tissueToxicity: "TISSUE_TOXICITY",
                            taLevel1: "TA_LEVEL_1",
                            taLevel2: "TA_LEVEL_2",
                            taLevel3: "TA_LEVEL_3",
                            pathway: "CTD_PATHWAY",
                            chem2Disease: "CTD_CHEM2DISEASE",
                            ctdChem2Gene25: "CTD_CHEM2GENE_25",
                            drugbankTargets: "DRUGBANK_TARGETS",
                            drugbankAtcCode: "DRUGBANK_ATC_CODE",
                            toxinsTargets: "TOXINS_TARGETS",
                            leadscopeToxicity: "LEADSCOPE_TOXICITY",
                            multicaseToxPrediction: "MULTICASE_TOX_PREDICTION",
                            toxRefDb: "TOXREFDB",
                            htsActive: "HTS_ACTIVE",
                            toxCast: "TOXCAST_ACTIVE",
                            toxPrintStructure: "TOXPRINT_STRUCTURE",
                            ctdChemicalsDiseases: "CTD_CHEMICALS_DISEASES",
                            ctdChemicalsGenes: "CTD_CHEMICALS_GENES",
                            goFatBp: "CTD_GOFAT_BIOPROCESS",
                            goSlimBp: "CTD_GOSLIM_BIOPROCESS",
                            ctdChemicalsGoenrichCellcomp: "CTD_CHEMICALS_GOENRICH_CELLCOMP",
                            ctdChemicalsGoenrichMolfunct: "CTD_CHEMICALS_GOENRICH_MOLFUNCT",
                            ctdChemicalsPathways: "CTD_CHEMICALS_PATHWAYS",
                            drugbankAtc: "DRUGBANK_ATC",
                            drugbankCarriers: "DRUGBANK_CARRIERS",
                            drugbankEnzymes: "DRUGBANK_ENZYMES",
                            drugbankTransporters: "DRUGBANK_TRANSPORTERS",
                    ]

                    //Translate params to the format the perl scripts expect.
                    for (j in groovyParams) {
                        //println "GOT: $j"
                        if (j.value == "on" && postParamTranslationMap.containsKey(j.key)) {
                            //add to annoSelectStr to perform enrichment
                            annoSelectStr += postParamTranslationMap[j.key.toString()] + "=checked "
                            //add to annoSelectSaved list to persist in case user wants to re-enrich
                            annoSelectSaved << ["${j.key}": "${j.value}"]
                        }
                    }

                    //println "WE SAVED: ${annoSelectSaved}"
                    //println("ANNO SELECT STR: $annoSelectStr")

                    //changed from incremental to UUID so each enrichment will have a unique ID, DIFFERENT than the transaction ID!
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
                        groovyParams["CASRNBox"].toString().eachLine({ line ->
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
                    println "Annotation selection string: $annoSelectStr"
                    //print "Calling enrichment analysis perl script...\n"
                    enrichmentService.performEnrichment(currentInputDir, currentOutputDir, annoSelectStr)
                    print "Enrichment completed.\n"

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

                    //create casrn file to make re-enrichment table - todo: make into own thing or at least clean up
                    if (enrichAnalysisType == "SMILESSimilarity" 
                    || enrichAnalysisType == "InChISimilarity"
                    || enrichAnalysisType == "SMILES"
                    || enrichAnalysisType == "InChI") {
                        //create file to store CASRNs for SMILES/InChI - TODO: make service
                        //println ">>> creating file at ${currentOutputDir}/CASRNs.txt"
                        File casrnFile = new File(currentOutputDir + "/CASRNs.txt")
                        def casrnNameIndex = 0
                        def currentSet = ""
                        params.CASRNBox.eachLine { line ->
                            println "============================="
                            println "$line"
                            println "============================="
                            if (line.startsWith("#")) { //set name
                                casrnFile << line + "\n"
                                currentSet = line
                                println "CURRENT SET: $currentSet"
                            }
                            else {  //else, casrn id
                                def totalSize = 0
                                casrnResultsData.each { casrnKey, casrnValues ->
                                    println ">>>> $casrnKey\t$casrnValues"
                                    totalSize += casrnValues.size()
                                    for (int i = 0; i < casrnValues.size(); i++) {
                                            if(casrnValues[i].casrn == line && casrnKey == currentSet && tmpCasrnNameList[casrnNameIndex] != null) {
                                                //error checking & handling for if we are missing any of this info
                                                if (tmpCasrnNameList[casrnNameIndex].cid == "") {
                                                    println "> no CID. replacing:"
                                                    tmpCasrnNameList[casrnNameIndex].cid = "none"
                                                }
                                                if (tmpCasrnNameList[casrnNameIndex].iupac_name == "") {
                                                    println "> no IUPAC Name. replacing:"
                                                    tmpCasrnNameList[casrnNameIndex].iupac_name = "none"
                                                }
                                                if (tmpCasrnNameList[casrnNameIndex].inchis == "") {
                                                    println "> no InChI. replacing:"
                                                    tmpCasrnNameList[casrnNameIndex].inchis = "none"
                                                }
                                                if (tmpCasrnNameList[casrnNameIndex].inchikey == "") {
                                                    println "> no InChIKey. replacing:"
                                                    tmpCasrnNameList[casrnNameIndex].inchikey = "none"
                                                }
                                                if (tmpCasrnNameList[casrnNameIndex].mol_formula == "") {
                                                    println "> no Molecular Formula. replacing:"
                                                    tmpCasrnNameList[casrnNameIndex].mol_formula = "none"
                                                }
                                                if (tmpCasrnNameList[casrnNameIndex].mol_weight == "") {
                                                    println "> no Molecular Weight. replacing:"
                                                    tmpCasrnNameList[casrnNameIndex].mol_weight = "none"
                                                }

                                                if (enrichAnalysisType == "SMILESSimilarity" || enrichAnalysisType == "InChISimilarity") {
                                                    casrnFile << casrnValues[i].casrn + "\t" + tmpCasrnNameList[casrnNameIndex].testsubstance_chemname + "\t" + String.format("%.2f",casrnValues[i].similarity.value) + "\t" + tmpSmilesNameList[casrnNameIndex] + "\t" + tmpCasrnNameList[casrnNameIndex].cid + "\t" + tmpCasrnNameList[casrnNameIndex].iupac_name + "\t" + tmpCasrnNameList[casrnNameIndex].inchis + "\t" + tmpCasrnNameList[casrnNameIndex].inchikey + "\t" + tmpCasrnNameList[casrnNameIndex].mol_formula + "\t" + tmpCasrnNameList[casrnNameIndex].mol_weight + "\t" + tmpCasrnNameList[casrnNameIndex].dtxsid + "\n"
                                                }
                                                else {
                                                    casrnFile << casrnValues[i].casrn + "\t" + tmpCasrnNameList[casrnNameIndex].testsubstance_chemname + "\t" + threshold + "\t" + tmpSmilesNameList[casrnNameIndex] + "\t" + tmpCasrnNameList[casrnNameIndex].cid + "\t" + tmpCasrnNameList[casrnNameIndex].iupac_name + "\t" + tmpCasrnNameList[casrnNameIndex].inchis + "\t" + tmpCasrnNameList[casrnNameIndex].inchikey + "\t" + tmpCasrnNameList[casrnNameIndex].mol_formula + "\t" + tmpCasrnNameList[casrnNameIndex].mol_weight + "\t" + tmpCasrnNameList[casrnNameIndex].dtxsid + "\n"
                                                }
                                                casrnNameIndex++
                                            }   
                                        //}
                                    }
                                }
                            }
                        }
                        //append annoSelectSaved map to file
                        annoSelectSaved.each { annoKey, annoValue ->
                            casrnFile << "%" + annoKey + "\t" + annoValue + "\n"
                        }
                        //append list of reactive groups, if applicable, to file
                        reactiveList.each { reactiveChemical ->
                            casrnFile << "!" + reactiveChemical.smiles + "\t" + reactiveChemical.casrn + "\t" + reactiveChemical.warn + "\n"
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

                    //pass the result set ID to the item in the queue
                    getQueueDataSuccess(_transactionId, CACHE_DIR, params.nodeCutoff)
                    getQueueDataEnd(_transactionId)

                    reply "$_transactionId\tsuccess"
                    return

                }//end of react
            }//end of enrichment process


            //******   This is the queue     ******//
            def queue = queueGroup.actor {
                RequestContextHolder.setRequestAttributes(requestContext)//set HTTP request attributes
                def transactionId = paramsThread.transactionId
                def queueListItem = [paramsThread, dataSource_psql, transactionId]
                
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

                
                react {result ->
                    def tmpSplit = result.split('\t')
                    println "tmpSplit >>> $tmpSplit"
                    def resultId = tmpSplit[0]
                    def status = tmpSplit[1]
                    def errorSmiles
                    def goodSmiles 

                    if (status == "success") {
                        println(">>> enrichment success! Freeing thread...")
                        for(int ind2 = 0; ind2 < transactionQueue.size(); ind2++) {
                            if(transactionQueue[ind2][0] == resultId){ //if we find the transaction's ID, delete it from the list
                                transactionQueue.remove(ind2)
                                
                                decrementQueue()
                            }
                        }
                        deleteQueueItem(resultId)
                    }
                    else { //this will handle rendering for empty input sets
                        if (tmpSplit.size() > 2) {
                            errorSmiles = tmpSplit[2]
                            goodSmiles = tmpSplit[3]
                            println(">>> enrichment failure: Invalid sets. Freeing thread...")
                            for(int ind2 = 0; ind2 < transactionQueue.size(); ind2++) {
                                if(transactionQueue[ind2][0] == resultId){ //if we find the transaction's ID, delete it from the list
                                    transactionQueue.remove(ind2)
                                    
                                    decrementQueue()
                                }
                            }
                            deleteQueueItem(resultId)
                            renderFailureErrors(status, errorSmiles, goodSmiles)
                        }
                        else {
                            println(">>> enrichment failure: No sets specified. Freeing thread...")
                            for(int ind2 = 0; ind2 < transactionQueue.size(); ind2++) {
                                if(transactionQueue[ind2][0] == resultId){ //if we find the transaction's ID, delete it from the list
                                    transactionQueue.remove(ind2)
                                    
                                    decrementQueue()
                                }
                            }
                            deleteQueueItem(resultId)
                            renderFailure(status)
                        }
                    }
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
        if (params.enrichType != "Annotation") {
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

            //grab list of casrns for SMILES/InChI
            def casrnResults = resultSetService.getCasrnResults(params.resultSet, params.nodeCutoff)

            //get annotation map for re-enrichment
            def annoResults = resultSetService.getAnnoResults(params.resultSet)

            //get list of reactive chemicals
            def reactiveResults = resultSetService.getReactiveResults(params.resultSet)

            def smilesWithResults = resultSetService.getSmilesWithResults()
            def smilesNoResults = resultSetService.getSmilesNoResults()
            def enrichAnalysisType = resultSetService.getAnalysisType()
            println "%%%%%%%%%%%%%%%%%%%%%LOOK AT ALL THIS%%%%%%%%%%%%%%%%%%%%%%%%%%%"
            println smilesWithResults
            println smilesNoResults
            println enrichAnalysisType

            println "========= PASSING =========== $reactiveResults"

            def gctPerSetDir = params.resultSet + "/gct_per_set/"

            def resultSetModel = new ResultSetModel(params.resultSet, resultList, numSets, sortedResultMap, multiSetHeatMapImages, smilesWithResults, smilesNoResults, enrichAnalysisType, gctPerSetDir)

            render(view: "results", model: [resultSetModel: resultSetModel, nodeCutoff: params.nodeCutoff, currentOutputDir: params.resultSet, reenrich: params.reenrich, casrnResults: casrnResults, annoResults: annoResults, reactiveResults:reactiveResults])
        } 
        else {
            //generate list of results to display //params.resultSet --> cacheDir
            def resultList = resultSetService.generateResultList(params.resultSet)
            println "Result list: $resultList"

            //get number of sets
            def numSets = resultSetService.getNumSets(params.resultSet)

             //create map of lists for results
            //as of 6-20-17 this should include individual set heatmap images
            def resultMap = resultSetService.getMultiSetFiles(params.resultSet)
            println "Result map: $resultMap"
            def sortedResultMap = resultMap.sort { it.key }
            println "Sorted result map: $sortedResultMap"

            //get annotation list

            def annotationResults = resultSetService.getAllAnnotations(params.resultSet)
            def resultSetModel = new ResultSetModelAnno(params.resultSet, resultList, numSets, sortedResultMap, annotationResults)
            render(view: "resultsAnno", model: [resultSetModel: resultSetModel, nodeCutoff: params.nodeCutoff, currentOutputDir: params.resultSet])
        }
    }

    @Override
    void afterPropertiesSet() throws Exception {
        this.ENRICH_INPUT_PATH = storageProperties.getInputDir()[0..-2]
        this.ENRICH_OUTPUT_PATH = storageProperties.getBaseDir()[0..-2]
        this.EXT_SCRIPT_PATH_PERL = scriptLocationProperties.getPerlScriptDir()
    }
}