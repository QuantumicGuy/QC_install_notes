#!/bin/bash
	usage=">>>>>>>>>>>>>>>> $(basename $0) <<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>      w.zhuang@msn.com       <<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>  First release: 2020-10-28  <<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>  Last update:   2020-10-29  <<<<<<<<<<<<<<<<
>>Usage: $0 [ -n nthreads | -s ompstacksize | -m  Multiwfnpath | -d dlname | -o ORCA_EXEDIR | -g GAUSS_EXEDIR | -r USERROOT | -c | -w | -h ]"

# Default values
[[ -d "${USERROOT}" ]] || USERROOT=${HOME}
dlflag=1
seflag=1
nbflag=0
mpflag=1
verflag=1
NUMPROC=$(($(grep -c processor /proc/cpuinfo)*3/8*2)); 
nthreads=$((NUMPROC<16 ? NUMPROC : 16))
NODE_MDEF=$(free | awk '/Mem:/{printf "%d", $4/1024}');
[[ -n "${NODE_MDEF}" && ${NODE_MDEF} =~ ^[0-9]+$ ]] && ompstacksize=$((NODE_MDEF*50/100 / 1000 * 100000000));
[[ ${ompstacksize} =~ ^[0-9]+$ ]] || ompstacksize=200000000 

# Read in input parameters
OPTIND=1
while getopts ":r:g:o:m:n:s:d:whc" opt; do
	case $opt in
		r) USERROOT="$OPTARG" ;;
		g) GAUSS_EXEDIR="$OPTARG" ;;
		o) ORCA_EXEDIR="$OPTARG" ;;
		m) Multiwfnpath="$OPTARG" ;;
		n) nthreads="$OPTARG" ;;
		s) ompstacksize="$OPTARG" ;;
		d) dlname="$OPTARG"; 			 
			if [[ $dlname -eq 1 ]]; then 
				version=$(wget -q -O - http://sobereva.com/multiwfn/download.html | grep Develop | sed "s/^.* version: \([0-9.]*\).*/\1/")
				dlname=Multiwfn_${version}_dev_bin_Linux.zip; 
			elif [[ $dlname -eq 2 ]]; then 
				dlname=Multiwfn_3.8_dev_bin_Linux.zip;
			elif echo $dlname | grep -qoP '^[0-9]+\.[0-9]+$'; then 
				dlname=Multiwfn_${dlname}_dev_bin_Linux.zip;			
			fi
			dlflag=0 ;;
		c) verflag=0 ;;        
		w) seflag=0 ;;        
		h) echo "$usage";
			aliasname="$(grep $(basename $0) ~/.bashrc | grep -o 'alias [^=]*' |grep -o '[^ ]*$')"
			if [[ -n "${aliasname}" ]]; then echo ">>Usage: Alternatively, use alias ${aliasname}" ; fi 
			exit 1 ;;
		\?) ((OPTIND--)); break ;;
	esac
done
shift $(($OPTIND - 1))

[[ -f "${Multiwfnpath}/Multiwfn" ]] || Multiwfnpath=$(dirname $(whereis -b Multiwfn | awk '{printf $2}') 2>/dev/null)
[[ -f "${Multiwfnpath}/Multiwfn" ]] || Multiwfnpath=$(dirname $(which Multiwfn 2>/dev/null) 2>/dev/null)
[[ -d "${Multiwfnpath}" ]] || Multiwfnpath=${USERROOT}/Multiwfn
[[ -d "${Multiwfnpath}" ]] || Multiwfnpath=$(dirname $(find ${USERROOT} -name "Multiwfn" -type f -exec ls -tr1 {} + | tail -1) 2>/dev/null)

if [[ $dlflag -eq 0 ]]; then
	wget --no-check-certificate http://sobereva.com/multiwfn/misc/${dlname%.*}.zip;
	wait
	if [[ -f "${Multiwfnpath}/Multiwfn" ]]; then 
		mv ${Multiwfnpath} ${Multiwfnpath}-old_$(date +%F -r ${Multiwfnpath}/Multiwfn)
        echo "Multiwfn version $(date +%F -r ${Multiwfnpath}/Multiwfn) has been backed up as ${Multiwfnpath##*/}-old_$(date +%F -r ${Multiwfnpath}/Multiwfn)"
	else
		Multiwfnpath=${USERROOT}/Multiwfn
	fi	
	unzip ${dlname%.*}.zip
	mv ${dlname%.*} ${Multiwfnpath}
    mv ${dlname%.*}.zip ${dlname%.*}_$(date +%F).zip
	echo "Multiwfn has been updated to the latest version from http://sobereva.com/multiwfn/misc/${dlname%.*}.zip"
