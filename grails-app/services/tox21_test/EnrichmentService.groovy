package tox21_test

import grails.gorm.transactions.Transactional
import grails.util.Holders
import org.springframework.beans.factory.InitializingBean
import groovyx.net.http.HTTPBuilder

@Transactional
class EnrichmentService implements InitializingBean {

    def scriptLocationProperties
    def config = Holders.getGrailsApplication().config
    def EXT_SCRIPT_PATH_PERL
    def EXT_SCRIPT_PATH_PYTHON
    def PYTHON_DIR = "${System.properties['user.home']}/anaconda3/envs/my-rdkit-env/bin/python3.6 "

    def validate() {

    }

    def convertInchiToSmiles(inchi) {
        println("| Running Python script...")
        Process convertInchiToMol = "${PYTHON_DIR}/${System.properties['user.home']}/tox21enricher/src/main/python/convertInchiToMol.py ${inchi}".execute()
        def pythonOut = new StringBuffer()
        def pythonErr = new StringBuffer()
        convertInchiToMol.consumeProcessOutput(pythonOut, pythonErr)
        convertInchiToMol.waitFor()
        if (pythonOut.size() > 0) {
            print ("Output: $pythonOut\n")
            return pythonOut.toString()
        }
        if (pythonErr.size() > 0) {
            print ("Error: $pythonErr\n")
        } 
    }

    def checkSmilesValid(smiles) {
        Process checkSmiles = "${PYTHON_DIR}/${System.properties['user.home']}/tox21enricher/src/main/python/checkSmiles.py ${smiles}".execute()
        def pythonOut = new StringBuffer()
        def pythonErr = new StringBuffer()
        checkSmiles.consumeProcessOutput(pythonOut, pythonErr)
        checkSmiles.waitFor()
        if (pythonOut.size() > 0) {
            print ("Output: $pythonOut\n")
            return pythonOut.toString()
        }
        if (pythonErr.size() > 0) {
            print ("Error: $pythonErr\n")
            return pythonErr.toString()
        } 
    }

    def convertMolToSmiles(molecule) {
        Process checkMols = "${PYTHON_DIR}/${System.properties['user.home']}/tox21enricher/src/main/python/convertMols.py ${molecule}".execute()
        def pythonOut = new StringBuffer()
        def pythonErr = new StringBuffer()
        checkMols.consumeProcessOutput(pythonOut, pythonErr)
        checkMols.waitFor()
        if (pythonOut.size() > 0) {
            print ("Output: $pythonOut\n")
            return pythonOut.toString()
        }
        if (pythonErr.size() > 0) {
            print ("Error: $pythonErr\n")
            return pythonErr.toString()
        }
    }

    def calcReactiveGroups(mol) {
        println("| Running Python script to look for reactive groups for current smile...")
        Process reactiveGroups = "${PYTHON_DIR}/${System.properties['user.home']}/tox21enricher/src/main/python/calcReactiveGroups.py ${mol}".execute()
        def pythonOut = new StringBuffer()
        def pythonErr = new StringBuffer()
        reactiveGroups.consumeProcessOutput(pythonOut, pythonErr)
        reactiveGroups.waitFor()
        if (pythonOut.size() > 0) {
            print ("Output: $pythonOut\n")
            return pythonOut.toString()
        }
        if (pythonErr.size() > 0) print ("Error: $pythonErr\n")
    }

    def calcCasrnReactiveGroups(mol, check) {
        def mismatchesToReturn = []

        def warn_cyanide    = mol.cyanide
        def warn_isocyanate = mol.isocyanate
        def warn_aldehyde   = mol.aldehyde
        def warn_epoxide    = mol.epoxide
        
        //check both the original SMILE and this CASRN for reactive groups; we need to check them all to find mismatches
        if(check[0].toInteger() != warn_cyanide) {
            mismatchesToReturn += "Cyanide"
        } 
        if(check[1].toInteger() != warn_isocyanate) {
            mismatchesToReturn += "Isocyanate"
        }
        if(check[2].toInteger() != warn_aldehyde) {
            mismatchesToReturn += "Aldehyde"
        }
        if(check[3].toInteger() != warn_epoxide) {
            mismatchesToReturn += "Epoxide"
        }

        return mismatchesToReturn
    }

