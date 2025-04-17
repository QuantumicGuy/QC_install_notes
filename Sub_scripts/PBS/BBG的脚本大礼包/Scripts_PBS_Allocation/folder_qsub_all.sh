#!/bin/bash
function travel_dir(){
initial_path=$(pwd)
file_counter=0
folder_counter=0
file_extension=pbs     # Set target extension
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
	  echo "[$serial] Running $file file..."
	  let file_counter++
	  let serial++
	  process      # Processing files here
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
echo "###### Total $file_counter *.$file_extension files have been submitted ######"
echo
} 

function process(){
qsub < $file   # Submit PBS jobs
echo "    ==> $file has been submitted!"
}

echo
echo "############  Running PBS submitting batch script  ############"


travel_dir  # Running travel_dir and process functions








