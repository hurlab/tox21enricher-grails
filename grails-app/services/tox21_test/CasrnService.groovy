package tox21_test

import grails.gorm.transactions.Transactional

@Transactional
class CasrnService {
    def scriptLocationProperties

    def private tox21CasrnList = []

    def setTox21CasrnList() {
        def filename = "tox21-casrn.txt"
        //TODO: create new property in resources.groovy for this asset
        def file = new File(scriptLocationProperties.getPerlScriptDir().toString()+ filename)
        file.eachLine({
            line ->
                this.tox21CasrnList.add(line)
        })
    }

    def getTox21CasrnList() {
        return this.tox21CasrnList
    }
}
