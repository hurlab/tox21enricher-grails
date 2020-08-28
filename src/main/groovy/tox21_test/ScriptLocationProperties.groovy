package tox21_test

/**
 * Created by Larson on 11/4/2016.
 */
class ScriptLocationProperties {
    private String perlScriptDir
    private String pythonScriptDir

    public String getPerlScriptDir() {
        //return this.perlScriptDir
	    return "/home/hurlab/tox21/src/main/perl/"
    }
    public void setPerlScriptDir(String perlScriptDir) {
        //this.perlScriptDir = perlScriptDir
	    this.perlScriptDir = "/home/hurlab/tox21/src/main/python/"
    }

    public String getPythonScriptDir() {
	    return "/home/hurlab/tox21/src/main/perl/"
    }
    public void setPythonScriptDir(String perlScriptDir) {
	    this.pythonScriptDir = "/home/hurlab/tox21/src/main/python/"
    }
}