fi

if [[ -f "$Multiwfnpath/Multiwfn" ]]; then
	echo "Executable Multiwfn  found in path: $Multiwfnpath";
	export PATH=$PATH:$Multiwfnpath
	chmod +x $Multiwfnpath/Multiwfn	
	export Multiwfnpath
	if [[ $verflag -eq 0 ]]; then 
		echo "Local Multiwfn version is: "
		Multiwfn < /dev/null 2> /dev/null | grep Version;
		echo "The latest Multiwfn version online is: "
		wget -q -O - http://sobereva.com/multiwfn/download.html | grep Develop | sed "s/^<h3>\(.*\)<.*/ \1/"
		exit
	fi
    if grep -q $(basename $0) ~/.bashrc; then nbflag=1; fi
    if grep -q Multiwfnpath ~/.bashrc; then mpflag=0; fi
    if [[ $seflag -eq 0 && $mpflag -eq 0 ]] || [[ $seflag -eq 0 && $nbflag -eq 0 && $mpflag -eq 1 ]]; then
        sed -i "/KMP_STACKSIZE/d"  ~/.bashrc
        sed -i "/Multiwfn/d"  ~/.bashrc
        sed -i "/$(basename $0)/d"  ~/.bashrc    
        echo "#-----Multiwfn_env.sh Start-----
    alias sob=\"bash $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")\"
    export KMP_STACKSIZE=${ompstacksize:-40000000000}    ; # Multiwfn Linux
    export Multiwfnpath=${USERROOT}/Multiwfn
    export PATH=\$PATH:\$Multiwfnpath
    alias mw=\"\$Multiwfnpath/Multiwfn\"
    chmod +x \$Multiwfnpath/Multiwfn
#-----Multiwfn_env.sh End-----" >> ~/.bashrc
        echo "~/.bashrc has been updated:"
		sed -n -e '/Multiwfn/,$p' ~/.bashrc
		echo "════════════════════════════════════════════════"
    elif [[ $nbflag -eq 0 && $mpflag -eq 1 ]]; then
        sed -i "/$(basename $0)/d"  ~/.bashrc    
        echo "alias sob=\"bash $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")\"" >> ~/.bashrc
        echo "~/.bashrc has been updated:"
        tail -1 ~/.bashrc
		echo "════════════════════════════════════════════════"
    elif [[ ! -f "$(grep -E $(basename $0) ~/.bashrc | grep -oP '(?<=sh ).*(?="$)')" && $nbflag -eq 1 ]]; then        
        sed -i "/KMP_STACKSIZE/d"  ~/.bashrc
        sed -i "/Multiwfn/d"  ~/.bashrc
        sed -i "/$(basename $0)/d"  ~/.bashrc    
        echo "alias sob=\"bash $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")\"" >> ~/.bashrc
        echo "~/.bashrc has been updated:"
        tail -1 ~/.bashrc
		echo "════════════════════════════════════════════════"
    elif [[ $seflag -eq 0 ]]; then
        echo "══════════════════ ~/.bashrc: ══════════════════"
		sed -n -e '/Multiwfn/,$p' ~/.bashrc
		echo "════════════════════════════════════════════════"
	fi
    echo    
else 
	echo Multiwfn not found! ;	exit 1;
fi

cd $Multiwfnpath
if [[ ! -f settings.ini && -f settings.ini.backup ]]; then 
	cp -a settings.ini.backup settings.ini;
elif [[ -f settings.ini && ! -f settings.ini.backup ]]; then 
	cp -a settings.ini settings.ini.backup; 
elif [[ ! -f settings.ini && ! -f settings.ini.backup ]]; then 
	echo File settings.ini not found. Pleasse check usage to provide via option -m or -r; exit 1;
