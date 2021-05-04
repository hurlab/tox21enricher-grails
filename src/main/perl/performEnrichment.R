library(plumber)
r <- plumb("~/tox21r/tox21enricher/performEnrichment.R")
r$run(host="127.0.0.1",port=8082)
