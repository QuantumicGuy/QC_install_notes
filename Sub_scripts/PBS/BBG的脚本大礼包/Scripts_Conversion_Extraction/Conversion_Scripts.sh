#!/bin/bash
function check_Multiwfn(){
which Multiwfn 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "<Multiwfn> command is not found, please recheck whether its environment variable is correctly set or not!"
  exit 1
fi
}

function check_formchk(){
which formchk 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "<formchk> command is not found, please recheck whether its environment variable is correctly set or not!"
  exit 1
fi
}

function check_unfchk(){
which unfchk 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "<unfchk> command is not found, please recheck whether its environment variable is correctly set or not!"
  exit 1
fi
}

function check_orca_2mkl(){
which orca_2mkl 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "<orca_2mkl> command is not found, please recheck whether its environment variable is correctly set or not!"
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
	  if [[ $mainchoice == 1 || $mainchoice == 2 || $mainchoice == 3 ]];then
	    check_out_log  # Checking whether *.out/*.log made by Gaussian and processing files
	  elif [[ $mainchoice == 4 ]];then  
	    formchk_unfchk_process    # Running formchk_unfchk_process function
	  elif [[ $mainchoice == 5 || $mainchoice == 6 ]];then
	    orca_2mkl_process   # Running orca_2mkl_process function
	  fi
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
echo "######  Total $file_counter/$nfiles *.$inp_extension files have been successfully converted to *.$out_extension files  ######"
echo
} 

function check_out_log(){
if [[ $inp_extension == log || $inp_extension == out ]];then
  if [[ $(grep -o "Entering Gaussian System" $file) == "Entering Gaussian System" ]];then
    Multiwfn_process
  else
    echo "    --> The $file file is not formed by Gaussian! Skipping..."
	let file_counter--
  fi
else
  Multiwfn_process
fi
}

function to_gjf(){
if [[ $inp_extension == fchk || $inp_extension == fch ]];then
  Multiwfn $file << EOF 1> /dev/null 2>&1  # Choose "n" in the fifth line to stop writing guess wavefunction into *.gjf
100
2
10
${file/%$inp_extension/$out_extension}
n
0
q
EOF
  if [[ $? -eq 0 ]];then
    echo "    ==> ${file/%$inp_extension/$out_extension} has been generated! [$file_counter of $nfiles]"
  else
    echo "    --> Fail to generate ${file/%$inp_extension/$out_extension}!"
    let file_counter--
  fi
else
  Multiwfn $file << EOF 1> /dev/null 2>&1
100
2
10
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
fi
}

function to_inp(){               # Select calculation level for ORCA-5 at the fourth line
Multiwfn $file << EOF 1> /dev/null 2>&1
oi
${file/%$inp_extension/$out_extension}
6
q
EOF
if [[ $? -eq 0 ]];then
  sed -i "s/nopop/nopop SCFConvForced NOTRAH/" ${file/%$inp_extension/$out_extension} # add "SCFConvForced" and "NOTRAH" keywords to the *.inp
  echo "    ==> ${file/%$inp_extension/$out_extension} has been generated! [$file_counter of $nfiles]"
else
  echo "    --> Fail to generate ${file/%$inp_extension/$out_extension}!"
  let file_counter--
fi
}

# 1 B97-3c      1b r2SCAN-3c
# 2 RI-BLYP-D3(BJ)/def2-TZVP
# 3 RI-B3LYP-D3(BJ)/def2-TZVP(-f)     4 RI-B3LYP-D3(BJ)/def2-TZVP
# 5 RI-wB97M-V/def2-TZVP
# 6 RI-PWPB95-D3(BJ)/def2-TZVPP       7 RI-PWPB95-D3(BJ)/def2-QZVPP
# 6b RI-wB97X-2-D3(BJ)/def2-TZVPP     7b RI-wB97X-2-D3(BJ)/def2-QZVPP
# 8 DLPNO-CCSD(T)/cc-pVTZ with normalPNO and RIJK
# 9 DLPNO-CCSD(T)/cc-pVTZ with tightPNO and RIJK
# 10 CCSD(T)/cc-pVTZ
# 11 CCSD(T)-F12/cc-pVDZ-F12 with RI
# 12 Approximated CCSD(T)/CBS with help of MP2 (cc-pVTZ->QZ extrapolation)
# 13 DLPNO-CCSD(T)/CBS with tightPNO and RIJK (def2-TZVPP->QZVPP extrapolation)
# 14 CCSD(T)/CBS (cc-pVTZ->QZ extrapolation)
# 20 sTD-DFT based on RI-wB97X-D3/def2-SV(P) orbitals
# 21 TDA-DFT RI-PBE0/def2-SV(P) with riints_disk (much faster than 22)
# 22 TDDFT RI-PBE0/def2-SV(P)
# 23 TDDFT RI-wB2GP-PLYP/def2-TZVP    231 TDDFT RI-DSD-PBEP86/def2-TZVP
# 24 EOM-CCSD/cc-pVTZ                 25 STEOM-DLPNO-CCSD/def2-TZVP

