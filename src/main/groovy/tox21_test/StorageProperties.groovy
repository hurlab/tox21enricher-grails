package tox21_test

/**
 * Created by Larson on 10/3/2016.
 */
//TODO: externalize
class StorageProperties {
    private String baseDir
    private String inputDir

    public String getBaseDir() {
        //return this.baseDir
	return "/home/hurlab/tox21/Output/"
    }
    public void setBaseDir(String baseDir) {
        this.baseDir = baseDir
	this.baseDir = "/home/hurlab/tox21/Input/"
    }
    public void setInputDir(String inputDir) {
        //this.inputDir = inputDir;
	this.inputDir = "/home/hurlab/tox21/Input/"
    }
    public String getInputDir() {
        //return this.inputDir;
	return "/home/hurlab/tox21/Input/"
    }
}
