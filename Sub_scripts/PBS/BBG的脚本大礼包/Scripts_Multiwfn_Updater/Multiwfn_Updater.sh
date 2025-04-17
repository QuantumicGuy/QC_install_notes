#!/bin/bash

# Check environment variables for Linux
function check_env_var1(){
	echo "Checking necessary environment variables for Multiwfn ..."
	sleep 0.5
    Multiwfnpath=$(which Multiwfn 2>/dev/null)
	if [[ -z $Multiwfnpath ]];then
		echo "<Multiwfn> is not found, please recheck whether its environment variable is correctly set or not!"
		exit 1
	fi
	
	gaupath=$(which g16 2>/dev/null)
	if [[ -z $gaupath ]];then
		gaupath=$(which g09 2>/dev/null)
		if [[ -z $gaupath ]];then
			echo "Neither <g16> nor <g09> is not found, please recheck whether its environment variable is correctly set or not!"
			exit 1
		fi
	fi
	
    cubegenpath=$(which cubegen 2>/dev/null)
	if [[ -z $cubegenpath ]];then
		echo "<cubegen> is not found, please recheck whether its environment variable is correctly set or not!"
		exit 1
	fi
	
    formchkpath=$(which formchk 2>/dev/null)
	if [[ -z $formchkpath ]];then
		echo "<formchk> is not found, please recheck whether its environment variable is correctly set or not!"
		exit 1
	fi
	
	orca_2mklpath=$(which orca_2mkl 2>/dev/null)
	if [[ -z $orca_2mklpath ]];then
		echo "Warning: <orca_2mkl> is not found! Skipping its environment variable..."
		echo
	fi
	
	echo "--------------- Environment Variable Information in Linux ---------------"
	echo "> Multiwfnpath= $Multiwfnpath"
	echo "> gaupath= $gaupath"
	echo "> cubegenpath= $cubegenpath"
	echo "> formchkpath= $formchkpath"
	echo "> orca_2mklpath= $orca_2mklpath"
	echo "-------------------------------------------------------------------------"
	echo
}

# Check environment variables for Windows
function check_env_var2(){
	echo "Checking necessary environment variables for Multiwfn ..."
	sleep 0.5
    Multiwfnpath=$(which Multiwfn.exe 2>/dev/null)
	if [[ -z $Multiwfnpath ]];then
		echo "<Multiwfn.exe> is not found, please recheck whether its environment variable is correctly set or not!"
		exit 1
	fi
	
	gaupath=$(which g16.exe 2>/dev/null)
	if [[ -z $gaupath ]];then
		gaupath=$(which g09.exe 2>/dev/null)
		if [[ -z $gaupath ]];then
			echo "Neither <g16.exe> nor <g09.exe> is not found, please recheck whether its environment variable is correctly set or not!"
			exit 1
		fi
	fi
	
    cubegenpath=$(which cubegen.exe 2>/dev/null)
	if [[ -z $cubegenpath ]];then
		echo "<cubegen.exe> is not found, please recheck whether its environment variable is correctly set or not!"
		exit 1
	fi
	
    formchkpath=$(which formchk.exe 2>/dev/null)
	if [[ -z $formchkpath ]];then
		echo "<formchk.exe> is not found, please recheck whether its environment variable is correctly set or not!"
		exit 1
	fi
	
	orca_2mklpath=$(which orca_2mkl.exe 2>/dev/null)
	if [[ -z $orca_2mklpath ]];then
		echo "Warning: <orca_2mkl.exe> is not found! Skipping its environment variable..."
		echo
	fi
	
	echo "--------------- Environment Variable Information in WSL ---------------"
	echo "> Multiwfnpath= $Multiwfnpath"
	echo "> gaupath= $gaupath"
	echo "> cubegenpath= $cubegenpath"
	echo "> formchkpath= $formchkpath"
	echo "> orca_2mklpath= $orca_2mklpath"
	
	Multiwfnpath_win=$(echo ${Multiwfnpath:5} | sed -e 's#[a-z]#\u&:#' -e 's#/#\\#g')
	gaupath_win=$(echo ${gaupath:5} | sed -e 's#[a-z]#\u&:#' -e 's#/#\\#g')
	cubegenpath_win=$(echo ${cubegenpath:5} | sed -e 's#[a-z]#\u&:#' -e 's#/#\\#g')
	formchkpath_win=$(echo ${formchkpath:5} | sed -e 's#[a-z]#\u&:#' -e 's#/#\\#g')
	orca_2mklpath_win=$(echo ${orca_2mklpath:5} | sed -e 's#[a-z]#\u&:#' -e 's#/#\\#g')
	
	# Set environment variables manually for Windows
	gaupath_win="D:\Program Files (x86)\Gaussian\G09W\g09.exe"
	cubegenpath_win="D:\Gaussian16_Linux\g16\cubegen.exe"
	formchkpath_win="D:\Gaussian16_Linux\g16\formchk.exe"
	orca_2mklpath_win="D:\ORCA_Linux\orca-4.2.1\orca_2mkl.exe"
	
	echo
	echo "------------- Environment Variable Information in Windows -------------"
	echo "> Multiwfnpath_win= $Multiwfnpath_win"
	echo "> gaupath= $gaupath_win"
	echo "> cubegenpath_win= $cubegenpath_win"
	echo "> formchkpath_win= $formchkpath_win"
	echo "> orca_2mklpath_win= $orca_2mklpath_win"
	echo "-----------------------------------------------------------------------"
	echo
}