function to_xyz(){
Multiwfn $file << EOF 1> /dev/null 2>&1
100
2
2
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

function to_mop(){              # Select calculation level for MOPAC here [the fifth line]
Multiwfn $file << EOF 1> /dev/null 2>&1
100
2
14
${file/%$inp_extension/$out_extension}
3
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

function fchk2mkl(){
Multiwfn $file << EOF 1> /dev/null 2>&1
100
2
9
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

function fchk2molden(){
Multiwfn $file << EOF 1> /dev/null 2>&1
100
2
6
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

function molden2fchk(){
Multiwfn $file << EOF 1> /dev/null 2>&1
100
2
7
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

function Multiwfn_process(){
if echo "${array_inp_extension[@]}" | grep -wq "$inp_extension" && [[ $out_extension == inp ]];then
  to_inp
elif echo "${array_inp_extension[@]}" | grep -wq "$inp_extension" && [[ $out_extension == xyz ]];then
  to_xyz
elif echo "${array_inp_extension[@]}" | grep -wq "$inp_extension" && [[ $out_extension == mop ]];then
  to_mop
elif echo "${array_inp_extension[@]}" | grep -wq "$inp_extension" && [[ $out_extension == gjf ]];then
  to_gjf
elif [[ ($inp_extension == fchk || $inp_extension == fch) && $out_extension == mkl ]];then
  fchk2mkl
elif [[ ($inp_extension == fchk || $inp_extension == fch) && $out_extension == molden ]];then
  fchk2molden
elif [[ $inp_extension == molden && $out_extension == fchk ]];then
  molden2fchk
fi
}

function formchk_unfchk_process(){
if [[ $chkfchkchoice == 1 ]];then
  formchk $file 1> /dev/null 2>&1
  if [[ $? -eq 0 ]];then
    echo "    ==> ${file/%$inp_extension/$out_extension} has been generated! [$file_counter of $nfiles]"
  else
    echo "    --> Fail to generate ${file/%$inp_extension/$out_extension}!"
    let file_counter--
  fi
elif [[ $chkfchkchoice == 2 ]];then
  unfchk $file 1> /dev/null 2>&1
  if [[ $? -eq 0 ]];then
    echo "    ==> ${file/%$inp_extension/$out_extension} has been generated! [$file_counter of $nfiles]"
  else
    echo "    --> Fail to generate ${file/%$inp_extension/$out_extension}!"
    let file_counter--
  fi
fi
}

function orca_2mkl_process(){
if [[ $mainchoice == 5 && $gbwmklchoice == 1 ]];then
  orca_2mkl ${file%.$inp_extension} 1> /dev/null 2>&1
  if [[ $? -eq 0 ]];then
    echo "    ==> ${file/%$inp_extension/$out_extension} has been generated! [$file_counter of $nfiles]"
  else
    echo "    --> Fail to generate ${file/%$inp_extension/$out_extension}!"
    let file_counter--
  fi
elif [[ $mainchoice == 5 && $gbwmklchoice == 2 ]];then
  orca_2mkl ${file%.$inp_extension} -gbw 1> /dev/null 2>&1
  if [[ $? -eq 0 ]];then
    echo "    ==> ${file/%$inp_extension/$out_extension} has been generated! [$file_counter of $nfiles]"
  else
    echo "    --> Fail to generate ${file/%$inp_extension/$out_extension}!"
    let file_counter--
  fi
elif [[ $mainchoice == 6 ]];then
  orca_2mkl ${file%.$inp_extension} -molden 1> /dev/null 2>&1
  if [[ $? -eq 0 ]];then
    echo "    ==> ${file/%$inp_extension/$out_extension} has been generated! [$file_counter of $nfiles]"
	mv ${file/%$inp_extension/molden.input} ${file/%$inp_extension/$out_extension}
  else
    echo "    --> Fail to generate ${file/%$inp_extension/$out_extension}!"
    let file_counter--
  fi
fi
}

function main_Multiwfn(){       
echo
echo "############  Generate quantum chemistry (QC) input files by Multiwfn 3.8 (dev) ############"
check_Multiwfn
array_inp_extension=(gjf xyz fchk fch out log)     # All supported extensions of input files
array_out_extension=(gjf inp mop xyz)              # All supported extensions of output files
echo
echo "Currently the *.gjf/*.xyz/*.fchk/*.fch/*.out/*.log input files are supported ^_^"
echo "Please input the extension of input files, e.g. gjf"
read inp_extension    # Set the extension of input files; support *.gjf/*.xyz/*.fchk/*.fch/*.out/*.log
echo "Currently the *.gjf/*.inp/*.mop/*.xyz output files as QC inputs are supported ^_^"
echo "Please input the extension of output files, e.g. inp"
read out_extension    # Set the extension of output files; support *.gjf/*.inp/*.mop/*.xyz
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
if echo "${array_out_extension[@]}" | grep -wq "$out_extension" && [[ $inp_extension == log || $inp_extension == out ]];then
  echo "Please check the following information: ^o^"
  echo "                  V  V  V  V  V  V  V"
  echo "Convert final geometry in all Gaussian [*.$inp_extension] files to that in [*.$out_extension] files..."
elif echo "${array_out_extension[@]}" | grep -wq "$out_extension" && [[ $inp_extension == xyz || $inp_extension == gjf || $inp_extension == fchk || $inp_extension == fch ]];then
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
travel_dir           # Running travel_dir and Multiwfn_process functions
}

function main_formchk_unfchk(){ 
echo
echo "############  Interconvert between [*.fchk] and [*.chk] files by formchk/unfchk tool from Gaussian16  ############"
echo "                >>>      Note that the *.fchk should be formed under the Linux platform      <<<"
echo "1 Convert [*.chk] files to [*.fchk] files by formchk tool from Gaussian16"
echo "2 Convert [*.fchk] files to [*.chk] files by unfchk tool from Gaussian16"
array_chkfchkchoice=(1 2)
read chkfchkchoice
while ! echo "${array_chkfchkchoice[@]}" | grep -wq "$chkfchkchoice" 
do
  echo "Please reinput function number..."
  read chkfchkchoice
done
initial_path=$(pwd)
if [[ $chkfchkchoice == 1 ]];then
  inp_extension=chk   # *.chk files will be processed by formchk tool
  out_extension=fchk
  check_formchk
elif [[ $chkfchkchoice == 2 ]];then
  inp_extension=fchk   # *.fchk files will be processed by unfchk tool
  out_extension=chk
  check_unfchk
fi
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Please check the following information: ^o^"
echo "                  V  V  V  V  V  V  V"
echo "Convert [*.$inp_extension] files to [*.$out_extension] files..."
echo "Press any key to start the conversion process... ^v^"
read -n 1
travel_dir         # Running travel_dir and formchk_unfchk_process functions
}

function main_orca_2mkl(){
if [[ $mainchoice == 5 ]];then
  echo
  echo "############  Interconvert between [*.gbw] and [*.mkl] files by orca_2mkl tool from ORCA-4.2.1  ############"
  echo "1 Convert [*.gbw] files to [*.mkl] files"
  echo "2 Convert [*.mkl] files to [*.gbw] files"
  array_gbwmklchoice=(1 2)
  read gbwmklchoice
  while ! echo "${array_gbwmklchoice[@]}" | grep -wq "$gbwmklchoice" 
  do
    echo "Please reinput function number..."
    read gbwmklchoice
  done
  if [[ $gbwmklchoice == 1 ]];then
    inp_extension=gbw   # *.gbw files will be converted to *.mkl by orca_2mkl tool
    out_extension=mkl
  elif [[ $gbwmklchoice == 2 ]];then
    inp_extension=mkl   # *.mkl files will be converted to *.gbw by orca_2mkl tool
    out_extension=gbw
  fi
elif [[ $mainchoice == 6 ]];then
  echo
  echo "############  Convert [*.gbw] files to [*.molden] files by orca_2mkl tool from ORCA-4.2.1  ############"
  inp_extension=gbw   # *.gbw files will be converted to *.molden by orca_2mkl tool
  out_extension=molden
fi
initial_path=$(pwd)
check_orca_2mkl
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Please check the following information: ^o^"
echo "                  V  V  V  V  V  V  V"
echo "Convert [*.$inp_extension] files to [*.$out_extension] files..."
echo "Press any key to start the conversion process... ^v^"
read -n 1
travel_dir         # Running travel_dir and orca_2mkl_process functions
}

function main_fchk2mkl(){
echo "############  Convert [*.fchk/*.fch] files to [*.mkl] files by Multiwfn 3.8 (dev)  ############"
echo "Please input the extention of formatted Gaussian checkpoint file: [fchk/fch]"
array_fchkfchchoice=(fchk fch)
read fchkfchchoice
while ! echo "${array_fchkfchchoice[@]}" | grep -wq "$fchkfchchoice" 
do
  echo "Please reinput the extention: [fchk/fch]"
  read fchkfchchoice
done
inp_extension=$fchkfchchoice
out_extension=mkl
initial_path=$(pwd)
check_Multiwfn
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Please check the following information: ^o^"
echo "                  V  V  V  V  V  V  V"
echo "Convert [*.$inp_extension] files to [*.$out_extension] files..."
echo "Press any key to start the conversion process... ^v^"
read -n 1
travel_dir         # Running travel_dir and Multiwfn_process functions
}

function main_fchkmolden(){
echo
echo "############  Interconvert between [*.fchk/*.fch] and [*.molden] files by Multiwfn 3.8 (dev)  ############"
echo "1 Convert [*.fchk/*.fch] files to [*.molden] files"
echo "2 Convert [*.molden] files to [*.fchk] files"
array_fchkmoldenchoice=(1 2)
read fchkmoldenchoice
while ! echo "${array_fchkmoldenchoice[@]}" | grep -wq "$fchkmoldenchoice" 
do
  echo "Please reinput function number..."
  read fchkmoldenchoice
done
if [[ $fchkmoldenchoice == 1 ]];then
  echo "Please input the extention of formatted Gaussian checkpoint file: [fchk/fch]"
  array_fchkfchchoice=(fchk fch)
  read fchkfchchoice
  while ! echo "${array_fchkfchchoice[@]}" | grep -wq "$fchkfchchoice" 
  do
    echo "Please reinput the extention: [fchk/fch]"
    read fchkfchchoice
  done
  inp_extension=$fchkfchchoice
  out_extension=molden
elif [[ $fchkmoldenchoice == 2 ]];then
  inp_extension=molden   
  out_extension=fchk
fi
initial_path=$(pwd)
check_Multiwfn
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Please check the following information: ^o^"
echo "                  V  V  V  V  V  V  V"
echo "Convert [*.$inp_extension] files to [*.$out_extension] files..."
echo "Press any key to start the conversion process... ^v^"
read -n 1
travel_dir         # Running travel_dir and Multiwfn_process functions
}




###################    file conversion script begins from the following lines    ################### 
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*                     file conversion script made by Jianyong Yuan                  *"
echo "*                              E-mail: 404283110@qq.com                             *"
echo "*                     Version 0.2 (dev), Release date: 2022-Mar-14                  *"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo
echo "                      ************ Main Function Menu ************                "
echo "1 Convert [*.gjf/*.xyz/*.fchk/*.fch/*.out/*.log] files to [*.gjf/*.inp/*.mop/*.xyz] files by Multiwfn"
echo "2 Convert [*.fchk/*.fch] files to [*.mkl] files by Multiwfn"
echo "3 Interconvert between [*.fchk/*.fch] and [*.molden] files by Multiwfn"
echo "4 Interconvert between [*.fchk] and [*.chk] Gaussian checkpoint files by formchk/unfchk tool"
echo "5 Interconvert between [*.gbw] and [*.mkl] ORCA files by orca_2mkl tool"
echo "6 Convert [*.gbw] files to [*.molden] files by orca_2mkl tool"

array_mainchoice=(1 2 3 4 5 6)
read mainchoice
while ! echo "${array_mainchoice[@]}" | grep -wq "$mainchoice" 
do
  echo "Please reinput function number..."
  read mainchoice
done
if [[ $mainchoice == 1 ]];then
  main_Multiwfn
elif [[ $mainchoice == 2 ]];then
  main_fchk2mkl
elif [[ $mainchoice == 3 ]];then
  main_fchkmolden
elif [[ $mainchoice == 4 ]];then
  main_formchk_unfchk
elif [[ $mainchoice == 5 || $mainchoice == 6 ]];then
  main_orca_2mkl
fi








