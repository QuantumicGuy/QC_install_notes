#!/bin/bash
	usage=">>>>>>>>>>>>>>>> $(basename $0) <<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>Multiwfn Update Assistant 2.0<<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>      w.zhuang@msn.com       <<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>  First release: 2020-10-28  <<<<<<<<<<<<<<<<
>>>>>>>>>>>>>>>>  Last update:   2020-11-01  <<<<<<<<<<<<<<<<
>>>>> Web: http://bbs.keinsci.com/thread-20052-1-1.html <<<<<
>>Usage: options: [ -n nthreads | -s ompstacksize | -m  Multiwfnpath | -d dlname | -o ORCA_EXEDIR | -g GAUSS_EXEDIR | -r USERROOT | -S OperatingSystem | -Z UnZipCommand  | -M  | -l  | -U | -c | -w | -h ]
>>Usage: bash $0 [ options ]
>>Usage: mua [ options ]
>>Usage: mua
>>Usage: mua -c
>>Usage: mua -d1
>>Usage: mua -w
>>Usage: mua -Sl
>>Usage: mua -Sw
>>Usage: mua -M
>>Usage: mua -U
>>Usage: mua -L
>>Usage: The fist time you use, you can execute the following three command lines 
>>    to get the latest script and download latest version of Multiwfn.
>>    After sourcing the .bashrc file or relogin you will be using alias mua instead  
>>    as shown in usage. Note if the link does not work, replace it with the updated 
>>    web address of $(basename $0) before rerun or download the script manually."'
>>Usage: cd <path-to-MUA>
>>Usage: bash ./MUA -d1 -w
>>Usage: source ~/.bashrc
>>Bugs are welcome to be reported on the abovementioned BBS.'
 
# Default values
# ##############################################################
# These default values can be set manually for convenience, 
# otherwise $(basename $0) will set them for you.
# 
# UNZIPEXE="unzip"
# UNZIPEXE="/drives/C/Program Files/7-Zip/7z.exe"
UNZIPEXE="C:\Program Files\7-Zip\7z.exe"
UNZIPEXEOPT="x"
MULTIWFN_PATH_DEFAULT='F:\xHOME\Multiwfn_3.8_dev_bin_Win64'
ORCA_EXEDIR_DEFAULT='F:\Programs\orca'
GAU_PATH_DEFAULT='C:\G16W\g16.exe'
# ##############################################################

isys=1 # 1 for Linux and 0 for Windows
if echo $PATH | grep -q WINDOWS; then 
    isys=0;
    UNZIPEXE="C:/Program Files/7-Zip/7z.exe"
    # UNZIPEXEOPT="x"
fi
if [[ $isys -eq 1 ]]; then UNZIPEXE="unzip"; UNZIPEXEOPT=""; fi

[[ -d "${USERROOT}" ]] || USERROOT=${HOME}
StoreDir=${USERROOT}/Software
[[ -d "${StoreDir}" ]] || mkdir -p ${StoreDir}

EXE=""; dlname="" ; manual=""
dlflag=1 ; seflag=1; nbflag=0 ; mpflag=1; verflag=1; umflag=1; uninstall=1; resources=1

NUMPROC=$(($(grep -c processor /proc/cpuinfo)*3/8*2)); 
nthreads=$((NUMPROC<16 ? NUMPROC : 16))
NODE_MDEF=$(free -m | awk '/Mem:/{printf "%d", $4}');
[[ -n "${NODE_MDEF}" && ${NODE_MDEF} =~ ^[0-9]+$ ]] && ompstacksize=$((NODE_MDEF*50/100 / 1000 * 100000000));
[[ ${ompstacksize} =~ ^[0-9]+$ ]] || ompstacksize=200000000 

