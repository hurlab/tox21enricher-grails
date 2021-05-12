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
	return "${System.properties['user.home']}/tox21enricher/Output/"
    }
    public void setBaseDir(String baseDir) {
        this.baseDir = baseDir
	this.baseDir = "${System.properties['user.home']}/tox21enricher/Input/"
    }
    public void setInputDir(String inputDir) {
        //this.inputDir = inputDir;
	this.inputDir = "${System.properties['user.home']}/tox21enricher/Input/"
    }
    public String getInputDir() {
        //return this.inputDir;
	return "${System.properties['user.home']}/tox21enricher/Input/"
    }
}
