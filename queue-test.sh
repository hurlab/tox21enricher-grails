#!/bin/bash
# script for testing queue capability of tox21api

#1
curl -i http://localhost:8080/tox21enricher/tox21-api/0ef83740-dc3a-436b-99c6-e97587812bbf/enrich
#2
curl -i http://localhost:8080/tox21enricher/tox21-api/0ef83740-dc3a-436b-99c6-e97587812bbf/enrich
#3
curl -i http://localhost:8080/tox21enricher/tox21-api/0ef83740-dc3a-436b-99c6-e97587812bbf/enrich
#4
curl -i http://localhost:8080/tox21enricher/tox21-api/0ef83740-dc3a-436b-99c6-e97587812bbf/enrich
#5
curl -i http://localhost:8080/tox21enricher/tox21-api/0ef83740-dc3a-436b-99c6-e97587812bbf/enrich
#6 - this one should be forced to wait
curl -i http://localhost:8080/tox21enricher/tox21-api/0ef83740-dc3a-436b-99c6-e97587812bbf/enrich
