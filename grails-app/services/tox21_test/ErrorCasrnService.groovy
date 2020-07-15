package tox21_test

import grails.gorm.transactions.Transactional

@Transactional
class ErrorCasrnService {

    def writeErrorCasrnsToFile(currentOutputDir, errorCasrns) {


        File errorCasrnsFile
        if (!errorCasrns.empty) {
            println "ERROR CASRNS: --------------------------- ${errorCasrns}"
            def setName
            errorCasrns.each { errorCasrn ->
                println "setName: ${setName}"
                println "errorCasrn.setName: ${errorCasrn.set}"
                if (!setName.equals(errorCasrn.set)) {
                    setName = errorCasrn.set
                    errorCasrnsFile = new File(currentOutputDir + '/' + setName + '__ErrorCasrns.txt')
                }
                println "errorCasrn: ${errorCasrn} ------------------ WTF"
                println "errorCasrnsFile -> ${errorCasrnsFile}"
                if (errorCasrnsFile != null) {
                    println "APPENDING"
                    errorCasrnsFile.append("${errorCasrn}\n")
                }
                else {
                    println "WRITING"
                    errorCasrnsFile.write("'Index' is the line on which the invalid input was found. 'Casrn' is the invalid CASRN. 'Set' is the invalid CASRN's input set.\n")
                    errorCasrnsFile.append("${errorCasrn}\n")
                }
            }
            if(errorCasrnsFile != null) {
                println "LOOK, IT EXISTS NOWWWWWWWWW"
            }
        }

        if(errorCasrnsFile != null) {
            println "LOOK, IT STILL EXISTSSSSSS"
            println "ERROR CASRNS TXT -> ${errorCasrnsFile.text}"
        }
    }
}