# Read in input parameters
OPTIND=1
while getopts ":r:g:o:m:n:s:S:d:Z:whcUMlL" opt; do
	case $opt in
		r) USERROOT="$OPTARG" ;;
		g) GAUSS_EXEDIR="$OPTARG" ;;
		o) ORCA_EXEDIR="$OPTARG" ;;
		m) Multiwfnpath="$OPTARG" ;;
		n) nthreads="$OPTARG" ;;
		s) ompstacksize="$OPTARG" ;;
		d) dlname="$OPTARG"; 
			if [[ $dlname == '1' ]]; then 
				version=$(wget -q -O - http://sobereva.com/multiwfn/download.html | grep Develop | sed "s/^.* version: \([0-9.]*\).*/\1/")
				dlname=Multiwfn_${version}_dev_bin_Linux.zip;
                umflag=0
			elif [[ $dlname == '2' ]]; then 
                version=3.8
				dlname=Multiwfn_3.8_dev_bin_Linux.zip;
			elif echo $dlname | grep -qoP '^[0-9]+\.[0-9]+$'; then
                version=$dlname            
				dlname=Multiwfn_${dlname}_dev_bin_Linux.zip;
			else 
               version=${dlname%_src*};version=${version%_bin*};version=${version%_dev*};version=${version##*_};
            fi            
            manual=${dlname%_src*}
            manual=${manual%_bin*}.pdf
			dlflag=0 ;;
		c) verflag=0      
             ;;  
		w) seflag=0 ;;        
		M) umflag=0 ;;        
		U) uninstall=0 ;;        
		l|L) resources=0 ;;        
		S) isys="$OPTARG" ;;        
		Z) UNZIPEXE="$OPTARG" ;;        
		h) echo "$usage";
			aliasname="$(grep $(basename $0) ~/.bashrc | grep -o 'alias [^=]*' |grep -o '[^ ]*$')"
			if [[ -n "${aliasname}" ]]; then echo ">>Usage: Enjoy Multiwfn and flying with $(basename $0) and ${aliasname} ......" ; fi 
			exit 1 ;;
		\?) ((OPTIND--)); echo "Invalid options"; break ;;
	esac
