/*
    This groovy script is meant to test groovy/Rserve integration.
    
*/

//Use Grape to grab the appropriate maven repository
//@Grab(group='org.rosuda.REngine', module='Rserve', version='1.8.1')
import org.rosuda.REngine.Rserve.RConnection

println "Connecting..."
def conn = new RConnection()
if (conn.isConnected()) {
    println "Connected!\n"
}

println "Checking working dir..."
def wd = conn.eval('getwd()').asString()
println "Working dir is ${wd}\n"

def filename = 'foo.txt'
println "Creating '${filename}'..."
conn.createFile(filename)
println "Done!\n"

def word = 'bar'
println "Writing ${word} to '${filename}'..."
conn.eval("writeLines('${word}', '${filename}')")
println "And so it is written.\n"
