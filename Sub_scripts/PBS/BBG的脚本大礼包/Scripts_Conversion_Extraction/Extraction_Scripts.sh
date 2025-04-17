#!/bin/bash
function check_freqchk(){
which formchk 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "<freqchk> command is not found, please recheck whether its environment variable is correctly set or not!"
  exit 1
fi
}

function check_Shermo(){
which Shermo 1> /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "<Shermo> command is not found, please recheck whether its environment variable is correctly set or not!"
  echo "Note that the Shermo tool can be obtained for free at http://sobereva.com/soft/shermo/"
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
	  if [[ $mainchoice == 1 ]];then
	    extr_sp_g16_process     
	  elif [[ $mainchoice == 2 ]];then  
	    extr_thermal_g16_process    
      elif [[ $mainchoice == 3 ]];then  
	    extr_tddft_g16_process 		
	  elif [[ $mainchoice == 4 ]];then
	    extr_sp_orca_process  
	  elif [[ $mainchoice == 5 ]];then
		extr_thermal_orca_process
	  elif [[ $mainchoice == 6 ]];then
	    freqchk_process 
	  elif [[ $mainchoice == 7 ]];then
	    opt_check_process
	  elif [[ $mainchoice == 8 ]];then
	    extr_sp_xtb_process
	  elif [[ $mainchoice == 9 || $mainchoice == 's' ]];then
	    Shermo_process
	  fi   
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
if [[ $mainchoice == 1 ]];then
  echo "######  SPE in total $file_counter/$nfiles Gaussian *.$inp_extension files have been successfully extracted  ######"
elif [[ $mainchoice == 2 ]];then
  echo "######  ZPE, Gcorr, Hcorr, and Ucorr in total $file_counter/$nfiles *.$inp_extension files have been successfully extracted  ######"
elif [[ $mainchoice == 3 ]];then
  echo "######  TDDFT info. in total $file_counter/$nfiles *.$inp_extension files have been successfully extracted  ######"
elif [[ $mainchoice == 4 ]];then
  echo "######  SPE in total $file_counter/$nfiles ORCA *.$inp_extension files have been successfully extracted  ######"
elif [[ $mainchoice == 6 ]];then
  echo "######  Gcorr, Hcorr, and Ucorr in total $file_counter/$nfiles *.$inp_extension files have been successfully recalculated at $temperature K  ######"
elif [[ $mainchoice == 7 ]];then
  echo "######  Total $file_counter/$nfiles *.$inp_extension Gaussian files have been checked  ######"
  if [[ $normal_noimagfreq_counter > 0 ]];then
    echo "****  Normally terminated files without imaginary frequency: $normal_noimagfreq_counter  ****"
  fi
  if [[ $normal_counter > 0 ]];then
    echo "   ****  Normally terminated files [no freq. info.]: $normal_counter  ****"
  fi
  if [[ $imagfreq_counter > 0 ]];then
    echo "            --->  Files with imaginary frequency: $imagfreq_counter  <---"
    echo "                         V   V   V   V   V"
	j=0
	for((i=0;i<${#arr_imagfreq[@]};i++));do
	  echo -n "${arr_imagfreq[i]}  "
	  let j++
	  if [[ $j == 5 ]];then
	    echo -ne "\n"
		j=0
	  fi
	done
	echo
  fi
  if [[ $opt_noconv_counter > 0 ]];then
    echo "            --->  Files with OPT issues: $opt_noconv_counter  <---"
    echo "                         V   V   V   V   V"
	j=0
	for((i=0;i<${#arr_opt_noconv[@]};i++));do
	  echo -n "${arr_opt_noconv[i]}  "
	  let j++
	  if [[ $j == 5 ]];then
	    echo -ne "\n"
		j=0
	  fi
	done
	echo
  fi
  if [[ $scf_noconv_counter > 0 ]];then
    echo "            --->  Files with SCF issues: $scf_noconv_counter  <---"
    echo "                         V   V   V   V   V"
	j=0
	for((i=0;i<${#arr_scf_noconv[@]};i++));do
	  echo -n "${arr_scf_noconv[i]}  "
	  let j++
	  if [[ $j == 5 ]];then
	    echo -ne "\n"
		j=0
	  fi
	done
	echo
  fi
  if [[ $other_err_counter > 0 ]];then
    echo "   -X->  Files with other issues to be manually checked: $other_err_counter  <-X-"
    echo "                         V   V   V   V   V"
	j=0
	for((i=0;i<${#arr_other_err[@]};i++));do
	  echo -n "${arr_other_err[i]}  "
	  let j++
	  if [[ $j == 5 ]];then
	    echo -ne "\n"
		j=0
	  fi
	done
	echo
  fi
  if [[ $skipping_counter > 0 ]];then
    echo "     ~~~  Skipped files: $skipping_counter [not Gaussian outputs]  ~~~"
  fi
elif [[ $mainchoice == 8 ]];then
  echo "######  SPE in total $file_counter/$nfiles xtb *.$inp_extension files have been successfully extracted  ######"
elif [[ $mainchoice == 9 ]];then
  echo "######  Total $file_counter/$nfiles *.$inp_extension files have been successfully processed by Shermo  ######"
fi
echo
} 

function freqchk_process(){      # Detailed settings for freqchk tool 
freqchk $file << EOF > temp_out.txt 2>&1
n
$temperature
1
1
y
n

EOF
if [[ $? -eq 0 ]];then
  Gcorr=$(grep "Thermal correction to Gibbs Free Energy" temp_out.txt | awk '{printf $7}')
  Hcorr=$(grep "Thermal correction to Enthalpy" temp_out.txt | awk '{printf $5}')
  Ucorr=$(grep "Thermal correction to Energy" temp_out.txt | awk '{printf $5}')
  ZPE=$(grep "Zero-point correction" temp_out.txt | awk '{printf $3}')
  printf "%-8s %-30s %-15s %-15s %-15s %-15s\n" $file_counter ${file%.$inp_extension} $Gcorr $Hcorr $Ucorr $ZPE >> $initial_path/Recalc_corr_g16_${temperature}K.txt
  echo "    ==> Gcorr, Hcorr, and Ucorr in Gaussian $file have been recalculated at $temperature K! [$file_counter of $nfiles]"
  echo "        No.$file_counter:   Name: ${file%.$inp_extension}   Gcorr= $Gcorr   Hcorr= $Hcorr   Ucorr= $Ucorr   ZPE= $ZPE"      
else
  echo "    --> Fail to process $file!"
  printf "%-8s %-30s %-15s %-15s %-15s %-15s\n" "X" ${file%.$inp_extension} "N/A" "N/A" "N/A" "N/A" >> $initial_path/Recalc_corr_g16_${temperature}K.txt
  let file_counter--
fi
rm temp_out.txt
}

function extr_thermal_g16_process(){
if grep -wq "Normal termination of Gaussian" $file && grep -wq "Zero-point correction" $file;then  # Check whether *.out/*.log is made by Gaussian and meanwhile contains frequency information
  Gcorr=$(grep "Thermal correction to Gibbs Free Energy" $file | awk '{printf $7}')
  Hcorr=$(grep "Thermal correction to Enthalpy" $file | awk '{printf $5}')
  Ucorr=$(grep "Thermal correction to Energy" $file | awk '{printf $5}')
  ZPE=$(grep "Zero-point correction" $file | awk '{printf $3}')
  printf "%-8s %-30s %-15s %-15s %-15s %-15s\n" $file_counter ${file%.$inp_extension} $Gcorr $Hcorr $Ucorr $ZPE >> $initial_path/Extract_corr_g16.txt
  echo "    ==> Gcorr, Hcorr, and Ucorr have been extracted from Gaussian $file! [$file_counter of $nfiles]"
  echo "        No.$file_counter:   Name: ${file%.$inp_extension}   Gcorr= $Gcorr   Hcorr= $Hcorr   Ucorr= $Ucorr   ZPE= $ZPE"  
else
  echo "    --> The $file file doesn't contain Gaussian frequency information! Skipping..."
  printf "%-8s %-30s %-15s %-15s %-15s %-15s\n" "X" ${file%.$inp_extension} "N/A" "N/A" "N/A" "N/A" >> $initial_path/Extract_corr_g16.txt
  let file_counter--
fi  
}

function extr_sp_g16_process(){
if grep -wq "Normal termination of Gaussian" $file && grep -wq "SCF Done" $file;then  # Check whether *.out/*.log is made by Gaussian and meanwhile SCF is converged
  SPE=$(grep "SCF Done" $file | awk 'END{printf $5}')
  printf "%-8s %-30s %-30s\n" $file_counter ${file%.$inp_extension} $SPE >> $initial_path/Extract_SPE_g16.txt
  echo "    ==> SPE of DFT/HF has been extracted from Gaussian $file! [$file_counter of $nfiles]"
  echo "        No.$file_counter:    Name: ${file%.$inp_extension}     SPE= $SPE"  
else
  echo "    --> The $file file doesn't contain converged Gaussian SPE! Skipping..."
  printf "%-8s %-30s %-30s\n" "X" ${file%.$inp_extension} "N/A" >> $initial_path/Extract_SPE_g16.txt
  let file_counter--
fi  
}

function extr_sp_orca_process(){  
if grep -wq "ORCA TERMINATED NORMALLY" $file && grep -wq "FINAL SINGLE POINT ENERGY" $file;then  # Check whether *.out/*.log is made by ORCA and meanwhile SCF is converged
  SPE=$(grep "FINAL SINGLE POINT ENERGY" $file | awk 'END{printf $5}')
  printf "%-8s %-30s %-30s\n" $file_counter ${file%.$inp_extension} $SPE >> $initial_path/Extract_SPE_orca.txt
  echo "    ==> SPE has been extracted from ORCA $file! [$file_counter of $nfiles]"
  echo "        No.$file_counter:    Name: ${file%.$inp_extension}     SPE= $SPE"  
else
  echo "    --> The $file file doesn't contain converged ORCA SPE! Skipping..."
  printf "%-8s %-30s %-30s\n" "X" ${file%.$inp_extension} "N/A" >> $initial_path/Extract_SPE_orca.txt
  let file_counter--
fi
}

function opt_check_process(){
if grep -wq "Entering Gaussian System" $file;then 
  if grep -wq "Frequencies --" $file; then
    if grep -wq "Normal termination of Gaussian" $file && [[ $(grep -w "Frequencies --" $file | awk 'NR==1{print $3}') > 0 ]];then
      echo "    ==> $file [$file_counter of $nfiles] normally ended with no imaginary frequency.."
	  let normal_noimagfreq_counter++
    elif grep -wq "Normal termination of Gaussian" $file && [[ $(grep -w "Frequencies --" $file | awk 'NR==1{print $3}') < 0 ]];then
	  echo "    ==> $file [$file_counter of $nfiles] contains imaginary frequency!!"
      arr_imagfreq[${#arr_imagfreq[@]}]=$file
	  let imagfreq_counter++
	fi
  elif grep -wq "Convergence failure" $file;then
	echo "    ==> $file [$file_counter of $nfiles] encountered SCF convergence issue!!"
	arr_scf_noconv[${#arr_scf_noconv[@]}]=$file
    let scf_noconv_counter++
  elif grep -wq "Optimization stopped" $file && grep -wq "Number of steps exceeded" $file;then
	echo "    ==> $file [$file_counter of $nfiles] encountered OPT convergence issue!!"
	arr_opt_noconv[${#arr_opt_noconv[@]}]=$file
    let opt_noconv_counter++
  elif grep -o "Normal termination of Gaussian" $file;then 
    echo "    ==> $file [$file_counter of $nfiles] normally ended [no freq. info.].."
	let normal_counter++
  else
    echo "    ==> $file [$file_counter of $nfiles] has other issues, please open and check the file manually!!!"
	arr_other_err[${#arr_other_err[@]}]=$file
    let other_err_counter++
  fi
else
  echo "    --> The $file file is not formed by Gaussian! Skipping..."
  let skipping_counter++
  let file_counter--
fi
}

function extr_tddft_g16_process(){
if grep -wq "Normal termination of Gaussian" $file && grep -wq "Excitation energies and oscillator strengths" $file;then
  multiplicity=$(grep "Excited State   $ex_number" $file | awk 'END{printf $4}')
  Eexc=$(grep "Excited State   $ex_number" $file | awk 'END{printf $5}')
  lambda=$(grep "Excited State   $ex_number" $file | awk 'END{printf $7}')
  f=$(grep "Excited State   $ex_number" $file | awk 'END{printf $9}')
  S=$(grep "Excited State   $ex_number" $file | awk 'END{printf $10}')
  printf "%-8s %-30s %-20s %-15s %-15s %-15s %-15s\n" $file_counter ${file%.$inp_extension} $multiplicity $Eexc $lambda ${f#f=} ${S#<S**2>=} >> $initial_path/Extract_TDDFT_g16.txt
  echo "    ==> TDDFT info. has been extracted from Gaussian $file! [$file_counter of $nfiles]"
  echo "        No.$file_counter:   Name: ${file%.$inp_extension}   Multi.= $multiplicity   Eexc= $Eexc   Lambda= $lambda   f= ${f#f=}   <S**2>= ${S#<S**2>}"  
else
  echo "    --> The $file file doesn't contain converged Gaussian TDDFT information! Skipping..."
  printf "%-8s %-30s %-20s %-15s %-15s %-15s %-15s\n" "X" ${file%.$inp_extension} "N/A" "N/A" "N/A" "N/A" "N/A" >> $initial_path/Extract_TDDFT_g16.txt
  let file_counter--
fi
}

function extr_thermal_orca_process(){
if grep -wq "ORCA TERMINATED NORMALLY" $file && grep -wq "THERMOCHEMISTRY" $file;then  # Check whether *.out/*.log is made by ORCA and meanwhile contains frequency information
  ZPE=$(grep "Zero point energy" $file | awk '{printf $5}')
  Eele=$(grep "Electronic energy                ..." $file | awk '{printf $4}')
  H=$(grep "Total Enthalpy" $file | awk '{printf $4}')
  G=$(grep "Final Gibbs free energy" $file | awk '{printf $6}')
  Ucorr=$(grep "Total correction" $file | awk '{printf $3}')
  Hcorr=$(echo "scale=8;$H - $Eele" | bc)
  Gcorr=$(echo "scale=8;$G - $Eele" | bc)
  printf "%-8s %-30s %-15.8f %-15.8f %-15.8f %-15.8f\n" $file_counter ${file%.$inp_extension} $Gcorr $Hcorr $Ucorr $ZPE >> $initial_path/Extract_corr_orca.txt
  echo "    ==> Gcorr, Hcorr, and Ucorr have been extracted from ORCA $file! [$file_counter of $nfiles]"
  printf "        No.%s:   Name: %s    Gcorr= %-0.8f   Hcorr= %-0.8f   Ucorr= %-0.8f   ZPE= %-0.8f" $file_counter ${file%.$inp_extension} $Gcorr $Hcorr $Ucorr $ZPE
else
  echo "    --> The $file file doesn't contain ORCA frequency information! Skipping..."
  printf "%-8s %-30s %-15s %-15s %-15s %-15s\n" "X" ${file%.$inp_extension} "N/A" "N/A" "N/A" "N/A" >> $initial_path/Extract_corr_orca.txt
  let file_counter--
fi  
}

function extr_sp_xtb_process(){
if (! grep -wq "convergence criteria cannot" $file) && (! grep -wq "FAILED TO CONVERGE GEOMETRY OPTIMIZATION" $file) && grep -wq "| TOTAL ENERGY" $file;then  # Check whether *.out/*.log is made by xtb and meanwhile SCF is converged
  SPE=$(grep "| TOTAL ENERGY" $file | awk 'END{printf $4}')
  printf "%-8s %-30s %-30s\n" $file_counter ${file%.$inp_extension} $SPE >> $initial_path/Extract_SPE_xtb.txt
  echo "    ==> SPE has been extracted from xtb $file! [$file_counter of $nfiles]"
  echo "        No.$file_counter:    Name: ${file%.$inp_extension}     SPE= $SPE"  
else
  echo "    --> The $file file doesn't contain converged xtb SPE! Skipping..."
  printf "%-8s %-30s %-30s\n" "X" ${file%.$inp_extension} "N/A" >> $initial_path/Extract_SPE_xtb.txt
  let file_counter--
fi
}

function Shermo_process(){
  function run_shermo(){
    echo "\n" | Shermo $file -ilowfreq $ilowfreq_treatment -T $temperature -P $pressure -sclZPE $sclZPE > temp_out.txt 2>&1
	if grep -wq "Error:" temp_out.txt;then
	  return 1
	fi
  }
  
  function extract_corr(){
    Gcorr=$(grep "Thermal correction to G:" temp_out.txt | awk '{printf $9}')
    Hcorr=$(grep "Thermal correction to H:" temp_out.txt | awk '{printf $9}')
    Ucorr=$(grep "Thermal correction to U:" temp_out.txt | awk '{printf $9}')
    ZPE=$(grep "Zero-point energy (ZPE):" temp_out.txt | awk '{printf $8}')
  }

if [[ $shermo_scan_choice == "n" ]];then
  run_shermo
  if [[ $? -eq 0 ]];then
    extract_corr
	printf "%-8s %-55s %-15s %-15s %-15s %-15s\n" $file_counter ${file%.$inp_extension} $Gcorr $Hcorr $Ucorr $ZPE >> $initial_path/Calc_corr_Shermo_${temperature}K.txt
    echo "    ==> Gcorr, Hcorr, and Ucorr in $file have been calculated at $temperature K [$file_counter of $nfiles]"
    echo "        No.$file_counter:   Name: ${file%.$inp_extension}   Gcorr= $Gcorr   Hcorr= $Hcorr   Ucorr= $Ucorr   ZPE= $ZPE"
  else
    echo "    --> Fail to process $file!"
    printf "%-8s %-55s %-15s %-15s %-15s %-15s\n" "X" ${file%.$inp_extension} "N/A" "N/A" "N/A" "N/A" >> $initial_path/Calc_corr_Shermo_${temperature}K.txt
	let file_counter--
  fi
  rm temp_out.txt
  
elif [[ $shermo_scan_choice == "y" ]];then
  printf "%-8s %-15s %-15s %-15s %-15s %-15s\n" "Step" "T[K]" "Gcorr[au]" "Hcorr[au]" "Ucorr[au]" "ZPE[au]" > ${file%.$inp_extension}_T_Shermo.txt
  temperature=$(echo "$ini_T" | awk '{printf "%.2f", $1}')
  run_shermo
  if [[ $? -eq 0 ]];then
    extract_corr
	echo "    ==> Gcorr, Hcorr, and Ucorr in $file have been calculated [$file_counter of $nfiles]"
	echo "        from $ini_T K to $final_T K with the interval of $stepsize_T K (total $total_steps_T steps)"
	printf "%-8s %-15s %-15s %-15s %-15s %-15s\n" "0" $temperature $Gcorr $Hcorr $Ucorr $ZPE >> ${file%.$inp_extension}_T_Shermo.txt
	for ((i=1; i<=$total_steps_T; i++));do
	  temperature=$(echo "$ini_T $stepsize_T $i" | awk '{printf "%.2f", $1 + $2 * $3}')
	  run_shermo
	  extract_corr 
	  info="        Calculating data at $temperature K {$i/$total_steps_T}"
	  [[ $i == $total_steps_T ]] && printf "$info""\n" || printf "$info""\r"
	  printf "%-8s %-15s %-15s %-15s %-15s %-15s\n" $i $temperature $Gcorr $Hcorr $Ucorr $ZPE >> ${file%.$inp_extension}_T_Shermo.txt
	done
	printf "        Completed! \n"
	printf "\n%s\n" "${file%.$inp_extension} @P= ${pressure} atm, sclZPE= ${sclZPE}, ilowfreq= ${ilowfreq_treatment}" >> ${file%.$inp_extension}_T_Shermo.txt
	sleep 1
  else
    echo "    --> Fail to process $file!"
    rm ${file%.$inp_extension}_T_Shermo.txt
	let file_counter--
  fi
  rm temp_out.txt
fi
}

function main_freqchk(){ 
echo
echo "############  Recalculate the ZPE, Gcorr, Hcorr, and Ucorr from Gaussian [*.fchk] files by freqchk tool  ############"
echo
check_freqchk
echo "Please input the temperature (K) at which the Gcorr, Hcorr, and Ucorr to be recalculated:  ^o^"
read temperature
while [[ ! $temperature =~ ^([1-9][0-9]*|[0])([.][0-9]+)?$ ]];do
  echo "Please input a non-negative real number:"
  read temperature
done
inp_extension=fchk   # *.fchk files will be processed by freqchk tool
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Press any key to start the recalculation process at $temperature K ... ^v^"
read -n 1
printf "%-8s %-30s %-15s %-15s %-15s %-15s\n" "No." "Name @${temperature}K" "Gcorr[au]" "Hcorr[au]" "Ucorr[au]" "ZPE[au]" > $initial_path/Recalc_corr_g16_${temperature}K.txt
travel_dir         # Running travel_dir and freqchk_process functions
}

function main_extr_thermal_g16(){ 
echo
echo "############  Extract the ZPE, Gcorr, Hcorr, and Ucorr from Gaussian16 output files  ############"
echo
echo "Please input the extention of Gaussian16 output files [out/log]:"
read inp_extension
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Press any key to start the extraction process... ^v^"
read -n 1
printf "%-8s %-30s %-15s %-15s %-15s %-15s\n" "No." "Name" "Gcorr[au]" "Hcorr[au]" "Ucorr[au]" "ZPE[au]" > $initial_path/Extract_corr_g16.txt
travel_dir         # Running travel_dir and extr_thermal_g16_process functions
}

function main_extr_sp_g16(){ 
echo
echo "############  Extract the SPE of DFT and HF from Gaussian16 output files  ############"
echo
echo "Please input the extention of Gaussian16 output files [out/log]:"
read inp_extension
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Press any key to start the extraction process... ^v^"
read -n 1
printf "%-8s %-30s %-30s\n" "No." "Name" "SPE[au]" > $initial_path/Extract_SPE_g16.txt
travel_dir         # Running travel_dir and extr_sp_g16_process functions
}

function main_extr_sp_orca(){ 
echo
echo "############  Extract the SPE from ORCA-5 output files  ############"
echo
echo "Please input the extention of ORCA-5 output files [out/log]:"
read inp_extension
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Press any key to start the extraction process... ^v^"
read -n 1
printf "%-8s %-30s %-30s\n" "No." "Name" "SPE[au]" > $initial_path/Extract_SPE_orca.txt
travel_dir         # Running travel_dir and extr_sp_orca_process functions
}

function main_opt_check(){
echo
echo "############  Detect the status of Gaussian optimization outputs  ############"
echo "              (imaginary frequency, opt/SCF convergency, etc.)"
echo
echo "Please input the extention of Gaussian16 output files [out/log]:"
array_outlogchoice=(out log)
read outlogchoice
while ! echo "${array_outlogchoice[@]}" | grep -wq "$outlogchoice" 
do
  echo "Please reinput the extention [out/log]..."
  read outlogchoice
done
inp_extension=$outlogchoice
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Press any key to start the detection process... ^v^"
read -n 1
normal_noimagfreq_counter=0
normal_counter=0 
imagfreq_counter=0
opt_noconv_counter=0
scf_noconv_counter=0
other_err_counter=0
skipping_counter=0
travel_dir         # Running travel_dir and opt_check_process functions
}

function main_extr_tddft_g16(){
echo
echo "############  Extract the excited-state energy and oscillator strength from Gaussian16 output files  ############"
echo
echo "Please input the extention of Gaussian16 output files [out/log]:"
read inp_extension
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Which excited state are you interested in?"
read ex_number
while [[ ! $ex_number =~ ^[1-9][0-9]*$ ]];do 
  echo "Please input a positive integer:"
  read ex_number
done
echo "Press any key to start the extraction process for excited state $ex_number ... ^v^"
read -n 1
echo "Excited State ${ex_number}:" > $initial_path/Extract_TDDFT_g16.txt
printf "%-8s %-30s %-20s %-15s %-15s %-15s %-15s\n" "No." "Name" "Multiplicity" "Eexc[eV]" "Lambda[nm]" "f" "<S**2>" >> $initial_path/Extract_TDDFT_g16.txt
travel_dir         # Running travel_dir and extr_tddft_g16_process functions
}

function main_extr_thermal_orca(){ 
echo
echo "############  Extract the ZPE, Gcorr, Hcorr, and Ucorr from ORCA-5 output files  ############"
echo
echo "Please input the extention of ORCA-5 output files [out/log]:"
read inp_extension
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Press any key to start the extraction process... ^v^"
read -n 1
printf "%-8s %-30s %-15s %-15s %-15s %-15s\n" "No." "Name" "Gcorr[au]" "Hcorr[au]" "Ucorr[au]" "ZPE[au]" > $initial_path/Extract_corr_orca.txt
travel_dir         # Running travel_dir and extr_thermal_orca_process functions
}

function main_extr_sp_xtb(){
echo
echo "############  Extract the SPE from xtb-6.3.3 output files  ############"
echo
echo "Please input the extention of xtb-6.3.3 output files [out/log]:"
read inp_extension
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo
echo "Press any key to start the extraction process... ^v^"
read -n 1
printf "%-8s %-30s %-30s\n" "No." "Name" "SPE[au]" > $initial_path/Extract_SPE_xtb.txt
travel_dir         # Running travel_dir and extr_sp_xtb_process functions
}

function main_Shermo(){
  function T_scanning_chocie(){
    echo "Whether to perform the temperature scanning for various thermochemistry correction quantities [y/n]? (default: No)"
    array_shermo_scan_choice=("y" "n")
    read shermo_scan_choice
    while ! echo "${array_shermo_scan_choice[@]}" | grep -wq "$shermo_scan_choice";do
      if [[ -z $shermo_scan_choice ]];then
        shermo_scan_choice="n"
    	break
      fi
      echo "Please reinput the choice [y/n]..."
      read shermo_scan_choice
    done
  }

  function low_freq_treatment(){
    echo "Please select a treatment for low frequencies:  ^o^"
    echo "0: Harmonic approximation (default)"
    echo "2: Grimme's entropy interpolation between harmonic and free-rotor approximations"
    echo "Note: Press enter key to use the default treatment: Harmonic approximation"
    array_ilowfreq_choice=(0 2)
    read ilowfreq_treatment
    while ! echo "${array_ilowfreq_choice[@]}" | grep -wq "$ilowfreq_treatment";do
      if [[ -z $ilowfreq_treatment ]];then
        ilowfreq_treatment=0
    	break
      fi
      echo "Please reinput the treatment number..."
      read ilowfreq_treatment
    done
  }
  
  function temperature_check(){
    [[ -z $ini_T ]] && echo "Note: Press enter key to use the default temperature: 298.15 K" || echo "Note: Press enter key to use the default temperature interval: 5.00 K"
    local T
    read T
    while [[ ! $T =~ ^([1-9][0-9]*|[0])([.][0-9]+)?$ ]];do
      if [[ -z $T ]];then
        [[ -z $ini_T ]] && T=298.15 || T=5.00
    	break
      fi
      echo "Please input a non-negative real number:"
      read T
    done
	Temperature=$T
  }

  function integer_check(){
    echo "Note: Press enter key to use the default integer: 10"
    local integer
    read integer
    while [[ ! $integer =~ ^[1-9][0-9]*$ ]];do
	  if [[ -z $integer ]];then
        integer=10
    	break
      fi
      echo "Please input a positive integer:"
      read integer
    done
	Integer=$integer
  }
  
  function pressure_check(){
    echo "Note: Press enter key to use the default pressure: 1.00 atm"
    local P
    read P
    while [[ ! $P =~ ^([1-9][0-9]*|[0])([.][0-9]+)?$ ]];do
      if [[ -z $P ]];then
      P=1.00
	  break
    fi
    echo "Please input a non-negative real number:"
    read P
    done
    Pressure=$P
  }

  function sclZPE_check(){
    echo "Note: Press enter key to use the default sclZPE: 1.0000"
    local sclzpe
    read sclzpe
    while [[ ! $sclzpe =~ ^([1-9][0-9]*|[0])([.][0-9]+)?$ ]];do
      if [[ -z $sclzpe ]];then
        sclzpe=1.0000
    	break
      fi
      echo "Please input a non-negative real number:"
      read sclzpe
    done
    SclZPE=$sclzpe
  }  
  

echo "############  Calculate the ZPE, Gcorr, Hcorr, and Ucorr by using Shermo 2.3 tool  ############"
echo "~~ Note that output files of frequency task of Gaussian/ORCA/GAMESS-US/NWChem are supported ~~"
echo
echo "Please input the extention of output files [out/log]:"
read inp_extension
check_Shermo
T_scanning_chocie
low_freq_treatment

if [[ $shermo_scan_choice == "n" ]];then
  echo "Please input the temperature (K) at which the Gcorr, Hcorr, and Ucorr to be calculated:  ^o^"
  temperature_check
  temperature=$(echo "$Temperature" | awk '{printf "%.2f", $1}')
elif [[ $shermo_scan_choice == "y" ]];then
  echo "Please input the initial temperature (K): ^o^"
  temperature_check
  ini_T=$(echo "$Temperature" | awk '{printf "%.2f", $1}')
  echo "Please input the stepsize of temperature (K): ^o^"
  temperature_check
  stepsize_T=$(echo "$Temperature" | awk '{printf "%.2f", $1}')
  echo "Please input the total steps of temperature (K): ^o^"
  integer_check
  total_steps_T=$Integer
  final_T=$(echo "$ini_T $stepsize_T $total_steps_T" | awk '{printf "%.2f", $1 + $2 * $3}')
fi

echo "Please input the pressure: (atm):  ^o^"
pressure_check
pressure=$(echo "$Pressure" | awk '{printf "%.2f", $1}')

echo "Please input the scale factor of vibrational frequencies for ZPE (sclZPE):  ^o^"
sclZPE_check
sclZPE=$(echo "$SclZPE" | awk '{printf "%.4f", $1}')

initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo

if [[ $shermo_scan_choice == "n" ]];then
  printf "Press any key to start the calculation at %.2f K, %.2f atm, sclZPE= %.4f, ilowfreq= %s ... ^v^" $temperature $pressure $sclZPE $ilowfreq_treatment
  read -n 1
  printf "%-8s %-55s %-15s %-15s %-15s %-15s\n" "No." "Name @${temperature}K, ${pressure}atm, sclZPE= ${sclZPE}, ilowfreq= ${ilowfreq_treatment}" "Gcorr[au]" "Hcorr[au]" "Ucorr[au]" "ZPE[au]" > $initial_path/Calc_corr_Shermo_${temperature}K.txt
elif [[ $shermo_scan_choice == "y" ]];then
  printf "Press any key to start the calculation at %.2f atm, sclZPE= %.4f, ilowfreq= %s ... ^v^\n" $pressure $sclZPE $ilowfreq_treatment
  printf "where the temperature ranges from %.2f K to %.2f K with the interval of %.2f K (Total %d steps)... ^v^"  $ini_T $final_T $stepsize_T $total_steps_T
  read -n 1
fi

travel_dir         # Running travel_dir and Shermo_process functions
}



###################    file conversion script begins from the following lines    ################### 
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*                data extraction script made by Jianyong Yuan             *"
echo "*                         E-mail: 404283110@qq.com                        *"
echo "*                Version 0.5 (dev), Release date: 2022-July-05            *"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo
echo "               ************ Main Function Menu ************                "
echo "1 Extract single point energy (SPE) of DFT and HF from Gaussian16 output files"
echo "2 Extract zero-point energy (ZPE) and thermal correction to G, H, and U (Gcorr, Hcorr, and Ucorr)"
echo "  from Gaussian16 output files"
echo "3 Extract TDDFT information from Gaussian16 output files"
echo "4 Extract SPE from ORCA-5 output files"
echo "5 Extract ZPE, Gcorr, Hcorr, and Ucorr from ORCA-5 output files"
echo "6 Recalculate Gcorr, Hcorr, and Ucorr by using freqchk tool and Gaussian16 [*.fchk] files"
echo "7 Detect the status of Gaussian optimization outputs (imaginary frequency, opt/SCF convergency, etc.)"
echo "8 Extract SPE from xtb-6.3.3 output files"
echo "9 Calculate ZPE, Gcorr, Hcorr, and Ucorr by using Shermo 2.3"
array_mainchoice=(1 2 3 4 5 6 7 8 9 's')
read mainchoice
while ! echo "${array_mainchoice[@]}" | grep -wq "$mainchoice" ;do
  echo "Please reinput the function number..."
  read mainchoice
done
if [[ $mainchoice == 1 ]];then
  main_extr_sp_g16
elif [[ $mainchoice == 2 ]];then
  main_extr_thermal_g16
elif [[ $mainchoice == 3 ]];then
  main_extr_tddft_g16
elif [[ $mainchoice == 4 ]];then
  main_extr_sp_orca
elif [[ $mainchoice == 5 ]];then
  main_extr_thermal_orca
elif [[ $mainchoice == 6 ]];then
  main_freqchk
elif [[ $mainchoice == 7 ]];then
  main_opt_check
elif [[ $mainchoice == 8 ]];then
  main_extr_sp_xtb
elif [[ $mainchoice == 9 ]];then
  main_Shermo
elif [[ $mainchoice == 's' ]];then
  shermo_scan_choice='n'
  inp_extension='log'
  ilowfreq_treatment=0
  temperature=298.15
  pressure=1.00
  sclZPE=0.9888
  initial_path=$(pwd)
  nfiles=$(find -name "*.$inp_extension" | wc -l)
  printf "%-8s %-55s %-15s %-15s %-15s %-15s\n" "No." "Name @${temperature}K, ${pressure}atm, sclZPE= ${sclZPE}, ilowfreq= ${ilowfreq_treatment}" "Gcorr[au]" "Hcorr[au]" "Ucorr[au]" "ZPE[au]" > $initial_path/Calc_corr_Shermo_${temperature}K.txt
  travel_dir
  temperature=423.00
  printf "%-8s %-55s %-15s %-15s %-15s %-15s\n" "No." "Name @${temperature}K, ${pressure}atm, sclZPE= ${sclZPE}, ilowfreq= ${ilowfreq_treatment}" "Gcorr[au]" "Hcorr[au]" "Ucorr[au]" "ZPE[au]" > $initial_path/Calc_corr_Shermo_${temperature}K.txt
  travel_dir 
fi







