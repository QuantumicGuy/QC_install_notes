#!/bin/bash
function travel_dir(){
file_counter=0
folder_counter=0
echo
echo Travelling all subdirectories in the path below to find all "*."$file_extension files:
echo $(pwd)
nfiles=$(find -name "*.$file_extension" | wc -l)
for dir in $(ls -R | grep :| tr : " ")
do
  cd $dir
  if ls *.$file_extension 1> /dev/null 2>&1;then
    serial=1
    let folder_counter++
	echo
    echo "*** No.$folder_counter folder *** >>> Entered" $dir
	echo "      V V V V"
	for file in *.$file_extension
	do
	  echo "[$serial] Locating $file file..."
	  let file_counter++
	  let serial++
	  process      # Process files here
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
if [[ $ASE_flag == 1 ]];then
  echo "######  Total $file_counter *.pbs and *.py files have been generated for $software  ######"
else
  echo "######  Total $file_counter *.pbs files have been generated for $software  ######"
fi
echo
} 

function process(){
cp $initial_path/$software.pbs ./${file/%$file_extension/pbs}       # Load the template PBS file
dos2unix -q ${file/%$file_extension/pbs}
if [[ $ASE_flag == 1 ]];then
  sed -i "s/^FILENAME=.*\.py/FILENAME=${file/%$file_extension/py}/" ${file/%$file_extension/pbs}       # Generate PBS job files     
else
  sed -i "s/^FILENAME=.*\.$file_extension/FILENAME=$file/" ${file/%$file_extension/pbs}       
fi
echo "    ==> ${file/%$file_extension/pbs} has been generated! [$file_counter of $nfiles]"

if [[ $gjf_synchronize == 1 ]];then
  dos2unix -q ${file}
  sed -i "s/^%chk=.*\.chk$/%chk=${file/%$file_extension/chk}/" ${file}     # Synchronize the filename of *.gjf into the contents of *.gjf (i.e., %chk=*.chk and title line)
  first_matching_space=$(grep -n "^$" $file | head -1 | cut -d : -f 1)
  title_line=$[${first_matching_space}+1]
  sed -i "${title_line}c opt_${file%.$file_extension}" ${file}
  echo "    ~~~ Meanwhile, the %chk=*.chk and title line in ${file} have been updated!"
fi
if [[ $ASE_flag == 1 ]];then
  cp $initial_path/ASE_xtb.py ./${file/%$file_extension/py}       # Load the ASE_xtb.py template file
  echo "    ~~~ Meanwhile, the ${file/%$file_extension/py} file has been created!"
fi
}


###################    PBS allocation script begins from the following lines    ###################        
echo
echo "############  Running PBS allocation script for input files of quantum chemistry softwares  ############"
echo
echo "Please input the symbol of target software [gau/orca/mopac/xtb/ase/skl]:"
echo "gau -> Gaussian(*.gjf); orca -> ORCA(*.inp); mopac -> MOPAC(*.mop); xtb -> xtb(*.xyz); ase -> ASE(*.py)"
echo "ase -> ASE(*.py); skl -> scikit-learn(*.py)"
array_choice=(gau orca mopac xtb ase skl)
read choice
while ! echo "${array_choice[@]}" | grep -wq "$choice" 
do
  echo "Please reinput the choice [gau/orca/mopac/xtb/ase/skl]..."
  read choice
done
declare -A map 
map=(["gau"]="gjf" ["orca"]="inp" ["mopac"]="mop" ["xtb"]="xyz" ["ase"]="py" ["skl"]="py")
file_extension=${map[$choice]}     # Set target extension

if [[ $file_extension == "gjf" ]];then
  echo "Whether to synchronize the filename of *.gjf into the contents of *.gjf (i.e., %chk=*.chk and title line) or not? [Yes/No]"
  array_choice=(Yes yes No no y n Y N)
  read choice_sync
  while ! echo "${array_choice[@]}" | grep -wq "$choice_sync" 
  do
    echo "Please reinput the decision [Yes/No]..."
    read choice_sync
  done
  if [[ $choice_sync == "Yes" || $choice_sync == "yes" || $choice_sync == "Y" || $choice_sync == "y" ]];then
    gjf_synchronize=1
  fi    
  software="Gaussian" 
elif [[ $file_extension == "inp" ]];then
  software="ORCA"
elif [[ $file_extension == "mop" ]];then
  software="MOPAC"
elif [[ $file_extension == "xyz" ]];then
  echo "Whether to use *.xyz files to perform molecular dynamics (MD) simulations by xtb or not? [Yes/No]"
  array_choice=(Yes yes No no y n Y N)
  read choice_xtb
  while ! echo "${array_choice[@]}" | grep -wq "$choice_xtb" 
  do
    echo "Please reinput the decision [Yes/No]..."
    read choice_xtb
  done
  if [[ $choice_xtb == "Yes" || $choice_xtb == "yes" || $choice_xtb == "Y" || $choice_xtb == "y" ]];then
    software="xtb_md"
  else
    software="xtb"
  fi
elif [[ $file_extension == "py" ]];then
  if [[ $choice == "ase" ]];then
    software="ASE_xtb"
  elif [[ $choice == "skl" ]];then
    software="scikit-learn"
  fi
fi
initial_path=$(pwd)

if [[ -f "${software}.pbs" ]];then            # Check whether the template PBS file exists or not
  if ! command -v dos2unix >/dev/null 2>&1;then
    echo ">>> Warning: <dos2unix> tool is required but it has not installed yet. Aborting... <<<"
    exit 1
  fi
  echo
  if [[ $file_extension == gjf && $gjf_synchronize == 1 ]];then
    echo "Press any key to generate PBS scripts for $software, and meanwhile update *.gjf files... ^v^"
  elif [[ $file_extension == py && $choice == "ase" ]];then
    if [[ -f "ASE_xtb.py" ]];then            # Check whether the ASE_xtb.py template file exists or not
      echo "Press any key to generate PBS scripts and *.py files for $software... ^v^"
	    echo "Note that the atomic coordinates should be saved as *.xyz files"
	    file_extension="xyz"
	    ASE_flag=1
	else
	    echo
      echo "ASE_xtb.py template file is not found in:"
      echo "$initial_path"
      echo
      echo "Please recheck the ASE_xtb.py file!!"
      exit 1
    fi
  else
    echo "Press any key to generate PBS scripts for $software... ^v^"
  fi
  read -n 1
  travel_dir           # Run travel_dir and process functions
else
  echo
  echo "${software}.pbs is not found in:"
  echo "$initial_path"
  echo
  echo "Please recheck the $software template PBS file!!"
  exit 1
fi








