package tox21_test

import groovy.json.JsonOutput
import groovy.sql.Sql
import javax.activation.MimetypesFileTypeMap
import java.awt.Color

class AnalysisResultsController {

    //injecting psql datasource
    def dataSource_psql
    //injecting storage properties bean
    def storageProperties
    def scriptLocationProperties
    def MimeTypeService
    def ResultSetService

    def enrichmentService
    def directoryCompressionService
    def errorCasrnService

    def index() {

    }

    //regenerate network (& heatmap) with new number of nodes
    def regenNetwork() {
        println("regenerating network with ${params.nodeCutoff} for set ${params.currentOutputDir}")
        def fullOutputDir = "${System.properties['user.home']}/tox21enricher/Output/${params.currentOutputDir}"
        enrichmentService.createDavidChart(fullOutputDir, params.nodeCutoff)
        enrichmentService.createClusteringImages("${fullOutputDir}" + "/gct/")
        ResultSetService.compressResultSet(params.currentOutputDir)
        redirect(uri: "/analysis/success?resultSet=${params.currentOutputDir}&nodeCutoff=${params.nodeCutoff}")
    }

    //TODO: Fix download/serve functionality.
    //downloadFile expects a resultSet number (output dir number) and a filename from params (passed implicitly)
    def downloadFile() {
        println "In downloadFile()..."
        def res = params
        println res
        println storageProperties.getBaseDir() + params.resultSet + "/" + params.filename
        def file = new File(storageProperties.getBaseDir() + params.resultSet + "/" + params.filename)
        println file.name
        if (file.exists())
        {
            String contentType = MimeTypeService.inferMimeType(params.filename)
            println contentType
            response.setContentType(contentType)
            response.setHeader("Content-disposition", "attachment; filename=\"${file.name}\"")
            response.outputStream << file.bytes
        }
        else render "Error! Specified file '${file.name}' does not exist."
    }

    def serveUserManual() {
        println "In serveFile()... (serveUserManual)"
        def file = new File(scriptLocationProperties.getPerlScriptDir() + params.filename)
        println file
        println params.filename
        if (file.exists())
        {
            //response.setContentType("application/octet-stream") // or or image/JPEG or text/xml or whatever type the file is
            String contentType = MimeTypeService.inferMimeType(params.filename)
            println contentType
            response.setContentType(contentType)
            response.outputStream << file.bytes
        }
        else render "Error! Specified file '${file.name}' does not exist."
    }

    def serveFile() {
        println "In serveFile()... (serveFile)"
        def file = new File(storageProperties.getBaseDir() + params.resultSet + "/" + params.filename)
        println file
        println params.filename
        if (file.exists())
        {
            //response.setContentType("application/octet-stream") // or or image/JPEG or text/xml or whatever type the file is
            String contentType = MimeTypeService.inferMimeType(params.filename)
            println contentType
            response.setContentType(contentType)
            response.outputStream << file.bytes
        }
        else render "Error! Specified file '${file.name}' does not exist."
    }

    def serveInputFile() {
        println "In serveInputFile()..."
        def file = new File(storageProperties.getInputDir() + params.resultSet + "/" + params.filename)
        println file
        println params.filename
        if (file.exists())
        {
            //response.setContentType("application/octet-stream") // or or image/JPEG or text/xml or whatever type the file is
            String contentType = MimeTypeService.inferMimeType(params.filename)
            println contentType
            response.setContentType(contentType)
            response.outputStream << file.bytes
        }
        else render "Error! Specified file '${file.name}' does not exist."
    }

    //TODO: make this part of serveFile()
    def serveHeatmapLegend() {
        println "In serveHeatmapLegend()..."
        //TODO: this is awful; do it a way that makes sense (use a method from grails to get the path)
        def String[] heatmapLegendFullPathSplit = storageProperties.getBaseDir().split("Output/");
        def String heatmapLegendFullPath = heatmapLegendFullPathSplit[0] + "grails-app/" + params.heatmapLegendPath
        println "HEATMAP LEGEND FULL PATH ------------------------------------------ $heatmapLegendFullPath"
        def file = new File(heatmapLegendFullPath)
        println params.heatmapLegendPath
        if (file.exists())
        {
            //response.setContentType("application/octet-stream") // or or image/JPEG or text/xml or whatever type the file is
            String contentType = MimeTypeService.inferMimeType(params.heatmapLegendPath)
            println contentType
            response.setContentType(contentType)
            response.outputStream << file.bytes
        }
        else render "Error! Specified file '${file.name}' does not exist."
    }

