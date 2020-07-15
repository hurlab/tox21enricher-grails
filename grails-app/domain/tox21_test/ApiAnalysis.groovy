package tox21_test
import grails.rest.*
import org.grails.datastore.gorm.*
import grails.compiler.GrailsCompileStatic

@GrailsCompileStatic
@Resource(uri='/tox21-api', formats=['json', 'xml'])
class ApiAnalysis implements GormEntity<ApiAnalysis>{
	String id = UUID.randomUUID().toString()

	String casrnInput 
	String annoSelectStr
	String smiles
	String enrichAnalysisType
	String meshTerm 
    String pharmAction
    String activityColumn
    String adverseEffect
    String indication
    String knownToxicity
	String mechLevel1
    String mechLevel2
    String mechLevel3
    String mechanism
    String meshLevel1
    String meshLevel2
    String meshLevel3
    String modeClass
    String productClass
    String structureActivity
    String taLevel1
    String taLevel2
    String taLevel3
    String therapeuticClass
    String tissueToxicity
    String chem2Disease
    String ctdChem2Gene25
    String pathway
    String drugbankAtcCode
    String drugbankTargets
    String htsActive
    String leadscopeToxicity
    String multicaseToxPrediction
    String toxCast
    String toxinsTargets 
    String toxPrintStructure
    String toxRefDb 
    String casrnBox
    String smilesSearchType
    String thresholdSelectValue
    String smileBox
    String analysisType

	//allows each variable to be NULL (for testing, will probably change later).
	static constraints = {
		casrnInput nullable: true
		annoSelectStr nullable: true
		smiles nullable: true
		enrichAnalysisType nullable: true

		casrnInput nullable: true
		annoSelectStr nullable: true
		smiles nullable: true
		enrichAnalysisType nullable: true
		meshTerm nullable: true
		pharmAction nullable: true
		activityColumn nullable: true
		adverseEffect nullable: true
		indication nullable: true
		knownToxicity nullable: true
		mechLevel1 nullable: true
		mechLevel2 nullable: true
		mechLevel3 nullable: true
		mechanism nullable: true
		meshLevel1 nullable: true
		meshLevel2 nullable: true
		meshLevel3 nullable: true
		modeClass nullable: true
		productClass nullable: true
		structureActivity nullable: true
		taLevel1 nullable: true
		taLevel2 nullable: true
		taLevel3 nullable: true
		therapeuticClass nullable: true
		tissueToxicity nullable: true
		chem2Disease nullable: true
		ctdChem2Gene25 nullable: true
		pathway nullable: true
		drugbankAtcCode nullable: true
		drugbankTargets nullable: true
		htsActive nullable: true
		leadscopeToxicity nullable: true
		multicaseToxPrediction nullable: true
		toxCast nullable: true
		toxinsTargets nullable: true
		toxPrintStructure nullable: true
		toxRefDb nullable: true
		casrnBox nullable: true
		smilesSearchType nullable: true
		thresholdSelectValue nullable: true
		smileBox nullable: true
		analysisType nullable: true
	}
    
	//generates a unique ID for each entry, so we don't just incrementally assign int IDs.
	static mapping = {
		id generator: 'assigned'
	}
       
}


