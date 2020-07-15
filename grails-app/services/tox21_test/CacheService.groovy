package tox21_test

import grails.gorm.transactions.Transactional

@Transactional
class CacheService {

    def getNextCacheDir(currentOutputDirPath) {
        def currentCacheDirString //This will be set once we have 'CurrentOutputDir.txt'
        def currentCacheDirTextFile = new File("$currentOutputDirPath")
        if (!currentCacheDirTextFile.exists()) {
            currentCacheDirTextFile.newWriter().withWriter{ w -> w << "1" }
            currentCacheDirString = currentCacheDirTextFile.text
        } else {
            print "CurrentOutputDir.txt exists!\n"
            currentCacheDirString = currentCacheDirTextFile.text
        }
        if (currentCacheDirString == "100") {
            currentCacheDirString = "1"
        } else {
            currentCacheDirString = currentCacheDirString.toInteger()
            print "Current cache dir int: $currentCacheDirString\n"
            currentCacheDirString++
            print "Current cache dir int++: $currentCacheDirString\n"
        }
        currentCacheDirString = currentCacheDirString.toString()
        print "Current cache dir string: $currentCacheDirString\n"
        def w = currentCacheDirTextFile.newWriter()
        w << currentCacheDirString
        w.close()
        return currentCacheDirString
    }
}
