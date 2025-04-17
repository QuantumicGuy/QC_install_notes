#!/bin/bash

##########################################################################
##########################################################################
##########		VMwfn version 1.9			##########
##########	      released at 2014/7/8			##########
##########	      Created by Zhong Cheng			##########
##########	      Email: 32589927@qq.com			##########
##########	   QQ Group: 44920936 or 18616395		##########
##########	Welcome to give advise or report bug		##########
##########################################################################
##########################################################################


#initialize parameters
VMD=vmd                         #the command to start vmd
MULTIWFN=Multiwfn               #command to start Multiwfn
RENDER=tachyon                   #command to start POVRAY in linux
GRID_QUALITY=3                  #grid quality of cube file
ORB_STYLE=sob                   #style for vmd
ORB_ISO=0.025                   #default iso value for isosurface
ORB_ALPHA=0.85			#default alpha value for isosurface
VMD_RESLTN=800                  #vmd window resolution
PIC_RESLTN_MULTI=3              #picture resoluton multiplier
PIC_FORMAT=N                    #picture format is png
AUTOMATIC=0                     #automatic mode, 0 for off, 1 for on
CLOSE_SWITCH="N"                #close switch, m close multiwfn, v close vmd, p close povray, r close povray window, g close vmd graphic interface
POVRAY_DISP=+D                  #povray render window display "+D" for display, "-D" for not display
VMD_DISP=win                    #vmd window display "win" for display, "text" for not  display
CUSTOM_JOB_INP=""               #custom job input
RENDER_SWITCH=1                 #use render or not, 1 use, 0 not use
VMD_SWITCH=1                    #use vmd or not, 1 use, 0 not use
MULTIWFN_SWITCH=1               #use multiwfn or not, 1 use, 0 not use
RECORD_MODE=0			#record all the usr operate profile
PLAYBACK_MODE=0			#playback all the usr operate profile
RECORD_NAME=""			#The name of usr operate profile
CUBE_SERIAL_NO=0		#The seiral number for every cube file 
FILE_ID=0			#FILE ID
PIC_SERIAL_NO=0
#### convert orbital input from relative notion to absolute number 		   #####
##### $1="all orbitals,alpha obitals,beta orbitals" 				   #####
##### $2="h3-l4 , 623,147" if spin unrestricted, both beta and alpha are generated #####
##### output sorted orbitals seperated by space in variable FORMAT_ORBS		   #####
function inpFormat()
{
    A=`echo $1 | cut -f2 -d ","`
    B=`echo $1 | cut -f3 -d ","`
    C=`echo $1 | cut -f1 -d ","`
    D=$(($B-$A))
    orbA=
    orbB=
    ### generate alpha orbitals
    orbA=$(echo $2 | awk -v HOMO=$A -v TOTAL=$C 'BEGIN{LUMO=HOMO+1;FS=",";OFS=" "}
    { gsub( /[ \t]*/,"" )
    for (i=1;i<=NF;i++) {
            if($i~/[HhLl][0-9]*\-[HhLl][0-9]*/ || $i~/[0-9]+\-[0-9]+/) {
                    split($i,be,"-")
                    if (be[1]~/[Hh][0-9]*/){be[1]=HOMO-substr(be[1],2)}
                    if (be[1]~/[Ll][0-9]*/){be[1]=LUMO+substr(be[1],2)}
                    if (be[2]~/[Hh][0-9]*/){be[2]=HOMO-substr(be[2],2)}
                    if (be[2]~/[Ll][0-9]*/){be[2]=LUMO+substr(be[2],2)}
                    if (be[1]>be[2]){temp=be[1];be[1]=be[2];be[2]=temp}
                    $i=be[1]
                    for (j=be[1]+1;j<=be[2];++j){$i=$i" "j}
                    if (be[1] <=0){$0="ERROR :orbital " be[1] " out of range"}
                    if (be[2] >TOTAL){$0="ERROR :orbital " be[2] " out of range"}
            }
            else if ($i~/[Hh][0-9]*/ && $i!~/\-/) {
                    $i=HOMO-substr($i,2)
            }
            else if ($i~/[Ll][0-9]*/ && $i!~/\-/) {
                    $i=LUMO+substr($i,2)
            }
            else if ($i~/[0-9]+/ && $i!~/\-/) {
                    if ($i > TOTAL || $i <=0 ){$0="ERROR: orbital " $i " out of range"}
            }
            else {$0="ERROR: wrong input format"}
    }}
    END {print $0}')
    ### generate beta orbitals if alpha HOMO != beta HOMO ###
    if [[ "$D" != "0" ]]; then
        E=$(($C*2))
        orbB=$(echo $2 | awk -v HOMO=$B -v TOTAL=$C -v T2=$E  'BEGIN{LUMO=HOMO+1;FS=",";OFS=" "}
        { gsub( /[ \t]*/,"" )
        for (i=1;i<=NF;i++) {
                if($i~/[HhLl][0-9]*\-[HhLl][0-9]*/ || $i~/[0-9]+\-[0-9]+/) {
                        split($i,be,"-")
                        if (be[1]~/[Hh][0-9]*/){be[1]=HOMO-substr(be[1],2)}
                        if (be[1]~/[Ll][0-9]*/){be[1]=LUMO+substr(be[1],2)}
                        if (be[2]~/[Hh][0-9]*/){be[2]=HOMO-substr(be[2],2)}
                        if (be[2]~/[Ll][0-9]*/){be[2]=LUMO+substr(be[2],2)}
                        if (be[1]>be[2]){temp=be[1];be[1]=be[2];be[2]=temp}
                        $i=be[1]
                        if (be[1] <= TOTAL){be[1]=be[1]+TOTAL}
                        for (j=be[1]+1;j<=be[2];++j){$i=$i" "j}
                        if (be[2] > T2){$0="ERROR :orbital " be[2] " out of range"}
                }
                else if ($i~/[Hh][0-9]*/ && $i!~/\-/) {
                        $i=HOMO-substr($i,2)
                }
                else if ($i~/[Ll][0-9]*/ && $i!~/\-/) {
                        $i=LUMO+substr($i,2)
                }
                else if ($i~/[0-9]+/ && $i!~/\-/) {
                       if ($i > T2){$0="ERROR: orbital " $i " out of range"}
                 #     if ($i <= TOTAL){$i=$i+TOTAL}
               }
                else {$0="ERROR: wrong input format"}
        }}
            END {print $0}')
    fi
### sort orbitals and delete redundant orbitals ###
    orb=`echo $orbA" "$orbB | awk '{for(i=1;i<=NF;i++){a[$i]=$i};for(i=1;i<=asort(a);i++) {printf a[i] " "};delete a}'`
    check_orb_error=`echo $orb | grep ERROR`
    if [[ "$check_orb_error" != "" ]];then
    echo "ERROR: wrong input format of orbitals" 
    exit 1
    fi
    FORMAT_ORBS=`echo $orb`
}

##### find the number of HOMO orbital form input file		#####
##### auto detect input file type (under construction......)	##### 
##### use $FILENAME				   		#####
##### output="total-orbitals,alpha-orbitals,beta-orbitals"	##### 
function findHOMO()
{
    TESTNAME=$(echo "$FILENAME" | tr "[A-Z]" "[a-z]")
    if [[ "${TESTNAME##*.}" == "fchk" ]] || [[ "${TESTNAME##*.}" == "fch" ]];then
        A=`awk '/alpha/{print $6}' $FILENAME`
        B=`awk '/beta/{print $6}' $FILENAME`
        C=`awk '/indepen/{print $6}' $FILENAME`
        elif [[ "${TESTNAME##*.}" == "molden" ]];then
        A=`grep -A1 Alpha $FILENAME | grep -c "Occup= [1-2]"`
        B=`grep -A1 Beta $FILENAME | grep -c "Occup= [1-2]"`
        if [[ "$B" == "0" ]]; then B=$A; fi
        C=`grep -c Alpha $FILENAME`

    elif [[ "${TESTNAME##*.}" == "out" ]] || [[ "${TESTNAME##*.}" == "log" ]];then
        check_if_gaussian=`grep "Gaussian, Inc." $FILENAME`
        if [[ "$check_if_gaussian" != "" ]];then
            popLineNum=`sed -n '/Population/=' $FILENAME | sed -n '$p'`
            A=$(sed -n $popLineNum',$p' $FILENAME | awk 'BEGIN{ac=0}/Alpha  occ. eigenvalues/{for(i=5;i<=NF;i++)ac=ac+1}END{print ac}')
            B=$(sed -n $popLineNum',$p' $FILENAME | awk 'BEGIN{ac=0}/Beta  occ. eigenvalues/{for(i=5;i<=NF;i++)ac=ac+1}END{print ac}')
            C=$(sed -n $popLineNum',$p' $FILENAME | awk 'BEGIN{ac=0}/Alpha (virt.)?( occ.)? eigenvalues/{for(i=5;i<=NF;i++)ac=ac+1}END{print ac}')
            if [[ "$B" == "0" ]]; then B=$A; fi	
        fi
        check_if_orca=`grep "* O   R   C   A *" $FILENAME`
        if [[ "$check_if_orca" != "" ]];then
            popLineNum=`sed -n '/ORBITAL ENERGIES/=' $FILENAME | sed -n '$p'`	
            A=$(sed -n $popLineNum',/\*\*\*\*/p' $FILENAME | awk 'BEGIN{ac=0}{if(($2~/1.0000/ || $2~/2.0000/) && check!=1)ac=ac+1;if($2~/0.0000/)check=1}END{print ac}')
            B=$(sed -n $popLineNum',/\*\*\*\*/p' $FILENAME | awk 'BEGIN{ac=0}{if(($2~/1.0000/ || $2~/2.0000/) && check==1)ac=ac+1;if($2~/DOWN/)check=1}END{print ac}')
            C=$(sed -n $popLineNum',/\*\*\*\*/p' $FILENAME | awk 'BEGIN{ac=0}{if(($2~/1.0000/ || $2~/2.0000/ || $2~/0.0000/) && check!=1 )ac=ac+1;if($2~/DOWN/)check=1}END{print ac}')
            if [[ "$B" == "0" ]]; then B=$A; fi
        fi
    elif [[ "${TESTNAME##*.}" == "cub" ]] || [[ "${TESTNAME##*.}" == "cub" ]];then
        FILETYPE=cub
    else
        FILETYPE=unk
    fi
    if [[ "$A" == "$B" ]]; then
        echo "$C,$A,$B"
    else
        B=$(($B+$C))
        echo "$C,$A,$B"
    fi
}

###### check input file type and grab the orbital energy 	######
###### $1 is the order of the orbital				######
###### used in function formatOrbEnergy				######
function orbEnergy()
{
    TESTNAME=$(echo "$FILENAME" | tr "[A-Z]" "[a-z]")
    if [[ "${TESTNAME##*.}" == "molden" ]];then
        grep Ene $FILENAME | awk -F= '{print $2}' | awk -FE '{if(NR==orb)printf("%12f",$1*10^$2*27.2119)}' orb=$1
    elif [[ "${TESTNAME##*.}" == "fchk" ]] || [[ "${TESTNAME##*.}" == "fch" ]];then
        sed -n '/Alpha Orbital Energies/,/Alpha MO coefficients/p' $FILENAME | awk '{for(i=1;i<=NF;i++){if($i~/.*E[-+][0-9][0-9]/)print $i}}' | awk -FE '{if(NR==orb)printf("%12f",$1*10^$2*27.2119)}' orb=$1
    elif [[ "${TESTNAME##*.}" == "out" ]] || [[ "${TESTNAME##*.}" == "log" ]];then
        check_if_gaussian=`grep "Gaussian, Inc." $FILENAME`
        if [[ "$check_if_gaussian" != "" ]];then
            popLineNum=`sed -n '/Population/=' $FILENAME | sed -n '$p'`
            sed -n $popLineNum',$p' $FILENAME | awk '/[(virt.)(occ.)] eigenvalues/{for(i=5;i<=NF;i++)print $i*27.2119}' | awk '{if(NR==orb)printf("%12f", $1)}' orb=$1
        fi
        check_if_orca=`grep "* O   R   C   A *" $FILENAME`
        if [[ "$check_if_orca" != "" ]];then
            popLineNum=`sed -n '/ORBITAL ENERGIES/=' $FILENAME | sed -n '$p'`
            sed -n $popLineNum',/\*\*\*\*/p' $FILENAME | awk '{if($2~/1.0000/ || $2~/2.0000/ || $2~/0.0000/) print $4}' | awk '{if(NR==orb)printf("%12f",$1)}' orb=$1
        fi
    fi
}

##### get orbital energy from fchk or molden file AND format them			#####
##### in open shell case 2 lines of orbital energy generated for a and b seperately 	#####
##### $1-$n=orbitals, output all energy in the file ORB_LEVEL				#####
function formatOrbEnergy()
{
    A=`echo $1 | cut -f2 -d ","`
    B=`echo $1 | cut -f3 -d ","`
    C=`echo $1 | cut -f1 -d ","`
    D=$(($B-$A))
    shift 
    if [ "$D" -eq "0" ];then
        printf "%-15.15s" ${LOCAL_FILENAME%.*} >> ORB_LEVEL 
        until [ $# -eq 0 ];do
            orbEnergy $1
            shift
        done >> ORB_LEVEL
        echo "" >> ORB_LEVEL
    else
        not_print_head=0
        printf "%-15.15s" ${LOCAL_FILENAME%.*}_a >> ORB_LEVEL 
        until [ $# -eq 0 ];do
            if [ "$1" -lt "$C" ];then
                orbEnergy $1
            elif [ "$not_print_head" -ne "1" ];then
                printf "\n%-15.15s" ${LOCAL_FILENAME%.*}_b 
                not_print_head=1
                orbEnergy $1
                else
                orbEnergy $1
            fi
            shift
        done >> ORB_LEVEL 
        echo "" >> ORB_LEVEL
    fi
}

###### generate the table head of orbital energy 				######
###### only relative orbial label are supported 				######
###### two lines of head generate in openshell case 				######
###### every file has it's own head, all the head are wrote in ORB_LEVEL	######
 
function orbitalEnergyHead()
{
    A=`echo $1 | cut -f2 -d ","`
    B=`echo $1 | cut -f3 -d ","`
    C=`echo $1 | cut -f1 -d ","`
    D=$(($B-$A))
    shift
    printf "%-15.15s" "file\orbital" >> ORB_LEVEL
    not_print_head=0
    until [ $# -eq 0 ];do
    #echo "current is $1, total is $C, alpha is $A, beta is $B"
        if [ "$1" -lt "$C" ];then
            RELATIVE_ORDER=$(($1-$A))
            if [ "$RELATIVE_ORDER" -eq "0" ];then printf "%12s" HOMO; fi
            if [ "$RELATIVE_ORDER" -eq "1" ];then printf "%12s" LUMO; fi
            if [ "$RELATIVE_ORDER" -lt "0" ];then printf "%12s" HOMO$RELATIVE_ORDER; fi
            if [ "$RELATIVE_ORDER" -gt "1" ];then printf "%12s" LUMO+$(($RELATIVE_ORDER-1)); fi
        elif [ "$not_print_head" -ne "1" ];then
            printf "\n%-15.15s" "file\orbital"
            not_print_head=1
            RELATIVE_ORDER=$(($1-$B))
            if [ "$RELATIVE_ORDER" -eq "0" ];then printf "%12s" HOMO; fi
            if [ "$RELATIVE_ORDER" -eq "1" ];then printf "%12s" LUMO; fi
            if [ "$RELATIVE_ORDER" -lt "0" ];then printf "%12s" HOMO$RELATIVE_ORDER; fi
            if [ "$RELATIVE_ORDER" -gt "1" ];then printf "%12s" LUMO+$(($RELATIVE_ORDER-1)); fi
        else 
            RELATIVE_ORDER=$(($1-$B))
            if [ "$RELATIVE_ORDER" -eq "0" ];then printf "%12s" HOMO; fi
            if [ "$RELATIVE_ORDER" -eq "1" ];then printf "%12s" LUMO; fi
            if [ "$RELATIVE_ORDER" -lt "0" ];then printf "%12s" HOMO$RELATIVE_ORDER; fi
            if [ "$RELATIVE_ORDER" -gt "1" ];then printf "%12s" LUMO+$((RELATIVE_ORDER-1)); fi
        fi
        shift
    done >> ORB_LEVEL
    printf "\n" >> ORB_LEVEL
}



##### generate orbital cube file using Multiwfn 			#####
##### use $FILENAME $GRID_QUALITY(1,2,3,or decimal) $1-$n=orbitals 	#####
##### output cubefile with filename_orbitalnum.cube 			#####
function multiwfnCubeGen()
{
until [ $# -eq 0 ];do
    CUBENAME=${LOCAL_FILENAME%.*}_$1.cube
    if [[ "$MULTIWFN_SWITCH" == "1" ]];then
        echo "Generating $CUBENAME with quality $GRID_QUALITY..."
        MULTIWFN_COM="5 4 $1 $GRID_QUALITY 2"
        echo $MULTIWFN_COM |  awk -F " " '{for(i=1;i<=NF;i++)print $i}' > Multiwfn_command
        ($MULTIWFN $FILENAME < Multiwfn_command 1> temp_multiwfn.out 2>null;rm temp_multiwfn.out)&
        while [ ! -f temp_multiwfn.out ];do sleep 0.001;done
        echo -n "0%-"
        while [ -f temp_multiwfn.out ];do
            CUBE_PROGRESS=$(grep "Finished:" temp_multiwfn.out | tail -1 | awk -F "[ /]+" '{printf("%d",$3/$4*100)}')
            if [[ $CUBE_PROGRESS > $CUBE_PROGRESS_PRE ]];then
                echo -n "$CUBE_PROGRESS%-";fi
            CUBE_PROGRESS_PRE=$CUBE_PROGRESS
            sleep 1
        done
        echo "Done!"
        mv MOvalue.cub $CUBENAME
    fi
    CUBE_SERIAL_NO=$(($CUBE_SERIAL_NO+1))
    CUBE_ID=$FILE_ID"_"$CUBE_SERIAL_NO
    echo $CUBE_ID" "$CUBENAME" STYLE_"$ORB_STYLE" "$ORB_ISO" "$ORB_STYLE" "$ORB_ALPHA >> CUBE_RECORD
    shift
done
}


##### change the iso and style by change the vmdrc file 					#####
##### $1=iso $2=style name, if no parameter, use default value $ORB_ISO and $ORB_STYLE		#####
##### at the end of this function, delete the "exit" at the end of vmdrc			#####
##### but not delete the "quit" at the end of vmdrc						##### 
##### for combined use with "G/g all" command of tcl in vmdrc					#####
function switchStyle() 
{
    STYLE_FILE=$1
    ISO_NEW=$2
    STYLE_NEW=$3
    ALPHA_NEW=$4
    if [[ "$ISO_NEW" != ""  && "$STYLE_NEW" != "" ]];then 
        ISO_CHECK=`echo $ISO_NEW | awk '{if ($0!~/^[-]?[0-9]*[.]?[0-9]+$/){print "0"}}'`
        if [[ "$ISO_CHECK" == "0" ]]; then
            echo "Illegal isovalue $ISO_NEW, must be a decimal";exit 1
        fi
        STYLE_NEW=`echo $STYLE_NEW | tr [A-Z] [a-z]`
        if [[ "$STYLE_NEW" != "sob" ]] && [[ "$STYLE_NEW" != "zc" ]]; then
            echo "Illegal input style $STYLE_NEW";exit 1
        else
            STYLE_FILE=STYLE_$STYLE_NEW
        fi
        awk -v ISO=$ISO_NEW 'BEGIN{ISO_NEG = -1*ISO}{
        if($0~/Isosurface ([0-9])*[.]?([0-9])+/){gsub(/Isosurface ([0-9])*[.]?([0-9])+/,"Isosurface "ISO);print;getline}
        if($0~/Isosurface -([0-9])*[.]?([0-9])+/){gsub(/Isosurface -([0-9])*[.]?([0-9])+/,"Isosurface "ISO_NEG);print;getline}
        print
        }' $STYLE_FILE > ${STYLE_FILE}.modified
        mv ${STYLE_FILE}.modified $STYLE_FILE
    fi

    cat STYLE_COMMON_WHITE > vmdrc
    cat $STYLE_FILE >> vmdrc
    #write Cube file name to vmc_command
    sed -i "/puts \"Cube file name:/d" vmd_command
    sed -i "/puts \"User operate profile:/i\puts \"Cube file name:		$CUBENAME\"" vmd_command
    #remove exit from vmd_command for same file
    CURRENT_MOL_NAME=${CUBENAME%_*} 
    if [[ "$CURRENT_MOL_NAME" != "$LAST_MOL_NAME" ]];then
        sed -i '/^exit$/d' vmd_command
        LAST_MOL_NAME=$CURRENT_MOL_NAME
    fi
    cat vmd_command >> vmdrc
}

##### generate .pov and correspond pov-ray .ini file from cube file		#####
##### use $FILENAME and $LOCAL_FILNAME 						#####
##### need $VMD_RESLTN(format 800,600 or a single 800 means that 		
##### aspect ratio is got from cube and the longer edge is larger than 800)	
##### default value is 800							#####
##### need $PIC_RESLTN_MULTI, pic resolution = window resolution * multiplier	#####
##### If RECORD_MODE is 1, copy usr operate profile  after every vmd step 
##### as prof_$RECORD_NAME_$CUBE_SERIAL_NO to dir $RECORD_NAME			#####
##### If PLAYBACK_MODE is 1, write usr operate profile to vmdrc before 	
##### every vmd step 								#####
##### need env var $PIC_FORMAT(same as povray opinion, N=PNG,J=JPEG,B=BMP
##### T=TGA,E=EXR,P=PPM,C=RLE,H=HDR). default value is N			#####
##### will use environment var POVRAY_DISP(+D or -D).				#####
##### will use environment var VMD_DISP (win or text). 				#####
##### will read cube file from CUBE_RECORD one by one 
##### will generate PIC_RECORD
##### output pov file with filename_orbitalnum_picSerialNum.pov    	
##### output ini file with filename_orbitalnum_picSerialNum.ini			#####
function renderPGen() {
    WIDTH=`echo "$VMD_RESLTN" | cut -d, -f1`
    HEIGHT=`echo "$VMD_RESLTN" | cut -d, -f2`
    JUDGE=`echo "$VMD_RESLTN" | cut -d, -f3`
    #read every cube in CUBE_RECORD
    if [[ ! -s CUBE_RECORD ]]; then echo "CUBE_RECORD is empty, POV-Ray input will not be generated";exit 1; fi
    NUMofCUBE=`grep -c . CUBE_RECORD`
    CurrentCUBEIndex=1
    while [[ "$CurrentCUBEIndex" -le "$NUMofCUBE" ]];do
        p1=`awk '{if(NR==current) print $1}' "current=$CurrentCUBEIndex" CUBE_RECORD`
        p2=`awk '{if(NR==current) print $2}' "current=$CurrentCUBEIndex" CUBE_RECORD`
        p3=`awk '{if(NR==current) print $3}' "current=$CurrentCUBEIndex" CUBE_RECORD`
        p4=`awk '{if(NR==current) print $4}' "current=$CurrentCUBEIndex" CUBE_RECORD`
        p5=`awk '{if(NR==current) print $5}' "current=$CurrentCUBEIndex" CUBE_RECORD`
        p6=`awk '{if(NR==current) print $6}' "current=$CurrentCUBEIndex" CUBE_RECORD`
        if [[ "$p3" == "" ]];then echo "Wrong format of CUBE_RECORD: the third parameter is missing at row $CurrentCUBEIndex";exit 1; fi
        if [[ "$p3" != "CLOSE" ]];then
            CUBE_ID=$p1
            CUBENAME=$p2
            #use switchstye to generate vmdrc fie
            switchStyle $p3 $p4 $p5 $p6
            #set VMD window resolution
            if [[ "$WIDTH" == "$JUDGE" ]] && [[ "$HEIGHT" == "$JUDGE" ]]; then
                w=`awk 'NR==4{print $1}' $CUBENAME`
                h=`awk 'NR==5{print $1}' $CUBENAME`
                WIDTH=$w
                HEIGHT=$h
                if [[ $w > $h ]]; then
                    i=$w
                else
                    i=$h
                fi
                LONGEDGE=$i
                until [[ $LONGEDGE -gt $JUDGE ]]; do
                    LONGEDGE=$(($LONGEDGE+$i))
                    WIDTH=$(($WIDTH+$w))
                    HEIGHT=$(($HEIGHT+$h))
                done
            fi
            if [[ "$WIDTH" == "0" ]] || [[ "$WIDTH" == "" ]]; then
                w=`awk 'NR==4{print $1}' $CUBENAME`
                h=`awk 'NR==5{print $1}' $CUBENAME`
                WIDTH=`echo "$HEIGHT $w $h" | awk '{printf "%d",$1/$3*$2 }'`
            fi
            if [[ "$HEIGHT" == "0" ]] || [[ "$HEIGHT" == "" ]]; then
                w=`awk 'NR==4{print $1}' $CUBENAME`
                h=`awk 'NR==5{print $1}' $CUBENAME`
                HEIGHT=`echo "$WIDTH $w $h" | awk '{printf "%d",$1/$2*$3 }'`
            fi
            echo "VMD window resolution is $WIDTH * $HEIGHT"

            #play back usr operate profile for each step if PLAYBACK_MODE=1
            if [[ "$PLAYBACK_MODE" == "1" ]];then
                CURRENT_OPT_PROFILE="prof_"$RECORD_NAME"_"$CUBE_ID
                if [ ! -f "$RECORD_NAME""/""$CURRENT_OPT_PROFILE" ];then
                    echo "Record file $RECORD_NAME""/$CURRENT_OPT_PROFILE not found"
                    exit 1
                fi 
                sed -i "/^source.*prof/d" vmdrc
                sed -i "/^#COMMAND START/a\source $RECORD_NAME/$CURRENT_OPT_PROFILE" vmdrc
            fi
            #execute VMD
            if [[ "$VMD_DISP" == "win" ]];then
                $VMD -e vmdrc -size $WIDTH $HEIGHT  $CUBENAME | awk '{if($0!~/^[A-Za-z]*)/)print}'
            fi
            if [[ "$VMD_DISP" == "text" ]];then
                $VMD -e vmdrc -size $WIDTH $HEIGHT -dispdev text  $CUBENAME | awk '{if($0!~/^[A-Za-z]*)/)print}'
            fi
            #trim usr opt profile AND set new WIDTH & HEIGHT value for povray
            USR_OPT_PROFILE=`sed -n "/^source.*prof/p" vmdrc | cut -f2 -d " "`
            if [[ "$USR_OPT_PROFILE" != "" ]];then
                awk 'BEGIN{xrotate=0;yrotate=0;zrotate=0;xtrans=0;ytrans=0;ztrans=0;scale=1;dwidth=800;dheight=600}
            #/rotate x by /{xrotate=xrotate+$4}
            #/rotate y by /{yrotate=yrotate+$4}
            #/rotate z by /{zrotate=zrotate+$4}
                /translate by /{xtrans=xtrans+$3;ytrans=ytrans+$4;ztrans=ztrans+$5}
            #/scale by /{scale=scale+$3}
                /display resize /{dwidth=$3;dheight=$4}
                {if($0!~/translate by / && $0!~/display resize /)print $0}
            END{
            #printf("rotate x by %.7f\n",xrotate)
            #printf("rotate y by %.7f\n",yrotate)
            #printf("rotate z by %.7f\n",zrotate)
            printf("translate by %.7f %.7f %.7f\n",xtrans,ytrans,ztrans)
            #printf("scale by %.7f\n",scale)
            printf("display resize %d %d\n",dwidth,dheight) 
            }' $USR_OPT_PROFILE > prof_temp
                mv prof_temp $USR_OPT_PROFILE
                WIDTH=`awk '/display resize /{print $3}' $USR_OPT_PROFILE`
                HEIGHT=`awk '/display resize /{print $4}' $USR_OPT_PROFILE`
            fi

            #record usr operate profile for each step if RECORD_MODE=1
            if [[ "$RECORD_MODE" == 1 ]];then
                USR_OPT_PROFILE=`sed -n "/^source.*prof/p" vmd_command | cut -f2 -d " "`
                CURRENT_OPT_PROFILE="prof_"$RECORD_NAME"_"$CUBE_ID
                if [[ "$USR_OPT_PROFILE" != "" ]];then
                    cp $USR_OPT_PROFILE $RECORD_NAME/$CURRENT_OPT_PROFILE
                    echo "copy $USR_OPT_PROFILE as $RECORD_NAME/$CURRENT_OPT_PROFILE"
                else
                    touch $RECORD_NAME/$CURRENT_OPT_PROFILE
                fi 
            fi

            #CUBE_SERIAL_NO=$(($CUBE_SERIAL_NO+1))

            #generate povray input file
            if [[ "$RENDER" == "povray" || "$RENDER" =~ "pvengine" ]];then
                for i in current_*.pov;do
                    FILE_ID=`echo $CUBE_ID | cut -f1 -d "_"`
                    PIC_SERIAL_NO=`echo $i | awk -F "[_.]" '{print $2}'`
                    PIC_ID=$CUBE_ID"_"$PIC_SERIAL_NO
                    if [[ "$FILE_ID" == "J" ]];then 
                        PICNAME=$CUBE_ID"_"${CUBENAME%.*}_${PIC_SERIAL_NO}.pov
                    else
                        PICNAME=${CUBENAME%.*}_${PIC_SERIAL_NO}.pov
                    fi
                    echo $PIC_ID" "$PICNAME >> PIC_RECORD
                    mv $i $PICNAME
                    PWIDTH=$(($WIDTH*$PIC_RESLTN_MULTI))
                    PHEIGHT=$(($HEIGHT*$PIC_RESLTN_MULTI))
                    echo ";povray ini file generated by VMwfn
                    +I$PICNAME
                    +W$PWIDTH
                    +H$PHEIGHT
                    +F$PIC_FORMAT
                    +A
                    -GS
                    -GD
                    -GR
                    -GW
                    $POVRAY_DISP" > ${PICNAME%.*}.ini
                done
            fi

            #generate tachyon input file
            if [[ "$RENDER" =~ "tachyon" ]];then
                for i in current_*.dat;do
                    FILE_ID=`echo $CUBE_ID | cut -f1 -d "_"`
                    PIC_SERIAL_NO=`echo $i | awk -F "[_.]" '{print $2}'`
                    PIC_ID=$CUBE_ID"_"$PIC_SERIAL_NO
                    if [[ "$FILE_ID" == "J" ]];then
                        PICNAME=$CUBE_ID"_"${CUBENAME%.*}_${PIC_SERIAL_NO}.dat
                    else
                        PICNAME=${CUBENAME%.*}_${PIC_SERIAL_NO}.dat
                    fi
                    echo $PIC_ID" "$PICNAME >> PIC_RECORD
                    mv $i $PICNAME
                    PWIDTH=$(($WIDTH*$PIC_RESLTN_MULTI))
                    PHEIGHT=$(($HEIGHT*$PIC_RESLTN_MULTI))
                    echo "-aasamples 12 -res $PWIDTH $PHEIGHT -o ${PICNAME%.*}.tga -format TARGA" > ${PICNAME%.*}.ini
                done
            fi
        fi
        CurrentCUBEIndex=$(($CurrentCUBEIndex+1))
    done
}

##### generate picture base on prviously generated ini file            #####
##### $POVRAY and file PIC_RECORD are needed				#####
##### no parameters are needed 						#####
function figureGen()
{
    if [[ ! -s PIC_RECORD ]]; then echo "PIC_RECORD is empty, no picture will be generated";exit 1; fi
    cat PIC_RECORD | while read p1 p2
    do
        if [[ "$RENDER" =~ "tachyon" ]];then
            $RENDER $p2 `cat ${p2%.*}.ini` 
            if [[ -n "$CHECK_IMAGEMAGIK" ]];then
                case "$PIC_FORMAT" in
                    [Nn] )
                        PIC_SURFFIX='png'
                        ;;
                    [Jj] )
                        PIC_SURFFIX='jpg';; 
                    [Hh] )
                        PIC_SURFFIX='hdr';;
                    [Bb] )
                        PIC_SURFFIX='bmp';;
                esac
                convert -trim  ${p2%.*}.tga ${p2%.*}.$PIC_SURFFIX
            fi
            elif [[ "$RENDER" == "povray" || "$RENDER" =~ "pvengine" ]];then
            $RENDER ${p2%.*}.ini | head 
        fi
    done
}

##### determine filetype and convert file to absolute path			#####
##### $1=input file name, can be relative or absolut path			#####
##### convert *.molden.input to *.molden					#####	
##### generate three environment var FILENAME and FILETYPE and LOCAL_FILENAME	#####
##### FILETYPE can be wfn/log/cub/unk						##### 
function filecheck()
{
    case $1 in 
    /*)
    FILENAME=`cd ${1%/*} 2>/dev/null; pwd`/${1##*/};;
    .*)
    FILENAME=`cd ../${1%/*} ; pwd`/${1##*/};;
    *)
    FILENAME=`cd ../; pwd`/${1##*/};;
    esac
    LOCAL_FILENAME=${FILENAME##*/};
    TESTNAME=$(echo "$FILENAME" | tr "[A-Z]" "[a-z]")
    if [[ "${TESTNAME##*.}" == "input" ]];then
        TESTNAME2="${TESTNAME%.*}"
        if [[ "${TESTNAME2##*.}" == "molden" ]];then 
            mv $FILENAME ${FILENAME%.*} 
            FILENAME=${FILENAME%.*}
            LOCAL_FILENAME=${FILENAME##*/}
        fi
    fi

    TESTNAME=$(echo "$FILENAME" | tr "[A-Z]" "[a-z]")
    if [[ "${TESTNAME##*.}" == "fchk" ]] || [[ "${TESTNAME##*.}" == "fch" ]] || [[ "${TESTNAME##*.}" == "wfn" ]] || [[ "${TESTNAME##*.}" == "wfx" ]] || [[ "${TESTNAME##*.}" == "molden" ]];then
        FILETYPE=wfn
    elif [[ "${TESTNAME##*.}" == "out" ]] || [[ "${TESTNAME##*.}" == "log" ]];then
        FILETYPE=log
    elif [[ "${TESTNAME##*.}" == "cube" ]] || [[ "${TESTNAME##*.}" == "cub" ]];then
        FILETYPE=cub
    else
        FILETYPE=unk
    fi
}

##### convert env var FILENAME to DOS format				#####
##### convert env var RENDER to window command				##### 
function linux2win()
{
    check_win=`uname | grep -i cygwin`
    if [[ "$check_win" != "" ]];then
        FILENAME=$(echo $FILENAME | awk 'BEGIN{FS="/"}{for(i=3;i<=NF;i++){printf $i;if(i==3){printf ":"};if(i<NF)printf "\\"}}')
    fi
}

###### process out file of Multiwfn					######
###### delete unnecessary information					######
###### $1 is the input file						######
function trimMultiwfn ()
{
    sed '1,/==============/d' $1 | sed -e '/?/d' -e '/e.g./d' -e '/Note:/d' -e '/Progress:/d' -e '/3~10-centers/d' -e '/Calculation took up/d' -e '/=========/d' | sed '/^ \-*[0-9][0-9]* [A-Z]/d' > multiwfn_temp.out
    mv multiwfn_temp.out $1
}

##### this function format custom job input
##### that is the expanding of compressed command in "[ ]"		######
##### the env var CUSTOM_JOB_INP will be dealt with			######
function convertCustomInput()
{
    TEST_EXPANDED=`echo $CUSTOM_JOB_INP | grep "\[" `
    until [[ "$TEST_EXPANDED" == "" ]];do
        COMMAND_BODY=`echo $CUSTOM_JOB_INP | awk -F "|" '{for(i=1;i<=NF;i++){if($i~/\[.*\]/) {print $i;break}}}'`
        COMMAND_HEAD=`echo $CUSTOM_JOB_INP | awk -F "|" '{for(i=1;i<=NF;i++){if($i~/\[.*\]/) {b=i;break}};for(i=1;i<b;i++){printf $i"|"}}'`
        COMMAND_TAIL=`echo $CUSTOM_JOB_INP | awk -F "|" '{for(i=1;i<=NF;i++){if($i~/\[.*\]/) {b=i;break}};for(i=b+1;i<=NF;i++){printf $i"|"}}'`
        EXPAND_COM=`echo $COMMAND_BODY | awk -F "[][]" '{print  $2}'`
        ORBINP_CHECK=`echo $EXPAND_COM | grep -i "orb:"`
        if [[ "$ORBINP_CHECK" != "" ]];then
            EXPAND_COM=`echo $EXPAND_COM | awk -F ":" '{print $2}'`
            ABHOMO=`findHOMO`
            inpFormat "$ABHOMO"  "$EXPAND_COM"
            EXPAND_COM=$FORMAT_ORBS
        fi 
        #check if orbs are out of range
        EXPAND_HEAD=`echo $COMMAND_BODY | awk -F "[][]" '{print  $1}'`
        EXPAND_TAIL=`echo $COMMAND_BODY | awk -F "[][]" '{print  $3}'`
        COMMAND_BODY=`echo $EXPAND_HEAD"["$EXPAND_COM"]"$EXPAND_TAIL`
        COMMAND_MAIN=`echo $COMMAND_BODY | awk -F "=" '{print $1}'`
        EXPAND_HEAD=`echo $COMMAND_MAIN | awk -F "[][]" '{print  $1}'`
        EXPAND_TAIL=`echo $COMMAND_MAIN | awk -F "[][]" '{print  $3}'`
        COMMAND_ALIAS=`echo $COMMAND_BODY | awk -F "=" '{print $2}'`
        COMMAND_ISO=`echo $COMMAND_BODY | awk -F "=" '{print $3}'`
        COMMAND_STYLE=`echo $COMMAND_BODY | awk -F "=" '{print $4}'`
        EXPANDED_BODY=`echo $EXPAND_COM | awk -F " " '{for(i=1;i<=NF;i++){printf head $i tail "=" alias$i "=" iso "=" style  "|"}}' "head=$EXPAND_HEAD" "tail=$EXPAND_TAIL" "iso=$COMMAND_ISO" "style=$COMMAND_STYLE" "alias=$COMMAND_ALIAS"`
        CUSTOM_JOB_INP=`echo $COMMAND_HEAD$EXPANDED_BODY$COMMAND_TAIL`
        TEST_EXPANDED=`echo $CUSTOM_JOB_INP | grep "\[" `
    done
    CUSTOM_JOB_INP=`echo $CUSTOM_JOB_INP | sed 's/|*$//' `
}


###### deal with custom job 						######
###### use CUSTOM_JOB_INP as input					######
###### use default cub file name generated by multiwfn as suffix	######
function customJob() 
{
    CUSTOM_JOB_NUM=`echo $CUSTOM_JOB_INP | awk -F"|" '{print NF}' `
    JOB_COUNT=1
    while [ $JOB_COUNT -le $CUSTOM_JOB_NUM ];do
        CURRENT_JOB=`echo $CUSTOM_JOB_INP | awk -F "|" -v ID=$JOB_COUNT '{print $ID}'`
        #check and expand JOB_NAME
        JOB_NAME_RAW=`echo $CURRENT_JOB | awk -F "=" '{print $1}'`
        JOB_NAME=`echo $JOB_NAME_RAW | tr [A-Z] [a-z]`
        JOB_NAME_CHECK=`echo $JOB_NAME | awk '{
        if ($0~/^[a-z]+$/)
        {print "1"}}'`
        if [[ "$JOB_NAME_CHECK" = "1" ]]; then
            case $JOB_NAME in
            ed)
            JOB_NAME="5 1 $GRID_QUALITY 2:density.cub"; DEFAULT_ISO=0.2; DEFAULT_ALIAS=density;;
            ged)
            JOB_NAME="5 2 $GRID_QUALITY 2:gradient.cub"; DEFAULT_ISO=0.2; DEFAULT_ALIAS=GED;;
            esd)
            JOB_NAME="5 5 $GRID_QUALITY 2:spindensity.cub";	DEFAULT_ISO=0.01; DEFAULT_ALIAS=ESD;;
            espn)
            JOB_NAME="5 8 $GRID_QUALITY 2:nucleiesp.cub"; DEFAULT_ISO=15; DEFAULT_ALIAS=ESPN;;
            elf)
            JOB_NAME="5 9 $GRID_QUALITY 2:ELF.cub";	DEFAULT_ISO=0.8; DEFAULT_ALIAS=ELF;;
            lol)
            JOB_NAME="5 10 $GRID_QUALITY 2:LOL.cub"; DEFAULT_ISO=0.5;DEFAULT_ALIAS=LOL;;
            lie)
            JOB_NAME="5 11 $GRID_QUALITY 2:infoentro.cub"; DEFAULT_ISO=0.01; DEFAULT_ALIAS=LIE;;
            rdg)
            JOB_NAME="5 13 $GRID_QUALITY 2:RDG.cub"; DEFAULT_ISO=0.5; DEFAULT_ALIAS=RDG;;
            rdgp)
            JOB_NAME="5 14 $GRID_QUALITY 2:RDGprodens.cub";	DEFAULT_ISO=0.2; DEFAULT_ALIAS=RDGP;;
            sl)
            JOB_NAME="5 15 $GRID_QUALITY 2:signlambda2rho.cub"; DEFAULT_ISO=0.4; DEFAULT_ALIAS=Slamda;;
            slp)
            JOB_NAME="5 16 $GRID_QUALITY 2:signlambda2rhoprodens.cub"; DEFAULT_ISO=0.4; DEFAULT_ALIAS=SlamdaP;;
            ch)
            JOB_NAME="5 17 $GRID_QUALITY 2:fermihole.cub"; DEFAULT_ISO=0.01; DEFAULT_ALIAS=fermiHole;;
            alip)
            JOB_NAME="5 18 $GRID_QUALITY 2:avglocion.cub"; DEFAULT_ISO=0.01; DEFAULT_ALIAS=localIP;;
            *)
            echo "The job name \"$JOB_NAME\" is not recognized, exit now";exit 1;;
            esac
            JOB_ALIAS=`echo $CURRENT_JOB | awk -F "=" '{print $2}'`
            if [[ "$JOB_ALIAS" == "" ]];then JOB_ALIAS=$DEFAULT_ALIAS; fi
            JOB_ISO=`echo $CURRENT_JOB | awk -F "=" '{print $3}'`
            if [[ "$JOB_ISO" = "" ]];then JOB_ISO=$DEFAULT_ISO;fi
            JOB_STYLE=`echo $CURRENT_JOB | awk -F "=" '{print $4}'`
            if [[ "$JOB_STYLE" = "" ]];then	JOB_STYLE=$ORB_STYLE;fi
            JOB_ALPHA=`echo $CURRENT_JOB | awk -F "=" '{print $5}'`
            if [[ "$JOB_ALPHA" = "" ]];then JOB_ALPHA=$ORB_ALPHA;fi
            CURRENT_JOB=$JOB_NAME"="$JOB_ALIAS"="$JOB_ISO"="$JOB_STYLE"="$JOB_ALPHA
        fi
        #check job alis 
        JOB_ALIAS=`echo $CURRENT_JOB | awk -F "=" '{print $2}'`
        if [[ "$JOB_ALIAS" == "" ]];then echo "custom job must have a name"; exit 1; fi
        JOB_ISO=`echo $CURRENT_JOB | awk -F "=" '{print $3}'`
        if [[ "$JOB_ISO" = "" ]];then JOB_ISO=$ORB_ISO;fi
        JOB_STYLE=`echo $CURRENT_JOB | awk -F "=" '{print $4}'`
        if [[ "$JOB_STYLE" = "" ]];then JOB_STYLE=$ORB_STYLE;fi
        JOB_ALPHA=`echo $CURRENT_JOB | awk -F "=" '{print $5}'`
        if [[ "$JOB_ALPHA" = "" ]];then JOB_ALPHA=$ORB_ALPHA;fi

        #generate Multiwfn command
        MULTIWFN_COM=`echo $JOB_NAME | awk -F":" '{print $1}'`
        echo $MULTIWFN_COM |  awk -F " " '{for(i=1;i<=NF;i++)print $i}' > Multiwfn_command

        #check Multiwfn_command for flnm
        rawname=`grep flnm Multiwfn_command | head -n 1`
        while [[ "$rawname" != "" ]];do
            rawnumber=`grep -n flnm Multiwfn_command | head -n 1 | cut -d : -f 1`
            flnm=$LOCAL_FILENAME
            eval subname=\$$rawname
            check_path=$(echo $FILENAME | grep ':\\')
            if [[ "$check_path" != "" ]]; then
                full_subname=${FILENAME%\\*}\\$subname
                echo "expanded flnm is $full_subname" 
            else
                full_subname=${FILENAME%/*}/$subname
            fi
            rawnumber1=$(($rawnumber-1))
            rawnumber2=$(($rawnumber+1))
            mv Multiwfn_command Multiwfn_command_temp
            sed -n '1,'"$rawnumber1"'p' Multiwfn_command_temp > Multiwfn_command
            echo $full_subname >> Multiwfn_command
            sed -n "$rawnumber2"',$p' Multiwfn_command_temp >> Multiwfn_command
            rm Multiwfn_command_temp
            rawname=`grep flnm Multiwfn_command | head -n 1`
        done
        #set outfile_name and outfile_type
        OUTFILE_NAME=`echo $JOB_NAME | awk -F":" '{print $2}'`
        OUTFILE_TYPE=`echo $OUTFILE_NAME | awk -F"." '{print $2}'`
        OUTFILE_NAME=`echo $OUTFILE_NAME | awk -F"." '{print $1}'`
        if [[ "$OUTFILE_NAME" == "" ]];then OUTFILE_NAME=${LOCAL_FILENAME%.*};fi
        #determine if out put file is cube 
        if [[ $OUTFILE_TYPE == "cub" ]];then
            CUBENAME=${LOCAL_FILENAME%.*}_$OUTFILE_NAME_$JOB_ALIAS.cube
            #generate and rename cube file; detect progress
            if [[ "$MULTIWFN_SWITCH" == "1" ]];then
                echo "Generating $CUBENAME with quality $GRID_QUALITY..."
                ($MULTIWFN $FILENAME < Multiwfn_command 1> temp_multiwfn.out 2>null;rm temp_multiwfn.out)&
                while [ ! -f temp_multiwfn.out ];do sleep 0.001;done
                echo -n "0%-"
                while [ -f temp_multiwfn.out ];do
                    CUBE_PROGRESS=$(grep "Finished:" temp_multiwfn.out | tail -1 | awk -F"[ /]+" '{printf("%d",$3/$4*100)}')
                    if [[ $CUBE_PROGRESS > $CUBE_PROGRESS_PRE ]];then
                    echo -n "$CUBE_PROGRESS%-";fi
                    CUBE_PROGRESS_PRE=$CUBE_PROGRESS
                    sleep 1
                done
                echo "Done!"
                mv $OUTFILE_NAME.cub $CUBENAME
            fi
        #generate file CUBE_RECORD
            CUBE_SERIAL_NO=$(($CUBE_SERIAL_NO+1))
            CUBE_ID=$FILE_ID"_"$CUBE_SERIAL_NO
            echo $CUBE_ID" "$CUBENAME" STYLE_"$JOB_STYLE" "$JOB_ISO" "$JOB_STYLE" "$JOB_ALPHA >> CUBE_RECORD

        #deal with other output file
        elif [[ $OUTFILE_TYPE != "" && "$MULTIWFN_SWITCH" == "1" ]];then
            $MULTIWFN $FILENAME < Multiwfn_command 1> ${LOCAL_FILENAME%.*}_$JOB_ALIAS.out 2>null
            trimMultiwfn ${LOCAL_FILENAME%.*}_$JOB_ALIAS.out 
            OTHERFILE=${LOCAL_FILENAME%.*}_$JOB_ALIAS"_"$OUTFILE_NAME.$OUTFILE_TYPE
            mv $OUTFILE_NAME.$OUTFILE_TYPE $OTHERFILE
            echo "${LOCAL_FILENAME%.*}_$JOB_ALIAS"_"$OUTFILE_NAME.$OUTFILE_TYPE and ${LOCAL_FILENAME%.*}_$JOB_ALIAS.out generated"
        elif [[ $OUTFILE_TYPE == "" && "$MULTIWFN_SWITCH" == "1" ]];then
            $MULTIWFN $FILENAME < Multiwfn_command 1> ${LOCAL_FILENAME%.*}_$JOB_ALIAS.out 2>null
            trimMultiwfn ${LOCAL_FILENAME%.*}_$JOB_ALIAS.out
            echo "${LOCAL_FILENAME%.*}_$JOB_ALIAS.out generated"
        fi
        JOB_COUNT=$(($JOB_COUNT+1))
    done
}


###### put this function before renderPGen
###### read input from $JOIN_JOB_INP
###### generate vmdrc file for join job and write information to CUBE_PROCESS
###### format for JOIN_JOB_INP is JOB1|JOB2|JOB3
###### format for each job is Number=iso=sytle=alpha=c+number=iso=style=alpha=c....
###### number is the number of the cube can be 1_1 for specific file or 1 for every file
###### if c is on, then corresponding cube will not be visualized
function joinCube()
{
    #delete all previous record in CUBE_RECORD
    sed -i '/^J_[0-9][0-9]*_[0-9][0-9]*/d' CUBE_RECORD
    JOIN_JOB_NUM=`echo $JOIN_JOB_INP | awk -F"|" '{print NF}' `
    JOIN_JOB_COUNT=1
    while [ $JOIN_JOB_COUNT -le $JOIN_JOB_NUM ];do
        CURRENT_JOIN_JOB=`echo $JOIN_JOB_INP | awk -F "|" -v ID=$JOIN_JOB_COUNT '{print $ID}'`
        TOTAL_CUBE_NUM=`echo $CURRENT_JOIN_JOB | awk -F"+" '{print NF}' `
        MASTER_CUBE=`echo $CURRENT_JOIN_JOB | awk -F"+" '{print $1}'`
        MASTER_CUBE_CODE=`echo $MASTER_CUBE | awk -F"=" '{print $1}'`
        MASTER_CUBE_ISO=`echo $MASTER_CUBE | awk -F"=" '{print $2}'`
        MASTER_CUBE_STYLE=`echo $MASTER_CUBE | awk -F"=" '{print $3}'`
        MASTER_CUBE_ALPHA=`echo $MASTER_CUBE | awk -F"=" '{print $4}'`
        MASTER_CUBE_OPTION=`echo $MASTER_CUBE | awk -F"=" '{print $5}'`
        #check the type of MASTER_CUBE_CODE
        if [[ "$MASTER_CUBE_CODE" =~ ^[0-9]+_[0-9]+$ ]];then
            MASTER_CUBE_NAME=`awk -v code=$MASTER_CUBE_CODE '{if($1==code)print $2}' CUBE_RECORD`
            #if opinions are empty, grap them from CUBE_RECORD  
            if [[ "$MASTER_CUBE_ISO" == "" ]];then MASTER_CUBE_ISO=`awk -v code=$MASTER_CUBE_CODE '{if($1==code)print $4}' CUBE_RECORD`; fi
            if [[ "$MASTER_CUBE_STYLE" == "" ]];then MASTER_CUBE_STYLE=`awk -v code=$MASTER_CUBE_CODE '{if($1==code)print $5}' CUBE_RECORD`; fi
            if [[ "$MASTER_CUBE_ALPHA" == "" ]];then MASTER_CUBE_ALPHA=`awk -v code=$MASTER_CUBE_CODE '{if($1==code)print $6}' CUBE_RECORD`; fi
            #modify CUBE_RECORD if c opinion is on
            if [[ "$MASTER_CUBE_OPTION" == "c" || "$MASTER_CUBE_OPTION" == "C" ]]; then
                awk -v cubecode=$MASTER_CUBE_CODE '{if( $1 == cubecode ){$3="CLOSE"}print $0}' CUBE_RECORD > CUBE_RECORD_TEMP
                mv CUBE_RECORD_TEMP CUBE_RECORD
            fi
        #set SLAVE_CUBE_NUM to null to make vmdrcGen to generate right material
            SLAVE_CUBE_NUM=""
            vmdrcGen STYLE_JOIN_$JOIN_JOB_COUNT 
            #initial slave cube count
            SLAVE_CUBE_NUM=1
            while [ $SLAVE_CUBE_NUM -lt $TOTAL_CUBE_NUM ];do
                SLAVE_CUBE=`echo $CURRENT_JOIN_JOB | awk -F"+" '{print $(CN+1)}' CN=$SLAVE_CUBE_NUM`  
                SLAVE_CUBE_CODE=`echo $SLAVE_CUBE | awk -F"=" '{print $1}'`
                #check the type of SLAVE_CUBE_CODE
                if [[ "$SLAVE_CUBE_CODE" =~ ^[0-9]+_[0-9]+$ ]];then
                    SLAVE_CUBE_NAME=`awk -v code=$SLAVE_CUBE_CODE '{if($1==code)print $2}' CUBE_RECORD`
                    SLAVE_CUBE_ISO=`echo $SLAVE_CUBE | awk -F"=" '{print $2}'`
                    if [[ "$SLAVE_CUBE_ISO" == "" ]];then SLAVE_CUBE_ISO=`awk -v code=$SLAVE_CUBE_CODE '{if($1==code)print $4}' CUBE_RECORD`; fi
                    SLAVE_CUBE_STYLE=`echo $SLAVE_CUBE | awk -F"=" '{print $3}'`
                    if [[ "$SLAVE_CUBE_STYLE" == "" ]];then SLAVE_CUBE_STYLE=`awk -v code=$SLAVE_CUBE_CODE '{if($1==code)print $5}' CUBE_RECORD`; fi
                    SLAVE_CUBE_ALPHA=`echo $SLAVE_CUBE | awk -F"=" '{print $4}'`
                    if [[ "$SLAVE_CUBE_ALPHA" == "" ]];then SLAVE_CUBE_ALPHA=`awk -v code=$SLAVE_CUBE_CODE '{if($1==code)print $6}' CUBE_RECORD`; fi
                    SLAVE_CUBE_OPTION=`echo $SLAVE_CUBE | awk -F"=" '{print $5}'`
                    if [[ "$SLAVE_CUBE_OPTION" == "c" || "$SLAVE_CUBE_OPTION" == "C" ]]; then
                        awk -v cubecode=$SLAVE_CUBE_CODE '{if( $1 == cubecode ){$3="CLOSE"}print $0}' CUBE_RECORD > CUBE_RECORD_TEMP
                        mv CUBE_RECORD_TEMP CUBE_RECORD
                    fi
                    vmdrcGen STYLE_JOIN_$JOIN_JOB_COUNT $SLAVE_CUBE_NAME
                else 
                    echo "Slave cube code:$SLAVE_CUBE_CODE do not match master cube code: $MASTER_CUBE_CODE" 
                    exit 1
                fi
                SLAVE_CUBE_NUM=$(($SLAVE_CUBE_NUM+1))
            done
            #write to cube record
            echo "J_"$JOIN_JOB_COUNT" "$MASTER_CUBE_NAME" STYLE_JOIN_"$JOIN_JOB_COUNT >> CUBE_RECORD
        #process general cube code 
        elif [[ "$MASTER_CUBE_CODE" =~ ^[0-9]+$ ]]; then
            MASTER_CUBECODE_COM=$MASTER_CUBE_CODE
            MAX_FILE_CODE=`awk '{if($1 ~ /^[0-9]+_[0-9]+$/) CN=$1}END{gsub(/_[0-9]+/,"",CN);print CN}' CUBE_RECORD`
            #initial file count
            CURRENT_FILE_CODE=1
            while [ $CURRENT_FILE_CODE -le $MAX_FILE_CODE ];do
                MASTER_CUBE_CODE=${CURRENT_FILE_CODE}_$MASTER_CUBECODE_COM
                MASTER_CUBE_NAME=`awk -v code=$MASTER_CUBE_CODE '{if($1==code)print $2}' CUBE_RECORD`
                if [[ "$MASTER_CUBE_NAME" == "" ]]; then 
                    echo "MASTER CUBE with code $MASTER_CUBE_CODE is missing. This may because some cubes are failed to generate, or the input cube code is wrong." 
                    exit 1
                fi
                #if opinions are empty, grap them from CUBE_RECORD  
                if [[ "$MASTER_CUBE_ISO" == "" ]];then MASTER_CUBE_ISO=`awk -v code=$MASTER_CUBE_CODE '{if($1==code)print $4}' CUBE_RECORD`; fi
                if [[ "$MASTER_CUBE_STYLE" == "" ]];then MASTER_CUBE_STYLE=`awk -v code=$MASTER_CUBE_CODE '{if($1==code)print $5}' CUBE_RECORD`; fi
                if [[ "$MASTER_CUBE_ALPHA" == "" ]];then MASTER_CUBE_ALPHA=`awk -v code=$MASTER_CUBE_CODE '{if($1==code)print $6}' CUBE_RECORD`; fi
                #modify CUBE_RECORD if c opinion is on
                if [[ "$MASTER_CUBE_OPTION" == "c" || "$MASTER_CUBE_OPTION" == "C" ]]; then
                    awk -v cubecode=$MASTER_CUBE_CODE '{if( $1 == cubecode ){$3="CLOSE"}print $0}' CUBE_RECORD > CUBE_RECORD_TEMP
                    mv CUBE_RECORD_TEMP CUBE_RECORD
                fi
                #set SLAVE_CUBE_NUM to null to tell vmdrc to generate right material
                SLAVE_CUBE_NUM=""
                vmdrcGen STYLE_JOIN_${JOIN_JOB_COUNT}_$CURRENT_FILE_CODE
                #initial slave cube count
                SLAVE_CUBE_NUM=1
                while [ $SLAVE_CUBE_NUM -lt $TOTAL_CUBE_NUM ];do
                    SLAVE_CUBE=`echo $CURRENT_JOIN_JOB | awk -F"+" '{print $(CN+1)}' CN=$SLAVE_CUBE_NUM`
                    SLAVE_CUBECODE_COM=`echo $SLAVE_CUBE | awk -F"=" '{print $1}'`
                    SLAVE_CUBE_CODE=${CURRENT_FILE_CODE}_$SLAVE_CUBECODE_COM
                    #check the type of SLAVE_CUBE_CODE
                    if [[ "$SLAVE_CUBE_CODE" =~ ^[0-9]+_[0-9]+$ ]];then
                        SLAVE_CUBE_NAME=`awk -v code=$SLAVE_CUBE_CODE '{if($1==code)print $2}' CUBE_RECORD`
                        #read slave cube properties
                        SLAVE_CUBE_ISO=`echo $SLAVE_CUBE | awk -F"=" '{print $2}'`
                        if [[ "$SLAVE_CUBE_ISO" == "" ]];then SLAVE_CUBE_ISO=`awk -v code=$SLAVE_CUBE_CODE '{if($1==code)print $4}' CUBE_RECORD`; fi
                        SLAVE_CUBE_STYLE=`echo $SLAVE_CUBE | awk -F"=" '{print $3}'`
                        if [[ "$SLAVE_CUBE_STYLE" == "" ]];then SLAVE_CUBE_STYLE=`awk -v code=$SLAVE_CUBE_CODE '{if($1==code)print $5}' CUBE_RECORD`; fi
                        SLAVE_CUBE_ALPHA=`echo $SLAVE_CUBE | awk -F"=" '{print $4}'`
                        if [[ "$SLAVE_CUBE_ALPHA" == "" ]];then SLAVE_CUBE_ALPHA=`awk -v code=$SLAVE_CUBE_CODE '{if($1==code)print $6}' CUBE_RECORD`; fi
                        SLAVE_CUBE_OPTION=`echo $SLAVE_CUBE | awk -F"=" '{print $5}'`
                        if [[ "$SLAVE_CUBE_OPTION" == "c" || "$SLAVE_CUBE_OPTION" == "C" ]]; then
                            awk -v cubecode=$SLAVE_CUBE_CODE '{if( $1 == cubecode ){$3="CLOSE"}print $0}' CUBE_RECORD > CUBE_RECORD_TEMP
                            mv CUBE_RECORD_TEMP CUBE_RECORD
                        fi
                        vmdrcGen STYLE_JOIN_${JOIN_JOB_COUNT}_$CURRENT_FILE_CODE $SLAVE_CUBE_NAME
                    else
                        echo "Slave cube code:$SLAVE_CUBE_CODE do not match master cube code: $MASTER_CUBE_CODE"
                        exit 1
                    fi
                    SLAVE_CUBE_NUM=$(($SLAVE_CUBE_NUM+1))
                done
                #write to cube record
                echo "J_"${JOIN_JOB_COUNT}_$CURRENT_FILE_CODE" "$MASTER_CUBE_NAME" STYLE_JOIN_"${JOIN_JOB_COUNT}_$CURRENT_FILE_CODE >> CUBE_RECORD
                CURRENT_FILE_CODE=$(($CURRENT_FILE_CODE+1))
            done
        else
            echo "Wrong cube code: $MASTER_CUBE_CODE"
            exit 1
        fi
        JOIN_JOB_COUNT=$(($JOIN_JOB_COUNT+1))
    done
}
#interprete the input and determing which cubes to join
#determing if the cubes need to be shut down, and modify CUBE_PROCESS
#generate vmdrc file for join
#generate povGen file


