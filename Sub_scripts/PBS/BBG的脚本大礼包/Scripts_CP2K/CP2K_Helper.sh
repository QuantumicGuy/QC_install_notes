#!/bin/bash
function check_multiwfn(){
which Multiwfn 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo ">>> Warning: <Multiwfn> tool is not found, please recheck its environment variable! <<<"
  exit 1
fi
}

function check_dos2unix(){
if ! command -v dos2unix >/dev/null 2>&1;then
  echo ">>> Warning: <dos2unix> tool is required but it has not installed yet. Aborting... <<<"
  exit 1
fi
}

function gen_pbs(){
cp $initial_path/CP2K.pbs ./${file/%$inp_extension/pbs}       # Load the template PBS file
dos2unix -q ${file/%$inp_extension/pbs}
sed -i "s/^FILENAME=.*\.$inp_extension/FILENAME=$file/" ${file/%$inp_extension/pbs} 
echo "    ==> ${file/%$inp_extension/pbs} has been generated! [$file_counter of $nfiles]"
}

function to_cp2k_inp(){              
Multiwfn $file << EOF 1> /dev/null 2>&1
cp2k
${file/%$inp_extension/inp}
-9
10
1
0
-1
3
1
2
2
2
3
2
4
9
1-250
10
2
0
q
EOF

# cp2k
# ${file/%$inp_extension/inp}
#-9
#10
#1
#0
# -1
# 3
# 1
# 2
# 2
# 2
# 3
# 2
# 4
# 10
# 2
# 0
# q
# EOF

if [[ $? -eq 0 ]];then
  echo "    ==> ${file/%$inp_extension/inp} has been generated! [$file_counter of $nfiles]"
else
  echo "    --> Fail to generate ${file/%$inp_extension/inp}!"
  let file_counter--
fi

# Settings of CP2K input files
# -9 Other settings
#		->	0 Return
# 			1 Set net charge, current:    0
#				->   Input net charge, e.g. 1
# 			2 Set spin multiplicity, current:  1
#				->	 Input spin multiplicity, e.g. 3
# 			3 Set number of repetitions of the cell in X, Y, Z, current:  1  1  1 (default)
#				->	 Input number of repetitions of the cell in X, Y, Z, e.g. 2,1,2
#			4 Toggle using finer grid for exchange-correlation part, current: No
# 			5 Set surface dipole correction, current: None (default)
#				->	 0 Do not use surface dipole correction
# 					 1 Use surface dipole correction in X direction
# 					 2 Use surface dipole correction in Y direction
# 					 3 Use surface dipole correction in Z direction	
# 			6 Toggle printing moments, current: No (default)
# 			8 Toggle using DFT+U, current: No (default)
# 			9 Define atomic magnetization
#				->	 Input indices of the atoms to define magnetization, e.g. 1,5-10,13,19
#					 To change kind name, input old and new name, e.g. Fe_1 Fe_B
#					 To exit, inputting "q"
# 		   10 Choose printing level of output information, current: Low (default)
#				-> 	 0 Silent;  1 Low;	2 Medium;  3 High
# 		   11 Set electric field vector
#				->	 Input external electric field vector in a.u., e.g. 0.0,0.0,0.025
# 		   12 Set number of virtual orbitals to solve, current:     0 (default)
#				-> 	 Input number of virtual orbitals to solve, e.g. 30
#					 If inputting -1, then all virtual orbitals will be solved
#
# -7 Set direction(s) of applying periodic boundary condition, current: XYZ (default)
#		->	NONE; X; XY; XYZ; XZ; Y; YZ; Z
#
# -4 Calculate atomic charges, current: None (default)
#		->	0 None; 1 Mulliken; 2 Lowdin; 3 Hirshfeld; 4 Hirshfeld-I; 5 Voronoi; 6 RESP; 7 REPEAT
#
# -3 Set exporting cube file, current: None (default)
#		->	-1 Just for printing HOMO and LUMO energies as well as HOMO-LUMO gap (i.e. Outputting HOMO and LUMO cubes only)
#			 0 None
# 			 1 Electron density (also with spin density for unrestricted calculation)
#			 2 Electron localization function (ELF)
#			 3 Exchange-correlation potential
#			 4 Hartree potential (negative of ESP)
#			 5 Each component of electric field
#			 6 Molecular orbital(s)
#
# -2 Toggle exporting .molden file for Multiwfn, current: No (default)
#
# -1 Choose task, current: Energy (default)
#		->	 1 Energy
#			 2 Energy + force
#			 3 Optimizing structure (cell is fixed)
#			 4 Optimizing both structure and cell
#			 5 Vibrational analysis
#			 6 Molecular dynamics
#			 7 Searching transition state using dimer algorithm
#			 9 NMR
#			 10 Polarizability
#			 11 Excited state (TDDFT)
#
#  0 Generate input file now!
#
#  1 Choose theoretical method, current: PBE (default)
#		->	 
#			 1 Pade (LDA)
#			 2 PBE        -2 revPBE     -3 PBEsol
#			 3 TPSS        4 BP86        5 BLYP
#			 6 PBE0       -6 PBE0 with ADMM
#			 7 B3LYP      -7 B3LYP with ADMM
#			 8 HSE06      -8 HSE06 with ADMM
#			 9 BEEF-vdW
#			 11 B97M-rV (via &LIBXC)       12 MN15L (via &LIBXC)
#			 13 SCAN (via &LIBXC)          14 r2SCAN (via &LIBXC)
#			 15 RPBE (via &LIBXC)
#			 20 RI-MP2        21 RI-SCS-MP2
#			 25 RI-B2PLYP     26 RI-B2GP-PLYP     27 RI-DSD-BLYP
#			 30 GFN1-xTB      40 PM6
#
#  2 Choose basis set and pseudopotential, current: DZVP-MOLOPT-SR-GTH (default)
#		->	 Note: <=5, 20, 21 correspond to GPW calculation using GTH pseudopotential, 
#			       the other ones correspond to full electron GAPW calculation
#			 -6 QZV3P-GTH
#			 -5 QZV2P-GTH
#			 -4 TZV2P-GTH
#			 -3 TZVP-GTH
#			 -2 DZVP-GTH
#			 -1 SZV-GTH
#			 1 SZV-MOLOPT-SR-GTH
#			 2 DZVP-MOLOPT-SR-GTH
#			 3 TZVP-MOLOPT-GTH
#			 4 TZV2P-MOLOPT-GTH
#			 5 TZV2PX-MOLOPT-GTH
#			 10 6-31G*
#			 11 6-311G**
#			 12 Ahlrichs-def2-TZVP
#			 13 pob-TZVP
#			 14 Ahlrichs-def2-QZVP
#			 20 cc-DZ with RI_DZ
#			 21 cc-TZ with RI_TZ
#
#  3 Set dispersion correction, current: None (default)
#		->	 0 None; 1 DFT-D3; 2 DFT-D3(BJ); 5 rVV10
#
#  4 Switching between diagonalization and OT, current: Diagonalization (default)
#
#  5 Set density matrix mixing, current: Broyden mixing (default) [only for diagonalization]
#		-> 	 1 Direct mixing with DIIS (default, usually poor);  2 Broyden mixing;  3 Pulay mixing
#
#  5 Toggle using outer SCF process, current: No [only for OT]
#
#  6 Toggle smearing electron occupation, current: No (default)
#
#  7 Toggle using self-consistent continuum solvation (SCCS), current: No (default)
#
#  8 Set k-points, current: GAMMA only (default)
#		->	Input number of k-points of MONKHORST-PACK in three directions, e.g. 8,6,2
#
#  9 **Set atom position constraint, current: None [only for opt tasks]
#		->  Input indices of the atoms to be constraint (fixed), e.g. 1,5,9-12,14-18
#		    If inputting "optH", then only hydrogens will be optimized while others will be fixed
#
# 10 **Set optimization method, current: LBFGS  [only for opt tasks]
#		->	 1 BFGS (Best choice for most situations)
#			 2 LBFGS (Suitable for very large systems)
#			 3 Conjugate gradient (More robust than BFGS and LBFGS especially when initial geometry is far from minimum, 
#			   unfortunately more expensive. Try it for difficult cases)
#
# 15 Toggle calculating excited states via TDDFT, current: No (default)

}