    def getGctJsonData() {
        def gctJsonStr
        //TODO: put an else condition here
        if (params.network.equals("1")) {
            gctJsonStr = new File(storageProperties.getBaseDir() + "${params.resultSet}/gctChartFullNetwork.json").text
        }
        else if (params.network.equals("2")) {
            gctJsonStr = new File(storageProperties.getBaseDir() + "${params.resultSet}/gctClusterNetwork.json").text
        }
        render gctJsonStr
    }

    def createNetwork() {
        def network
        if (params.network.equals("1")) {
            network = 1
        }
        else if (params.network.equals("2")) {
            network = 2
        }
        else
            network = -1
        def resultSet = params.resultSet
        def numSets = params.int('numSets')

        println "NUMBER OF SETS $numSets"

        def inputSets = ResultSetService.getInputSets(resultSet, numSets, network, params.nodeCutoff)
        def filePath, fh
        println "PARAMS.NETWORK: ${params.network}"
        if (params.network.equals("1")) {
            filePath = new File(storageProperties.getBaseDir() + "${params.resultSet}/gct/Chart_Top${params.nodeCutoff}_ALL__P_0.05_P__ValueMatrix.ForNet").getCanonicalPath()
            println "Network == 1"
            fh = new File (storageProperties.getBaseDir() + "${params.resultSet}/gct/gctChartFullNetwork.json")
        }
        else if (params.network.equals("2")) {
            filePath = new File(storageProperties.getBaseDir() + "${params.resultSet}/gct/Cluster_Top${params.nodeCutoff}_ALL__P_0.05_P__ValueMatrix.ForNet").getCanonicalPath()
            println "Network == 2"
            fh = new File (storageProperties.getBaseDir() + "${params.resultSet}/gct/gctClusterNetwork.json")
        } else { println "params.network was neither 1 or 2. Something went wrong." }

        if (fh.exists()) {
            println "JSON file ${fh} in Output ${params.resultSet} already exists."
            return
        }

        def file = new File(filePath)

        def terms = []
        def uids = []

        println "params: $params"

        //TODO: make better
        def setCheckboxes
        def numSetCheckboxes
        def termsFromSelectedSets = []  //list of lists of terms
        String[] inputSetCheckbox;
        if (params.checkbox) {  //this should run and terms will be populated based on selected input sets (i.e. user was just on network page and submitted different network parameters)
            setCheckboxes = params.checkbox
            println setCheckboxes.getClass()
            if (setCheckboxes.getClass() == java.lang.String) {  //if user only checked one input set
                numSetCheckboxes = 1
                inputSetCheckbox = new String[numSetCheckboxes]
                inputSetCheckbox[0] = setCheckboxes
                for (int i = 0; i < numSetCheckboxes; i++) {
                    termsFromSelectedSets.add(inputSets.getAt(setCheckboxes))
                    println termsFromSelectedSets
                    println "setCheckboxes: ${setCheckboxes} inputSets.getAt(setCheckboxes) ${inputSets.getAt(setCheckboxes)}"
                }
                for (int i = 0; i < termsFromSelectedSets.size(); i++) {
                    for (int j = 0; j < termsFromSelectedSets[i].size(); j++) {
                        if (!terms.contains(termsFromSelectedSets[i][j])) {
                            println "term: ${termsFromSelectedSets[i][j]}"
                            terms.add(termsFromSelectedSets[i][j])
                            uids.add(termsFromSelectedSets[i][j])
                        }
                        else {
                            println "Term already present in terms list. Skipping."
                        }
                    }
                }
            }
            else {
                numSetCheckboxes = setCheckboxes.size()
                inputSetCheckbox = new String[numSetCheckboxes]
                for (int i = 0; i < numSetCheckboxes; i++) {
                    termsFromSelectedSets.add(inputSets.getAt(setCheckboxes[i]))
                    inputSetCheckbox[i] = setCheckboxes[i]
                    println termsFromSelectedSets
                    println "${setCheckboxes[i]} ${inputSets.getAt(setCheckboxes[i])}"
                }
                for (int i = 0; i < termsFromSelectedSets.size(); i++) {
                    for (int j = 0; j < termsFromSelectedSets[i].size(); j++) {
                        if (!terms.contains(termsFromSelectedSets[i][j])) {
                            println "term: ${termsFromSelectedSets[i][j]}"
                            terms.add(termsFromSelectedSets[i][j])
                            uids.add(termsFromSelectedSets[i][j])
                        }
                        else {
                            println "Term already present in terms list. Skipping."
                        }
                    }
                }
            }
            println "setCheckboxes: $setCheckboxes"
            println "numSetCheckboxes: $numSetCheckboxes"


        }
        else {  //this should run after enrichment as the normal pipeline/dataflow
            file.eachLine() { line, lineNumber ->
                if(lineNumber != 1) {
                    def values = line.split("\t")
                    terms.add(values[2])
                    uids.add(values[1])
                }
            }
            inputSetCheckbox = inputSets.keySet()
        }
        println "inputSetCheckbox: $inputSetCheckbox"

        //TODO: if/else for input sets; put input sets into terms[]; check if term already in terms[], if so continue



println "Terms: $terms"
println "UIDs: $uids"
println "Terms length: ${terms.size()}"
println "UIDs length: ${uids.size()}"
println ""

        //create array for SQL parameter binding
        //needs to be each term, then each term again
        //so, it should be twice the size of terms
        def termsSqlParams = []
        def uidsSqlParams = []
        terms.each { termsSqlParams << it }
        terms.each { termsSqlParams << it }
        uids.each { uidsSqlParams << it }
        uids.each { uidsSqlParams << it }

println "Terms SQL Params length: ${termsSqlParams.size()}"
println "Terms SQL Params: $termsSqlParams"
println ""

        def termsJoined = terms.join("','")
        def uidsJoined = uids.join("','")
println "Terms joined: $termsJoined"
println ""

println "UIDs joined: $uidsJoined"
println ""

        def termsString = "'" + termsJoined + "'"
        def uidsString = "'" + termsJoined + "'"
println "Terms string: $termsString"
println ""

    uids.each { println it }

        //string of question marks for bound params
        //should be the same size as terms
        def termsStringPlaceholder = ""
        def termPlaceholderCount = 0
        terms.each {
        //    termsStringPlaceholder += "?,"
            
            termPlaceholderCount++
        }
        uids.each { termsStringPlaceholder += "$it," }


println ""
println "TERMS LENGTH: ${terms.size()}"
        if(terms.size() < 1) {
            println ">>>>>>>>>>>. no terms, returning error"
            def qval
            if (params.qval == null) {
                qval = 0.05
            } else {
                qval = params.qval
            }
            render(view: "networkError", model: [resultSet: params.resultSet, network: params.network, inputSets: inputSets, numSets: numSets, qval: qval, nodeCutoff: params.nodeCutoff])
            return
        }

println ""
println "Term string placeholder length: $termPlaceholderCount"
println ""
        termsStringPlaceholder = termsStringPlaceholder.substring(0, termsStringPlaceholder.length() -1)
println "Terms string placeholder: $termsStringPlaceholder"

        def sql = new Sql(dataSource_psql)

        def qval
        if (params.qval == null) {
            qval = 0.05
        } else {
            qval = params.qval
        }
        println "qval: $qval"

        //mysql query for network generation
        //^^ this is now psql ^^
        def rows = sql.rows '''SELECT
  p.*, a.annoterm as name1, b.annoterm as name2, ac.annoclassname as class1, bc.annoclassname as class2, ac.baseurl as url1, bc.baseurl as url2
  FROM annoterm_pairwise p
    LEFT JOIN annotation_detail a 
      ON p.term1uid = a.annotermid
    LEFT JOIN annotation_detail b 
      ON p.term2uid = b.annotermid
    LEFT JOIN annotation_class ac 
      ON a.annoclassid = ac.annoclassid
    LEFT JOIN annotation_class bc 
      ON b.annoclassid = bc.annoclassid
  WHERE p.term1uid IN (''' + termsStringPlaceholder + ") AND p.term2uid IN (" + termsStringPlaceholder + ") AND p.qvalue <" + qval

        sql.close()

        println "###################################### ROWS: $rows"

        //create map for annotation class colors
        def classColors = generateAnnoClassColors()

        //create hashset for class legend
        def classes = new HashSet()

        //get rid of singletons bc that's how hashes work
        def rowsSet = new HashSet()
        for (p in rows) {
            //def pval = findTermPval(p)
            //TODO: make sure '@' never actually appears in term or class names :+1:
            rowsSet << p["name1"] + "@" + p["class1"] + "@" + p["url1"] + "@" + classToColor(p["class1"], classColors)
            rowsSet << p["name2"] + "@" + p["class2"] + "@" + p["url2"] + "@" + classToColor(p["class2"], classColors)
            classes << p["class1"]
            classes << p["class2"]
        }

        println "###################################### ROWS SET: $rowsSet"

        def map = [elements:[:]]
        map.elements = [nodes:[],edges:[]]
        for (s in rowsSet) {
            //TODO: strip class out of s and use that for name
            //can't strip bc hyphens are common in term names
            //added class after '@' above
            //now just split on that '@' and take the class name (first index)

            String[] rowsSetSplit = s.split("@")
            def id = "${rowsSetSplit[0]}@${rowsSetSplit[1]}"
            def url
            def color = rowsSetSplit[3]
            def rgb = Eval.me(color)
            def rgbCss = "rgb(" + rgb[0] + ", " + rgb[1] + ", " + rgb[2] + ")"
            if (rowsSetSplit[2].equals("null")) {
                url = null
                println "URL of ${id} is null"
            }
            else
                url = "${rowsSetSplit[2]}${rowsSetSplit[0]}"
            println "node color: $rgbCss"
            map.elements.nodes << [id: id, label: rowsSetSplit[0], url: url, color: rgbCss]
        }

        for (p in rows) {
            def color = generateJaccardColor(p.jaccardIndex)
            def rgb = Eval.me(color)
            def rgbCss = "rgb(" + rgb[0] + ", " + rgb[1] + ", " + rgb[2] + ")"
            println "edge color: $rgbCss"
            def edgeUuid = UUID.randomUUID().toString()
            map.elements.edges << [from: p.name1 + "@" + p.class1, to: p.name2 + "@" + p.class2, jaccard: p.jaccardIndex, color: rgbCss, id: edgeUuid]
        }
        println(JsonOutput.prettyPrint(JsonOutput.toJson(map)))
        //network JSON file in appropriate Output directory and for appropriate network
        //TODO: put an else condition here
        def gctJsonData
        if (params.network.equals("1")) {
            gctJsonData = new File(storageProperties.getBaseDir() + "${params.resultSet}/gctChartFullNetwork.json")
        }
        else if (params.network.equals("2")) {
            gctJsonData = new File(storageProperties.getBaseDir() + "${params.resultSet}/gctClusterNetwork.json")
        }
        gctJsonData.write(JsonOutput.prettyPrint(JsonOutput.toJson(map)))
        //pass parameter to createNetwork view
        render(view: "createNetworkVis", model: [resultSet: params.resultSet, network: params.network, inputSets: inputSets, numSets: numSets, qval: qval, inputSetCheckbox: inputSetCheckbox, classColors: classColors, classes: classes, nodeCutoff: params.nodeCutoff])
    }

