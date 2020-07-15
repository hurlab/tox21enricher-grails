//Configs pulled from grails-app/conf/tox21_test-config.properties

grails.mime.types = [
    json:	['application/json', 'text/json'],
    xml: 	['text/xml', 'application/xml']

]


//MySQL datasource
dataSource {
    pooled = true
    jmxExport = true
    driverClassName = "com.mysql.jdbc.Driver"
    url = "jdbc:mysql://127.0.0.1/tox21enricher?serverTimezone=UTC"
    username = "username"
    password = "password"
    properties {
        //Validation query keeps server from timing out.
        validationQuery = "SELECT 1 AS tox21_validation"
        validationQueryTimeout = 3
        validationInterval = 15000
        testOnBorrow = true
        testWhileIdle = true
    }
}
//PostgreSQL datasource
dataSource_psql {
    pooled = true
    driverClassName = "org.postgresql.Driver"
    dialect = "org.hibernate.dialect.PostgreSQLDialect"
    url = "jdbc:postgresql://127.0.0.1/tox21enricher"
    username = "username"
    password = "password"
}

hibernate {
    cache.use_second_level_cache = true
    cache.use_query_cache = false
//    cache.region.factory_class = 'net.sf.ehcache.hibernate.EhCacheRegionFactory' // Hibernate 3
    cache.region.factory_class = 'org.hibernate.cache.ehcache.EhCacheRegionFactory' // Hibernate 4
    singleSession = true // configure OSIV singleSession mode
    flush.mode = 'manual' // OSIV session flush mode outside of transactional context
}

// environment specific settings
environments {
    development {
        dataSource {
            dbCreate = "validate" // one of 'create', 'create-drop', 'update', 'validate', ''
        }
        dataSource_psql {
            dbCreate = "validate"
        }
        hibernate {
            dbCreate = "update"
        }
    }
    test {
        dataSource {
            dbCreate = "validate"
            //url = "jdbc:h2:mem:testDb;MVCC=TRUE;LOCK_TIMEOUT=10000;DB_CLOSE_ON_EXIT=FALSE"
        }
    }
    production {
        dataSource {
            dbCreate = "validate"
            url = "jdbc:mysql://127.0.0.1/tox21enricher"
        }
        dataSource_psql {
            dbCreate = "validate"
            url = "jdbc:postgresql://127.0.0.1/tox21enricher"
        }
    }
}
