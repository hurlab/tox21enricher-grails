//Configs pulled from grails-app/conf/tox21_test-config.properties

grails.mime.types = [
    json:	['application/json', 'text/json'],
    xml: 	['text/xml', 'application/xml']

]

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
        dataSource_psql {
            dbCreate = "validate" // one of 'create', 'create-drop', 'update', 'validate', ''
        }
        hibernate {
            dbCreate = "update"
        }
    }
    test {
    }
    production {
        dataSource_psql {
            dbCreate = "validate"
            url = "jdbc:postgresql://127.0.0.1/tox21enricher"
        }
    }
}
