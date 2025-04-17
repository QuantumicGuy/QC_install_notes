#!/bin/bash 
#date 2021/01/4 version 0.03 author=zbwu1996@gmail.com 

if [ $# -lt 1 ];then
    echo -e "Usage: ------lazy------" 
    exit 1
fi

eV=27.21138
# kcal=627.509474
function scf_energy {
awk 'BEGIN{
     printf "%-18s", "Energy:(unit eV)"
     if ( getline  < "tmp_value" >0) ##  the file exists
     {printf "%-10s","scan-value"
          l=1 }
     close("tmp_value")   ###Close handle
     while (getline line < "tmp_value" >0) ###read the file line by line
     {value[l] = line 
             l++}
     close("tmp_value")
     if ( getline <  "tmp_conver_info" > 0)
     {printf ("%-28s", "  MF       RF       MD       RD  ")
         c=1}
     close("tmp_conver_info") 
     while (getline line < "tmp_conver_info" >0)
     {conv[c] = line
            c++}
     close("tmp_conver_info")
     printf "\n"
}
{scf[NR]=$5} 
END{
   if ( l>=1){ 
      for(i=1;i<=NR;i++)
      printf("%-5s %10.5f "  " %8s \n",i,(scf[i]-scf[1])*"'$eV'",value[i])
      }
   else
      {
	  for(i=1;i<=NR;i++)
	      if ( "'$all_E'" != 1 ){
	  		if (i <= 10  ||  i >= NR - 9)
      			{printf("%-5s %10.5f "  " %24s  \n",i,(scf[i]-scf[1])*"'$eV'",conv[i])}
      		else if (i==11 && NR > 20 )
				print "......"
		  }
		  else{
      		 printf("%-5s %10.5f "  " %24s  \n",i,(scf[i]-scf[1])*"'$eV'",conv[i])
		  }
      }
}' "$1"
}  

function cat_tmp_head {
cat  > tmp_head  <<EOF 
%nprocshared=4
%mem=6GB
# HF/6-31G 

Title Card Required

EOF
}

function get_coordinate {
    grep "Standard orientation:" -A $2  $1 | tail -n $3 | awk '{
    printf("%14.8f %14.8f %14.8f \n",  $(NF-2), $(NF-1) , $NF)
    }'> tmp_geom
} 
#get_coordinate $filename $atom_1 $atom 
#get  geometric coordinates from the input file

function Total_Energy {
for  j in $(seq 0 "$2")
do
    if [ "$j" == 0 ];then 
        grep "SCF Done" "$1" | awk '{field=$5}END{print $5}' > tmp_file 
    else
        grep -E "Excited State\s*${j}:" "$1" | awk '{field=$5}END{print  $5}' >> tmp_file
    fi
done
awk 'BEGIN{RS = ""; FS = "\n"}
{ for (i=1;i<=NF;i++)
   if ( i==1 )
     printf("%16.8f",$i)
   else
     printf("%16.8f",$1+$i/"'$eV'")
}END{print "\t"}' tmp_file >> total_"${filename}"
}  
##usage Total_Energy $1  $2    
##$1: filename  $2 N states 

function print_header {
   awk  'BEGIN{
        for (i=0;i<=""$nstates"";i++)
        if (i == 0)
          printf ("%-15s  S%-15s " ,"Opt_time" ,i)
        else
          printf ("S%-15s", i) 
        printf "\n"
        line=1
     }
     {
     if ( NF >= 1) 
     	{print line "\t" $0
        line++ }
     }'  "$1" >"$2"
}
### print_header $1 $2 
#format output total energy

function conver_info {
       awk '/Maximum Force/{
       MF=$3/$4
       getline ; RF=$3/$4
       getline ; MD=$3/$4
       getline ; RD=$3/$4
       printf("%-8.2f %-8.2f %-8.2f %-8.2f \n",MF ,RF ,MD, RD)}' "$1" > "$2"
}
# conver_info $1 $2(output file)

while getopts :gf:ahn: opt 
do
    case "$opt" in
    g) geom=1;;
    f) nframe=${OPTARG} 
       if [ "$nframe" -ge "0" ];then 
          true 
       else
           echo "${nframe} must be number"
           exit 1
       fi
            
       ;;
    a) all_E=1 ;;
    n) nstates=${OPTARG} 
       if [ "$nstates" -ge "0" ]; then
          true
       else
          echo "total ${nstates}  must be number"
          exit 1
       fi
       ;;
    h) echo "-g:geom, -f:frame, -a:All energy" ;;
    *) echo -e "parameter error\nTry 'use -h' for more information." ;;
    esac
done
shift $((OPTIND - 1))

if [ "$nstates" ];then
   true 
else
   nstates=4
fi 

