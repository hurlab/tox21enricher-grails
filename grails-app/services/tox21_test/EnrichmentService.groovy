package tox21_test

import grails.gorm.transactions.Transactional
import grails.util.Holders
import org.springframework.beans.factory.InitializingBean

@Transactional
class EnrichmentService implements InitializingBean {

    def scriptLocationProperties
    def config = Holders.getGrailsApplication().config
    def EXT_SCRIPT_PATH_PERL

    def validate() {

    }

    def performEnrichment(inputDir, outputDir, annoSelectStr) {
        println "current input dir: $inputDir"
        println "current output dir: $outputDir"
        println "annoSelectStr: $annoSelectStr"
        println "perl ${EXT_SCRIPT_PATH_PERL} $inputDir $outputDir $annoSelectStr"
        Process process = "perl ${EXT_SCRIPT_PATH_PERL}Perform_Tox21_PubChem_Enrichment_v2.3.pl $inputDir $outputDir $annoSelectStr".execute(null, new File("${EXT_SCRIPT_PATH_PERL}"))
        def out = new StringBuffer()
        def err = new StringBuffer()
        process.consumeProcessOutput(out, err)
        process.waitFor()
        if (out.size() > 0) print ("Output: $out\n")
        if (err.size() > 0) print ("Error: $err\n")
        print ("Exit value: ${process.exitValue()}\n")
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
        Process process = "perl ${EXT_SCRIPT_PATH_PERL}Create_DAVID_CHART_CLUSTER_gct_v2.2.pl $outputDir $nodeCutoff ALL P 0.05 P".execute(null, new File("${EXT_SCRIPT_PATH_PERL}"))
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
    }

}