function travel_dir(){
nfiles=$(find -name "*.$inp_extension" | wc -l)
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
	  if [[ $mainchoice == 1 ]];then		
		jobfiles="CP2K input files"
		to_cp2k_inp
	  elif [[ $mainchoice == 2 ]];then		
		jobfiles="PBS scripts"
		gen_pbs
	  elif [[ $mainchoice == 3 ]];then
		jobfiles="*."$out_extension" files"
		to_outputfiles
	  elif [[ $mainchoice == 4 ]];then
		jobfiles="*."$inp_extension" files"
		extr_sp_cp2k_process
	  fi
	done
  fi
  cd $initial_path
done

echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
if [[ $mainchoice == 4 ]];then
  echo "######  Total $file_counter/$nfiles $jobfiles have been successfully extracted  ######"
else
  echo "######  Total $file_counter/$nfiles $jobfiles have been successfully generated  ######"
fi
echo
}

function to_outputfiles(){
Multiwfn $file << EOF 1> /dev/null 2>&1
100
2
${out_array[$out_extension]}
${file/%$inp_extension/$out_extension}
0
q
EOF

if [[ $? -eq 0 ]];then
  echo "    ==> ${file/%$inp_extension/$out_extension} has been generated! [$file_counter of $nfiles]"
else
  echo "    --> Fail to generate ${file/%$inp_extension/$out_extension}!"
  let file_counter--
fi 
}

function check_PBS_template(){
if [ -f "CP2K.pbs" ];then
  echo "Loading the CP2K template PBS file (CP2K.pbs)..."
  echo
else
  echo
  echo "The CP2K template PBS file (CP2K.pbs) is not found in the following path:"
  echo "$initial_path"
  echo
  echo "Please recheck the CP2K.pbs file!!"
  exit 1
fi
}

