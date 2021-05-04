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
pool <- dbPool(
  drv = dbDriver("PostgreSQL",max.con = 100),
  dbname = "tox21enricher",
  host = "localhost",
  user = "username",
  password = "password",
  idleTimeout = 3600000
)