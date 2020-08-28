// https://mvnrepository.com/artifact/mysql/mysql-connector-java
//@GrabConfig( systemClassLoader=true )
    //@Grab(group='mysql', module='mysql-connector-java', version='5.1.38')


import groovy.sql.Sql

def filePath = file

def file = new File(filePath)

def terms = []

file.splitEachLine("\t") { line -> 
	terms.add(line[1])
}

//println "Terms: $terms"
//println ""

termsJoined = terms.join("','")
//println "Terms joined: $termsJoined"
//println ""

termsString = "'" + termsJoined + "'"
//println "Terms string: $termsString"
//println ""

def url = "jdbc:mysql://localhost:3306/tox21second"
def user = "user"
def password = "password"
def driver = "com.mysql.jdbc.Driver"

def sql = Sql.newInstance(url, user, password, driver)

//do stuff
def rows = sql.rows '''SELECT
  p.*, a.annoTerm as name1, b.annoTerm as name2
  FROM annoterm_pairwise p
    LEFT JOIN annotation_detail a ON p.term1UID = a.annoTermID
    LEFT JOIN annotation_detail b ON p.term2UID = b.annoTermID
  WHERE a.annoTerm in (''' + termsString + ") AND b.annoTerm IN (" + termsString + ") AND p.qvalue > .05;"
  
  /*println '''SELECT
  p.*, a.annoTerm as name1, b.annoTerm as name2
  FROM annoterm_pairwise p
    LEFT JOIN annotation_detail a ON p.term1UID = a.annoTermID
    LEFT JOIN annotation_detail b ON p.term2UID = b.annoTermID
  WHERE a.annoTerm in (''' + termsString + ''') AND b.annoTerm = IN (''' + termsString + ''')'''*/
//println rows.join("\n")
sql.close()

import groovy.json.JsonOutput 
def map = [elements:[:]]
map.elements = [nodes:[],edges:[]]
for (s in terms) {
  map.elements.nodes << [data: [id: s, name: s]]
}
for (p in rows) {
  map.elements.edges << [data: [source: p.name1, target: p.name2]]
}
println(JsonOutput.prettyPrint(JsonOutput.toJson(map)))
