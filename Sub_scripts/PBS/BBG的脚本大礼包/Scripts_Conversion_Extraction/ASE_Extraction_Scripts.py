#!/usr/bin/env python3

import os,re,time

def search(dir_name, target_file_name):
    target_list = []
    for root, dirs, files in os.walk(dir_name):
        for f in files:
            full_path = os.path.join(root, f)
            if re.search(target_file_name, f):
                target_list.append(full_path)  
    return target_list

def process(raw):
    global opt_conv_flag
    global opt_not_converged_count
    state = False
    for i in range(len(raw)):
        if "ASE program" in raw[i]:
            state = True
        if "Total energy of the current geometry" in raw[i]:
            target_line = i + 1
            opt_conv_flag = 0
            break
        elif "Total energy of the optimized geometry" in raw[i]:
            target_line = i + 1
            last_opt_info = raw[i-3]
            opt_conv_detect(last_opt_info)
            break
    if state == True and opt_conv_flag in [0,1]:
        SPE = raw[target_line].split()[3]
        outputs.write("%-8s %-30s %-30s\n" % (file_counter,filename[:-4],SPE))
    elif state == True and opt_conv_flag == 2:
        SPE = raw[target_line].split()[3]
        outputs.write("%-8s %-30s %-30s\n" % (str(file_counter) + "*",filename[:-4],SPE + "*")) 
        opt_not_converged_count += 1
    else:
        SPE = "N/A"
        outputs.write("%-8s %-30s %-30s\n" % ("X",filename[:-4],"N/A"))
    return state,SPE

def opt_conv_detect(last_opt_info):
    global opt_conv_flag
    global opt_conv_threshold
    opt_conv_flag = 1
    opt_conv_threshold = 0.005     # set the convergence threshold of geometry optimization here
    last_opt_con_value = eval(last_opt_info.split()[4])
    if last_opt_con_value > opt_conv_threshold:
        opt_conv_flag = 2
        




#############   Start from the following lines   #############
start_time = time.time()
current_path = os.getcwd()
target_file_name = r".*\.log$"   # set the extension of the target files here
all_target_files = search(current_path, target_file_name)
nfiles = len(all_target_files)
newfilename = "ASE_Extraction.txt"
opt_not_converged_count = 0
file_counter = 0
folder_counter = 0
old_dirname = ""
print("~~~~ Running at the current working directory... ~~~~\n{0}".format(current_path))
with open(newfilename,"a") as outputs:
    outputs.write("%-8s %-30s %-30s\n" % ("No.","Name","SPE[au]"))
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
            raw = inputs.readlines()
            state,SPE = process(raw)
            if state == True and opt_conv_flag in [0,1]:
                print("    ==> SPE has been extracted from ASE {0}! [{1} of {2}]".format(filename,file_counter,nfiles))
                print("        No.{0}:    Name: {1}     SPE= {2}".format(file_counter,filename[:-4],SPE))
            elif state == True and opt_conv_flag == 2:
                print("    ==> SPE has been extracted from ASE {0}! [{1} of {2}]".format(filename,file_counter,nfiles))
                print("        No.{0}:    Name: {1}     SPE= {2}".format(str(file_counter) + "*",filename[:-4],SPE + "*"))
                print("        @@ Warning: The geometry is not converged !!! (fmax > {0})".format(opt_conv_threshold))
            else:
                print("    --> The {0} file doesn't contain ASE information! Skipping...".format(filename))
                file_counter -= 1


print("\n######  SPE in total {0}/{1} ASE output files have been successfully extracted  ######".format(file_counter,nfiles))

if opt_not_converged_count > 0:
    print("           @@@@  Note that total {0} geometries have NOT converged  @@@@".format(opt_not_converged_count))

end_time = time.time()
tot_seconds = round(end_time - start_time,2)
days = tot_seconds // 86400
hours = (tot_seconds % 86400) // 3600
minutes = (tot_seconds % 86400 % 3600)// 60
seconds = tot_seconds % 60
print("\n>> Elapsed time: {0:2d} days {1:2d} hours {2:2d} minutes {3:5.2f} seconds <<".format(int(days),int(hours),int(minutes),seconds))
