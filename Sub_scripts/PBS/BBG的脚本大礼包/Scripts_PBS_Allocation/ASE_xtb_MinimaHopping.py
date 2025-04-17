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
  
def search(ini_path, target_file_name):
    target_root_list = []
    for root, dirs, files in os.walk(ini_path, topdown=True):
        if root != ini_path:
            break
        for f in files:     
            if re.search(target_file_name, f):
                target_root_list.append(f)
    return target_root_list

from ase import Atoms
from ase.units import Hartree
from ase.constraints import FixAtoms
from ase.optimize import BFGSLineSearch
from ase.optimize.minimahopping import MinimaHopping
from ase.io import read,write,iread
##from xtb.ase.calculator import XTB     
from xtb import GFN1
import os,sys,shutil,re,datetime,time

start_time = time.time()
start_date = datetime.datetime.now()

name = sys.argv[1]
mol = read(name+".xyz")
total_atoms = len(mol.get_atomic_numbers())

# orthorhombic cell parameter
a, b, c = 19.6495, 19.6495, 27.5607 
mol.cell = [a, b, c]

# PBC: periodic boundary conditions
mol.pbc = (True, True, True)

print('***  ASE program with xtb-6.3.pre2 started at {0}  ***\n'.format(start_date.strftime("%Y-%m-%d %H:%M:%S")))
print('-> Task name:  %50s' %name)
print('-> Orthorhombic cell parameters:  %31s' %mol.get_cell())
print('-> Total number of atoms in a cell:  %27s' %total_atoms)
print('-> PBC dimensions:  %45s' %mol.get_pbc())

#  fix atoms (index starts from 1)
fixed_atoms = "2,4-10,12,14-20,22,24-30,32,34-40,42,44-50,52,54-60,62,64-70,72,74-80,82,84-90,92,94-100,102,104-110,112,114-120,122,124-130,132,134-140,142,144-150,152,154-160,162,164-170,172,174-180,182,184-190,192,194-200,202,204-210,212,214-220,222,224-230,232,234-240,242,244-250" 
fix = FixAtoms(indices=labels_conversion(fixed_atoms))
mol.set_constraint(fix)
print('-> The atoms with following labels are fixed:\n{0}'.format(labels_conversion(fixed_atoms)))

# set calculation level, charge, and magnetic moment
total_charges = 0
total_magnetic_moments = 0    # magmom(μ_B) equals the number of unpaired electrons
mol.calc = GFN1(accuracy=1, electronic_temperature=300, max_iterations=5000)
##mol.calc = XTB(method="GFN1-xTB", accuracy=1.0, electronic_temperature=300, max_iterations=5000)
mol.set_initial_charges(charges=[total_charges/total_atoms,]*total_atoms)
mol.set_initial_magnetic_moments(magmoms=[total_magnetic_moments/total_atoms,]*total_atoms)

# start global geometry optimization
print('~~~ Global geometry optimization started... ~~~')
mh = MinimaHopping(atoms=mol,T0=1000,optimizer=BFGSLineSearch,minima_threshold=0.5)
mh(totalsteps=10) 

print('~~~ Global geometry optimization terminated... ~~~')


write("minima_all.xyz", iread("minima.traj"), columns=['symbols','positions'], write_results=False)
os.remove('xtbrestart')
os.remove('wbo')
current_path = os.getcwd()
os.mkdir(current_path+os.path.sep+"md")
os.mkdir(current_path+os.path.sep+"qn")
md_file_name = r"^md.*\.(traj|log)$"
qn_file_name = r"^qn.*\.(traj|log)$"
md_target_root_files = search(current_path, md_file_name)
qn_target_root_files = search(current_path, qn_file_name)
for md_file in md_target_root_files:
    shutil.move(md_file,"md"+os.path.sep+md_file)
for qn_file in qn_target_root_files:
    shutil.move(qn_file,"qn"+os.path.sep+qn_file)

end_time = time.time()
end_date = datetime.datetime.now()
print('***  ASE program with xtb-6.3.pre2 terminated at {0}  ***'.format(end_date.strftime("%Y-%m-%d %H:%M:%S")))

tot_seconds = round(end_time - start_time,2)
days = tot_seconds // 86400
hours = (tot_seconds % 86400) // 3600
minutes = (tot_seconds % 86400 % 3600)// 60
seconds = tot_seconds % 60
print(">> Elapsed time: {0:2d} days {1:2d} hours {2:2d} minutes {3:5.2f} seconds <<".format(int(days),int(hours),int(minutes),seconds))
