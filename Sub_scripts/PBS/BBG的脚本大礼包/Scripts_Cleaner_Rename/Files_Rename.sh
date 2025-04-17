#!/bin/bash
function travel_dir(){
initial_path=$(pwd)
file_counter=0
folder_counter=0
file_extension=xyz     # Set target extension
echo
echo Travelling all subdirectories in the path below to find all "*."$file_extension files:
echo $(pwd)
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
	  echo "[$serial] Renaming $file file..."
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
echo "###### Total $file_counter *.$file_extension files have been renamed ######"
echo
} 

function process(){
mv $file ${file/_opted/}   # change *_opted.xyz to *.xyz
echo "    ==> $file has been renamed to ${file/_opted/}!"
}

echo
echo "############  Running batch renaming script  ############"


travel_dir  # Running travel_dir and process functions


