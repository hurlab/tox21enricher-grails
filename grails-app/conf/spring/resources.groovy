import tox21_test.ScriptLocationProperties
import tox21_test.StorageProperties
import grails.util.Environment

// Place your Spring DSL code here
beans = {
    switch(Environment.current) {
        case Environment.PRODUCTION:
            storageProperties(StorageProperties) {
                baseDir = "~/tox21enricher/Output/"
                inputDir = "~/tox21enricher/Input/"
            }
            scriptLocationProperties(ScriptLocationProperties) {
                perlScriptDir = "~/tox21enricher/src/main/perl/"
                pythonScriptDir = "~/tox21enricher/src/main/python/"
            }
            break

        case Environment.DEVELOPMENT:
            storageProperties(StorageProperties) {
                baseDir = "~/tox21enricher/Output/"
                inputDir = "~/tox21enricher/Input/"
            }
            scriptLocationProperties(ScriptLocationProperties) {
                perlScriptDir = "~/tox21enricher/src/main/perl/"
                pythonScriptDir = "~/tox21enricher/src/main/python/"
            }
            break
    }
}
