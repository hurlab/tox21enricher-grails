package tox21_test

import grails.gorm.transactions.Transactional

import static groovy.io.FileType.FILES

@Transactional
class ResultSetService {
    def storageProperties
    def directoryCompressionService
    def private smilesWithResults
    def private smilesNoResults
    def private analysisType

    //TODO: figure out if this is necessary
    def private getResultSetDir(resultSet) {
        return storageProperties.getBaseDir() + resultSet.toString()
    }


    def getInputSetDir(inputSet) {
        println "INPUT SET DIR? ----------------------------------- ${storageProperties.getInputDir()}"
        return storageProperties.getInputDir() + inputSet.toString()
    }

    def getNumSets(inputSet) {
        def inputSetDir = new File(getInputSetDir(inputSet))
        println "INPUT SET DIR ACTUALLY --------------------------------- $inputSetDir"
        def numSets = inputSetDir.listFiles().size()
        return numSets
    }

    def generateResultList(resultSet) {
        def resultList = []
        def dir = new File(storageProperties.getBaseDir() + resultSet)
        println storageProperties.getBaseDir() + resultSet		
        dir.eachFile(FILES) { file ->
            resultList << file.name
        }
        return resultList
    }

    def getMultiSetFiles(resultSet) {
        def results = [:]
        def dir = new File(storageProperties.getBaseDir() + resultSet) 
        dir.eachFile(FILES) { file ->
            if (!file.name.contains("__")) {
                return
            }
            def setName = file.name.tokenize("__").first()
            if (!results.containsKey(setName)) {
                results[setName] = []
            }
            results[setName] << file.name
        }

        //now for the individual set heatmap images
        //they need to be in the same results map otherwise it will be much more difficult to iterate over them in results.gsp
	println "TEST:" + storageProperties.getBaseDir() + resultSet + "/gct_per_set"
        dir = new File(storageProperties.getBaseDir() + resultSet + "/gct_per_set")
        dir.eachFile(FILES) { file ->
            if (!file.name.contains("__")) {
                return
            }
            def setName = file.name.tokenize("__").first()
            if (!results.containsKey(setName)) {
                results[setName] = []
            }
            //if you need to serve more than the jpegs, adjust this if statement
            if (file.name.endsWith("png")) {	//adjusted for new .png files
                results[setName] << file.name
            }
        }

        //now for the input sets
        //TODO: include the original SMILE input if that option is used
        //all this will do for now is serve the input set of CASRNs, no matter the original input method (SMILE vs. CASRN)
        dir = new File(getInputSetDir(resultSet))
        dir.eachFile(FILES) { file ->
            def setName = file.name.tokenize(".").first()
            if (!results.containsKey(setName)) {
                results[setName] = []
            }
                results[setName] << file.name
        }
        return results
    }

    def getMultiSetHeatMapImages(resultSet, nodeCutoff) {
        //todo: clean this up.
        def chartImage = new File("/home/hurlab/tox21/Output/${resultSet}/gct/Chart_Top${nodeCutoff}_ALL__P_0.05_P__ValueMatrix.png")
        def clusterImage = new File("/home/hurlab/tox21/Output/${resultSet}/gct/Cluster_Top${nodeCutoff}_ALL__P_0.05_P__ValueMatrix.png")
        def images 
        if (chartImage.exists() == true && clusterImage.exists() == true) {
            images = ["Chart_Top${nodeCutoff}_ALL__P_0.05_P__ValueMatrix.png", "Cluster_Top${nodeCutoff}_ALL__P_0.05_P__ValueMatrix.png"]
        }
        else {
            images = []
        }
        
        return images
    }

    def compressResultSet(resultSet) {
        directoryCompressionService.makeZip("tox21enricher.zip", storageProperties.getBaseDir() + resultSet)
    }

    def getSmilesWithResults() {
        return this.smilesWithResults
    }

    def getSmilesNoResults() {
        return this.smilesNoResults
    }

    def getAnalysisType() {
        return this.analysisType
    }

    def setSmilesWithResults(smilesWithResults) {
        this.smilesWithResults = smilesWithResults
    }

    def setSmilesNoResults(smilesNoResults) {
        this.smilesNoResults = smilesNoResults
    }

    def setAnalysisType(analysisType) {
        this.analysisType = analysisType
    }

