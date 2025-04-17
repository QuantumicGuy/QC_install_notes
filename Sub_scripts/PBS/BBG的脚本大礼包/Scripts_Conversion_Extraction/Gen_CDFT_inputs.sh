#!/bin/bash

function travel_dir(){
file_counter=0
folder_counter=0
serial=0
echo
echo "~~~~ Ready to travel all subdirectories in the path below ~~~~"
echo $(pwd)
for dir in $(ls -R | grep :| tr : " ")
do
  cd $dir
  if ls *.$inp_extension 1> /dev/null 2>&1;then
    let folder_counter++
	echo
    echo "*** No.$folder_counter folder *** >>> Entered" $dir
	echo "      V V V V"
	for file in *.$inp_extension
	do
	  let serial++
	  let file_counter++
	  echo "[$serial] Locating $file file..."
	  Gen_CDFT_inputs      # Processing files here
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
echo "######  Total $file_counter/$nfiles *.$inp_extension files ($serial systems) have been successfully processed by Multiwfn  ######"
echo
} 

function Gen_CDFT_inputs(){               
anion_filename=${file/./_N+1.}
cation_filename=${file/./_N-1.}
second_matching_space=$(grep -n "^$" *.gjf | awk -F ":" 'NR==2{print $1}')
target_line=$[${second_matching_space}+1]
cp $file $anion_filename
cp $file $cation_filename
sed -i "${target_line}c ${anion_chg_spm}" $anion_filename
sed -i "${target_line}c ${cation_chg_spm}" $cation_filename

printf "[system %4d] ==> Gaussian input files for N+1 and N-1 systems have been generated:\n" $serial
printf "[system %4d] ==> Gaussian input files for N+1 systems: %s\n" $serial $anion_filename
printf "[system %4d] ==> Gaussian input files for N-1 systems: %s\n" $serial $cation_filename
printf "[system %4d] ==> Currently, %d of %d *.%s files haved been processed successfully.\n" $serial $file_counter $nfiles $inp_extension
}

###################    the script begins from the following lines    ################### 
echo "************* Generation of Gaussian input files for CDFT **************"
echo "Please input the extension of the Gaussian input files: [gjf]"
read inp_extension
echo "Please input the charge and spin multiplicity of N+1 system: [e.g. -1 2]"
read anion_chg_spm
echo "Please input the charge and spin multiplicity of N-1 system: [e.g. 1 2]"
read cation_chg_spm
echo 
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)

printf "Press any key to start to generate [*.$inp_extension] files for CDFT... ^v^"
read -n 1
travel_dir


















