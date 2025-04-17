#!/usr/bin/python3

import os,sys,re,time
  
def search(ini_path, target_file_name):
    target_list = []
    for root, dirs, files in os.walk(ini_path, topdown=True):
        for f in files:     
            if re.search(target_file_name, f):
                full_path = os.path.join(root, f)
                target_list.append(full_path)
    return target_list

def write_results(ini_path, all_results, nfiles):
    other_file_count = 0
    outputs = open(ini_path + os.path.sep + "Total_Task_Time.txt","w")
    print("{0:<8s} {1:<30s} {2:<15s} {3:<25s}".format("No.","File Name", "Task Type", "CPU Time [hours]"), file=outputs)
    for i in range(nfiles):
        line_number = i + 1
        if all_results[i][1] != "N/A":
            print("{0:<8d} {1:<30s} {2:<15s} {3:<10.1f}".format(line_number - other_file_count, all_results[i][0], all_results[i][1], all_results[i][2]), file=outputs)
        else:
            print("{0:<8s} {1:<30s} {2:<15s} {3:<10s}".format("X", all_results[i][0], all_results[i][1], all_results[i][2]), file=outputs)
            other_file_count += 1
    print("\nTotal CPU Time: {0:20.1f} hours\nTotal Gaussian/ORCA files: {1:15d}".format(sum_cpu_time, file_counter), file=outputs)
    #outputs.write("\nTotal CPU Time: {0:10.1f} hours\n".format(sum_cpu_time))
    outputs.close()

def read_and_process(each_file):
    global file_counter
    global sum_cpu_time
    NCPU = 0
    tot_hours = 0
    result = []
    task_flag = "N/A"
    timer = {'days':0,'hours':0,'minutes':0}
    with open(each_file,"r") as inputs:
        for each_line in inputs:
            if "Entering Gaussian System" in each_line:
                task_flag = "Gaussian"
            elif "O   R   C   A" in each_line:
                task_flag = "ORCA"
            if task_flag == "Gaussian" and "Job cpu time:" in each_line:
                timer['days'] +=  int(each_line.split()[3])
                timer['hours'] +=  int(each_line.split()[5])
                timer['minutes'] +=  int(each_line.split()[7])
            elif task_flag == "ORCA" and "TOTAL RUN TIME:" in each_line:
                timer['days'] +=  int(each_line.split()[3])
                timer['hours'] +=  int(each_line.split()[5])
                timer['minutes'] +=  int(each_line.split()[7])
            elif task_flag == "ORCA" and "%pal nprocs" in each_line:
                NCPU = int(each_line.split()[4])                    
    if task_flag == "ORCA":
        tot_hours = timer['days']*24 + timer['hours'] + round(timer['minutes']/60,1)
        tot_hours *= NCPU
    elif task_flag == "Gaussian":
        tot_hours = timer['days']*24 + timer['hours'] + round(timer['minutes']/60,1)
    elif task_flag == "N/A":
        tot_hours = "N/A"
        file_counter -= 1
    result.append(os.path.basename(each_file))
    result.append(task_flag)
    result.append(tot_hours)
    all_results.append(result)
    if task_flag != "N/A":
        sum_cpu_time += tot_hours
        print("    ==> {0} has been processed! [{1} of {2}]".format(filename,file_counter,nfiles))
        print("    File Name: {0:<25s}  Task Type: {1:<10s}  CPU Time: {2:10.1f} hours".format(result[0],result[1],result[2]))
    else:
        print("    ==> {0} is not Gaussian/ORCA output file, skipping... [{1} of {2}]".format(filename,file_counter,nfiles))
        print("    File Name: {0:<25s}  Task Type: {1:<10s}  CPU Time: {2:>10s}".format(result[0],result[1],result[2]))

    
#############   Start from the following lines   #############
sum_cpu_time = 0
file_counter = 0
folder_counter = 0
old_dirname = ""
current_path = os.getcwd()
target_file_name = r".*\.log$"

print("~~~~ Running over the current working directory and all subdirectories... ~~~~\n{0}\n".format(current_path))
input("Press any key to perform the statistics of CPU time for all the Gaussian/ORCA outputs [*.log] ... ^_^")
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
    read_and_process(i_file)

write_results(current_path, all_results, nfiles)
print("\n######  CPU time from total {0}/{1} *.log files have been successfully extracted  ######".format(file_counter,nfiles))
print("        ++++++++++++++++   Total CPU Time: {0:10.1f} hours  ++++++++++++++++\n".format(sum_cpu_time))

end_time = time.time()
tot_seconds = round(end_time - start_time,2)
days = tot_seconds // 86400
hours = (tot_seconds % 86400) // 3600
minutes = (tot_seconds % 86400 % 3600)// 60
seconds = tot_seconds % 60
print(">> Elapsed time: {0:2d} days {1:2d} hours {2:2d} minutes {3:5.2f} seconds <<".format(int(days),int(hours),int(minutes),seconds))
