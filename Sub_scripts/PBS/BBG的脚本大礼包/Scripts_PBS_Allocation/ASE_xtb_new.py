#!/usr/bin/python3
def labels_conversion(input_string): 
  new_string = []
  tmp = input_string.split(",")
  for i in tmp:
    if "-" in i:
      start = int(i.split("-")[0]) - 1
      end = int(i.split("-")[1])
      for j in range(start,end):
        new_string.append(j)
    else:
      new_string.append(int(i) - 1)
  return new_string

from ase import Atoms
from ase.units import Hartree
from ase.constraints import FixAtoms
from ase.optimize import BFGSLineSearch
from ase.io import read,write,iread
##from xtb.ase.calculator import XTB     
from xtb import GFN1
import os,sys,datetime,time

start_time = time.time()
start_date = datetime.datetime.now()

name = sys.argv[1]
mol = read(name+".xyz")
total_atoms = len(mol.get_atomic_numbers())

# three lattice vectors of the cell 
a = [20.2367,0.0,0.0]
b = [3.94571083,19.95983846,0.0]
c = [0.0,0.0,27.7896]
mol.cell = [a, b, c]

# PBC: periodic boundary conditions
mol.pbc = (True, True, True)

print('***  ASE program with xtb-6.3.pre2 started at {0}  ***\n'.format(start_date.strftime("%Y-%m-%d %H:%M:%S")))
print('-> Task name:  %50s' %name)
print('-> Cell parameters:  %10s' %mol.get_cell())
print('-> Total number of atoms in a cell:  %27s' %total_atoms)
print('-> PBC dimensions:  %45s' %mol.get_pbc())

#  fix atoms (index starts from 1)
fixed_atoms = "1-20,22-41,43-62,64-83,85-104,106-125,127-146,148-167,169-188,190-209,211-230,232-251,253-272,274-293,295-314,316-335"
fix = FixAtoms(indices=labels_conversion(fixed_atoms))
mol.set_constraint(fix)
print('-> The atoms with following labels are fixed:\n{0}'.format(labels_conversion(fixed_atoms)))

# set calculation level, charge, and magnetic moment
total_charges = 0
total_magnetic_moments = 0     # magmom(μ_B) equals the number of unpaired electrons
mol.calc = GFN1(accuracy=1, electronic_temperature=300, max_iterations=5000)
##mol.calc = XTB(method="GFN1-xTB", accuracy=1.0, electronic_temperature=300, max_iterations=5000)
mol.set_initial_charges(charges=[total_charges/total_atoms,]*total_atoms)
mol.set_initial_magnetic_moments(magmoms=[total_magnetic_moments/total_atoms,]*total_atoms)

# calculate single point energy (SPE) of the initial geometry
e_mol = mol.get_potential_energy()
print('\nTotal energy of the initial geomertry: \n{0:.6f} eV   <==>   {1:.8f} Hartree\n'.format(e_mol, e_mol/Hartree))

print('~~~ Geometry optimization started... ~~~')
opt = BFGSLineSearch(mol, maxstep=0.01, trajectory=name+".traj", restart=name+".pckl")
opt.run(fmax=0.005, steps=1600)
print('~~~ Geometry optimization terminated... ~~~')

# calculate single point energy (SPE) of the optimized geometry
e_mol_opted = mol.get_potential_energy()
print('\nTotal energy of the optimized geometry: \n{0:.6f} eV   <==>   {1:.8f} Hartree\n'.format(e_mol_opted, e_mol_opted/Hartree))

write(name+"_opted.xyz", read(name+".traj"), columns=['symbols','positions'], write_results=False)
write(name+"_traj.xyz", iread(name+".traj"), columns=['symbols','positions'], write_results=False)
os.remove('xtbrestart')
os.remove('wbo')

end_time = time.time()
end_date = datetime.datetime.now()
print('***  ASE program with xtb-6.3.pre2 terminated at {0}  ***'.format(end_date.strftime("%Y-%m-%d %H:%M:%S")))

tot_seconds = round(end_time - start_time,2)
days = tot_seconds // 86400
hours = (tot_seconds % 86400) // 3600
minutes = (tot_seconds % 86400 % 3600)// 60
seconds = tot_seconds % 60
print(">> Elapsed time: {0:2d} days {1:2d} hours {2:2d} minutes {3:5.2f} seconds <<".format(int(days),int(hours),int(minutes),seconds))
