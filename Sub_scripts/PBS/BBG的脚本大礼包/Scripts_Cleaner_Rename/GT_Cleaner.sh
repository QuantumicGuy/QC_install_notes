#!/bin/bash

# Check environment variables for Gaussian 
function check_env_var(){
	echo "Checking the environment variable for Gaussian scratch directory ..."
	sleep 0.5
	if [[ -z $GAUSS_SCRDIR ]];then
		echo "<\$GAUSS_SCRDIR> is not found, please set it first!"
		exit 1
	else
	    echo "The Gaussian temporary files are saved in:"
		echo "$GAUSS_SCRDIR"
		echo
		sleep 0.5
	fi
}

# Check and delete the temporary files which are currently not being used 
function tmp_cleaner(){
    cd $GAUSS_SCRDIR
	if [[ ! $(ls) ]];then
		echo "##  The scratch directory is already empty!  ##"
		exit 1
	fi
	for files in $(ls);do
		array_filename[${#array_filename[@]}]=${files%.*}
	    #echo ${files}
		#echo ${array_filename[@]} | grep -wq ${files%.*}
	    #if [[ $? == 1 ]];then
		#	array_filename[${#array_filename[@]}]=${files%.*}
		#fi
	done
	array_filename=($(awk -v RS=' ' '!a[$1]++' <<< ${array_filename[@]}))
	#echo ${array_filename[@]}
	task_count=${#array_filename[@]}
	remove_count=0
	read -p "There are total $task_count Gaussian jobs, press any key to remove the idle ones ..."
	echo
	sleep 0.5
	
	for filename in $(echo ${array_filename[@]});do
		PID=${filename:4}
		ProcNumber=$(ps -e |grep -w $PID |wc -l)
		if [[ $ProcNumber == 0 ]];then
			echo "-> Gau-${PID}.* files are NOT being used now! Removing them ..."
			rm -rf Gau-${PID}.*
			let remove_count++
		else
			echo "=> Gau-${PID}.* files are currently being used! Skipping ..."
		fi
	done
	sleep 0.5
	echo
	echo "#####  Total $remove_count/$task_count jobs have been safely removed  ####"
}


###################   the cleaner begins from the following lines    ################### 
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*      cleaner for Gaussian temporary files made by Jianyong Yuan         *"
echo "*                         E-mail: 404283110@qq.com                        *"
echo "*                Version 1.1 (dev), Release date: 2021-Feb-8              *"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo
echo "Press any key to start the cleaner script... ^v^"
read -n 1
check_env_var
tmp_cleaner

