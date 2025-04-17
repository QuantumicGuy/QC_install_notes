#!/bin/bash
function check_Multiwfn(){
which Multiwfn 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "<Multiwfn> command is not found, please recheck whether its environment variable is correctly set or not!"
  exit 1
fi
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
      Calc_Size
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

function Calc_Size(){               
Multiwfn $file << EOF 1> temp.txt 2>&1
100
21
size
0
q
0
q
EOF
if [[ $? -eq 0 ]];then
  X=$(grep "Length of the three sides:" temp.txt | awk 'END{printf $6}')
  Y=$(grep "Length of the three sides:" temp.txt | awk 'END{printf $7}')
  Z=$(grep "Length of the three sides:" temp.txt | awk 'END{printf $8}')
  printf "%-8s %-30s %-20s %-20s %-20s\n" $file_counter ${file%.$inp_extension} $X $Y $Z >> $initial_path/Calc_Sizes.txt
  echo "    ==> Molecular size has been calculated from $file! [$file_counter of $nfiles]"
  echo "        No.$file_counter:    Name: ${file%.$inp_extension}   X/Y/Z = $X  $Y  $Z  Angstrom"
else
  echo "    --> Fail to calculate molecular size from $file file! Skipping..."
  printf "%-8s %-30s %-20s %-20s %-20s\n" "X" ${file%.$inp_extension} "N/A" "N/A" "N/A" >> $initial_path/Calc_Sizes.txt
  let file_counter--
fi
rm temp.txt
}

###################    the script begins from the following lines    ################### 
echo "************* Calculate molecular sizes by Multiwfn **************"
echo "Please input the extension of the geometry files: [xyz, gjf, etc.]"
read inp_extension
echo
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)

printf "Press any key to start to calculate the molecular sizes based on the [*.$inp_extension] files... ^v^"
read -n 1
check_Multiwfn
printf "%-8s %-30s %-20s %-20s %-20s\n" "No." "NAME" "X [Angstrom]" "Y [Angstrom]" "Z [Angstrom]" > Calc_Sizes.txt
travel_dir


