    def createNetworkVis() {

        render(view: "createNetworkVis", model: [resultSet: params.resultSet, network: params.network, inputSets: inputSets, nodeCutoff: params.nodeCutoff])
    }

    def demoNetwork() {
        render(view: "demoNetwork")
    }

    def classToColor(annoClass, classColors) {
        if (classColors[annoClass]) {
            return classColors[annoClass]
        }
        else
            println "classColors[annoClass] does not exist"
    }

    def generateAnnoClassColors() {
        return [ACTIVITY_CLASS:[255, 11, 11], 
                ADVERSE_EFFECT:[246, 71, 36], 
                CTD_CHEM2DISEASE:[248, 112, 43], 
                CTD_CHEM2GENE_25:[251, 136, 20], 
                CTD_GOFAT_BIOPROCESS:[253, 174, 17],
                CTD_GOSLIM_BIOPROCESS:[171, 118, 14],
                CTD_PATHWAY:[249, 213, 32], 
                CTD_CHEMICALS_DISEASES:[33, 209, 86],
                CTD_CHEMICALS_GENES:[107, 237, 124],
                CTD_CHEMICALS_GOENRICH_CELLCOMP:[169, 232, 178],
                CTD_CHEMICALS_GOENRICH_MOLFUNCT:[12, 201, 107],
                CTD_CHEMICALS_PATHWAYS:[105, 207, 58],
                DRUGBANK_CARRIERS:[254, 254, 25],
                DRUGBANK_ENZYMES:[48, 246, 246], 
                DRUGBANK_TRANSPORTERS:[7, 210, 250],
                DRUGBANK_ATC:[217, 252, 41], 
                DRUGBANK_ATC_CODE:[50, 185, 253], 
                DRUGBANK_TARGETS:[178, 253, 29], 
                HTS_ACTIVE:[144, 244, 43], 
                HTS_STRONGACTIVE:[80, 140, 20], 
                INDICATION:[102, 245, 30], 
                KNOWN_TOXICITY:[54, 254, 14], 
                LEADSCOPE_TOXICITY:[42, 246, 42], 
                MECH_LEVEL_1:[18, 253, 58], 
                MECH_LEVEL_2:[6, 252, 88], 
                MECH_LEVEL_3:[15, 248, 131], 
                MECHANISM:[31, 252, 178], 
                MESH:[48, 249, 215], 
                MODE_CLASS:[26, 137, 247], 
                MULTICASE_TOX_PREDICTION:[8, 88, 248], 
                PHARMACTIONLIST:[47, 80, 247], 
                PRODUCT_CLASS:[31, 31, 244], 
                STRUCTURE_ACTIVITY:[52, 12, 251], 
                TA_LEVEL_1:[98, 20, 254], 
                TA_LEVEL_2:[140, 31, 249], 
                TA_LEVEL_3:[170, 17, 247], 
                THERAPEUTIC_CLASS:[212, 34, 248], 
                TISSUE_TOXICITY:[254, 48, 254], 
                TOXCAST_ACTIVE:[244, 30, 209], 
                TOXINS_TARGETS:[252, 35, 180], 
                TOXPRINT_STRUCTURE:[249, 24, 137], 
                TOXREFDB:[247, 55, 119], 
                TISSUE_TOXICITY:[244, 31, 67]]
    }