# Check unrar tool
function check_unrar(){
	which unrar 1> /dev/null 2>&1
	if [[ $? -ne 0 ]];then
		echo "<unrar> command is not found, please check whether it has been installed or not!"
		echo "P.s. You can use 'sudo apt install unrar' to install it ^~^"
		exit 1
	fi
}

# Check unzip tool
function check_unzip(){
	which unzip 1> /dev/null 2>&1
	if [[ $? -ne 0 ]];then
		echo "<unzip> command is not found, please check whether it has been installed or not!"
		echo "P.s. You can use 'sudo apt install unzip' to install it ^~^"
		exit 1
	fi
}

# Check local version of Multiwfn 
function check_local_version(){
	if [[ $mainchoice == 1 ]];then
		Multiwfn < /dev/null 2>&1 |  grep "Version" | awk '{printf("%s%s",$2,$5)}' > tmpfile1
	elif [[ $mainchoice == 2 ]];then
		Multiwfn.exe < /dev/null 2>&1 |  grep "Version" | awk '{printf("%s%s",$2,$5)}' > tmpfile1
		sed -i "s/\r//" tmpfile1
	fi
	version=$(awk -F "," '{printf("%s",$1)}' tmpfile1)
	release_date=$(awk -F "," '{printf("%s",$2)}' tmpfile1)
	printf "=> Local version of Multiwfn:  %20s  %s\n" $version $release_date
	rm tmpfile1
}

# Check the latest version of Multiwfn 
function check_online_version(){
	curl -s http://sobereva.com/multiwfn/download.html | grep "Develop" | sed -e "s/　/ /g" -e "s/<\/h3>/ /g" | awk '{printf("%s %s", $3, $6)}' > tmpfile2
	version_ol=$(awk '{printf("%s",$1)}' tmpfile2)
	release_date_ol=$(awk '{printf("%s",$2)}' tmpfile2)	
	printf "=> Latest online version of Multiwfn:  %12s  %s\n" $version_ol $release_date_ol
	rm tmpfile2
}

# Download the latest version of Multiwfn
function download_latest_online_version(){
	if [[ $mainchoice == 1 ]];then
		dlname=Multiwfn_${version_ol%(dev)}_dev_bin_Linux.zip
	elif [[ $mainchoice == 2 ]];then
		dlname=Multiwfn_${version_ol%(dev)}_dev_bin_Win64.rar
	fi	
	echo
	wget --no-check-certificate http://sobereva.com/multiwfn/misc/${dlname};
}

