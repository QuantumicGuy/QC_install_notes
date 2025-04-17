#!/usr/bin/env python3

import os,sys,re,time

def labels_conversion(input_string): 
  new_string = []
  tmp = input_string.split(",")
  for i in tmp:
    if "-" in i:
      start = int(i.split("-")[0])
      end = int(i.split("-")[1]) + 1
      for j in range(start,end):
        new_string.append(j)
    else:
      new_string.append(int(i))
  return new_string
  
def search(ini_path, target_file_name):
    target_list = []
    for root, dirs, files in os.walk(ini_path, topdown=True):
        for f in files:     
            if re.search(target_file_name, f):
                full_path = os.path.join(root, f)
                target_list.append(full_path)
    return target_list

def calc_size(coordinate_lists,filename):
    vdW_bondi_dict = {'H':1.20,'He':1.40,'Li':1.82,'Be':1.90,'B':2.13,'C':1.70,'N':1.55,'O':1.52,'F':1.47,'Ne':1.54,'Na':2.27,'Mg':1.73,'Al':2.51,'Si':2.10,'P':1.80,'S':1.80,'Cl':1.75,'Ar':1.88,'K':2.75,'Ca':2.40,'Ti':2.39,'Cr':2.25,'Mn':2.24,'Fe':2.23,'Co':2.23,'Ni':2.22,'Cu':2.26,'Zn':2.29,'Br':1.95,'Ag':1.72,'I':1.98,'Hg':1.70,'Au':1.66}
    X_max = [coordinate_lists[0][0],float(coordinate_lists[0][1])]
    X_min = [coordinate_lists[0][0],float(coordinate_lists[0][1])]
    Y_max = [coordinate_lists[0][0],float(coordinate_lists[0][2])]
    Y_min = [coordinate_lists[0][0],float(coordinate_lists[0][2])]
    Z_max = [coordinate_lists[0][0],float(coordinate_lists[0][3])]
    Z_min = [coordinate_lists[0][0],float(coordinate_lists[0][3])]
    for i in range(total_atoms):
        if float(coordinate_lists[i][1]) > X_max[1]:
            X_max[1] = float(coordinate_lists[i][1])
            X_max[0] = coordinate_lists[i][0]
        if float(coordinate_lists[i][1]) < X_min[1]:
            X_min[1] = float(coordinate_lists[i][1])
            X_min[0] = coordinate_lists[i][0]
        if float(coordinate_lists[i][2]) > Y_max[1]:
            Y_max[1] = float(coordinate_lists[i][2])
            Y_max[0] = coordinate_lists[i][0]
        if float(coordinate_lists[i][2]) < Y_min[1]:
            Y_min[1] = float(coordinate_lists[i][2])
            Y_min[0] = coordinate_lists[i][0]
        if float(coordinate_lists[i][3]) > Z_max[1]:
            Z_max[1] = float(coordinate_lists[i][3])
            Z_max[0] = coordinate_lists[i][0]
        if float(coordinate_lists[i][3]) < Z_min[1]:
            Z_min[1] = float(coordinate_lists[i][3])
            Z_min[0] = coordinate_lists[i][0]    
    X_length = X_max[1] - X_min[1] + vdW_bondi_dict[X_max[0]] + vdW_bondi_dict[X_min[0]]
    Y_length = Y_max[1] - Y_min[1] + vdW_bondi_dict[Y_max[0]] + vdW_bondi_dict[Y_min[0]]
    Z_length = Z_max[1] - Z_min[1] + vdW_bondi_dict[Z_max[0]] + vdW_bondi_dict[Z_min[0]]
    return filename[:-4], X_length, Y_length, Z_length

def write_results(ini_path, all_results, nfiles):
    outputs = open(ini_path + os.path.sep + "Calc_Size_Results.txt","w")
    print("%-8s %-20s %-15s %-15s %-15s" %("No.","Name", "X [Angstrom]", "Y [Angstrom]", "Z [Angstrom]"), file=outputs)
    for i in range(nfiles):
        print("%-8s %-20s %-15.4f %-15.4f %-15.4f" %(i+1, all_results[i][0], all_results[i][1], all_results[i][2], all_results[i][3]), file=outputs)
    outputs.close()


    
#############   Start from the following lines   #############
file_counter = 0
folder_counter = 0
old_dirname = ""
current_path = os.getcwd()
target_file_name = r".*\.xyz$"

print("~~~~ Running at the current working directory... ~~~~\n{0}\n".format(current_path))
input("Press any key to calculate molecular sizes based on the original coordinates... ^_^")
start_time = time.time()
all_target_files = search(current_path, target_file_name)
nfiles = len(all_target_files)
all_results = []

for i_file in all_target_files:
    file_counter += 1
    dirname = os.path.dirname(i_file)
    filename = os.path.basename(i_file)
    if dirname != old_dirname:
        serial = 1
        folder_counter += 1
        old_dirname = dirname
        print("\n*** No.{0} folder *** >>> Entered {1}".format(folder_counter,dirname))
        print("[{0}] Loading {1} file...".format(serial,filename))
    else:
        serial += 1
        print("[{0}] Loading {1} file...".format(serial,filename))

    with open(i_file,"r") as inputs:
        raw = inputs.readlines()
        total_atoms = int(raw[0])
        coordinate_lists = [[] for i in range(total_atoms)]
        for i in range(total_atoms):
            coordinate_lists[i] = raw[i+2].split()   

        result = calc_size(coordinate_lists,filename)
        all_results.append(result)
        print("    ==> {0} has been processed! [{1} of {2}]".format(filename,file_counter,nfiles))
        print("    Name: %-20s  X/Y/Z = %-10.4f %-10.4f %-10.4f  Angstrom" %(result[0],result[1],result[2],result[3]))

write_results(current_path, all_results, nfiles)
print("\n######  Molecular sizes from total {0}/{1} *.xyz files have been successfully calculated  ######".format(file_counter,nfiles))

end_time = time.time()
tot_seconds = round(end_time - start_time,2)
days = tot_seconds // 86400
hours = (tot_seconds % 86400) // 3600
minutes = (tot_seconds % 86400 % 3600)// 60
seconds = tot_seconds % 60
print(">> Elapsed time: {0:2d} days {1:2d} hours {2:2d} minutes {3:5.2f} seconds <<".format(int(days),int(hours),int(minutes),seconds))
