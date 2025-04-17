#!/bin/bash
function travel_dir(){
file_counter=0
folder_counter=0
echo
echo Travelling all subdirectories in the path below to find all "*."$file_extension files:
echo $(pwd)
for dir in $(ls -R | grep :| tr : " ");do
  cd $dir
  if ls *.$file_extension 1> /dev/null 2>&1;then
    serial=1
    let folder_counter++
	echo
    echo "*** No.$folder_counter folder *** >>> Entered" $dir
	echo "      V V V V"
	for file in *.$file_extension;do
	  let file_counter++
	  let serial++
	  echo "[$serial] Loading $file file... [$file_counter of $nfiles]"
	  process      # Processing files here
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
echo "###### Total $file_counter *.$file_extension files have been processed ######"
echo
} 

function process(){
input_filename=${file%.pkl}
template_file_full_path=$initial_path"/"$template_file
sed -i -r "s/^input_filename =(.*)\#(.*)/input_filename = '$input_filename' \#\2/" $template_file_full_path
sed -i -r "s/^ML_type =(.*)\#(.*)/ML_type = '$ML_type' \#\2/" $template_file_full_path

python3 $template_file_full_path > ${file/%pkl/log}

if grep -wq "Scikit-learn predictions (finding max/min Y)" ${file/%pkl/log};then

  y_max=$(grep -A1 "Maximum of the predictions (y_max)" ${file/%pkl/log} | awk 'END{printf $0}')
  y_min=$(grep -A1 "Minimum of the predictions (y_min)" ${file/%pkl/log} | awk 'END{printf $0}')
  X_max=$(grep -A1 "Features (X) at the y_max" ${file/%pkl/log} | awk 'END{printf $0}'| tr -s " ")
  X_min=$(grep -A1 "Features (X) at the y_min" ${file/%pkl/log} | awk 'END{printf $0}'| tr -s " ")
  
  printf "%-8s %-20s %15s %45s %15s %45s\n" $file_counter ${file%.$file_extension} $y_max "$X_max" $y_min "$X_min" >> $initial_path/Extract_sklearn_predictions_find_best.txt
  echo "    ==> $file has been processed!"
  echo "        No.$file_counter:    Name: ${file%.$file_extension}     "
  echo "        y_max= $y_max          X_max= $X_max                    "
  echo "        y_min= $y_min          X_min= $X_min                    "
else
  echo "    --> The $file file doesn't contain scikit-learn predictions! Skipping..."
  printf "%-8s %-20s %15s %45s %15s %45s\n" "X" ${file%.$file_extension} "N/A" "N/A" "N/A" "N/A" >> $initial_path/Extract_sklearn_predictions_find_best.txt
  let file_counter--
fi
}

###############  The ML prediction script starts from here  ###############
file_extension="pkl"     # the *.pkl file to be load as target model
template_file="ML_predictions_max_min.py"
ML_type="Regression"

echo
echo "############  Running scikit-learn prediction (*.pkl) batch script  ############"
initial_path=$(pwd)
nfiles=$(find -name "*.$file_extension" | wc -l)
  
if [[ -f $template_file ]];then            # Check whether the template file exists or not
  if ! command -v dos2unix >/dev/null 2>&1;then
    echo ">>> Warning: <dos2unix> tool is required but it has not installed yet. Aborting... <<<"
    exit 1
  fi
  dos2unix -q $template_file
  echo
  echo "Press any key to perform predictions based on the $template_file and *.pkl... ^v^"
  read -n 1
  printf "%-8s %-20s %15s %45s %15s %45s\n" "No." "Name" "y_max" "X_max" "y_min" "X_min" > Extract_sklearn_predictions_find_best.txt
  travel_dir           # Run travel_dir and process functions
else
  echo
  echo "$template_file is not found in:"
  echo "$initial_path"
  echo
  echo "Please recheck the $template_file template file!!"
  exit 1
fi