    def getInputSets(resultSet, numSets, network, nodeCutoff) {
        println numSets
        println network
        def fh
        if (network == 1) {
            fh = new File(storageProperties.getBaseDir() + "${resultSet}/gct/Chart_Top${nodeCutoff}_ALL__P_0.05_P__ValueMatrix.ForNet") 
	}
        else if (network == 2)
            fh = new File(storageProperties.getBaseDir() + "${resultSet}/gct/Cluster_Top${nodeCutoff}_ALL__P_0.05_P__ValueMatrix.ForNet")
        else {
            println("Network type not set. Aborting.")
            return
        }
        def lines = fh.readLines()
        def inputSets = []
        def firstInputSetIndex
        int numInputSets = (Integer) numSets
        println "numInputSets: $numInputSets"
        def inputSetsMap = [:]
        def lineSplit
        def lineSplitList = []

        def final TERM_NAME_INDEX = 1;  //TODO: get rid of magic number
        
        def maxSetsNumber = 0
        def processedFirstLine = false

        println "IN ResultSetService.getInputSets()"
        
        lines.each { String line ->  //TODO: add number
            println "line: $line"
            lineSplit = line.split("\t") as List  //split as List so we can add an element to it if the last column had "\t" and got trimmed off (thus, one too short)
            println "lineSplit: $lineSplit"

            //I think we don't have to hardcode this
            //if (lineSplit.size() == 5) {
            //    lineSplit << ""  //add("") didn't work here for some reason; left shift also didn't work -> add/leftShift didn't work b/c .split() result type is Array not List or ArrayList; it should work now
            //    println "lineSplit $lineSplit"
            //}
            //else if (lineSplit.size() == 4) {  //need to figure out how this happens, but I think it's what's causing PAH to get more than what should be added
            //    lineSplit << ""
            //    lineSplit << ""
            //    println "lineSplit $lineSplit"
            //}




            
            //println "lineSplitList.size(): ${lineSplitList.size()}"

            if (processedFirstLine == true) {           // add buffer each line so it can be read correctly if too short
                for (int j=lineSplit.size(); j < maxSetsNumber; j++) {
                    lineSplit << ""
                }
            }

            firstInputSetIndex = (lineSplit.size() - numInputSets)  //if there are 3 input sets and 3 other tokens as expected before the input set columns, this will be 3 which is the starting index of set names
            
            println "lineSplit.size(): ${lineSplit.size()}"

            println "firstInputSetIndex: $firstInputSetIndex"
            println "${lineSplit[firstInputSetIndex]}"

            if (line.startsWith("GROUPID")) {  //if first line  //TODO: check if first line based on number from .each loop thing?
                println "LINE STARTED WITH 'GROUPID'"
                println "firstInputSetIndex: $firstInputSetIndex"
                //for (int i = 0; i < numInputSets; i++) {  //put input set names into list
                def inputSetIndex = 0
                for (int i = firstInputSetIndex; i < firstInputSetIndex + numInputSets; i++) {
                    //println ">>>ADDING: ${lineSplit[i + firstInputSetIndex]}"
                    println ">>>ADDING: ${lineSplit[i]} with index $i"
                    //inputSets[i] = lineSplit[i + firstInputSetIndex]
                    inputSets[inputSetIndex] = lineSplit[i]
                    inputSetIndex++
                }
                for (int i = 0; i < numInputSets; i++) {  //grab input set name and put into input map as key
                    inputSetsMap.put(inputSets[i], [])                    
                }
                maxSetsNumber = lineSplit.size()//figure out how many sets we have
                processedFirstLine = true

                println "inputSets $inputSets"
                println "inputSetsMap $inputSetsMap"
            }
            else {  //TODO: change to else if to check for ... other cases
                def inputSetIndex = 0
                //for (int i = 0; i < numInputSets; i++) {  //grab input set name and put in inputSets[]
                for (int i = firstInputSetIndex; i < firstInputSetIndex + numInputSets; i++) {
                    println "i before if: $i"
                    //println "lineSplit[i + firstInputSetIndex]: ${lineSplit[i + firstInputSetIndex]}"
                    println "lineSplit[i]: ${lineSplit[i]}"
                    //if (lineSplit[i + firstInputSetIndex] != "" && Character.isDigit(lineSplit[i + firstInputSetIndex].charAt(0))) {
                    if (lineSplit[i] != null && lineSplit[i] != "" && Character.isDigit(lineSplit[i].charAt(0))) {  //if not null and is a numerical value
                        println "i after if: $i"
                        //println "inputSets[i]: ${inputSets[i]}"
                        println "inputSets[i]: ${inputSets[inputSetIndex]}"
                        
                        println ">>>>>trying to add id: ${lineSplit[TERM_NAME_INDEX]}"
                        println ">>>>>trying to add dc: ${lineSplit[i]}"
                        println ">>>>>adding to index : ${i}"

                        //inputSetsMap.getAt("${inputSets[i]}").add(lineSplit[TERM_NAME_INDEX])
                        inputSetsMap.getAt("${inputSets[inputSetIndex]}").add(lineSplit[TERM_NAME_INDEX])
                        inputSetsMap.getAt("${inputSets[inputSetIndex]}").add(lineSplit[i])
                        //inputSetsMap.getAt("${inputSets[i]}").add(lineSplit[i + firstInputSetIndex])

                        //def indexOfSetToAddTerm = i + firstInputSetIndex
                        //println "indexOfSetToAddTerm $indexOfSetToAddTerm"
                        //println "adding ${lineSplit[TERM_NAME_INDEX]} to ${inputSets[i]}"
                        println "adding ${lineSplit[TERM_NAME_INDEX]} to ${inputSets[inputSetIndex]}"
                    }
                    inputSetIndex++
                }
            }

        }

        println "inputSetsMap $inputSetsMap"

        //******     This will re-analyze each item and remove ones that fall outside of the node cutoff limit       ******//
        def sortedInputSets = [:]
        inputSetsMap.each { sortedKey, sortedValue -> 
            def tmpSort = [:]
            for (int j = 0; j < sortedValue.size(); j++) {        //if so, iterate through that data set's associated items
                if (j % 2 != 0) {                                                    //and for each decimal number (they should always be on odd-numbered indices)
                    tmpSort += ["${sortedValue[j-1]}":sortedValue[j]]
                }
            }
            tmpSort = tmpSort.sort { a, b -> b.value.toFloat() <=> a.value.toFloat() }
            def listToKeep = []
            def deleteCutoff = 0
            tmpSort.each { sk, sv ->
                if (deleteCutoff < nodeCutoff.toInteger()) {
                    listToKeep += sk
                }
                deleteCutoff++
            }
            sortedInputSets += [(sortedKey.toString()):listToKeep]
        }

        println ">>>SORTED LIST:"
        sortedInputSets.each { key, value ->
            println "------$key------"
            println "| $value"
        }
        println sortedInputSets

        println "inputSetsMap $inputSetsMap"
        println "inputSets $inputSets"
        //return inputSetsMap
        return sortedInputSets
    }
}
