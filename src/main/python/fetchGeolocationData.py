#!/home/hurlab/anaconda3/envs/my-rdkit-env/bin/python3.6

# Python script that will fetch geolocation data for the IP addresses stored in the "enrichment_list" table in the PostgreSQL database every week

from datetime import date
import time
import psycopg2
from psycopg2 import Error
import requests
import sys

# Timestamp when the script runs
print("! Beginning geolocation service at: " + time.strftime("%H:%M:%S", time.localtime()) + " on: " + str(date.today()))

try:
    conn = psycopg2.connect("dbname='tox21enricher'")
    cur = conn.cursor()

    # Grab IP addresses with missing geolocation data
    cur.execute("SELECT DISTINCT ip FROM enrichment_list WHERE loc_continent IS NULL OR loc_country IS NULL OR loc_region IS NULL OR loc_city IS NULL OR loc_zip IS NULL OR loc_latitude IS NULL OR loc_longitude IS NULL;")
    res = cur.fetchall()
    print("received: ",res)
    
    numberMissing = cur.rowcount
    print("rowcount: ",numberMissing)
    if numberMissing > 2500:    # Must be less than 10,000/month or less than 2500/week - if greater, trim to 2500
        res = res[0:2500]

    if numberMissing != 0:      # If nothing is missing, don't query API
        apiQueryStr = ""
        for i in res:
            tmp = str(i).replace('(','').replace(')','').replace(',','').replace('\'','')
            # Query ipstack API
            apiQueryStr = str("http://api.ipstack.com/"+tmp+"?access_key=a0a6ebfe176c732bac09b9f5eb736993")
            print("GET ",apiQueryStr)
            req = requests.get(url=apiQueryStr)
            reqJson = req.json()

            #location variables
            continent   = reqJson['continent_name']   #switch to 'continent_code' for shorter representation
            country     = reqJson['country_name']     #switch to 'country_code' for shorter representation
            region      = reqJson['region_name']      #switch to 'region_code' for shorter representation
            city        = reqJson['city']
            zipcode     = reqJson['zip']
            latitude    = reqJson['latitude']
            longitude   = reqJson['longitude']

            # Update db table with geolocation data
            locationSaveToDbStr = "UPDATE enrichment_list SET loc_continent='"+continent+"', loc_country='"+country+"', loc_region='"+region+"', loc_city='"+city+"', loc_zip='"+str(zipcode)+"', loc_latitude='"+str(latitude)+"', loc_longitude='"+str(longitude)+"' WHERE ip='"+tmp+"';"

            print(">> "+ str(locationSaveToDbStr))
            cur.execute(locationSaveToDbStr)
            conn.commit()

except (Exception, Error) as error:
    print("Error while connecting to PostgreSQL", error)
finally:
    if (conn):
        cur.close()
        conn.close()
        print("Closed PostgreSQL database connection.")