package tox21_test

class ResultSetModel {

    //static contraints = { }

    private resultSet           //int
    private resultList          //list
    private numSets             //int
    private sortedResultMap     //map
    private images              //list
    private smilesWithResults   //list
    private smilesNoResults     //list
    private enrichAnalysisType  //string
    private gctPerSetDir        //string

    public ResultSetModel() {
        this.resultSet = -1
        this.resultList = [-1]
        this.numSets = -1
        this.sortedResultMap = ["NoSet":-1]
        this.images = [-1]
        this.smilesWithResults = [-1]
        this.smilesNoResults = [-1]
        this.enrichAnalysisType = "NoAnalysisType"
        this.gctPerSetDir = "NoPath"
    }

    public ResultSetModel(resultSet, resultList, numSets, sortedResultMap, images, smilesWithResults, smilesNoResults, enrichAnalysisType, gctPerSetDir) {

        this.resultSet = resultSet
        this.resultList = resultList
        this.numSets = numSets
        this.sortedResultMap = sortedResultMap
        this.images = images
        this.smilesWithResults = smilesWithResults
        this.smilesNoResults = smilesNoResults
        this.enrichAnalysisType = enrichAnalysisType
        this.gctPerSetDir = gctPerSetDir
    }

    //resultSet is int of current results dir
    public setResultSet(resultSet) {
        this.resultSet = resultSet
    }

    //resultList is list of files in results dir
    public setResultList(resultList) {
        this.resultList = resultList
    }

    //numSets is number of sets in result set
    public setNumSets(numSets) {
        this.numSets = numSets
    }

    //sortedResultMap is a sorted map of files in result set
    public setSortedResultMap(sortedResultMap) {
        this.sortedResultMap = sortedResultMap
    }

    //images is list of multi set heat map images
    public setImages(images) {
        this.images = images
    }

    //smilesWithResults is a list of the SMILE strings from input that had matching tox21 CASRNs
    public setSmilesWithResults(smilesWithResults) {
        this.smilesWithResults = smilesWithResults
    }

    //smilesNoResults is a list of SMILE string from input that did match any tox21 CASRNs
    public setSmilesNoResults(smilesNoResults) {
        this.smilesNoResults = smilesNoResults
    }

    //enrichAnalysisType is a string that represents the type of input the user entered (SMILES or CASRNS)
    public setEnrichAnalysisType(enrichAnalysisType) {
        this.enrichAnalysisType = enrichAnalysisType
    }

    //gctPerSetDir is a string that points to the gct_per_set directory that contains the heatmap jpegs for individual sets
    public setGctPerSetDir(gctPerSetDir) {
        this.gctPerSetDir = gctPerSetDir
    }

    public getResultSet() {
        return this.resultSet
    }

    public getResultList() {
        return this.resultList
    }

    public getNumSets() {
        return this.numSets
    }

    public getSortedResultMap() {
        return this.sortedResultMap
    }

    public getImages() {
        return this.images
    }

    public getSmilesWithResults() {
        return this.smilesWithResults
    }

    public getSmilesNoResults() {
        return this.smilesNoResults
    }

    public getEnrichAnalysisType() {
        return this.enrichAnalysisType
    }

    public getGctPerSetDir() {
        return this.gctPerSetDir
    }

    public String toString() {
        def ret = "**************************************************\n" +
                "Result set: ${this.getResultSet()}\n" +
                "Result list: ${this.getResultList()}\n" +
                "Num sets: ${this.getNumSets()}\n" +
                "Sorted result map: ${this.getSortedResultMap()}\n" +
                "Images: ${this.getImages()}\n" +
                "Smiles with results: ${this.getSmilesWithResults()}\n" +
                "Smiles no results: ${this.getSmilesNoResults()}\n" +
                "Enrich analysis type: ${this.getEnrichAnalysisType()}\n" +
                "gctPerSetDir: ${this.getGctPerSetDir()}\n" +
                "**************************************************"
        return ret
    }
}