##### generate vmd script file vmdrc 					#####
##### $ORB_STYLE(sob,zc) $AUTOMATIC $ORB_ISO 				#####
##### $AUTOMATIC(1=auto,0=manual) 					#####
##### $ORB_ISO, the valid format is 0.xxx, default value is 0.025	#####
##### output a vmdrc file named current.pov				#####
function vmdrcGen()
{
if [[ "$1" != "" && "$2" == "" ]];then
GENERATE_MAST_RC=1
JOIN_SLAVE_RC=0
CURRENT_ISO_RC=$MASTER_CUBE_ISO
CURRENT_ALPHA_RC=$MASTER_CUBE_ALPHA
CURRENT_STYLE_RC=$MASTER_CUBE_STYLE
elif [[ "$1" != "" && "$2" != "" ]];then
JOIN_SLAVE_RC=1
GENERATE_MAST_RC=0
CURRENT_ISO_RC=$SLAVE_CUBE_ISO
CURRENT_ALPHA_RC=$SLAVE_CUBE_ALPHA
CURRENT_STYLE_RC=$SLAVE_CUBE_STYLE
fi
#check if it is a map job
CHECK_MAP=`echo "$CURRENT_STYLE_RC" | grep "\[.*\]$"`
if [[ "$CHECK_MAP" != "" ]];then
CURRENT_MAP_JOB=`echo "$CURRENT_STYLE_RC" | awk -F "[][]" '{print $2}'`
CURRENT_STYLE_RC=`echo "$CURRENT_STYLE_RC" | awk -F "[][]" '{print $1}'`
if [[ "$CURRENT_STYLE_RC" == "" ]]; then CURRENT_STYLE_RC="sob"; fi
MAP_JOB_CODE=`echo "$CURRENT_MAP_JOB" | awk -F ":" '{print $1}'`
MAP_JOB_RANGE=`echo "$CURRENT_MAP_JOB" | awk -F ":" '{print $2}'`
MAP_JOB_COLOR=`echo "$CURRENT_MAP_JOB" | awk -F ":" '{print $3}'`
MAP_JOB_OPTION=`echo "$CURRENT_MAP_JOB" | awk -F ":" '{print $4}'`
if [[ "$MAP_JOB_RANGE" == "" ]]; then MAP_JOB_RANGE="-0.04 0.02"; fi
if [[ "$MAP_JOB_COLOR" == "" ]]; then MAP_JOB_COLOR="BGR"; fi
if [[ "$MAP_JOB_OPTION" == "" ]]; then MAP_JOB_OPTION="C"; fi
#check the format of map job code
if [[ "$MAP_JOB_CODE" =~ ^[0-9]+_[0-9]+$ ]];then
MAP_CUBE_NAME=`awk -v CUBE_CODE=$MAP_JOB_CODE '{if($0 ~ "^"CUBE_CODE)print $2}' CUBE_RECORD`
elif [[ "$MAP_JOB_CODE" =~ ^[0-9]+$ ]];then
MAP_JOBCODE_COM=$MAP_JOB_CODE
MAP_JOB_CODE=${CURRENT_FILE_CODE}_$MAP_JOBCODE_COM
MAP_CUBE_NAME=`awk -v CUBE_CODE=$MAP_JOB_CODE '{if($0 ~ "^"CUBE_CODE)print $2}' CUBE_RECORD`
else 
echo "Wrong cube code: $MAP_CUBE_CODE"
exit 1
fi
#modify the CUBE_RECORD file to close cube in map job
if [[ "$MAP_JOB_OPTION" == "c" || "$MAP_JOB_OPTION" == "C" ]]; then
awk -v cubecode=$MAP_JOB_CODE '{if( $1 == cubecode ){$3="CLOSE"}print $0}' CUBE_RECORD > CUBE_RECORD_TEMP
mv CUBE_RECORD_TEMP CUBE_RECORD
fi
#write the map script
MAP_JOB_SCRIPT="
#MAP_SCRIPT start
puts \"New cube added to mol [mol addfile $MAP_CUBE_NAME]\"
mol modcolor 1 top Volume 1
mol scaleminmax top 1 $MAP_JOB_RANGE
color scale method $MAP_JOB_COLOR
#MAP_SCRIPT end
"
fi

if [[ "$CURRENT_ISO_RC" == "" ]];then CURRENT_ISO_RC=$ORB_ISO;fi
if [[ "$CURRENT_ALPHA_RC" == "" ]];then CURRENT_ALPHA_RC=$ORB_ALPHA;fi
if [[ "$CURRENT_STYLE_RC" == "" ]];then CURRENT_STYLE_RC=$ORB_STYLE;fi
if [[ "$SLAVE_CUBE_NUM" == "" ]];then SLAVE_CUBE_NUM=0;fi
echo "" > vmdrc
### write style to vmdrc ###
STYLE_COMMON_WHITE="
# STYLE WHITE NORMAL
display projection Orthographic
display depthcue off
display nearclip set 0.01
display farclip set 100
color Display Background white
axes location Off
menu main move 5 650
display nearclip set 0.01
display nearclip set 0.01
display farclip set 100
display farclip set 100
mol color Name
"
STYLE_ATOM_sob="
#set color and material for atoms
mol material Opaque
mol modstyle 0 top CPK 0.600000 0.400000 30.000000 30.000000
mol modcolor 0 0 Element
color Element C yellow
color Element N blue
color Element S orange
color Element B pink
color Element F cyan
color Element Cl green
color Element Br ochre
color Element I magenta
#carbon color
color change rgb 4 0.700000 0.700000 0.500000
#nitrogen color
color change rgb 0 0.250000 0.450000 1.000000
#sulfer colar
color change rgb 3 1.000000 0.700000 0.000000
#material for atoms
material change ambient Opaque 0.100000
material change diffuse Opaque 0.500000
material change specular Opaque 0.100000
material change shininess Opaque 0.300000
"
STYLE_SURFACE_sob="
#style for surfaces
mol addrep top
mol addrep top
mol delrep 3 top
mol delrep 3 top
mol modstyle 1 top Isosurface $CURRENT_ISO_RC 0 0 0 1 0
mol modstyle 2 top Isosurface [expr -1*$CURRENT_ISO_RC] 0 0 0 1 0
mol modcolor 1 top ColorID 12
mol modcolor 2 top ColorID 21
#iso surface 1 color
color change rgb 12 0.300000 1.000000 0.400000
#iso surface 2 color
color change rgb 21 0.400000 0.600000 1.000000
#material for surfaces
#creat new material for change alpha
if {![regexp sob$SLAVE_CUBE_NUM [ material list ]]} {
puts \"Creat new material [material add sob$SLAVE_CUBE_NUM copy Diffuse]\" }
mol modmaterial 1 top sob$SLAVE_CUBE_NUM
mol modmaterial 2 top sob$SLAVE_CUBE_NUM
material change ambient sob$SLAVE_CUBE_NUM 0.150000
material change diffuse sob$SLAVE_CUBE_NUM 0.600000
material change specular sob$SLAVE_CUBE_NUM 0.150000
material change shininess sob$SLAVE_CUBE_NUM 0.350000
material change opacity sob$SLAVE_CUBE_NUM $CURRENT_ALPHA_RC
mol modmaterial 1 top sob$SLAVE_CUBE_NUM
mol modmaterial 2 top sob$SLAVE_CUBE_NUM
"


STYLE_ATOM_zc="
mol modstyle 0 top CPK 0.600000 0.400000 30.000000 30.000000
mol material AOEdgy
color Name C gray
color Name H silver
color Name S orange
color change rgb 14  1.000000 0.300000 0.000000
color change rgb 6  0.800000 0.800000 0.800000
color change rgb 3 1.000000 0.700000 0.000000
material change ambient AOEdgy 0.100000 
material change diffuse AOEdgy 0.600000    
material change shininess AOEdgy 0.350000  
material change outline AOEdgy 0.000000   
material change outlinewidth AOEdgy 0.000000
"
STYLE_SURFACE_zc="
mol addrep top
mol addrep top
mol delrep 3 top
mol delrep 3 top
mol modstyle 1 top Isosurface $CURRENT_ISO_RC 0 0 0 1 1
mol modstyle 2 top Isosurface [expr -1*$CURRENT_ISO_RC] 0 0 0 1 1
mol modcolor 1 top ColorID 10
mol modcolor 2 top ColorID 1
color change rgb 10 0.150000 0.600000 1.000000
color change rgb 1  1.000000 0.150000 0.000000
if {![regexp zc$SLAVE_CUBE_NUM [ material list ]]} {
puts \"Creat new material [material add zc$SLAVE_CUBE_NUM copy Diffuse]\" }
material change ambient zc$SLAVE_CUBE_NUM 0.150000
material change diffuse zc$SLAVE_CUBE_NUM 0.600000
material change specular zc$SLAVE_CUBE_NUM 0.300000
material change shininess zc$SLAVE_CUBE_NUM 0.600000
material change opacity zc$SLAVE_CUBE_NUM $CURRENT_ALPHA_RC
mol modmaterial 1 top zc$SLAVE_CUBE_NUM
mol modmaterial 2 top zc$SLAVE_CUBE_NUM
"
### write command to vmdrc ###
echo '
    #COMMAND START
    logfile USROPT
    exec echo "" > USROPT_ODD
    puts "Choose from following short command:
    \"n/N\": next with current(n) or default(N) setting
    \"s/l name\": save(s) or load(l) operate with \"prof_name\" and set it as current setting (default name is usr)
    \"sn name\": save operate with \"prof_name\" and do next with current setting (default name is usr)
    \"r\": render current scene, can be saved by \"s\" command
    \"g/G \[all\]\": automatic go though all orbitals with current(g) or default(G) setting, add option \"all\" to go through all tasks
    \"i decimal id\": change the iso value(decimal) of mol surface(id), default id is 0. Set negative value to reverse phase. 
    \"a decimal id\": change the transparency(decimal) of mol surface(id), default id is 0. The transparency value is between 1(opacity) and 0(invisible) 
    \"u styleName id\": use style of styleName to molecule(id), default id is 0 \"sob\" and \"zc\" are available, can be saved by \"s\" command"

    #check if it is a map job, and write corresponding command
    if {[exec sed -n "/^#MAP_SCRIPT/p" vmdrc] != "" } {
    puts "\"ms min max\": change the map scale (input both min and max) for color scale
    \"mc scaleColor\": change the map color scheme for color scale. Available options are:\"RWB,BWR,RGryB,BGryR,RGB,BGR,RWG,GWR,GWB,BWG,BlkW,WBlk\""
    proc ms {{MIN -0.04} {MAX 0.02} {MOL_NUM 0}} {
    global MAP_SCALE
    if { $MAP_SCALE($MOL_NUM) != "" } { mol top $MOL_NUM; mol scaleminmax top 1 $MIN $MAX; puts "MAP_SCALE($MOL_NUM) : [set MAP_SCALE($MOL_NUM) "$MIN $MAX"]"} else { puts "Mol $MOL_NUM dose not have a map cube"}
    }
    proc mc {{MCOLOR GBR} {MOL_NUM 0}} {
    global MAP_COLOR
    if { $MAP_COLOR($MOL_NUM) != "" } { mol top $MOL_NUM; color scale method $MCOLOR; puts "MAP_COLOR($MOL_NUM) : [set MAP_COLOR($MOL_NUM) $MCOLOR]"} else { puts "Mol $MOL_NUM dose not have a map cube"}
    }
    }

    puts "Cube file name: currentCubeName"
    #check Current user operate profile
    puts "User operate profile:	[set CURRENT [ exec sed -n "/^source.*prof/p" vmdrc | cut -f2 -d " " ]]"

    #set COMBINED_RC in order to read variables BASE_STYLE ISO_VALUE and ALPHA_VALUE
    cp vmdrc COMBINED_RC
    if { $CURRENT != "" } {exec cat $CURRENT >> COMBINED_RC }
    for {set i 0} {$i<[exec grep -c "^# STYLE BEGIN" vmdrc]} {incr i} {
    set BASE_STYLE($i) [exec cat COMBINED_RC | gawk -v row=$i {BEGIN{molid=0;matreg="mol modmaterial 1 "row}{if($0 ~/^# STYLE BEGIN/){if(molid==row)STYLE=$4;molid=molid+1}if($0 ~ matreg){sub(/[0-9]+/,"",$5);STYLE=$5}}END{print STYLE}} ]
    set BASE_STYLE_D($i) [exec cat COMBINED_RC | gawk -v row=$i {BEGIN{molid=0}{if($0 ~/^# STYLE BEGIN/){if(molid==row)STYLE=$4;molid=molid+1}}END{print STYLE}}]
    puts "BASE_STYLE($i)/Default:	$BASE_STYLE($i)/$BASE_STYLE_D($i)"   }
    for {set i 0} {$i<[exec grep -c "^# STYLE BEGIN" vmdrc]} {incr i} {
    set ISO_VALUE($i) [exec cat COMBINED_RC | gawk -v row=$i {BEGIN{molid=0;isoreg="mol modstyle 1 "row" Isosurface"}{if($0 ~/^mol modstyle 1 top Isosurface/){if(molid==row)ISO=$6;molid=molid+1}if($0 ~ isoreg)ISO=$6}END{print ISO}}] 
    set ISO_VALUE_D($i) [exec cat COMBINED_RC | gawk -v row=$i {BEGIN{molid=0}{if($0 ~/^mol modstyle 1 top Isosurface/){if(molid==row)ISO=$6;molid=molid+1}}END{print ISO}}] 
    puts "ISO_VALUE($i)/Defaut:	$ISO_VALUE($i)/$ISO_VALUE_D($i)" }
    for {set i 0} {$i<[exec grep -c "^# STYLE BEGIN" vmdrc]} {incr i} {
    set ALPHA_VALUE($i) [exec cat COMBINED_RC | gawk -v row=$i {BEGIN{alphareg="^material change opacity [a-zA-Z]+"row}{if($0 ~ alphareg) ALPHA=$5} END{print ALPHA}}] 
    set ALPHA_VALUE_D($i) [exec cat COMBINED_RC | gawk -v row=$i {BEGIN{molid=0}{if($0 ~ /^material change opacity/){if(molid==row)ALPHA=$5;molid=molid+1}}END{print ALPHA}}] 
    puts "ALPHA_VALUE($i)/Default:	$ALPHA_VALUE($i)/$ALPHA_VALUE_D($i)"   }

    #grab MAP_SCALE and MAP_COLOR from COMBINED_RC
    if {[exec sed -n "/^#MAP_SCRIPT/p" vmdrc] != "" } {
    for {set i 0} {$i<[exec grep -c "^# STYLE BEGIN" vmdrc]} {incr i} {
    set MAP_SCALE($i) [exec gawk -v row=$i {BEGIN{countRow=0;mapsreg="^mol scaleminmax "row}{if($0 ~ /^# STYLE END/)countRow=countRow+1;if(countRow==row+1){if($0 ~/^mol scaleminmax top/){SMIN=$5;SMAX=$6}}if($0 ~ mapsreg){SMIN=$5;SMAX=$6}}END{print SMIN,SMAX}} COMBINED_RC]
    if {[regexp {[0-9]} $MAP_SCALE($i)]} {puts "MAP_SCALE($i) : $MAP_SCALE($i)"}
    set MAP_COLOR($i) [exec gawk {/^color scale method/{MAPC=$4}END{print MAPC}} COMBINED_RC]
    if {[regexp {[0-9]} $MAP_SCALE($i)]} {puts "MAP_COLOR($i) : $MAP_COLOR($i)"}
    }
    }

    if { $CURRENT == "" } {puts "Picture ID:		[ set ID 0 ]" } else {puts "Picture ID:		[ set ID [ exec gawk "BEGIN{i=0}/render/{i=i+1}END{print i}" $CURRENT ]]" }
    #exec rm COMBINED_RC
    proc r {} {global ID;render render_command;incr ID;puts "Current picture ID is: $ID"}
    proc n {} {global ID;render render_command;quit}
    proc N {} {global ID;exec sed -i "/^source.*prof/d" vmd_command;render render_command;quit}
    proc s {{NAME "usr"}} {
    global CURRENT
    global ISO_VALUE
    global BASE_STYLE
    if { $CURRENT != "" } {
    exec cat $CURRENT > temp_vmdrc
    exec cp temp_vmdrc prof_$NAME
    logfile off
    exec cat USROPT >> prof_$NAME
    set WIN_RES [display get size]
    exec echo "display resize $WIN_RES" >> prof_$NAME
    logfile USROPT
    }
    if { $CURRENT == "" } {
    logfile off
    exec cat USROPT > prof_$NAME
    set WIN_RES [display get size]
    exec echo "display resize $WIN_RES" >> prof_$NAME
    logfile USROPT
    }
    exec sed -i "/^source.*prof/d" vmd_command
    exec sed -i "/^#COMMAND START/a\source prof_$NAME" vmd_command
    puts "current user operate profile is: [set CURRENT [ exec sed -n "/^source.*prof/p" vmd_command | cut -f2 -d " " ]]"
    }
    proc l {{NAME "usr"}} {
    if {[file exists prof_$NAME]} {source prof_$NAME;puts "current setting profile is prof_$NAME"} else {puts "prof_$NAME NOT exist"}
    exec sed -i "/^source.*prof/d" vmd_command
    exec sed -i "/^#COMMAND START/a\source prof_$NAME" vmd_command
    }
    proc g {{OPTION ""}} {
    global ID
    render render_command
    exec echo "render render_command" >> vmd_command
    if { $OPTION == "all" } {exec echo "quit" >> vmd_command} else {exec echo "exit" >> vmd_command}
    quit
    }
    proc G {{OPTION ""}} {
    global ID
    render render_command
    exec echo "render render_command" >> vmd_command
    if { $OPTION == "all" } {exec echo "quit" >> vmd_command} else {exec echo "exit" >> vmd_command}
    exec sed -i "/^source.*prof/d" vmd_command
    quit
    }
    proc i {{ORB_ISO} {MOL_NUM 0}} {
    mol top $MOL_NUM
    global ISO_VALUE
    if {[regexp {[-]?[0-9]*[.]?[0-9]+} $ORB_ISO]} {
    mol modstyle 1 top Isosurface $ORB_ISO 0 0 0 1 0 
    set CURRENT_ISO_NEG [ expr -1*$ORB_ISO ]
    mol modstyle 2 top Isosurface $CURRENT_ISO_NEG 0 0 0 1 0
    puts "ISO_VALUE($MOL_NUM) is: [ set ISO_VALUE($MOL_NUM) $ORB_ISO ]"
    } else {puts "invalid format, must be a number"}
    }
    proc a {{SURF_ALPHA} {MOL_NUM 0}} {
    mol top $MOL_NUM
    global BASE_STYLE
    global ALPHA_VALUE
    if {[regexp {^[0]*[.][0-9]+$} $SURF_ALPHA] || [regexp {^[1]$} $SURF_ALPHA]} {
    material change opacity $BASE_STYLE($MOL_NUM)$MOL_NUM $SURF_ALPHA
    puts "ALPHA_VALUE($MOL_NUM) is [ set ALPHA_VALUE($MOL_NUM) $SURF_ALPHA]"
    } else {puts "invalid format, must be a number no larger than 1"}
    }
    proc sn {{NAME "usr"}} {
    s $NAME
    n
    }
    proc u {{STYLE_NAME} {MOL_NUM 0}} {
    mol top $MOL_NUM
    global BASE_STYLE
    global ISO_VALUE
    global ALPHA_VALUE
    if { $STYLE_NAME == "zc" || $STYLE_NAME == "sob" } {
    source STYLE_$STYLE_NAME
    mol modstyle 1 top Isosurface $ISO_VALUE($MOL_NUM) 0 0 0 1 0
    set NEG_ISO_VALUE [ expr -1*$ISO_VALUE($MOL_NUM) ]
    mol modstyle 2 top Isosurface $NEG_ISO_VALUE 0 0 0 1 0
    if {![regexp $STYLE_NAME$MOL_NUM [ material list ]]} {
    material add $STYLE_NAME$MOL_NUM copy ${STYLE_NAME}0 }
    mol modmaterial 1 top $STYLE_NAME$MOL_NUM
    mol modmaterial 2 top $STYLE_NAME$MOL_NUM
    material change opacity $STYLE_NAME$MOL_NUM $ALPHA_VALUE($MOL_NUM)
    material change opacity ${STYLE_NAME}0 $ALPHA_VALUE(0)
    puts "BASE_STYLE($MOL_NUM) is [set BASE_STYLE($MOL_NUM) $STYLE_NAME]"
    } else { puts "style \"$STYLE_NAME\" not defined" }
    }
' > vmd_command
#modify vmd_command for different render opinion
if [[ "$RENDER" =~ "tachyon" ]];then
sed -i 's/render_command/Tachyon current_$ID.dat/' vmd_command
elif [[ "$RENDER" == "povray" || "$RENDER" =~ "pvengine" ]];then
sed -i 's/render_command/POV3 current_$ID.pov/' vmd_command
fi

#generate STYLE file

if [[ "$GENERATE_MAST_RC" == "1" ]];then
echo "# STYLE BEGIN $CURRENT_STYLE_RC" > $1
eval echo \"\$STYLE_ATOM_$CURRENT_STYLE_RC\" >> $1
eval echo \"\$STYLE_SURFACE_$CURRENT_STYLE_RC\" >> $1
echo "# STYLE END" >> $1

elif [[ "$JOIN_SLAVE_RC" == "1" ]];then
echo "puts \"New cube joined as mol [mol new $2 type cube]\"" >> $1
echo "# STYLE BEGIN $CURRENT_STYLE_RC" >> $1
eval echo \"\$STYLE_ATOM_$CURRENT_STYLE_RC\" >> $1
eval echo \"\$STYLE_SURFACE_$CURRENT_STYLE_RC\" >> $1
echo "# STYLE END" >> $1
else
echo "$STYLE_COMMON_WHITE" > STYLE_COMMON_WHITE

echo "# STYLE BEGIN sob" > STYLE_sob
echo "$STYLE_ATOM_sob" >> STYLE_sob
echo "$STYLE_SURFACE_sob" >> STYLE_sob
echo "# STYLE END" >> STYLE_sob

echo "# STYLE BEGIN zc" > STYLE_zc
echo "$STYLE_ATOM_zc" >> STYLE_zc
echo "$STYLE_SURFACE_zc" >> STYLE_zc
echo "# STYLE END" >> STYLE_zc
fi

if [[ "$CHECK_MAP" != "" ]];then
echo "$MAP_JOB_SCRIPT" >>  $1
fi


#automatic option

if [[ "$AUTOMATIC" == "1" ]];then

if [[ "$RENDER" =~ "tachyon" ]];then
echo "render Tachyon current_$ID.dat" >> vmd_command
elif [[ "$RENDER" == "povray" || "$RENDER" =~ "pvengine" ]];then
echo "render POV3 current_$ID.pov" >> vmd_command
fi
echo "quit" >> vmd_command
fi

}




function usage()
{
echo 'usage: 
vmwfn -options inputfiles(fchk/fch,molden,wfn/wfx,cube/cub,log/out)
options:
-l calculate orbital energy, coming soon...
#-r generate RDG graph, coming soon...
-o draw molecular orbitals, eg: -o 1,2,h3-l,l2-26 (h3 stands for HOMO-3 and l2 stands for LUMO+2)
-j join multiple cube, format: cube1=iso=style=alpha=close+cube2=iso=style=alpha=close
#-e analysis excited state composition, coming soon...
-v show version 
-h show help on specific option, eg: "-h c" to show the usage of -c command
-c run custom job, format: multiwfnCommand(alias):outputFileName-jobalisa-iso-style|secondJob eg: "5,10,3,2:LOL.cub-lol-0.5-sob|ELF" 
-A turn on automatic mode, default is interactive mode 
-S style, default style is "sob", you can change it to "zc"
-P "record name", preview mode is on, and all the user operate is recorded using the name "record name", default grid quality is set to 1, and povray will not be used in this mode.
-L "record name", load the user operate for each cube file.
-G grid quality of Cube file, can be 1,2,3 for low, medium or high quality, or any decimal like 0.1 for grid spacing. Default: 3
-I iso value for surface, default value is 0.025
-R vmd window resolution in pixels (800,600 for exact; 800,0 fix width; 0,800 fix height; 800 for approximate). Default: 800
-M picture resolution multiplier, pic resolution=window resolution*multiplier. Default: 3
-F output picutre format: "N" for png, "J" for jpg, "H" for hdr, "B" for bmp, "T" for tga, default is png
-C close povray render "r" window or vmd graphic "g" interface, can also disable provay "p" or vmd "v" or multiwfn "m"
'
exit	
}


while getopts "l:o:t:e:c:j:vh:S:I:R:M:D:F:C:G:P:L:A" Option 
do 
case $Option in 
l) echo  "Calculate orbitals energys of $OPTARG"; ORB_LEVEL=1; ORBS_L=$OPTARG;; 
o) echo  "Draw orbitals of $OPTARG"; ORB_GRAPH=1; ORBS_G=$OPTARG;;
p) echo "project cubes $OPTARG"; CUBE_PROJECTION=1; PROJECT_PROFILE=$OPTARG;; 
#t) echo  "Draw hole and electron distribution"; HOLE_ELECTRON=1; STATES_G=$OPTARG;; 
#e) echo  "Analysis excited state composition"; EXCITED_COMPOSITION=1; STATES_A=$OPTARG;; 
c) echo  "Run custom Multiwfn job of $OPTARG"; CUSTOM=1; CUSTOM_JOB_INP=$OPTARG;;
j) echo  "Combine multiple cube"; JOIN_CUBE=1; JOIN_JOB_INP=$OPTARG;;
v) echo  "Current version: 1.9 Publish time: 2014.07.08. 
Please contact author for bug and ANY suggestions. E-mail:GGDHZDX@QQ.COM/QQ:3258992
Join QQ GROUP for discussion: 18616395(Sobereva's super group)  or 44920936(my ORCA group)"; NO_JOB=1;;
h) HELP_SWITCH=1; HELP_OPTION=$OPTARG; NO_JOB=1;;
P) echo  "Preview mode on and record use operate as $OPTARG"; RECORD_MODE=1;RECORD_NAME=$OPTARG;;
L) echo  "Load recorded use operate $OPTARG to do all jobs"; PLAYBACK_MODE=1;RECORD_NAME=$OPTARG;;
A) echo  "Automatic mode is on"; AUTOMATIC=1;;
G) echo  "Set grid quality to $OPTARG"; GRID_QUALITY=$OPTARG;USR_GRID=1;;
S) echo  "Set gra phic style to $OPTARG"; ORB_STYLE=$OPTARG;USR_ORB_STYLE=1;;
I) echo  "Set ISO value to $OPTARG"; ORB_ISO=$OPTARG;USR_ORB_ISO=1;;
R) echo  "Set VMD window resolution to $OPTARG"; VMD_RESLTN=$OPTARG;USR_VMD_RESLTN=1;;
M) echo  "Set picture resolution multiplier to $OPTARG"; PIC_RESLTN_MULTI=$OPTARG;USR_PIC_RESLTN_MULTI=1;;
F) echo  "Set output picture format to $OPTARG"; PIC_FORMAT=$OPTARG;USR_PIC_FORMAT=1;;
C) echo  "Close functions of $OPTARG"; CLOSE_SWITCH=$OPTARG;USR_CLOSE=1;; 
*) usage
esac 
done 
shift $(($OPTIND - 1)) 

