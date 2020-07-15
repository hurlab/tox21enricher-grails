package tox21_test

class BootStrap {

    def init = { servletContext ->
	new ApiAnalysis(
		casrnBox: "[CASRNBox:#Set1\n965-90-2\n50-50-0\n979-32-8\n4245-41-4\n143-50-0\n17924-92-4\n297-76-7\n152-43-2\n313-06-4\n4956-37-0\n112400-86-9, smilesSearchType:Substructure, thresholdSelectValue:0.5, SMILEBox:, analysisType:CASRNS, controller:analysis, format:null, action:enrich]",
		casrnInput: "casrnInput-Test-1",
		goodCasrns: "[#Set1, 965-90-2, 50-50-0, 979-32-8, 4245-41-4, 143-50-0, 17924-92-4, 297-76-7, 152-43-2, 313-06-4, 4956-37-0, 112400-86-9]",
		errorCasrns: "[]",
		annoSelectStr: "MESH_LEVEL_3=checked KNOWN_TOXICITY=checked MODE_CLASS=checked TOXINS_TARGETS=checked CTD_CHEM2GENE_25=checked TOXCAST=checked MESH_LEVEL_1=checked PHARMACTIONLIST=checked MESH_LEVEL_2=checked INDICATION=checked PRODUCT_CLASS=checked DRUGBANK_TARGETS=checked MECHANISM=checked HTS_ACTIVE=checked MECH_LEVEL_3=checked MULTICASE_TOX_PREDICTION=checked MECH_LEVEL_1=checked MECH_LEVEL_2=checked TA_LEVEL_2=checked TA_LEVEL_1=checked TOXREFDB=checked CTD_CHEM2DISEASE=checked DRUGBANK_ATC_CODE=checked TA_LEVEL_3=checked ACTIVITY_CLASS=checked THERAPEUTIC_CLASS=checked CTD_PATHWAY=checked ADVERSE_EFFECT=checked LEADSCOPE_TOXICITY=checked MESH=checked TISSUE_TOXICITY=checked STRUCTURE_ACTIVITY=checked TOXPRINT_STRUCTURE=checked",
		groovyParams: "groovyParams-Test-1",
		psqlErrorSmiles: "[]",
		psqlGoodSmiles: "[]",
		smiles: "[]",
		smilesWithResults: "[]",
		smilesNoResults: "[]",
		enrichAnalysisType: "CASRNS"
	).save() 
    }
    def destroy = {
    }
}
