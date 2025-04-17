#!/bin/bash
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
	  extr_imafreq
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
echo "######  Imafreq values in total $file_counter/$nfiles *.$inp_extension files have been successfully extracted  ######"
}

function extr_imafreq(){
if grep -wq "Normal termination of Gaussian" $file && grep -wq "1 imaginary frequencies (negative Signs)" $file;then  # Check whether *.out/*.log is made by Gaussian and meanwhile only 1 imaginary frequency is obtained
  Imafreq=$(grep -A9 "1 imaginary frequencies (negative Signs)" $file | awk 'END{printf $3}')
  printf "%-8s %-30s %-30s\n" $file_counter ${file%.$inp_extension} $Imafreq >> $initial_path/Extract_Imafreq_Gauss.txt
  echo "    ==> The only imaginary frequency value has been extracted from $file! [$file_counter of $nfiles]"
  echo "        No.$file_counter:    Name: ${file%.$inp_extension}     Imafreq= $Imafreq"  
else
  echo "    --> The $file file doesn't contain one imaginary frequency! Skipping..."
  printf "%-8s %-30s %-30s\n" "X" ${file%.$inp_extension} "N/A" >> $initial_path/Extract_Imafreq_Gauss.txt
  let file_counter--
fi  
}

echo
echo "************* Extract imaginary frequency values from Gaussian files **************"
echo
echo "Please input the extention of Gaussian16 output files [out/log]:"
read inp_extension
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
printf "%-8s %-30s %-30s\n" "No." "NAME" "Imafreq [cm-1]" > Extract_Imafreq_Gauss.txt
travel_dir