done
shift $(($OPTIND - 1))

 
case $isys in
	1|[Ll]*) isys=1;
        EXE="";
        echo Working with Linux version of Multiwfn
        ;;
	0|[Ww]*) isys=0;
        EXE=".exe";
        dlname=${dlname//Linux.zip/Win64.rar}
        echo Working with Windows version of Multiwfn
        ;;
esac

[[ -f "${Multiwfnpath}/Multiwfn${EXE}" ]] || Multiwfnpath=$(dirname $(find "${Multiwfnpath:-$PWD}" -name "Multiwfn${EXE}" -type f -exec ls -tr1 {} + | tail -1) 2>/dev/null)
[[ -f "${Multiwfnpath}/Multiwfn${EXE}" ]] || [[ ! -d "${USERROOT}" ]] || Multiwfnpath=$(dirname $(find ${USERROOT} -name "Multiwfn${EXE}" -type f -exec ls -tr1 {} + | tail -1) 2>/dev/null)
[[ -f "${Multiwfnpath}/Multiwfn${EXE}" ]] || Multiwfnpath=$(dirname $(which "Multiwfn${EXE}" 2>/dev/null) 2>/dev/null)
[[ -f "${Multiwfnpath}/Multiwfn${EXE}" ]] || Multiwfnpath=$(dirname $(whereis -b "Multiwfn${EXE}" 2>/dev/null | awk '{printf $2}') 2>/dev/null)
[[ -f "${Multiwfnpath}/Multiwfn${EXE}" ]] || [[ ! -d "${USERROOT}" ]] || Multiwfnpath="${USERROOT}/Multiwfn"
[[ -d "${Multiwfnpath}" ]] || Multiwfnpath="${MULTIWFN_PATH_DEFAULT//\\//}"

if [[ $dlflag -eq 0 ]]; then
    echo "$usage";
    echo ""
    if [[ -f "${dlname}" ]]; then mv -f ${dlname} ${dlname%.*}.tmp.${dlname##*.}; fi
    if ! wget --no-check-certificate "http://sobereva.com/multiwfn/misc/${dlname}"; then
        if ! wget --no-check-certificate "http://sobereva.com/multiwfn/old/${version}/${dlname}"; then
            dlstr=$(wget -q -O - http://sobereva.com/multiwfn/download.html | grep misc | sed "s~^.*<a href=\"\(.*\)\".*~\1~" | sed -e "s~\".*$~~g" | grep ${dlname} )        
            if [[ -f "${dlstr##*/}" ]]; then mv -f ${dlstr##*/} ${dlstr##*/}.tmp.${dlstr##*.}; fi
            if test -z "${dlstr}" || ! wget --no-check-certificate "http://sobereva.com/multiwfn/${dlstr}"; then        
                dlstr=$(wget -q -O - http://sobereva.com/multiwfn/old/list.htm | grep '<a href=' | sed "s~^.*_blank>\(.*\)</a>.*~\1~" | sed -e "s~\\\~/~g" | grep ${dlname} );
                if [[ -f "${dlstr##*/}" ]]; then mv -f ${dlstr##*/} ${dlstr##*/}.tmp.${dlstr##*.}; fi
                if test -z "${dlstr}"  ||  ! wget --no-check-certificate "http://sobereva.com/multiwfn/old/${dlstr}"; then
                    echo Error in downloading ${dlname} 
                    echo Check error messages. Try again later. 
                    echo $(basename $0): http://bbs.keinsci.com/thread-20052-1-1.html
                    echo Multiwfn: http://sobereva.com/multiwfn/
                    echo Historical version: http://sobereva.com/multiwfn/old/list.htm
                    echo 'wget --spider -r -np http://sobereva.com/multiwfn/old/list.htm'
                    echo "Available list:"
                    curl -s  http://sobereva.com/multiwfn/download.html | grep misc | sed "s~^.*<a href=\"\(.*\)\".*~\1~" | sed -e "s~\".*$~~g"
                    curl -s  http://sobereva.com/multiwfn/old/list.htm | grep '<a href=' | sed "s~^.*_blank>\(.*\)</a>.*~\1~" | sed -e "s~\\\~/~g"
                    echo 'Check "wget -q -O -" alternative "curl -s", try curl instead of wget.'
                    echo 
                    echo "Note historical versions before 3.0 may have different file naming."
                    echo "Note latest versions may be named as Multiwfn_3.8_dev_bin_win64.rar "
                    echo "    Multiwfn_3.8_dev_bin_Linux.zip   Multiwfn_3.8_dev_src_Linux.zip "
                    echo "    Multiwfn_3.7_bin_win64.rar       Multiwfn_3.7_bin_win32.rar "
                    echo "    Multiwfn_3.7_bin_Linux.zip       Multiwfn_3.7_bin_Linux_noGUI.zip "
                    echo "    Multiwfn_3.7_bin_Mac.zip         Multiwfn_3.7_bin_Mac_noGUI.zip "
                    echo "    Multiwfn_3.7_src_Linux.zip ..."
                    exit 1; 
                fi
            fi
        fi
    fi
	wait
    if [[ $umflag -eq 1 ]]; then exit; fi
    
	if [[ -f "${Multiwfnpath}/Multiwfn${EXE}" ]]; then
        verdate=$(date +%F -r "${Multiwfnpath}/Multiwfn${EXE}")
		mv "${Multiwfnpath}" "${StoreDir}/${Multiwfnpath##*/}-old${verdate}"
        echo "Multiwfn version ${verdate} has been backed up as ${Multiwfnpath##*/}-old${verdate}"
	else
		Multiwfnpath=${USERROOT}/Multiwfn
	fi
    UNZIPEXE="${UNZIPEXE//\\//}"; 
    "${UNZIPEXE}" $UNZIPEXEOPT ${dlname}
	if [[  $? == 0 ]]; then        
        echo Installation done!
    else  
       eval "${UNZIPEXE}" $UNZIPEXEOPT ${dlname}
    fi    
	mv -f "${dlname%.*}" "${Multiwfnpath}"
    mv -f ${dlname} "${StoreDir}/${dlname%.*}$(date +%F).${dlname##*.}"
	echo "Multiwfn has been updated to the latest version from http://sobereva.com/multiwfn/misc/${dlname}"
fi

if [[ $umflag -eq 0 ]]; then
    if [[ -z "${manual}" ]]; then 
        version=$(wget -q -O - http://sobereva.com/multiwfn/download.html | grep Develop | sed "s/^.* version: \([0-9.]*\).*/\1/")
        manual=Multiwfn_${version}_dev.pdf
    fi
    if [[ -f ${manual} ]]; then mv -f ${manual} ${StoreDir}/${manual%.*}.$(date +%F -r ${manual}).pdf; fi    
    wget --no-check-certificate http://sobereva.com/multiwfn/misc/${manual};
	wait
    mv -f ${manual} ${Multiwfnpath}/
    if [[ $dlflag -eq 1 ]]; then exit ; fi
fi

if [[ $resources -eq 0 ]]; then 
    echo Resources available on http://sobereva.com/multiwfn/download.html 
    wget -q -O - http://sobereva.com/multiwfn/download.html | grep misc | sed "s~^.*<a href=\"\(.*\)\".*~\1~" | sed -e "s~\".*$~~g"
    echo Resources available on http://sobereva.com/multiwfn/old/list.htm
    wget -q -O - http://sobereva.com/multiwfn/old/list.htm | grep '<a href=' | sed "s~^.*_blank>\(.*\)</a>.*~\1~" | sed -e "s~\\\~/~g"
    exit
fi

if grep -q $(basename $0) ~/.bashrc; then nbflag=1; fi
if grep -q Multiwfnpath ~/.bashrc; then mpflag=0; fi

if [[ -f "$Multiwfnpath/Multiwfn${EXE}" ]]; then
	echo "Executable Multiwfn${EXE}  found in path: $Multiwfnpath";
	export PATH=$PATH:$Multiwfnpath
	chmod +x "$Multiwfnpath/Multiwfn${EXE}"	
	export Multiwfnpath
	if [[ $verflag -eq 0 ]]; then 
		echo "Local Multiwfn version is: "
		Multiwfn${EXE} < /dev/null 2> /dev/null | grep Version;
        echo "The latest Multiwfn version online is: "
        wget -q -O - http://sobereva.com/multiwfn/download.html | grep Develop | sed "s/^<h3>\(.*\)<.*/ \1/"
        exit
	fi

    if [[ $seflag -eq 0 && $mpflag -eq 0 ]] || [[ $seflag -eq 0 && $nbflag -eq 0 && $mpflag -eq 1 ]]; then
        sed -i "/KMP_STACKSIZE/d"  ~/.bashrc
        sed -i "/Multiwfn/d"  ~/.bashrc
        sed -i "/$(basename $0)/d"  ~/.bashrc    
        echo "#-----Multiwfn_env.sh Start-----
    alias mua=\"bash $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")\"
    export KMP_STACKSIZE=${ompstacksize:-40000000000}    ; # Multiwfn Linux
    export Multiwfnpath=${Multiwfnpath:-${USERROOT}/Multiwfn}
    export PATH=\$PATH:\$Multiwfnpath
    alias mw=\"\$Multiwfnpath/Multiwfn${EXE}\"
    chmod +x \$Multiwfnpath/Multiwfn${EXE}
#-----Multiwfn_env.sh End-----" >> ~/.bashrc
        echo "~/.bashrc has been updated:"
        echo "══════════════════ ~/.bashrc: ══════════════════"
		sed -n -e '/Multiwfn/,$p' ~/.bashrc
		echo "════════════════════════════════════════════════"
    elif [[ $nbflag -eq 0 && $mpflag -eq 1 ]]; then
        sed -i "/$(basename $0)/d"  ~/.bashrc    
        echo "alias mua=\"bash $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")\"" >> ~/.bashrc
        echo "~/.bashrc has been updated:"
        echo "══════════════════ ~/.bashrc: ══════════════════"
        tail -1 ~/.bashrc
		echo "════════════════════════════════════════════════"
    elif [[ ! -f "$(grep -E $(basename $0) ~/.bashrc | grep -oP '(?<=sh ).*(?="$)')" && $nbflag -eq 1 || $uninstall -eq 0 ]]; then        
        sed -i "/KMP_STACKSIZE/d"  ~/.bashrc
        sed -i "/Multiwfn/d"  ~/.bashrc
        sed -i "/$(basename $0)/d"  ~/.bashrc    
        echo "alias mua=\"bash $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")\"" >> ~/.bashrc
        echo "~/.bashrc has been updated:"
        echo "══════════════════ ~/.bashrc: ══════════════════"
        sed -n -e '/Multiwfn/,$p' ~/.bashrc
        # tail -1 ~/.bashrc
		echo "════════════════════════════════════════════════"
    elif [[ $seflag -eq 0 ]]; then
        echo "══════════════════ ~/.bashrc: ══════════════════"
		sed -n -e '/Multiwfn/,$p' ~/.bashrc
		echo "════════════════════════════════════════════════"
	fi
    echo    
else 
	echo Multiwfn${EXE} not found! ;	
    echo "$usage";
    echo ""
    if [[ $nbflag -eq 0 ]]; then
        echo "alias mua=\"bash $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")\"" >> ~/.bashrc
    fi    
    if [[ $verflag -eq 0 ]]; then 
        echo "The latest Multiwfn version online is: "
        wget -q -O - http://sobereva.com/multiwfn/download.html | grep Develop | sed "s/^<h3>\(.*\)<.*/ \1/"
    fi    
    exit 1;
fi

# Updating settings for Multiwfn${EXE}
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

# Updating paths for Gaussian
[[ -f "${gaupath}" ]] || [[ ! -d "${GAUSS_EXEDIR}" ]] || { gaupath="${GAUSS_EXEDIR//\\//}" && gaupath="${gaupath##*/}" && gaupath="${gaupath::3}" && gaupath="${GAUSS_EXEDIR//\\//}/${gaupath,,}${EXE}"; }
[[ -f "${gaupath}" ]] || [[ ! -d "${GAUSS_EXEDIR}" ]] || gaupath=$(find "${GAUSS_EXEDIR}" -name "g16${EXE}" -type f -exec ls -tr1 {} + 2>/dev/null | tail -1)
[[ -f "${gaupath}" ]] || [[ ! -d "${GAUSS_EXEDIR}" ]] || gaupath=$(find "${GAUSS_EXEDIR}" -name "g09${EXE}" -type f -exec ls -tr1 {} + 2>/dev/null | tail -1)
[[ -f "${gaupath}" ]] || [[ -z "${GAUSS_EXEDIR}" ]] || gaupath=${GAUSS_EXEDIR##*:}/${GAUSS_EXEDIR##*/}
[[ -f "${gaupath}" ]] || [[ ! -d "${USERROOT}" ]] || gaupath=$(find "${USERROOT}" -name "g16${EXE}" -type f -exec ls -tr1 {} + 2>/dev/null | tail -1)
[[ -f "${gaupath}" ]] || [[ ! -d "${USERROOT}" ]] || gaupath=$(find "${USERROOT}" -name "g09${EXE}" -type f -exec ls -tr1 {} + 2>/dev/null | tail -1)
[[ -f "${gaupath}" ]] || gaupath=$(whereis -b "g16${EXE}" 2>/dev/null | awk '{printf $2}' 2>/dev/null)
[[ -f "${gaupath}" ]] || gaupath=$(whereis -b "g09${EXE}" 2>/dev/null | awk '{printf $2}' 2>/dev/null)
[[ -f "${gaupath}" ]] || gaupath=$(which "g16${EXE}" 2>/dev/null)
[[ -f "${gaupath}" ]] || gaupath=$(which "g09${EXE}" 2>/dev/null)
[[ -n "${gaupath}" ]] || gaupath="${GAU_PATH_DEFAULT//\\//}"
if [[ -f "${gaupath}" ]]; then
	echo "Executable ${gaupath##*/}       found in path: ${gaupath%/*}";   
else 
	echo GAUSSIAN not found! Pleasse check usage to provide via option -g or -r;
fi
cubegenpath="${gaupath%/*}/cubegen${EXE}"
formchkpath="${gaupath%/*}/formchk${EXE}"
if [[ $isys -eq 0 ]]; then
    gaupath="${gaupath//\\//}"; gaupath="${gaupath//\//\\\\}";
    cubegenpath="${cubegenpath//\\//}"; cubegenpath="${cubegenpath//\//\\\\}";
    formchkpath="${formchkpath//\\//}"; formchkpath="${formchkpath//\//\\\\}";
fi
new='iloadGaugeom= 1  //'; old='iloadGaugeom= .*//'; sed -i "s~$old~$new~gi" settings.ini
new='gaupath= '\""${gaupath}"\"'  //'; old='gaupath= .*//'; sed -i "s~$old~$new~gi" settings.ini
new='cubegenpath= '\""${cubegenpath}"\"'  //'; old='cubegenpath= .*//'; sed -i "s~$old~$new~gi" settings.ini
new='formchkpath= '\""${formchkpath}"\"'  //'; old='formchkpath= .*//'; sed -i "s~$old~$new~gi" settings.ini 

# Updating path for orca_2mkl${EXE}
[[ -f "${ORCA_EXEDIR}/orca_2mkl${EXE}" ]] || ORCA_EXEDIR=$(dirname $(find "${ORCA_EXEDIR:-$PWD}" -name "orca_2mkl${EXE}" -type f -exec ls -tr1 {} + | tail -1) 2>/dev/null)
[[ -f "${ORCA_EXEDIR}/orca_2mkl${EXE}" ]] || [[ ! -d "${USERROOT}" ]] || ORCA_EXEDIR=$(dirname $(find "${USERROOT}" -name "orca_2mkl${EXE}" -type f -exec ls -tr1 {} + | tail -1) 2>/dev/null)
[[ -f "${ORCA_EXEDIR}/orca_2mkl${EXE}" ]] || ORCA_EXEDIR=$(dirname $(which orca_2mkl${EXE} 2>/dev/null) 2>/dev/null)
[[ -f "${ORCA_EXEDIR}/orca_2mkl${EXE}" ]] || ORCA_EXEDIR=$(dirname $(whereis -b orca_2mkl${EXE} 2>/dev/null | awk '{printf $2}') 2>/dev/null)
[[ -f "${ORCA_EXEDIR}/orca_2mkl${EXE}" ]] || [[ ! -d "${USERROOT}" ]] || ORCA_EXEDIR="${USERROOT}/orca"
[[ -d "${ORCA_EXEDIR}" ]] || ORCA_EXEDIR="${ORCA_EXEDIR_DEFAULT//\\//}"
if [[ -f "${ORCA_EXEDIR}/orca_2mkl${EXE}" ]]; then
	echo "Executable orca_2mkl${EXE} found in path: $ORCA_EXEDIR";
else 	
    echo orca_2mkl${EXE} not found!  Pleasse check usage to provide via option -o or -r;
fi   
orca_2mklpath="${ORCA_EXEDIR}/orca_2mkl${EXE}";
if [[ $isys -eq 0 ]]; then
    orca_2mklpath="${orca_2mklpath//\\//}"; orca_2mklpath="${orca_2mklpath//\//\\\\}";
fi
new='orca_2mklpath= '\""${orca_2mklpath}"\"'  //'; old='orca_2mklpath= .*//'; sed -i "s~$old~$new~gi" settings.ini

echo -e "\n\t****:-) HURRAY! settings.ini updated NORMALLY****\n"
echo ' Make sure all the parameters are set properly.'
echo ' These parameters in updated settings.ini are:'
grep -E "nthreads=|ompstacksize=|isilent=|iloadGaugeom=|gaupath=|cubegenpath=|formchkpath=|orca_2mklpath=" settings.ini | grep -oP '^.*(?=//)'
cd - >/dev/null 2>&1