    def performEnrichment(inputDir, outputDir, annoSelectStr, processUUID, nodeCutoff) {
        println "current input dir: $inputDir"
        println "current output dir: $outputDir"
        println "annoSelectStr: $annoSelectStr"

        def tmpSplitAnno = annoSelectStr.split(" ")
        def annotationCheckedList = ""
        tmpSplitAnno.each {
            def tmpAnno = it.split("=")
            //if(tmpAnno[1] == "checked") annotationCheckedList += "${tmpAnno[0]},"
            annotationCheckedList += "${tmpAnno[0]} "
        }

        ///*

        def postEnrichment = new HTTPBuilder('http://localhost:8082')
        def postEnrichmentMessage = postEnrichment.get(path:'/enrich', query: [enrichmentUUID:"${processUUID}", annoSelectStr:"${annotationCheckedList}", nodeCutoff:nodeCutoff])

        println ">>> received from R server: $postEnrichmentMessage"
        //*/

        /*
        println "perl ${EXT_SCRIPT_PATH_PERL} $inputDir $outputDir $annoSelectStr"
        Process process = "perl ${EXT_SCRIPT_PATH_PERL}API_Perform_Tox21_PubChem_Enrichment_v2.3.pl $inputDir $outputDir $annoSelectStr".execute(null, new File("${EXT_SCRIPT_PATH_PERL}"))
        def out = new StringBuffer()
        def err = new StringBuffer()
        process.consumeProcessOutput(out, err)
        process.waitFor()
        if (out.size() > 0) print ("Output: $out\n")
        if (err.size() > 0) print ("Error: $err\n")
        print ("Exit value: ${process.exitValue()}\n")
        */
        
    }

    def createIndividualGCT(inputDir, outputDir) {
        Process process = "perl ${EXT_SCRIPT_PATH_PERL}Generate_individual_gct_file_for_significant_terms.pl $inputDir $outputDir 100 ALL P 0.05 P".execute(null, new File("${EXT_SCRIPT_PATH_PERL}"))
        def out = new StringBuffer()
        def err = new StringBuffer()
        process.consumeProcessOutput(out, err)
        process.waitFor()
        if (out.size() > 0) print ("Output: $out\n")
        if (err.size() > 0) print ("Error: $err\n")
        print ("Exit value: ${process.exitValue()}\n")
    }

    def createDavidChart(outputDir, nodeCutoff) {
        //changed to version 2.3 to support accessing database
        Process process = "perl ${EXT_SCRIPT_PATH_PERL}Create_DAVID_CHART_CLUSTER_gct_v2.4.pl $outputDir $nodeCutoff ALL P 0.05 P".execute(null, new File("${EXT_SCRIPT_PATH_PERL}"))
        def out = new StringBuffer()
        def err = new StringBuffer()
        process.consumeProcessOutput(out, err)
        process.waitFor()
        if (out.size() > 0) print ("Output: $out\n")
        if (err.size() > 0) print ("Error: $err\n")
        print ("Exit value: ${process.exitValue()}\n")
    }

    def createClusteringImages(outputDir) {
        Process process = "perl ${EXT_SCRIPT_PATH_PERL}Create_Hierarchical_Clustering_Images.pl $outputDir".execute(null, new File("/${EXT_SCRIPT_PATH_PERL}"))
        def out = new StringBuffer()
        def err = new StringBuffer()
        process.consumeProcessOutput(out, err)
        process.waitFor()
        if (out.size() > 0) print ("Output: $out\n")
        if (err.size() > 0) print ("Error: $err\n")
        print ("Exit value: ${process.exitValue()}\n")
    }

    @Override
    void afterPropertiesSet() throws Exception {
        this.EXT_SCRIPT_PATH_PERL = scriptLocationProperties.getPerlScriptDir()
        this.EXT_SCRIPT_PATH_PYTHON = scriptLocationProperties.getPythonScriptDir()
    }



}
