package tox21_test

class ResultSetModelAnno {

    //static contraints = { }

    private resultSet           //int
    private resultList          //list
    private numSets             //int
    private sortedResultMap     //map
    private annotationList      //list

    public ResultSetModelAnno() {
        this.resultSet = -1
        this.resultList = [-1]
        this.numSets = -1
        this.sortedResultMap = ["NoSet":-1]
        this.annotationList = [-1]
    }

    public ResultSetModelAnno(resultSet, resultList, numSets, sortedResultMap, annotationList){

        this.resultSet = resultSet
        this.resultList = resultList
        this.numSets = numSets
        this.sortedResultMap = sortedResultMap
        this.annotationList = annotationList

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

    //annotationList is a list of annotations for a chemical
    public setAnnotationList(annotationList) {
        this.annotationList = annotationList
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

    public getAnnotationList() {
        return this.annotationList
    }


    public String toString() {
        def ret = "**************************************************\n" +
                "Result set: ${this.getResultSet()}\n" +
                "Result list: ${this.getResultList()}\n" +
                "Num sets: ${this.getNumSets()}\n" +
                "Sorted result map: ${this.getSortedResultMap()}\n" +
                "Annotation List: ${this.getAnnotationList()}\n" + 
                "**************************************************"
        return ret
    }
}
