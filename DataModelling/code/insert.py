# script to execute multiple insert statements
import psycopg2
import csv
# Connect to database
conn = psycopg2.connect("host='localhost' port='5432' dbname='mydb' user='postgres' password='******'")
cur = conn.cursor()
# Read tuple from csvfile
with open('Consumer_Complaints.csv', 'r') as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in spamreader:
    	# sql statement
    	cur.execute("""insert into us_chronic_disease_indicators (yearstart, yearend, locationabbr, topic, question, response) values (%s,%s,%s,%s,%s,%s);""",(row[0],row[1],row[2],row[3],row[4],row[5]))
conn.commit()
conn.close()