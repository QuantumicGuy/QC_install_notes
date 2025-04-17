#!/usr/bin/env python3
# Written By Qiang for workfunction Visualization from PLANAR_AVERAGE.dat file

import matplotlib.pyplot as plt

x = []
y = []
with open("PLANAR_AVERAGE.dat", mode='r') as f:
    first_line = f.readline()
    name_x = first_line.split()[0]
    name_y = first_line.split()[1]
    for line in f:
        xy=line.rstrip().split()
        x.append(float(xy[0]))
        y.append(float(xy[1]))

plt.plot(x,y) 
plt.xlabel(name_x) 
plt.ylabel(name_y) 
#plt.savefig('workfunction' + '.pdf', dpi=400)
plt.show()
