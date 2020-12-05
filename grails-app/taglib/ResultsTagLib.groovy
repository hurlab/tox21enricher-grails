class ResultsTagLib { 
    def eachReactive = { attrs, body ->
        def reactiveList = attrs.reactive
        def itemToCheck = attrs.check 
        //println "############################################"
        //println reactiveList + " | " + itemToCheck
        //println "############################################"
        println ">>> making input for: ${itemToCheck}"
        def foundMismatch = "warnNo"

        reactiveList.each { reactive ->
            if (reactive.casrn  == itemToCheck) {
                foundMismatch = "warnYes"
            }
        }
        // put in format <casrn>__#Set<set number>
        def itemToShow = "${attrs.check}__#${attrs.dataSetName}"
        out << '<input class="' << foundMismatch << '" type="checkbox" name="CASRNSChecked" id="CASRNSChecked" value="' << itemToShow << '" checked="checked" />'
    }
}