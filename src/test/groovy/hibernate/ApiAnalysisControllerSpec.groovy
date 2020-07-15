package tox21_test

import grails.testing.web.controllers.ControllerUnitTest
import grails.test.hibernate.HibernateSpec
import spock.lang.Specification

@SuppressWarnings('MethodName')
class ApiAnalysisControllerSpec extends HibernateSpec implements ControllerUnitTest<ApiAnalysisController> {

    static doWithSpring = {
        jsonSmartViewResolver(JsonViewResolver)
    }

    def setup() {
    }

    def cleanup() {
    }

    void "test something"() {
        expect:"fix me"
            true == true
    }
}
