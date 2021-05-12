package tox21_test

/**
 * Created by Larson on 11/4/2016.
 */
class ScriptLocationProperties {
    private String perlScriptDir
    private String pythonScriptDir

    public String getPerlScriptDir() {
        //return this.perlScriptDir
	    return "${System.properties['user.home']}/tox21enricher/src/main/perl/"
    }
    public void setPerlScriptDir(String perlScriptDir) {
        //this.perlScriptDir = perlScriptDir
	    this.perlScriptDir = "${System.properties['user.home']}/tox21enricher/src/main/python/"
    }

    public String getPythonScriptDir() {
	    return "${System.properties['user.home']}/tox21enricher/src/main/perl/"
    }
    public void setPythonScriptDir(String perlScriptDir) {
	    this.pythonScriptDir = "${System.properties['user.home']}/tox21enricher/src/main/python/"
    }
}
