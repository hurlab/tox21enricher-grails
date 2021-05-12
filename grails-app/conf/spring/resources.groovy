import tox21_test.ScriptLocationProperties
import tox21_test.StorageProperties
import grails.util.Environment

// Place your Spring DSL code here
beans = {
    switch(Environment.current) {
        case Environment.PRODUCTION:
            storageProperties(StorageProperties) {
                baseDir = "${System.properties['user.home']}/tox21enricher/Output/"
                inputDir = "${System.properties['user.home']}/tox21enricher/Input/"
            }
            scriptLocationProperties(ScriptLocationProperties) {
                perlScriptDir = "${System.properties['user.home']}/tox21enricher/src/main/perl/"
                pythonScriptDir = "${System.properties['user.home']}/tox21enricher/src/main/python/"
            }
            break

        case Environment.DEVELOPMENT:
            storageProperties(StorageProperties) {
                baseDir = "${System.properties['user.home']}/tox21enricher/Output/"
                inputDir = "${System.properties['user.home']}/tox21enricher/Input/"
            }
            scriptLocationProperties(ScriptLocationProperties) {
                perlScriptDir = "${System.properties['user.home']}/tox21enricher/src/main/perl/"
                pythonScriptDir = "${System.properties['user.home']}/tox21enricher/src/main/python/"
            }
            break
    }
}