# Download the latest manual of Multiwfn
function download_latest_manual(){
	flag=0
	curl -s http://sobereva.com/multiwfn/download.html | grep "Develop" | sed -e "s/　/ /g" -e "s/<\/h3>/ /g" | awk '{printf("%s %s", $3, $6)}' > tmpfile2
	version_ol=$(awk '{printf("%s",$1)}' tmpfile2)	
	printf "=> Latest online manual of Multiwfn:  %12s\n" $version_ol
	rm tmpfile2
	Multiwfnpath1=$(which Multiwfn 2>/dev/null)
	Multiwfnpath2=$(which Multiwfn.exe 2>/dev/null)
	if [[ -z $Multiwfnpath1 && -z $Multiwfnpath2 ]];then
		echo "Neither <Multiwfn> nor <Multiwfn.exe> is not found, please recheck whether its environment variable is correctly set or not!"
		exit 1
	elif [[ -n $Multiwfnpath1 && -z $Multiwfnpath2 ]];then
		Multiwfnpath=$Multiwfnpath1
		flag=1
	elif [[ -z $Multiwfnpath1 && -n $Multiwfnpath2 ]];then
		Multiwfnpath=$Multiwfnpath2
		flag=1
	elif [[ -n $Multiwfnpath1 && -n $Multiwfnpath2 ]];then
		flag=2
	fi
	dlname=Multiwfn_${version_ol%(dev)}_dev.pdf	
	echo
	wget --no-check-certificate http://sobereva.com/multiwfn/misc/${dlname};
	echo
	if [[ $flag == 1 ]];then
		Multiwfnfolder=$(dirname "${Multiwfnpath}")
		/bin/cp -rf $dlname "${Multiwfnfolder}"
		echo "=> $dlname has been copied to ${Multiwfnfolder}"
	elif [[ $flag == 2 ]];then
		Multiwfnfolder1=$(dirname "${Multiwfnpath1}")
		/bin/cp -rf $dlname "${Multiwfnfolder1}"
		Multiwfnfolder2=$(dirname "${Multiwfnpath2}")
		/bin/cp -rf $dlname "${Multiwfnfolder2}"
		echo "=> $dlname has been copied to:"
		echo "(1)Linux:    ${Multiwfnfolder1}"
		echo "(2)Windows:  ${Multiwfnfolder2}"
	fi
	echo
	echo "Note: The original $dlname is saved to the $initial_path"
	echo "Whether to delete it or not? [Y/N]"
	array_choice=("Y" "N" "y" "n")
	read choice
	while ! echo "${array_choice[@]}" | grep -wq "$choice" 
	do
		echo "Please reinput your choice: [Y/N]"
		read choice
	done
	if [[ $choice == "N" || $choice == "n" ]];then
		exit 1
	elif [[ $choice == "Y" || $choice == "y" ]];then
		rm -rf $dlname
	fi
}

# Install the latest Multiwfn and back up the old one
function install_backup(){
	Multiwfnfolder=$(dirname "${Multiwfnpath}")
	mv "$Multiwfnfolder" "${Multiwfnfolder}-old_${release_date}"
	echo
    echo "Local version ${Multiwfnfolder##*/}                 has been backed up as:"
	echo "          --> ${Multiwfnfolder##*/}-old_${release_date}"
	mv $dlname "${Multiwfnfolder%/*}"
	cd "${Multiwfnfolder%/*}"
	echo
	echo "Extracting ${dlname} ..."
	if [[ $mainchoice == 1 ]];then
		unzip -q $dlname
	elif [[ $mainchoice == 2 ]];then
		unrar x -idq $dlname
	fi	
	echo "=> Multiwfn has been updated to the latest version ${version_ol} ${release_date_ol}"
	echo
	rm $dlname
}

# Update the settings.ini of Multiwfn for Windows
function update_settings(){
	# NUMPROC=$(($(grep -c processor /proc/cpuinfo)*3/8*2))
	# nthreads=$((NUMPROC<16 ? NUMPROC : 16))
	nCPU=$(cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l)
	nCore=$(cat /proc/cpuinfo| grep "cpu cores"| uniq |awk END'{print($4)}')
	tot_phys_core=$(($nCPU * $nCore))
	nthreads=$tot_phys_core
	NODE_MDEF=$(free | awk '/Mem:/{printf "%d", $4/1024}')
	[[ -n "${NODE_MDEF}" && ${NODE_MDEF} =~ ^[0-9]+$ ]] && ompstacksize=$((NODE_MDEF*50/100 / 1000 * 100000000))
	[[ ${ompstacksize} =~ ^[0-9]+$ ]] || ompstacksize=200000000
	
	cd ${dlname%.*}
	if [[ $mainchoice == 1 ]];then
		chmod +x Multiwfn
	elif [[ $mainchoice == 2 ]];then
		chmod +x Multiwfn.exe
	fi
	cp -a settings.ini settings.ini.backup
	
	echo "------------- parameters in the original settings.ini -------------"
	if [[ $mainchoice == 1 ]];then
		grep -E "nthreads=|ompstacksize=|isilent=|iloadGaugeom=|gaupath=|cubegenpath=|formchkpath=|orca_2mklpath=" settings.ini.backup | grep -oP '^.*(?=//)'
		new="nthreads= ${nthreads:-16}  //"; old='nthreads= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new="ompstacksize= ${ompstacksize:-200000000}  //"; old='ompstacksize= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new='isilent= 1  //'; old='isilent= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new='iloadGaugeom= 1  //'; old='iloadGaugeom= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new='gaupath= '\""${gaupath}"\"'  //'; old='gaupath= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new='cubegenpath= '\""${cubegenpath}"\"'  //'; old='cubegenpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new='formchkpath= '\""${formchkpath}"\"'  //'; old='formchkpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new='orca_2mklpath= '\""${orca_2mklpath}"\"'  //'; old='orca_2mklpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
	elif [[ $mainchoice == 2 ]];then
		grep -E "nthreads=|ompstacksize=|imodlayout=|iloadGaugeom=|gaupath=|cubegenpath=|formchkpath=|orca_2mklpath=" settings.ini.backup | grep -oP '^.*(?=//)'
		new="nthreads= ${nthreads:-16}  //"; old='nthreads= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new="ompstacksize= ${ompstacksize:-200000000}  //"; old='ompstacksize= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new='imodlayout= 1  //'; old='imodlayout= .*//'; sed -i "s~$old~$new~gi" settings.ini
		new='iloadGaugeom= 1  //'; old='iloadGaugeom= .*//'; sed -i "s~$old~$new~gi" settings.ini
		gaupath_win=$(echo $gaupath_win | sed 's#\\#\\\\#g')
		new='gaupath= '\""${gaupath_win}"\"'  //'; old='gaupath= .*//'; sed -i "s~$old~$new~gi" settings.ini
		cubegenpath_win=$(echo $cubegenpath_win | sed 's#\\#\\\\#g')
		new='cubegenpath= '\""${cubegenpath_win}"\"'  //'; old='cubegenpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
		formchkpath_win=$(echo $formchkpath_win | sed 's#\\#\\\\#g')
		new='formchkpath= '\""${formchkpath_win}"\"'  //'; old='formchkpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
		orca_2mklpath_win=$(echo $orca_2mklpath_win | sed 's#\\#\\\\#g')
		new='orca_2mklpath= '\""${orca_2mklpath_win}"\"'  //'; old='orca_2mklpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
	fi	
	echo "-------------------------------------------------------------------"
	echo
	echo "=> The settings.ini of Multiwfn has been updated!"
	echo
	echo "------------- parameters in the updated settings.ini -------------"
	if [[ $mainchoice == 1 ]];then
		grep -E "nthreads=|ompstacksize=|isilent=|iloadGaugeom=|gaupath=|cubegenpath=|formchkpath=|orca_2mklpath=" settings.ini | grep -oP '^.*(?=//)'
	elif [[ $mainchoice == 2 ]];then
		grep -E "nthreads=|ompstacksize=|imodlayout=|iloadGaugeom=|gaupath=|cubegenpath=|formchkpath=|orca_2mklpath=" settings.ini | grep -oP '^.*(?=//)'
	fi
	echo "------------------------------------------------------------------"
	cd $initial_path
}