function extr_sp_cp2k_process(){  
if grep -wq "\*\*\*\* \*\*\*\* \*\*\*\*\*\*  \*\*  PROGRAM ENDED AT" $file && ! (grep -wq "SCF run NOT converged" $file);then  # Check whether *.out/*.log is made by CP2K and meanwhile SCF is converged
  SPE=$(grep "ENERGY| Total FORCE_EVAL" $file | awk 'END{printf $9}')
  printf "%-8s %-30s %-30s\n" $file_counter ${file%.$inp_extension} $SPE >> $initial_path/Extract_SPE_cp2k.txt
  echo "    ==> SPE has been extracted from CP2K $file! [$file_counter of $nfiles]"
  echo "        No.$file_counter:    Name: ${file%.$inp_extension}     SPE= $SPE"
else
  echo "    --> The $file file doesn't contain converged CP2K SPE! Skipping..."
  printf "%-8s %-30s %-30s\n" "X" ${file%.$inp_extension} "N/A" >> $initial_path/Extract_SPE_cp2k.txt
  let file_counter--
fi
}


###################    The CP2K helper begins from the following lines    ################### 
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*                         CP2K helper made by Jianyong Yuan                         *"
echo "*                              E-mail: 404283110@qq.com                             *"
echo "*                     Version 1.1 (dev), Release date: 2022-Mar-5                   *"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo
echo "                      ************ Main Function Menu ************                "
echo "1 Generate the CP2K input files (*.inp) from *.gjf/*.cif/*.inp/*.restart/*.xyz files by using Multiwfn"
echo "2 Generate the PBS scripts for CP2K tasks"
echo "3 Convert the *.gjf/*.cif/*.inp/*.restart/*.xyz files to *.gjf/*.cif/*.xyz files by using Multiwfn"
echo "4 Extract the final energy (Total FORCE_EVAL) from CP2K output files (*.out/*.log)"

initial_path=$(pwd)
array_mainchoice=(1 2 3 4)
read mainchoice
while ! echo "${array_mainchoice[@]}" | grep -wq "$mainchoice" 
do
  echo "Please reinput function number..."
  read mainchoice
done

if [[ $mainchoice == 1 ]];then
  check_multiwfn
  echo "Please input the extention of the input file supported in Multiwfn: [cif/gjf/inp/restart/xyz]"
  echo "Notes: *.gjf/*.xyz should contain cell parameters; *.inp/*.restart represent CP2K input files"
  array_inputchoice=("cif" "gjf" "inp" "restart" "xyz")
  read inputchoice
  while ! echo "${array_inputchoice[@]}" | grep -wq "$inputchoice" 
  do
    echo "Please reinput the extention: [cif/gjf/inp/restart/xyz]"
    read inputchoice
  done
  inp_extension=$inputchoice
  echo "Press any key to generate the CP2K input files... ^v^"
  read -n 1
  travel_dir
  
elif [[ $mainchoice == 2 ]];then
  inp_extension="inp"
  check_PBS_template
  check_dos2unix
  echo "Press any key to allocate the PBS script to CP2K tasks... ^v^"
  read -n 1
  travel_dir
  
elif [[ $mainchoice == 3 ]];then
  check_Multiwfn
  array_inp_extension=("gjf" "cif" "inp" "restart" "xyz")       # All supported extensions of input files
  array_out_extension=("gjf" "cif" "xyz")   	                # All supported extensions of output files
  declare -A out_array
  out_array=(["gjf"]=10 ["cif"]=33 ["xyz"]=2)
  echo
  echo "Currently the *.gjf/*.cif/*.inp/*.restart/*.xyz input files are supported ^_^"
  echo "Please input the extension of input files, e.g. restart"
  read inp_extension
  echo "Currently the *.gjf/*.cif/*.xyz output files are supported ^_^"
  echo "Please input the extension of output files, e.g. xyz"
  read out_extension
  echo
  if echo "${array_out_extension[@]}" | grep -wq "$out_extension" && echo "${array_inp_extension[@]}" | grep -wq "$inp_extension";then
    echo "Please check the following information: ^o^"
    echo "                  V  V  V  V  V  V  V"
    echo "Convert all [*.$inp_extension] files to [*.$out_extension] files..."
  else
    echo ">>> Convernsion of [*.$inp_extension] files to [*.$out_extension] files is NOT supported (┬_┬) <<<"
    exit 0
  fi
  echo
  echo "Press any key to start the conversion process... ^v^"
  read -n 1
  travel_dir
  
elif [[ $mainchoice == 4 ]];then
  echo
  echo "Please input the extention of CP2K output files [out/log]:"
  read inp_extension
  echo
  echo "Press any key to start the extraction process... ^v^"
  read -n 1
  printf "%-8s %-30s %-30s\n" "No." "Name" "SPE[au]" > $initial_path/Extract_SPE_cp2k.txt
  travel_dir         
  
fi






