#!/usr/bin/env python

# Loads the sys to additional input in the line
# Loads the re search function

import sys,getopt,os,types
import re

# Set global variables

# This comes from the input
# Gives the name to a possible new file

def getlistmin(my_list):
 min=my_list[0]
 for i in my_list:
  if i<min:
   min = i
 return min

def readfchk(input):
 print "reading %s" %(input)
 openold = open(input,"r")
 Property = " "
 Energy = " "
 Dipole = " "
 Polarizbility = " "
 Hyper = " "
 startD = 0
 startP = 0
 startH = 0
 startE = 0
# Read the entire original file

 rline = openold.readlines()
 for z in range (len(rline)):
    if "Total Energy                               R" in rline[z]:
        startE = z 
        string1 = rline[startE]
        Energy = string1[-25:]
 for i in range (len(rline)):
    if "Dipole Moment                              R   N=           3" in rline[i]:
        startD = i+1
        Dipole = rline[startD]
 if startD==0:
    print "Dipole moments not found!"

 for j in range (len(rline)):
    if "Polarizability                             R   N=           6" in rline[j]:
        startP = j+1
        Polarizbility = rline[startP]
        Polarizbility = Polarizbility + rline[startP+1]   
 if startP==0:
    print "Polarizability not found!"
 for k in range (len(rline)):
    if "HyperPolarizability                        R   N=          10" in rline[k]:
        startH = k+1
        Hyper = rline[startH]
        Hyper = Hyper + rline[startH+1]
 if startH==0:
    print "Hyperpolarizability not found!"
 L = 1 + len(Dipole.split()) + len(Polarizbility.split()) + len(Hyper.split())
# print L 
 Property = str(L) + Energy + Dipole + Polarizbility + Hyper
# print Property
# words = Property.split()
# L = len(words)
# print L
# Property = str(L) + " " + Property
# print Property
 Prop = Property.split()
 openold.close()
 return Prop


def usage():
 print "usage:./FF_gamma.py \n The ouput will be FF.out" 

#make sure good command
opts, args = getopt.getopt(sys.argv[1:], "hi:o:")
for op, value in opts:
 if op == "-h":
   usage()
   sys.exit()

def checkfile(input):
  if not os.path.isfile(input):
   print "%s is not in the current directory" %(input)
   sys.exit()

#define constants
FF_out = "FF.out"
COMPO = ('','x','y','z','xx','xy','yy','xz','yz','zz','xxx','xxy','xyy','yyy','xxz','xyz','yyz','xzz','yzz','zzz')

def getco():
 CO_beta=8.6392290
 CO_gamma=0.0005036
 print "for beta 1au=8.6392290E-33 esu, for gamma 1au=0.0005036E-36 esu"
 OPT = input("The atomic units will be transferred to esu \nenter 1 for beta (10E-33 esu) \nenter 2 for gamma (10E-36 esu) \nenter 3 to keep au \nNote that all properties will multiply this coefficient and wrong results will be obtained for some properties \n")
 CO = 1
 if OPT == 1:
  CO = CO_beta
 if OPT == 2:
  CO = CO_gamma 
 return CO

def getNsize():
 Nsize = 0.0003
 nn = input ("The electronic field is assumed as 0.0003 au \ninput 0 to keep or enter the strength \n")
 if nn != 0:
  Nsize = nn
 return Nsize

def getTitle(choice,N):
 if N == 1:
  line1 = "Energy"
 if N == 4:
  line1 = "Energy and dipole moments"
 if N == 10:
  line1 = "Energy, dipole moments and polarizabilities"
 if N == 20:
  line1 = "Energy, dipole moments, polarizabilities and hyperpolarizabilities"
 line = "The %d - order derivatives of %s \n" %(choice,line1)
 title = line + "for beta units in 10E-33 esu; for gamma units in 10E-36 esu \n" 
 return title 

def getoutputname(Paxis,Nsize,choice):
 name = Paxis + str(Nsize) + "_" + str(choice) + "order" + ".out"
 return name

