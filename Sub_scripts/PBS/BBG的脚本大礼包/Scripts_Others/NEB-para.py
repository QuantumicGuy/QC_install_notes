#!/usr/bin/python3

from ase import Atoms
from xtb.ase.calculator import XTB
from ase.io import iread,read
from ase.build import minimize_rotation_and_translation
from ase.optimize import BFGS,MDMin
from ase.neb import NEB
from ase.parallel import world
import os
import sys
import mpi4py

os.environ["OMP_NUM_THREADS"] = "2"
os.environ["MKL_NUM_THREADS"] = "2" 
os.environ["OMP_STACKSIZE"] = "8G"

Nbeads=24

## 1. Load reactant and optimize it.
reac = read('1.xyz')  # Reactant saved in 1.xyz
reac.calc = XTB(method="GFN2-xTB")
E = reac.get_potential_energy()
print("Single-point energy of reactant: ",E)
opt = BFGS(reac, trajectory='opt1.traj', logfile='opt1.log')
opt.run(fmax=0.05)
E = reac.get_potential_energy()
print("optimized Single-point energy of reactant: ",E)

## 2. Load product and optimize it.
prod = read('2.xyz') # Product saved in 1.xyz
minimize_rotation_and_translation(reac,prod)
prod.calc = XTB(method="GFN2-xTB")
E = prod.get_potential_energy()
print("Single-point energy of reactant: ",E)
opt = BFGS(prod, trajectory='opt1.traj', logfile='opt1.log')
opt.run(fmax=0.05)
E = prod.get_potential_energy()
print("optimized Single-point energy of product: ",E)

## 3. Make a string and set calculator.
images = [reac]
images += [reac.copy() for i in range(Nbeads)]
images += [prod]

# Set calculators:
n = len(images)-2 # internal Beads
j = world.rank * n // world.size
print(n,j,world.size)

for i, image in enumerate(images[1:-1]):
    if i == j:
        image.calc = XTB(method="GFN2-xTB")

#  Interpolate the images Linearly
neb = NEB(images,parallel=True)
neb.interpolate()


## 4. Optimize:
optimizer = BFGS(neb, trajectory='A2B.traj')
optimizer.run(fmax=0.04)




