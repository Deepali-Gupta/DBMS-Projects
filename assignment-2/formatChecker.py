import sys

fName = sys.argv[1];

if not fName.endswith(".sql"):
	print("Invalid File Name. Format Check FAILED!");
	sys.exit();
try:
	f = open(fName);
except(IOError):
	print("No Such File. Format Check FAILED!");
	sys.exit();

lines = f.readlines();

currState = 0;
#currState = 0: expecting start of a new query eg. "--1--"
#currState = 1: expecting preamble, or query. "--PREAMBLE--" or "--QUERY--"

def queryNumberLine(l):
	if not l.startswith("--"):
		return 0;
	if not l.endswith("--"):
		return 0;
	l = l.lstrip("-");
	l = l.rstrip("-");
	try:
		q = int(l);
	except ValueError:
		return 0;
	return 1;

def preambleStartLine(l):
	if l == "--PREAMBLE--":
		return 1;
	return 0;

def queryStartLine(l):
	if l == "--QUERY--":
		return 1;
	return 0;

def cleanupStartLine(l):
	if l == "--CLEANUP--":
		return 1;
	return 0;

def createViewLine(l):
	if l.startswith("CREATE VIEW "):
		return 1;
	return 0;

def getViewName(l):
	return l.split()[2];

def dropViewLine(l):
	if l.startswith("DROP VIEW "):
		return 1;
	return 0;


lineNumber = 0;
currLine = "";
prevLine = 0;

for l in lines:
	lineNumber += 1;
	l = l.rstrip();
	if len(l) == 0:
		continue;
	if (currState == 0):
		if queryNumberLine(l) == 0:
			print("Line " + `lineNumber` + ": Expected --queryNumber--. eg. --1--. Format Check FAILED!");
			sys.exit(0);
		currState = 1;
		continue;
	elif (currState == 1):
		if preambleStartLine(l)==1:
			currState = 2;
		elif queryStartLine(l)==1:
			currState = 3;
		else:
			print("Line " + `lineNumber` + ": Expected --PREAMBLE-- or --QUERY--. Format Check FAILED!");
			sys.exit(0);
	elif (currState == 2):
		if createViewLine(l)==1:
			currState = 2;
		elif queryStartLine(l)==1:
			currState = 3;
		elif l.startswith("--"):
			print("Line " + `lineNumber` + ": Expected --QUERY--. Format Check FAILED!");
			sys.exit(0);
	elif (currState == 3):
		if l.startswith('--'):
			print("Line " + `lineNumber` + ": Expected QUERY. Format Check FAILED!");
                        sys.exit(0);
		if l.endswith(';'):
			currState = 4;
	elif (currState == 4):
		if cleanupStartLine(l)==1:
			currState = 5;
		elif queryNumberLine(l) == 1:
			currState = 1;
		else:
			print("Line " + `lineNumber`+": Expected --queryNumber-- or --CLEANUP--. Format Check FAILED!");
			sys.exit(0);
	elif currState == 5:
		if dropViewLine(l) == 1:
			currState = 5;	#or nothing to do
		elif queryNumberLine(l) == 1:
                        currState = 1;
                elif l.startswith("--"):
                        print("Line " + `lineNumber`+": Expected --queryNumber--. Format Check FAILED!");
                        sys.exit(0);

		
		

		
		

f.close();
print("Format Check PASSED.");