for inf in "$@"
do
if [ -f "$inf" ];then
      filename=${inf%.*}
      echo "${filename}"
      SCAN=$(grep "scan point" -m 1 -c "${inf}")
      td=$(grep "Total Energy" -m 1 -c "${inf}")
    if [ -n "$geom" ] ; then
       cat_tmp_head
       natom=$(grep "NAtoms" -m 1 "${inf}" | awk '{print $2}') #  the number of molecular atom
       natom_1=$((natom + 4))
       grep "Charge =" -m 1  -A "${natom}" "${inf}" | awk 'NR>=2 { print $1 }' >tmp_element 
       grep "Charge =" -m 1  "${inf}"  | awk '{print $3 " " $6}' >tmp_charge
       sed -i "\$r  tmp_charge" tmp_head
    fi
    if [  "$td" -eq 1 ];then
       word="Total Energy"
    else
       word="SCF Done"
    fi
    if [ "$SCAN" -eq 1 ]; then
       scan_time=$(grep "scan point" -m 1 "${inf}" | awk '{print $NF}')
       scan_var=$(grep "Scan" "${inf}" | awk '{if ($4~/^[+-]?[0-9]+[.]?[0-9]*/) print $3}')
       a=1
       for i in $scan_var; do
          grep "$i" "${inf}" | awk '{ if (NR>=2) print $4}' >tmp_value_$a
          a=$((a + 1))
       done
       paste -d "  "  tmp_value_* > tmp_value
       #exit 0
       #scan_var=$(grep "Scan"  -m 1 ${inf} | awk '{print $3}') ###2D scan is error
       #grep "${scan_var}" ${inf} | awk '{ if(NR>=2)  print $4 >>"tmp_value"}'
       line=$(grep -E -n "Optimization (completed|stopped)" -n "${inf}" | awk 'BEGIN{FS = ":"}{print $1}')
       line=$(echo -e "${line}\n$(grep "" -c "${inf}" )")  ##Multi-line records
       line_begin=1
       for i in $line
       do
           c=$((i + 1))
           if [ -n "$all_E" ];then 
             sed -n "${c}q;${line_begin},${i}p" "${inf}" >tmp_cycle #low
             grep "${word}" tmp_cycle | tail -n 1 >>tmp_energy
             Total_Energy tmp_cycle $nstates
           else
             sed -n "${c}q;${line_begin},${i}p" "${inf}" | grep "${word}" | tail -n 1 >>tmp_energy 
           fi
           #sed -n "${line_begin},${i}{/${word}/p}" ${inf} | tail -n 1 >> tmp_energy
           #  sed -n "${line_begin},${i}p" ${inf} >tmp_cycle
           #grep "${word}" tmp_cycle | tail -n 1 >>tmp_energy 
           line_begin=$i
       done
       if [ -e "total_${filename}" ] ;then 
          print_header total_"${filename}" tmp_test 
          mv tmp_test total_"${filename}"
       fi 
       if [ -n "$geom" ];then
           line_begin=1
           ls geom_"${filename}" &>/dev/null || mkdir geom_"${filename}"
           l=1
           for i in $line;do 
               if [ "$l" -le "$scan_time" ];then
   	             c=$((i + 1))
                   sed -n "${c}q;${line_begin},${i}p" "${inf}" >tmp_cycle 
                   get_coordinate tmp_cycle ${natom_1} "${natom}"
                   paste tmp_element tmp_geom > tmp_xyz
                   cat tmp_head tmp_xyz | sed '$a\   ' >geom_"${filename}"/${l}.gjf
                   line_begin=$i
                   l=$((l + 1))
               else
                    break 
               fi
           done
       fi
    else
         grep "${word}" "${inf}" >tmp_energy
         conver_info "${inf}" tmp_conver_info
         if [ -n "$geom" ]; then ####Extract geometric configuration of N iteration steps
            line=$(grep "$word" -n "${inf}" | awk 'BEGIN{FS=":"}{printf("%s \t", $1)}')
            last_line=$(grep "" -c "${inf}")
            opt_time=$(grep "${word}" -c "${inf}")
            if [ "${nframe}" -gt "${opt_time}" ]; then
               echo "frame ${nframe} is error"
               exit 1
            fi
            # ${var} and "${var}" are different 
            line=$(echo "${line}" | sed -r -e "s/^/1 &/" -e "s/$/& ${last_line}/" -e "s/\s+/#/g") 
            if [ "$nframe" -eq 0 ]; then
               nframe=${opt_time}
            fi
            awk 'BEGIN{var="'${line}'";N="'${nframe}'";split(var,arr,"#")}  ###Use array
               {
               if ( arr[N] <= NR  &&  NR <= arr[N+1])
               print $0  > "tmp_cycle"
               }' "${inf}"
            get_coordinate tmp_cycle ${natom_1} "${natom}"
            paste tmp_element tmp_geom >tmp_xyz
            cat tmp_head tmp_xyz | sed '$a\   ' >"${filename}"_"${nframe}".gjf
         fi
         if [ -n "$all_E" -a "$td" -eq 1 ]; then ####Calculate the energy of each iteration
            line=$(grep 'Threshold  Converged?' -n "${inf}" | awk 'BEGIN{FS=":"}{print $1}')
            line=$(echo -e "${line}\n$(grep "" -c "${inf}")")
            line_begin=1
            for i in $line; do ###Frequent I/O operations are slow
               c=$((i + 1))
               sed -n "${c}q;${line_begin},${i}p" "${inf}" >tmp_cycle
               Total_Energy tmp_cycle $nstates
               line_begin=$i
            done
            print_header total_"${filename}" tmp_test
            mv tmp_test total_"${filename}"
         fi
    fi
   
    scf_energy tmp_energy
   
    if [ "$scan_time" ];then 
       echo -e "scan time/variable  is $scan_time/$scan_var"
    fi
   
    normal_ter=$(grep "Normal termination" -c "${inf}")
    error_ter=$(grep "Error termination" -c "${inf}")
    if [ "$normal_ter" -ge 1 ] || [ "$error_ter" -eq 1 ]; then
       if [ "$normal_ter" -ge 1 ]; then
        echo "Job terminated normally"
     else
        echo "Job did not terminate normally"
     fi
    else
        echo "Job may still be running on"
    fi
    rm tmp_*
else
    echo "${inf}: No such file "
fi  
done
