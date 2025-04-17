#!/usr/bin/env python3

from ase.io import read,write,iread
import os,sys,time,re

def search(ini_path, target_file_name, depth):
    target_list = []
    target_root_list = []
    for root, dirs, files in os.walk(ini_path, topdown=True):
        if root != ini_path and depth == False:
            break
        for f in files:     
            if re.search(target_file_name, f):
                full_path = os.path.join(root, f)
                target_list.append(full_path)
                if root == ini_path:
                   target_root_list.append(full_path)
    return target_list, target_root_list

def process(lists):
    global file_counter,folder_counter
    old_dirname = ""
    for i in lists:
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
        output_xyz = filename[:-5]+"_opted.xyz"
        output_traj_xyz = filename[:-5]+"_traj.xyz"
        write(dirname+os.path.sep+output_xyz, read(i), columns=['symbols','positions'], write_results=False)
        write(dirname+os.path.sep+output_traj_xyz, iread(i), columns=['symbols','positions'], write_results=False)
        print('    ==> Conversion completed!')
        
    
    
#############   Start from the following lines   #############
print("###  Script for conversion from ASE *.traj files to *.xyz files  ###")
print("1  Convert the *.traj files in the current directory and all subdirectories to *.xyz files")
print("2  Convert the *.traj files in ONLY the current directory to *.xyz files")
print("3  Convert the user-defined *.traj file in the current directory to the *.xyz file")
print("** Hint: Press enter key to directly choose function 2")
choice_list = ['1','2','3','']
choice = input()
while choice not in choice_list:
    choice = input("Please reinput your choice:\n")
if choice == '1':
    print("The script will run over the current directory and all subdirectories...")
elif choice == '2' or choice == '':
    print("The script will run over the current directory...")
elif choice == '3':
    input_file_name = input("Please input the filename (e.g. ABC.traj) to be converted in the current directory:\n")
    while not os.path.isfile(input_file_name):
        input_file_name = input("The [{0}] does not exist, please check and reinput the filename:\n".format(input_file_name))

input("Press any key to start the conversion... ^_^")

start_time = time.time()
file_counter = 0
folder_counter = 0
current_path = os.getcwd()
target_file_name = r".*\.traj$"
if choice == '1':
    depth = True
    all_target_files, all_target_root_files = search(current_path, target_file_name, depth)
    nfiles = len(all_target_files)
    process(all_target_files)
elif choice == '2' or choice == '':
    depth = False
    all_target_files, all_target_root_files = search(current_path, target_file_name, depth)
    nfiles = len(all_target_root_files)
    process(all_target_root_files)
elif choice == '3':
    target_file = []
    nfiles = 1
    target_file.append(current_path + os.path.sep + input_file_name)
    process(target_file)


print("\n######  Total {0}/{1} ASE *.traj files have been successfully converted  ######".format(file_counter,nfiles))

end_time = time.time()
tot_seconds = round(end_time - start_time,2)
days = tot_seconds // 86400
hours = (tot_seconds % 86400) // 3600
minutes = (tot_seconds % 86400 % 3600)// 60
seconds = tot_seconds % 60
print(">> Elapsed time: {0:2d} days {1:2d} hours {2:2d} minutes {3:5.2f} seconds <<".format(int(days),int(hours),int(minutes),seconds))