# Compare the local version with the latest online one
function compare_versions(){
	echo
	if [[ ${version} == ${version_ol} && ${release_date} == ${release_date_ol} ]];then
		echo "The local version of Multiwfn is already the latest one, continue to update? [Y/N]"
		array_choice=("Y" "N" "y" "n")
		read choice
		while ! echo "${array_choice[@]}" | grep -wq "$choice" 
		do
			echo "Please reinput your choice: [Y/N]"
			read choice
		done
		if [[ $choice == "N" || $choice == "n" ]];then
			exit 1
		fi
	else
		echo "~~ New verison of Multiwfn ${version_ol} released at ${release_date_ol} is found! ~~"
		echo
		echo "Press any key to update ... ^0^"
		read -n 1
	fi
}


###################    Multiwfn.exe updater script begins from the following lines    ################### 
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "*                                 Multiwfn Updater                                  *"
echo "*                               Author: Jianyong Yuan                               *"
echo "*                              E-mail: 404283110@qq.com                             *"
echo "*                     version 1.1 (dev), release date: 2020-Oct-31                  *"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo
echo "               ************ Main function menu ************                "
echo "1 Check and update the Linux version of Multiwfn"
echo "2 Check and update the Windows version of Multiwfn on the WSL platform"
echo "3 Download the manual of Multiwfn to the Multiwfnpath"
echo
initial_path=$(pwd)
array_mainchoice=(1 2 3)
read mainchoice
while ! echo "${array_mainchoice[@]}" | grep -wq "$mainchoice" 
do
  echo "Please reinput function number..."
  read mainchoice
done
if [[ $mainchoice == 1 ]];then
	echo 
	echo "Press any key to update the Linux version of Multiwfn ... ^v^"
	read -n 1
	check_env_var1
	check_unzip
	check_local_version
	check_online_version
	compare_versions
	download_latest_online_version
	install_backup
	update_settings
elif [[ $mainchoice == 2 ]];then
	echo 
	echo "Press any key to update the Windows version of Multiwfn on the WSL platform... ^v^"
	read -n 1
	check_env_var2
	check_unrar
	check_local_version
	check_online_version
	compare_versions
	download_latest_online_version
	install_backup
	update_settings
elif [[ $mainchoice == 3 ]];then
	echo 
	echo "Press any key to download the manual of Multiwfn to the Multiwfnpath ... ^v^"
	read -n 1
	download_latest_manual
fi


