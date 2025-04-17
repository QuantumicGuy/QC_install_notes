#!/usr/bin/env python

# Loads the sys to additional input in the line
# Loads the re search function

import sys
import re

# Set global variables
start = 0
end = 0

# This comes from the input
# Gives the name to a possible new file

filename = sys.argv[1]
newfile = str(filename)[:-4] + ".xyz"

# Open the original file in read mode
# Create a new file with writing rights

openold = open(filename,"r")
opennew = open(newfile,"w")

# Read the entire original file

rline = openold.readlines()

for p in range (len(rline)):
    if "Optimization completed." in rline[p]:
        print "Optimization completed"

for q in range (len(rline)):
    if "-- Stationary point found." in rline[q]:
        print "Stationary point found"

for s in range (len(rline)):
    if "imaginary frequencies (negative Signs)" in rline[s]:
        print "Imaginary frequencies found"

start=0

for i in range (len(rline)):
    if "Standard orientation:" in rline[i]:
        start = i
if start==0:
    for i in range (len(rline)):
       if "Input orientation:" in rline[i]:
           start = i


for m in range (start + 5, len(rline)):
    if "---" in rline[m]:
        end = m
        break

# Conversion section

for line in rline[start+5 : end] :
    words = line.split()
    word1 = int(words[1])
    word3 = str(words[3])
    if word1 == 17 :
        word1 = "Cl"
    elif word1 == 9 :
        word1 = "F "
    elif word1 == 35 :
        word1 = "Br"
    elif word1 == 5 :
        word1 = "B "
    elif word1 == 46 :
        word1 = "Pd"
    elif word1 == 6 :
        word1 = "C "
    elif word1 == 1:
        word1 = "H "
    elif word1 == 7:
        word1 = "N "
    elif word1 == 8:
        word1 = "O "
    elif word1 == 16:
        word1 = "S "
    print >>opennew, "%s%s" % (word1,line[30:-1])
openold.close()
opennew.close()

