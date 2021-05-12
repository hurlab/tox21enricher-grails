library(config)
library(DT)
library(pool)
library(rjson)
library(RPostgreSQL)
library(shiny)
library(shinyBS)
library(shinycssloaders)
library(shinydashboard)
library(shinyjs)

# Connect to PostgreSQL tox21enricher database
tox21db <- config::get("tox21enricher")
pool <- dbPool(
  drv = dbDriver("PostgreSQL",max.con = 100),
  dbname = tox21db$database,
  host = tox21db$host,
  user = tox21db$uid,
  password = tox21db$pwd,
  idleTimeout = 3600000
)