if [[ "$HELP_SWITCH" == "1" ]]; then 
case $HELP_OPTION in
o) echo "draw selected orbitals using vmd and povray
e.g. vmwfn -o h,l urfile.fchk will draw orbital HOMO and LUMO
Can use absolute orbital number (e.g. 5,23) or relative oribital label (e.g. h2 for HOMO-2, l3 for LUMO+3)
Use comma to seperate orbitals, or use dash line to set the orbital range (e.g. h5,h1-l1 stands for HOMO-5,HOMO-1,HOMO,LUMO,LUMO+1)
In open shell case, use relative oribital label will generate alpha and beta orbitals seperately (e.g. h means HOMO-alpha and HOMO-beta) 
";;
c) echo "run custom Multiwfn job, can input multiple jobs, sepertate each job by vertical line e.g. job1|job2|job3
the input format for job1 is COMMAND:FILENAME-JOBNAME-ISO-STYLE

COMMAND is a series of multiwfn command seperated by blank 
e.g. vmwfn -c "7 7 n-mySCPA" urfile.fchk will do a SCPA population and output result as urfile_mySCPA.out   
Can use packed command with [],
e.g  vmwfn -c "8 3 [100 101 102 103]-compos" urfile.fchk  will do a SCPA orbital composition analysis for orbials 100 101 102 103
User can also use relative orbital input format by start with "orb:" in [  ] 
e.g. vmwfn -c "8 3 [orb:h2,h-l2]-compos" urfile.fchk will do a SCPA orbital composition analysis for orbitals HOMO-2,HOMO,LUMO,LUMO+1,LUMO+2 
e.g. vmwfn -c "9 6 [1,2 1,3]-mayer" urfile.fchk will do Mayer bond order between atom 1 and 2, as well as 1 and 3
Only one pack for each command is supported 