fi
echo ' The following parameters in original settings.ini are:'
grep -E "nthreads=|ompstacksize=|isilent=|iloadGaugeom=|gaupath=|cubegenpath=|formchkpath=|orca_2mklpath=" settings.ini.backup | grep -oP '^.*(?=//)'
echo 
new="nthreads= ${nthreads:-16}  //"; old='nthreads= .*//'; sed -i "s~$old~$new~gi" settings.ini
new="ompstacksize= ${ompstacksize:-200000000}  //"; old='ompstacksize= .*//'; sed -i "s~$old~$new~gi" settings.ini
new='isilent= 1  //'; old='isilent= .*//'; sed -i "s~$old~$new~gi" settings.ini

[[ -z "${GAUSS_EXEDIR}" ]] || gaupath=${GAUSS_EXEDIR##*:}/${GAUSS_EXEDIR##*/}
[[ -f "${gaupath}" ]] || gaupath=$(whereis -b g16 | awk '{printf $2}' 2>/dev/null)
[[ -f "${gaupath}" ]] || gaupath=$(whereis -b g09 | awk '{printf $2}' 2>/dev/null)
[[ -f "${gaupath}" ]] || gaupath=$(which g16 2>/dev/null)
[[ -f "${gaupath}" ]] || gaupath=$(which g09 2>/dev/null)
[[ -f "${gaupath}" ]] || gaupath=$(find ${USERROOT} -name "g16" -type f -exec ls -tr1 {} + 2>/dev/null | tail -1)
[[ -f "${gaupath}" ]] || gaupath=$(find ${USERROOT} -name "g09" -type f -exec ls -tr1 {} + 2>/dev/null | tail -1)
if [[ -f "${gaupath}" ]]; then
	echo "Executable ${gaupath##*/}       found in path: ${gaupath%/*}";
	cubegenpath="${gaupath%/*}/cubegen"
	formchkpath="${gaupath%/*}/formchk"
	new='iloadGaugeom= 1  //'; old='iloadGaugeom= .*//'; sed -i "s~$old~$new~gi" settings.ini
	new='gaupath= '\""${gaupath}"\"'  //'; old='gaupath= .*//'; sed -i "s~$old~$new~gi" settings.ini
	new='cubegenpath= '\""${cubegenpath}"\"'  //'; old='cubegenpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
	new='formchkpath= '\""${formchkpath}"\"'  //'; old='formchkpath= .*//'; sed -i "s~$old~$new~gi" settings.ini    
else 
	echo GAUSSIAN not found! Pleasse check usage to provide via option -g or -r;	exit 1;
fi

[[ -f "${ORCA_EXEDIR}/orca_2mkl" ]] || ORCA_EXEDIR=$(dirname $(whereis -b orca_2mkl | awk '{printf $2}') 2>/dev/null)
[[ -f "${ORCA_EXEDIR}/orca_2mkl" ]] || ORCA_EXEDIR=$(dirname $(which orca_2mkl 2>/dev/null) 2>/dev/null)
[[ -f "${ORCA_EXEDIR}/orca_2mkl" ]] || ORCA_EXEDIR=${USERROOT}/orca
[[ -f "${ORCA_EXEDIR}/orca_2mkl" ]] || ORCA_EXEDIR=$(dirname $(find ${USERROOT} -name "orca" -type f -exec ls -tr1 {} + | tail -1) 2>/dev/null)
if [[ -f "${ORCA_EXEDIR}/orca_2mkl" ]]; then
	echo "Executable orca_2mkl found in path: $ORCA_EXEDIR";
	orca_2mklpath="${ORCA_EXEDIR}/orca_2mkl";
	new='orca_2mklpath= '\""${orca_2mklpath}"\"'  //'; old='orca_2mklpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
else 
	echo orca_2mkl not found!  Pleasse check usage to provide via option -o or -r;	exit 1;
fi

echo -e "\n\t****:-) HURRAY! settings.ini updated NORMALLY****\n"
echo ' Make sure all the parameters are set properly.'
echo ' These parameters in updated settings.ini are:'
grep -E "nthreads=|ompstacksize=|isilent=|iloadGaugeom=|gaupath=|cubegenpath=|formchkpath=|orca_2mklpath=" settings.ini | grep -oP '^.*(?=//)'
cd - >/dev/null 2>&1
