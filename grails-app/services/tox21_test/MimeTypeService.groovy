package tox21_test

import grails.gorm.transactions.Transactional

@Transactional
class MimeTypeService {

    def inferMimeType(String fileName) {
        def knownExt2Filetypes = [
                gct:'text/plain',
                txt:'text/plain',
                xls:'application/vnd.ms-excel',
                zip:'application/zip',
                jpeg: 'image/jpeg',
                jpg: 'image/jpeg',
                png: 'image/png',
                gif: 'image/gif'
        ]
        def fileExt
        if (fileName.contains('.')) {
            fileExt = fileName.tokenize('.').last()
        }
        return knownExt2Filetypes[fileExt.toLowerCase()]

    }


}
