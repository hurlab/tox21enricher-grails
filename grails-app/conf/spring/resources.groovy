import tox21_test.ScriptLocationProperties
import tox21_test.StorageProperties
import grails.util.Environment

// Place your Spring DSL code here
beans = {
    switch(Environment.current) {
        case Environment.PRODUCTION:
            storageProperties(StorageProperties) {
                baseDir = "/home/hurlab/tox21/Output/"
                inputDir = "/home/hurlab/tox21/Input/"
            }
            scriptLocationProperties(ScriptLocationProperties) {
                perlScriptDir = "/home/hurlab/tox21/src/main/perl/"
                pythonScriptDir = "/home/hurlab/tox21/src/main/python/"
            }
            break

        case Environment.DEVELOPMENT:
            storageProperties(StorageProperties) {
                baseDir = "/home/hurlab/tox21/Output/"
                inputDir = "/home/hurlab/tox21/Input/"
            }
            scriptLocationProperties(ScriptLocationProperties) {
                perlScriptDir = "/home/hurlab/tox21/src/main/perl/"
                pythonScriptDir = "/home/hurlab/tox21/src/main/python/"
            }
            break
    }
}