    def generateJaccardColor(jaccard) {
        println("Jaccard: $jaccard")
        println("TYPE: ${jaccard.getClass()}")
        if (jaccard < 0.0)
            println("Invalid jaccard (below 0)")
        else if (jaccard >= 0.0 && jaccard < 0.1) {
            return "[132, 232, 246]"
        }
        else if (jaccard >= 0.1 && jaccard < 0.2) {
            return "[121, 210, 233]"
        }
        else if (jaccard >= 0.2 && jaccard < 0.3) {
            return "[110, 189, 221]"
        }
        else if (jaccard >= 0.3 && jaccard < 0.4) {
            return "[99, 168, 289]"
        }
        else if (jaccard >= 0.4 && jaccard < 0.5) {
            return "[88, 147, 196]"
        }
        else if (jaccard >= 0.5 && jaccard < 0.6) {
            return "[78, 126, 184]"
        }
        else if (jaccard >= 0.6 && jaccard < 0.7) {
            return "[67, 104, 72]"
        }
        else if (jaccard >= 0.7 && jaccard < 0.8) {
            return "[56, 83, 159]"
        }
        else if (jaccard >= 0.8 && jaccard < 0.9) {
            return "[45, 62, 147]"
        }
        else if (jaccard >= 0.9 && jaccard <= 1.0) {
            return "[34, 41, 135]"
        }
        else
            println "Invalid jaccard (above 1): $jaccard"
        return "-1"
    }

}
