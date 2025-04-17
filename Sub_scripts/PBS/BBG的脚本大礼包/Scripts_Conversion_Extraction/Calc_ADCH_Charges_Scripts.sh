#!/bin/bash
function check_Multiwfn(){
which Multiwfn 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "<Multiwfn> command is not found, please recheck whether its environment variable is correctly set or not!"
  exit 1
fi
}

function labels_conversion(){
array_labels=()
for i in $(echo $inp_atom_labels | tr , " ");do
  if [[ $i =~ "-" ]];then
    ii=$(echo $i | tr - " ")
	temp_array=($ii)
    start_num=${temp_array[0]}
	end_num=${temp_array[1]}
	for j in $(seq $start_num $end_num);do
	  array_labels[${#array_labels[@]}]=$j
	done
  else
    array_labels[${#array_labels[@]}]=$i
  fi
done
}

function travel_dir(){
file_counter=0
folder_counter=0
echo
echo "~~~~ Ready to travel all subdirectories in the path below ~~~~"
echo $(pwd)
for dir in $(ls -R | grep :| tr : " ")
do
  cd $dir
  if ls *.$inp_extension 1> /dev/null 2>&1;then
    serial=1
    let folder_counter++
	echo
    echo "*** No.$folder_counter folder *** >>> Entered" $dir
	echo "      V V V V"
	for file in *.$inp_extension
	do
	  echo "[$serial] Loading $file file..."
	  let file_counter++
	  let serial++
      Calc_ADCH_Charges
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
echo "######  Total $file_counter/$nfiles *.$inp_extension files have been successfully processed by Multiwfn  ######"
echo
} 

function Calc_ADCH_Charges(){               
Multiwfn $file << EOF 1> /dev/null 2>&1
7
11
1
y
0
q
EOF
if [[ $? -eq 0 ]];then
  printf "%-6s %-30s" $file_counter ${file%.$inp_extension} >> $initial_path/Calc_ADCH_Charges.txt 
  for line_num in ${array_labels[@]};do
	target_atom_charge=$(awk -v awk_var=$line_num 'NR==awk_var {printf $5}' ${file/%$inp_extension/chg})
	printf "%-15s" $target_atom_charge >> $initial_path/Calc_ADCH_Charges.txt
  done
  printf "\n" >> $initial_path/Calc_ADCH_Charges.txt
  echo "    ==> ADCH charges have been calculated from $file! [$file_counter of $nfiles]"
else
  echo "    --> Fail to calculate ADCH charges from $file file! Skipping..."
  printf "%-6s %-30s" $file_counter ${file%.$inp_extension} >> $initial_path/Calc_ADCH_Charges.txt 
  for line_num in $(seq ${#array_labels[@]});do
	printf "%-15s" "N/A" >> $initial_path/Calc_ADCH_Charges.txt
  done
  printf "\n" >> $initial_path/Calc_ADCH_Charges.txt
  let file_counter--
fi
}

###################    the script begins from the following lines    ################### 
echo "************* Calculate ADCH charges by Multiwfn **************"
echo "Please input the extension of the formatted Gaussian check-point files: [fchk/fch]"
read inp_extension
echo
echo "Please input atom labels to be calculated, e.g. 3,5-8,15-20"
read inp_atom_labels
echo
labels_conversion 
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)

printf "Press any key to start to calculate the ADCH charges based on the [*.$inp_extension] files... ^v^"
read -n 1
check_Multiwfn
printf "%-6s %-30s" "No." "NAME" > Calc_ADCH_Charges.txt
for target_atom in ${array_labels[@]};do
  printf "%-15s" $target_atom >> Calc_ADCH_Charges.txt
done
printf "\n" >> Calc_ADCH_Charges.txt
travel_dir


