FILENAME is the file generate by multiwfn 
e.g. vmwfn -c "10 7 0 3:DISLIN.PNG-DOS" urfile.fchk will generate a dos graph named urfile_DOS_DISLIN.PNG

JOBNAME is the user defined name for the job and jobname will incorprate into output file name. 
For all the non-predefine job, JOBNAME is a must have

ISO is the iso value for surface graph, only valid if FILENAME is *.cub 
e.g. vmwfn -c "5 9 3 2:ELF.cub-myELF-0.7" urfile.fchk will generate a ELF graph with iso value of 0.7

STYLE is the style for surface graph, only valid if FILENAME is *.cub 
e.g. vmwfn -c "5 9 3 2:LOL.cub-myLOL--zc" urfile.fchk will generate a LOL graph with default iso value and style of zc
";;

v) echo "Show current version and contact information";;
A) echo "Automatic perform all task, default is off, same effect as 'g all' command in interacitve mode";;

G) echo "Set the grid quality, can be 1,2,3 for low, medium and high quality as defined in Multiwfn 
or any decimal such as 0.1 to set the grid point interval to 0.1A
For large molecule and high quality picture use decimal not bigger than 0.1 is recommanded";;

S) echo "Set the style for the orbitals, now only 'sob' and 'zc' are available, default is sob
e.g. vmwfn -S zc -o h,l *.fchk   will generate obitals in zc style
User can change style in interactive mode
Welcome to send your style to me to incorporate into this script";;