#var = input("what properties to read? Please input the following numbers \n 1: dipole monents \n 2: polarizbilities \n")

Hints = "This script is going to calculate the 1st, 2nd, 3rd and 4th derivatives with finite field method (response properties)\nDipole moments, polarizabilities and hyperpolarizabilities will be read from fchk files. \ninput 1 2 3 or 4 \n"
choice = input(Hints)

if choice==1:
 f1 = raw_input("formula f'=(f(x+delta)-f(x))/delta \ntwo files is required f1 for the first term and f2 for the second one; input f1 now \n")
 checkfile(f1)
 str1 = readfchk(f1)
 N1 =int(str1[0])
 prop1 = str1[1:]

 f2 = raw_input("input f2 \n")
 checkfile(f2)
 str2 = readfchk(f2)
 N2 = int(str2[0])

 N = min(N1,N2)
 SUM = list()
 CO = getco() 
 Paxis = raw_input ("The electronic field along which axis: x, y or z? \n")
 Nsize = getNsize()
 FF_out = getoutputname(Paxis,Nsize,choice) 
 P = getTitle(choice,N)
 output = open(FF_out,"a")
 output.write(P)
 print P 
 for i in range(N):
  deri = CO*(float(prop1[i])-float(prop2[i]))/Nsize
  COMPONENTS = COMPO[i] + Paxis 
  Value = "%-11.1f" %(deri)
  PPPP = COMPONENTS + " " + Value + "\n"
  print PPPP
  output.write(PPPP)
  SUM.append(deri)
 output.close() 

Paxis = raw_input ("The electronic field along which axis: x, y or z? \n")
N=[]
propp=[]
if choice == 2:
 print "3 files are required. They are assumed to be %s-3.fchk, %s0.fchk and %s+3.fchk" % (Paxis,Paxis,Paxis)
 nfile = 3
 deltaff = ["-3","0","+3"]
if choice == 3:
 nfile = 4
 deltaff = ["-6","-3","+3","+6"]
 print "4 files are required. They are assumed to be %s-6.fchk, %s-3.fchk, %s+3.fchk and %s+6.fchk" %(Paxis,Paxis,Paxis,Paxis)
if choice == 4:
 nfile = 7
 deltaff = ["-9","-6","-3","0","+3","+6","+9"]
 print "7 files are required. They are assumed to be %s-9.fchk %s-6.fchk %s-3.fchk, %s0.fchk, %s+3.fchk, %s+6.fchk and %s+9.fchk" %(Paxis,Paxis,Paxis,Paxis,Paxis,Paxis,Paxis)
for i in range(nfile):
   nnnn=deltaff[i]
   name="y"+nnnn+".fchk"
   checkfile(name)
#   print f[i]
   strs = readfchk(name)
   N.append(int(strs[0]))
   propp.append(strs[1:])
#   print propp
N_min = getlistmin(N) 
SUM = list()
CO = getco()
Nsize = getNsize()
FF_out = getoutputname(Paxis,Nsize,choice)
P = getTitle(choice,N_min)
output = open(FF_out,"a")
output.write(P)
print P 
for i in range(N_min):
  if choice == 2:
   deri = CO*(float(propp[0][i])-2*float(propp[1][i])+float(propp[2][i]))/Nsize**2
  if choice == 3:
   deri = CO*(float(propp[0][i])-2*float(propp[1][i])+2*float(propp[2][i])-float(propp[3][i]))/(2*Nsize**3)
  if choice == 4:
   deri = CO*(float(propp[0][i])-12*float(propp[1][i])+39*float(propp[2][i])-56*float(propp[3][i])+39*float(propp[4][i])-12*float(propp[5][i]+float(propp[6][i])))/(36*Nsize**4)   
  COMPONENTS = COMPO[i] + Paxis + Paxis + Paxis
  Value = "%-11.1f" %(deri)
  PPPP = COMPONENTS + " " + Value + "\n"
  print PPPP
  output.write(PPPP)
  SUM.append(deri)
output.close() 

 
