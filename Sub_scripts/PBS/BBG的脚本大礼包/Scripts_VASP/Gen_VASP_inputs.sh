#!/bin/bash
function check_vaspkit(){
which vaspkit 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo ">>> Warning: <vaspkit> tool is not found, please recheck its environment variable! <<<"
  exit 1
fi
}

function check_dos2unix(){
if ! command -v dos2unix >/dev/null 2>&1;then
  echo ">>> Warning: <dos2unix> tool is required but it has not installed yet. Aborting... <<<"
  exit 1
fi
}

function travel_dir(){
nfiles=$(find -name "INCAR" | wc -l)
folder_counter=0
echo
echo "~~~~ Ready to travel all subdirectories in the path below ~~~~"
echo $(pwd)
for dir in $(ls -R | grep :| tr : " ")
do
  cd $dir
  if ls INCAR 1> /dev/null 2>&1;then
    let folder_counter++
	echo
    echo "*** No.$folder_counter folder *** >>> Entered" $dir
	echo "      V V V V"
	if ls *.cif 1> /dev/null 2>&1;then
	  cif_file=$(ls *.cif)
	  taskname=${cif_file%.cif}
	else
	  echo "--> *.cif not found! Skipping..."
	  let folder_counter--
	  cd $initial_path
	  continue
	fi
	if [[ $mainchoice == 1 ]];then
	  echo "==> Loading the $cif_file file for the [$taskname] task..."
      echo "~~> Generating the POSCAR, POTCAR, and KPOINTS files... [$folder_counter of $nfiles]"
	  gen_POSCAR
	  gen_POTCAR
	  gen_KPOINTS
	elif [[ $mainchoice == 2 ]];then
	  echo "==> Loading the original POSCAR file for the [$taskname] task..."
      echo "~~> Generating the new POSCAR file and back up the original one (POSCAR.old)... [$folder_counter of $nfiles]"
	  gen_POSCAR_Fix
	  mv POSCAR POSCAR.old
	  mv POSCAR_FIX POSCAR
	elif [[ $mainchoice == 3 ]];then
		cp $initial_path/VASP.pbs ./$taskname.pbs
		dos2unix -q $taskname.pbs    
        echo "==> $taskname.pbs has been generated! [$folder_counter of $nfiles]"
	fi
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
echo "######  Total $folder_counter/$nfiles VASP tasks have been successfully generated  ######"
echo
} 

function gen_POSCAR(){
vaspkit << EOF 1> /dev/null 2>&1
105
$cif_file
$element_order
EOF
if [[ $? -eq 0 ]];then
  echo "    The POSCAR file has been generated!"
else
  echo "    Fail to generate the POSCAR file!"
fi
}

function gen_POTCAR(){
vaspkit << EOF 1> /dev/null 2>&1
103
EOF
if [[ $? -eq 0 ]];then
  echo "    The POTCAR file has been generated!"
  grep "TITEL  =" POTCAR | awk '{print "        " $3 "  " $4  "  " $5 }'
else
  echo "    Fail to generate the POTCAR file!"
fi
}

function gen_KPOINTS(){
vaspkit << EOF 1> /dev/null 2>&1
102
2
$Kmesh_resolved_value
EOF
if [[ $? -eq 0 ]];then
  echo "    The KPOINTS file has been generated!"
else
  echo "    Fail to generate the KPOINTS file!"
fi
}

function gen_POSCAR_Fix(){
vaspkit << EOF 1> /dev/null 2>&1
402
1
2
$fixed_atoms_height
1
EOF
if [[ $? -eq 0 ]];then
  echo "    The new POSCAR file with fixed atoms has been generated!"
else
  echo "    Fail to generate the new POSCAR file with fixed atoms!"
fi
}

function check_PBS_template(){
if [ -f "VASP.pbs" ];then
  echo "Loading the VASP template PBS file (VASP.pbs)..."
  echo
else
  echo
  echo "The VASP template PBS file (VASP.pbs) is not found in:"
  echo "$initial_path"
  echo
  echo "Please recheck the VASP.pbs file!!"
  exit 1
fi
}



###################    Generation script of VASP inputs begins from the following lines    ################### 
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*                     VASP-input generator made by Jianyong Yuan                    *"
echo "*                              E-mail: 404283110@qq.com                             *"
echo "*                     Version 1.0 (dev), Release date: 2021-Jan-6                   *"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo
echo "                      ************ Main Function Menu ************                "
echo "1 Generate the POSCAR file from *.cif, and make the KPOINTS and POTCAR files by using vaspkit"
echo "2 Fix atoms in the POSCAR file (fractional coordinates) by using vaspkit"
echo "3 Generate the PBS script for VASP tasks"

initial_path=$(pwd)
array_mainchoice=(1 2 3)
read mainchoice
while ! echo "${array_mainchoice[@]}" | grep -wq "$mainchoice" 
do
  echo "Please reinput function number..."
  read mainchoice
done
if [[ $mainchoice == 1 ]];then
  check_vaspkit
  echo "Please input the order of element in the POSCAR file:"
  echo "e.g. 'C N O Si S Zn H'"
  read element_order
  echo "Please input the Kmesh-resolved value (in Units of 2*π/Angstrom) for the KPOINTS file:"
  echo "+-------------------------- Warm Tips --------------------------+"
  echo "  * Accuracy Levels: Gamma-Only: 0"
  echo "                            Low: 0.06~0.04"
  echo "                           Fine: 0.02-0.01"
  echo "  * 0.03-0.04 is Generally Precise Enough!"
  echo "+---------------------------------------------------------------+"
  read Kmesh_resolved_value
  echo "Press any key to generate POSCAR, POTCAR, and KPOINTS files... ^v^"
  read -n 1
  travel_dir
elif [[ $mainchoice == 2 ]];then
  check_vaspkit
  echo "Atoms between your chosen section in z direction (fractional coordinates) will be fixed:"
  echo "Type z_min z_max, Note: z_min < z_max"
  echo "e.g. '0,0.13'"
  read fixed_atoms_height
  echo "Press any key to fix the selected atoms in the POSCAR files... ^v^"
  read -n 1
  travel_dir
elif [[ $mainchoice == 3 ]];then 
  check_PBS_template
  check_dos2unix
  echo "Press any key to allocate the PBS script to VASP tasks... ^v^"
  read -n 1
  travel_dir
fi