P) echo "turn on the preview mode, and record all the user operate for each cube file
e.g. vmwfn -P somename -o h,l *.molden.input   will record user defined style of HOMO,LUMO for all the molden file
with the name somename, no picture will be generated in this mode and grid quality is set to 1 automatically
usually combined with -L option for generating large and high quanlity pictures";;

L) echo "load the recorded user operate save in -P mode
e.g. vmwfn -L somename -o h,l -A -G 0.1 -C gr *.molden.input   will use the user defined style recorded with name somename
for all the HOMO,LUMO in every .molden.input file. use -A to automaticall perform all task and -G to set a high quality grid
-C to close useless vmd and provay graphic windows. make sure the orbitals is exactly the same as those in -P mode";;
 
I) echo "Set the iso value for the orbitals, default value is 0.025
Can be any negative or positive value
e.g. vmwfn -I 0.05 -o h *.fchk    will generate HOMO with isovalue set to 0.05
User can change this value in the interactive mode";;

R) echo "Set the resolution for vmd window, default value is 800
e.g. vmwfn -R 800,600 -o h,l *.fchk  
means the vmd window that pop up in will have width of 800 and height of 600
if set to 800,0 then the width is fixed to 800 and the height is adjusted according to the aspect raitio of cube file
0,600 means fixed the height to 600
a single number 800 means the short edge is longer than 800, and the long edge is adjusted according to cube file
User can change this value in the interactive mode";;

