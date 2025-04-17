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

def process(raw):
    title = raw[1]
    for i in range(total_parts):
        outputs = open(dirname + os.path.sep + output_filename_list[i],"w")
        total_atoms = len(label_lists[i])
        outputs.write(str(total_atoms)+"\n")
        # outputs.write(output_filename_list[i][:-4]+"\n")
        outputs.write(title)  # write the original title
        for j in range(total_atoms):
            target_index = label_lists[i][j] + 1
            outputs.write(raw[target_index])


#############   Start from the following lines   #############
file_counter = 0
folder_counter = 0
old_dirname = ""
residual_atoms_flag = False
current_path = os.getcwd()
target_file_name = r".*\.xyz$"

print("How many parts will the *.xyz file be divided into? e.g. 2")
total_parts = input()
while not re.search(r"^[1-9]\d*$", total_parts):
    total_parts = input("Please reinput a positive integer:\n")
total_parts = int(total_parts)
label_lists = [[] for i in range(total_parts)]

for i in range(total_parts):
    if i < total_parts - 1:
        input_string = input("Input atom list for part {0}, e.g. 3,5-8,15-20\n".format(i+1))
        label_lists[i].extend(labels_conversion(input_string))
    else:
        input_string = input("Input atom list for part {0}; input 'r' to select all residual atoms\n".format(i+1))
        if input_string != "r":
            label_lists[i].extend(labels_conversion(input_string))
        else:
            residual_atoms_flag = True

print("~~~~ Running at the current working directory... ~~~~\n{0}\n".format(current_path))
input("Press any key to start the extraction... ^_^")
start_time = time.time()
all_target_files = search(current_path, target_file_name)
nfiles = len(all_target_files)

for i in all_target_files:
    file_counter += 1
    dirname = os.path.dirname(i)
    filename = os.path.basename(i)
    if dirname != old_dirname:
        serial = 1
        folder_counter += 1
        old_dirname = dirname
        print("\n*** No.{0} folder *** >>> Entered {1}".format(folder_counter,dirname))
        print("[{0}] Loading {1} file...".format(serial,filename))
    else:
        serial += 1
        print("[{0}] Loading {1} file...".format(serial,filename))

    with open(i,"r") as inputs:
        output_filename_list = []
        for output_labels in range(total_parts):
            output_filename_list.append(filename[:-4] + "_" + str(output_labels + 1) + ".xyz")

        raw = inputs.readlines()
        if residual_atoms_flag == True:
            all_input_atom_list = [ i for i in range(1,int(raw[0])+1)]
            residual_atom_list = []
            total_selected_atom_list = []
            for i in range(total_parts - 1):
                total_selected_atom_list.extend(label_lists[i])
            for residual_atom_label in all_input_atom_list:
                if residual_atom_label not in total_selected_atom_list:
                    residual_atom_list.append(residual_atom_label)
            label_lists[total_parts-1] = residual_atom_list.copy()
        
        process(raw)
        print("    ==> {0} has been processed! [{1} of {2}]".format(filename,file_counter,nfiles))

print("\n######  Coordinates of total {0}/{1} *.xyz files have been successfully extracted  ######".format(file_counter,nfiles))

end_time = time.time()
tot_seconds = round(end_time - start_time,2)
days = tot_seconds // 86400
hours = (tot_seconds % 86400) // 3600
minutes = (tot_seconds % 86400 % 3600)// 60
seconds = tot_seconds % 60
print(">> Elapsed time: {0:2d} days {1:2d} hours {2:2d} minutes {3:5.2f} seconds <<".format(int(days),int(hours),int(minutes),seconds))

print("Whether to delete the original *.xyz files? [y/n]")
delete_choice = input()
while delete_choice not in ["yes","no","y","n","Yes","No","Y","N"]:
    delete_choice = input("Please reinput your choice: [y/n]\n")
if delete_choice in ["yes","y","Yes","Y"]:
    for obj_original_xyz in all_target_files:
        os.remove(obj_original_xyz)
    print("All the original *.xyz files have been deleted!")




