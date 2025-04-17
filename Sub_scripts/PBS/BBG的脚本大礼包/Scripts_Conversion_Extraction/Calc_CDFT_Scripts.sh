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
	nfiles_cur_dir=$(find -name "*.$inp_extension" | wc -l)
	if [[ $nfiles_cur_dir == 3 ]];then
	  neutral_filepath=""
	  anion_filepath=""
	  cation_filepath=""
	  for file in *.$inp_extension;do
		if [[ $file =~ .*"N+1."$inp_extension ]];then
		  anion_filepath=$(pwd)"/"$file
		elif [[ $file =~ .*"N-1."$inp_extension ]];then
		  cation_filepath=$(pwd)"/"$file
		else
		  neutral_filepath=$(pwd)"/"$file
		fi
	  done
	  
	  if [[ $anion_filepath != "" && $cation_filepath != "" && $neutral_filepath != "" ]];then
	    let file_counter+=3
	    let serial++
		printf "[system %4d] Found N   labeled file: %s ...\n" $serial ${neutral_filepath/$(pwd)'/'/}
	    printf "[system %4d] Found N+1 labeled file: %s ...\n" $serial ${anion_filepath/$(pwd)'/'/}
		printf "[system %4d] Found N-1 labeled file: %s ...\n" $serial ${cation_filepath/$(pwd)'/'/}
	    Calc_CDFT_indices
	  else
	    echo "    Error: The 3 files could not match with N, N+1, N-1 labels, skipping..."
	  fi
	else
	  echo "    Warning: The number of *.$inp_extension files is not equal to 3, skipping..."
	fi
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

function Calc_CDFT_indices(){               
Multiwfn $neutral_filepath  << EOF &> /dev/null
22
2
$neutral_filepath
$anion_filepath
$cation_filepath
0
q
EOF
if [[ $? -eq 0 ]];then
  neutral_filename=${neutral_filepath/$(pwd)'/'/}
  output_name=CDFT_${neutral_filename/%$inp_extension/txt}
  mv CDFT.txt $output_name
  printf "[system %4d] ==> Various CDFT indices have been generated and saved as the %s file!\n" $serial $output_name
  printf "[system %4d] ==> Currently, %d of %d *.%s files haved been processed successfully.\n" $serial $file_counter $nfiles $inp_extension
else
  echo "    --> Failed to generate CDFT indices! Skipping..."
  let serial--
  let file_counter-=3
fi
}

###################    the script begins from the following lines    ################### 
echo "************* Calculate various quantitative indices based on CDFT by Multiwfn **************"
echo "Please input the extension of the formatted Gaussian check-point files: [fchk/fch]"
read inp_extension
echo 
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)

printf "Press any key to start to calculate various quantitative indices based on CDFT by using [*.$inp_extension] files... ^v^"
read -n 1
check_Multiwfn
travel_dir


