M) echo "Picture resolution Multiplier, default value is 3
e.g. vmwfn -R 800,600 -M 2 -o h,l *.fchk
means that the picture resolution  is 1600*1200";;

F) echo "Set output picture format, default is N
N for png, J for jpg, H for hdr, B for bmp, T for tga
e.g. vmwfn -F J -o L *.fchk will generate LUMO in jpg format";;

C) echo  "Close part of functions; this option is quit usefull
let's say you have 50 fchk file to deal with, which means you have to generate 100 cube file to produce all the HOMO and LUMO.
The process is very time consuming, so you can generate the all the cube files first
vmwfn -C vp -o h,l *.fchk   will close vmd and povray and use multiwfn only to generate all the cube file
go out and some fresh air, or just open a game and play for a while.... after it finished,
vmwfn -C mp -o h,l *.fchk   will close multiwfn and povray and allow user to use vmd to adjust the style for all the orbitals, finally
vmwfn -C mvr -o h,l *.fchk  will close multiwfn and vmd and render window and use povray to automatically render all the pictures";;

esac
fi

if [[ "$NO_JOB" == "1" ]]; then exit 0;fi
if [[ $# -lt 1 ]]; then usage;exit 0;fi

#check all the program
CHECK_VMD=`which vmd`
if [[ "$CHECK_VMD" == "" ]];then
    echo "Warning!!! command vmd not found, please add it to you PATH environment variable"
fi
CHECK_MULTIWFN=`which Multiwfn`
if [[ "$CHECK_MULTIWFN" == "" ]];then
    echo "Warning!!! command Multiwfn not found, please add it to you PATH environment variable"
fi
CHECK_IMAGEMAGIK=`which convert`
if [[ "$CHECK_IMAGEMAGIK" == "" ]];then
    echo "Warning!!! command convert not found, only tga format will be produced if using tachyon "
fi 
CHECK_TACHYON1=`which tachyon 2> null`
CHECK_TACHYON2=`which tachyon_WIN32 2> null`
CHECK_POVRAY1=`which povray 2> null`
CHECK_POVRAY2=`which pvengine64 2> null`
CHECK_POVRAY3=`which pvengine32-sse2 2> null`
CHECK_POVRAY4=`which pvengine 2> null`
if [[ "$RENDER" == "tachyon" ]];then
if [[ "$CHECK_TACHYON1" != "" ]];then
RENDER=tachyon
elif [[ "$CHECK_TACHYON2" != "" ]];then
RENDER=tachyon_WIN32
else
RENDER=povray
fi
elif  [[ "$RENDER" == "povray" ]];then
if [[ "$CHECK_POVRAY1" != "" ]];then
RENDER=povray
elif [[ "$CHECK_POVRAY2" != "" ]];then
RENDER=pvengine64
elif [[ "$CHECK_POVRAY3" != "" ]];then
RENDER=pvengine32-sse2
elif [[ "$CHECK_POVRAY4" != "" ]];then
RENDER=pvengine
elif [[ "$CHECK_TACHYON1" != "" ]];then
RENDER=tachyon
elif [[ "$CHECK_TACHYON2" != "" ]];then
RENDER=tachyon_WIN32
fi
else
echo "Warning!!! Command of render(tachyon;tachyon_WIN32;povray;pvengine not found, no graph will generate"
fi
echo "Using $RENDER as render command"

mkdir VMwfn_DATA 
cd VMwfn_DATA

#make record dir and set variables if record mode is on
if [[ "$RECORD_MODE" == "1" ]];then
	mkdir $RECORD_NAME
	if [[ "$USR_GRID" != "1" ]];then
	GRID_QUALITY=1
	fi
	if [[ "$USR_CLOSE" != "1" ]];then
	CLOSE_SWITCH=p
	fi
fi

#check input error and initial all variable 
#if -o is on, then -l is auto on; the orbital input checking is left for specific file.
if [[ "$ORB_GRAPH" == "1" ]]; then
	ORB_LEVEL=1;ORBS_L=$ORBS_G
fi

#check ORB_STYLE
if [[ "$USR_ORB_STYLE" == "1" ]];then
ORB_STYLE=`echo $ORB_STYLE | tr A-Z a-z`
if [[ "$ORB_STYLE" != "sob" ]] && [[ "$ORB_STYLE" != "zc" ]]; then
	echo "Illegal input style $ORB_STYLE";exit 1
fi
fi

#check if ORB_ISO is number
if [[ "$USR_ORB_ISO" == "1" ]];then
ISO_CHECK=`echo $ORB_ISO | awk '{
if ($0!~/^[-]?[0-9]*[.]?[0-9]+$/)
{print "0"}}'`
if [[ "$ISO_CHECK" == "0" ]]; then
	echo "Illegal isovalue $ORB_ISO, must be a decimal";exit 1
fi
fi
#check if VMD_RESLTN is right format
if [[ "$USR_VMD_RESLTN" == "1" ]];then
RESLTN_CHECK=`echo $VMD_RESLTN | awk '{
if ($0!~/^[0-9]*[,]?[0-9]+$/ && $0!~/^[0-9]+[,]?[0-9]*$/)
{print "0"}}'`
if [[ "$RESLTN_CHECK" == "0" ]]; then
	echo "Illegal format of VMD window resolution $VMD_RESLTN";exit 1
fi
fi
#check if PIC_RESLTN_MULTI is right
if [[ "$USR_PIC_RESLTN_MULTI" == "1" ]];then
MULTI_CHECK=`echo $PIC_RESLTN_MULTI | awk '{
if ($0!~/^1?[0-9]$/)
{print "0"};}'`
if [[ "$MULTI_CHECK" == "0" ]]; then
        echo "Illegal format of picture resolution multiplier $PIC_RESLTN_MULTI, must be a integer number between 1 and 20";exit 1
fi
fi
#check the format of picture
if [[ "$USR_PIC_FORMAT" == "1" ]];then
FORMAT_CHECK=`echo $PIC_FORMAT | awk '{
if ($0!~/^[NJBTEPCHnjbtepch]$/)
{print "0"}}'`
if [[ "$FORMAT_CHECK" == "0" ]]; then
        echo "Illegal input for picture format $PIC_FORMAT";exit 1
fi
fi

#check and convert the format of grid qulity
if [[ "$USR_GRID" == "1" ]];then
GRID_CHECK=`echo $GRID_QUALITY | awk '{
if ($0~/^[1-3]$/){print "1"}
else if ($0~/^[0-9]*\.[0-9]*$/){print "2"}
else {print "0"}
}'`
if [[ "$GRID_CHECK" == "2" ]]; then
	GRID_QUALITY=`echo "4 $GRID_QUALITY,$GRID_QUALITY,$GRID_QUALITY"`
elif [[ "$GRID_CHECK" == "0" ]]; then
	echo "Illegal format for GRID QUALITY $GRID_QUALITY";exit 1
fi
fi

#check close options
if [[ "$USR_CLOSE" == "1" ]];then
CLOSE_CHECK=`echo $CLOSE_SWITCH | awk '{
if ($0!~/^[NRGPVMrgpvm]*$/){print "0"}}'`
if [[ "$CLOSE_CHECK" == "0" ]]; then
        echo "Illegal input for close option $CLOSE_SWITCH";exit 1
fi
CLOSE_SWITCH=$(echo $CLOSE_SWITCH | tr "[A-Z]" "[a-z]") 
TEST_SWITCH=$(echo "$CLOSE_SWITCH" | grep "r")
if [[ "$TEST_SWITCH" != "" ]];then POVRAY_DISP=-D; fi
TEST_SWITCH=$(echo "$CLOSE_SWITCH" | grep "g")
if [[ "$TEST_SWITCH" != "" ]];then VMD_DISP=text; fi
TEST_SWITCH=$(echo "$CLOSE_SWITCH" | grep "p")
if [[ "$TEST_SWITCH" != "" ]];then RENDER_SWITCH=0; fi
TEST_SWITCH=$(echo "$CLOSE_SWITCH" | grep "v")
if [[ "$TEST_SWITCH" != "" ]];then VMD_SWITCH=0; fi
TEST_SWITCH=$(echo "$CLOSE_SWITCH" | grep "m")
if [[ "$TEST_SWITCH" != "" ]];then MULTIWFN_SWITCH=0; fi
fi
#genrate vmdrc file
vmdrcGen
if [[ "$ORB_LEVEL" == "1" ]]; then
#clear ORB_LEVEL
echo "" > ORB_LEVEL
fi

#clear CUBE_RECORD and PIC_RECORD
if [[ "$VMD_SWITCH" != "0" ]]; then rm -f PIC_RECORD 2> /dev/null; fi

rm -f CUBE_RECORD 2> /dev/null

#deal input file one by one
until [ $# -eq 0 ];do
    FILE_ID=$(($FILE_ID+1))
    CUBE_SERIAL_NO=0
    filecheck $1
    linux2win
    echo "Begin processing $FILENAME ..."

    #process custom job
    if [[ "$CUSTOM" == "1" ]] && [[ "$FILETYPE" == "wfn" ]]; then
        convertCustomInput
        echo "Processing custom job by Multiwfn..."
        customJob
    fi

    #process orbital job
    if [[ "$ORB_GRAPH" == "1" ]] && [[ "$FILETYPE" == "wfn" ]]; then
        ABHOMO=`findHOMO`
        inpFormat "$ABHOMO" "$ORBS_G"
        #check orbs to see if have error
        echo "Begin to generate cubes for orbitals $ORBS_L($FORMAT_ORBS) of ${FILENAME##*/}:"
        multiwfnCubeGen $FORMAT_ORBS
    fi

    #process orbital level job
    if [[ "$ORB_LEVEL" == "1" ]]; then
        ABHOMO=`findHOMO`
        inpFormat "$ABHOMO" "$ORBS_L"
        echo "Extracting energy levels for orbitals $ORBS_L($FORMAT_ORBS) of ${FILENAME##*/} ..."
        orbitalEnergyHead $ABHOMO $FORMAT_ORBS
        formatOrbEnergy $ABHOMO $FORMAT_ORBS
        awk '/file\\orbital/{if($0 != head ){print $0;head=$0}}$0 !~/file\\orbital/{print $0}' ORB_LEVEL > ORB_LEVEL_TEMP
        mv ORB_LEVEL_TEMP ORB_LEVEL_$ORBS_L
        echo "Orbital levels saved in file named ORB_LEVEL_$ORBS_L!"
    fi

    shift
done

if [[ "$JOIN_CUBE" == "1" ]];then
    echo -n "Preparing for Join Cube job ..."
    joinCube
    echo "Done!"
fi


if [[ "$VMD_SWITCH" == "1" ]];then
    renderPGen
fi


if [[ "$RENDER_SWITCH" == "1" ]];then
    figureGen
fi


