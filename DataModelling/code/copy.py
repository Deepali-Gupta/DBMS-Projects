import csv
# to duplicate data
with open('U.S._Chronic_Disease_Indicators__CDI_.csv', 'r') as csvfile: 
	spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
	with open('new_us.csv','w') as secfile: 
		spamwriter = csv.writer(secfile,delimiter=',',quotechar='|')
		for row in spamreader:
			for i in range(0,267):
				spamwriter.writerow(row)