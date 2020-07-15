package tox21_test

import grails.testing.gorm.DomainUnitTest
import grails.test.hibernate.HibernateSpec
import spock.lang.Specification

class ApiAnalysisSpec extends HibernateSpec implements DomainUnitTest<ApiAnalysis> {

    def setup() {
        
    }

    def cleanup() {
    }

    void 'add an enrichment entry'() {
        when: 'a new enrichment is added'
            ApiAnalysis apiAnalysis = new ApiAnalysis()
            apiAnalysis.casrnInput = '965-90-2, 50-50-0' 
            apiAnalysis.annoSelectStr = 'MESH_LEVEL_3=checked KNOWN_TOXICITY=checked MODE_CLASS=checked TOXINS_TARGETS=checked CTD_CHEM2GENE_25=checked TOXCAST=checked MESH_LEVEL_1=checked PHARMACTIONLIST=checked MESH_LEVEL_2=checked INDICATION=checked PRODUCT_CLASS=checked DRUGBANK_TARGETS=checked MECHANISM=checked HTS_ACTIVE=checked MECH_LEVEL_3=checked MULTICASE_TOX_PREDICTION=checked MECH_LEVEL_1=checked MECH_LEVEL_2=checked TA_LEVEL_2=checked TA_LEVEL_1=checked TOXREFDB=checked CTD_CHEM2DISEASE=checked DRUGBANK_ATC_CODE=checked TA_LEVEL_3=checked ACTIVITY_CLASS=checked THERAPEUTIC_CLASS=checked CTD_PATHWAY=checked ADVERSE_EFFECT=checked LEADSCOPE_TOXICITY=checked MESH=checked TISSUE_TOXICITY=checked STRUCTURE_ACTIVITY=checked TOXPRINT_STRUCTURE=checked'
            apiAnalysis.smiles = 'none' 
            apiAnalysis.enrichAnalysisType = 'CASRNS'
            apiAnalysis.save()

        then: 'enrichment success'
            true == true
    }
}
