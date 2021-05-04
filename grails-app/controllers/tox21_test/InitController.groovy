package tox21_test

import grails.util.Holders
import groovy.sql.Sql
import net.sf.json.JSON
import org.postgresql.util.PSQLException
import org.springframework.beans.factory.InitializingBean
import org.springframework.web.servlet.ModelAndView

//for concurrency/async
import static groovyx.gpars.actor.Actors.actor
import grails.http.client.*
import grails.events.*
import java.util.concurrent.*
import java.util.*
import org.grails.web.util.WebUtils
import java.lang.management.ManagementFactory
import groovyx.net.http.*

import org.springframework.web.context.request.RequestContextHolder
import org.springframework.web.context.request.RequestAttributes

//file
import static groovy.io.FileType.FILES
import java.util.zip.ZipOutputStream
import java.util.zip.ZipEntry
import java.nio.channels.FileChannel

class InitController {

    def index() { 

    }
    //inject psql datasource
    def casrnService
    def dataSource_psql

    def getAnnoClassAsJson() {
        def sql = new Sql(dataSource_psql)
        def rows = sql.rows("SELECT * FROM annotation_class;")
        //println rows

        respond rows    //have to use respond instead of render
    }

    def getEnrichCount() {
        def sql = new Sql(dataSource_psql)
        def rows = sql.rows("SELECT COUNT(*) FROM enrichment_list;")
        respond rows
    }
    
}
