#!/bin/bash

echo
echo ">>>> Calculating static 3rd polarizability by using dipole moments in ORCA <<<<"
echo 
## read the FF orientation, initial FF value, stepsize, and Nstep
echo "---------------------------------stage (1/4)-------------------------------------"
read -p "Press ENTER to read the FF orientation, initial FF value, stepsize, and Nstep"
counts=$(ls -F | grep "/" | wc -l)
min=1
max=0
for folder in $(ls -F |grep /)
do
  string=$(echo "$folder" | sed 's/_/ /g; s/\///g; s/-/ /g')
  molname=$(echo "$string" | awk '{printf $1}')
  ori=$(echo "$string" | awk '{printf $2}')
  FF=$(echo "$string" |  awk '{printf $3}') 
  if [[ $(echo "$FF > $max" | bc) = 1 ]]; then
  max=$FF
  fi
  if [[ $(echo "$FF < $min" | bc) = 1 ]]; then
  min=$FF
  fi
done
nstep=$(echo "0.5*$counts-1" | bc | awk '{printf "%d", $0}')
stepsize=$(echo "scale=4;($max-$min)/$nstep" | bc | awk '{printf "%.4f", $0}')
echo
echo "------------------INFO------------------------"
echo ">> $counts task files have been found!"
echo ">> Initial FF    =   $min au"
echo ">> Final FF      =   $max au" 
echo ">> Step size     =   $stepsize au" 
echo ">> Step number   =   $nstep"
echo "-----------------------------------------------" 
echo
echo

## check the ORCA outputs
echo "---------------------------------stage (2/4)-------------------------------------"
read -p "Press ENTER to check whether the ORCA outputs terminate normally..."
flag=0
for i in $(ls -F |grep /)
do
foldername=$(echo "$i" | sed 's/\///g')
cd $i
  for inf in *.out
  do
  mark=$(grep "ORCA TERMINATED NORMALLY" $inf)
  if [[ -z "$mark" ]]; then
  echo "ERROR: The [$foldername] file did NOT terminate normally!! "
  flag=$(echo "$flag+1" | bc)
  fi
  done
  cd ..
done
if [[ $flag = 0 ]]; then
echo
echo ">>> All $counts tasks terminated normally <<<"
elif [[ $flag = 1 ]]; then
echo
echo "$flag error is detected ! Please check it manually..."
else
echo
echo "$flag errors are detected ! Please check them manually..."
fi
echo

## collect diple moment components at various FF
echo "---------------------------------stage (3/4)-------------------------------------"
read -p "Press ENTER to collect diple moment components at various FF..."
echo
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
printf "%20s %20s %20s %20s\n" "NAME" "X [au]" "Y [au]" "Z [au]" > ${molname}_${ori}_Dipole.out
printf "%20s %20s %20s %20s\n" "NAME" "X [au]" "Y [au]" "Z [au]"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
for i in $(ls -F |grep /)
do
cd $i
  for inf in *.out
  do
  X=$(grep "Total Dipole Moment" $inf | awk 'END {printf $5}')
  Y=$(grep "Total Dipole Moment" $inf | awk 'END {printf $6}')
  Z=$(grep "Total Dipole Moment" $inf | awk 'END {printf $7}')
  printf "%20s %20.8f %20.8f %20.8f\n" ${i%/} $X $Y $Z >> ../${molname}_${ori}_Dipole.out
  printf "%20s %20.8f %20.8f %20.8f\n" ${i%/} $X $Y $Z
  done
cd ..
done
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo
echo ">>> All the diple moment components were saved in the ${molname}_${ori}_Dipole.out file <<<"
echo

## calculate static 3rd polarizability components at different FF
echo "---------------------------------stage (4/4)-------------------------------------"
read -p "Press ENTER to calculate static 3rd polarizability components at different FF..."
echo
reply=0
until [[ $reply = "Y" || $reply = "N" || $reply = "y" || $reply = "n" ]]
do
echo "Whether to use the results in last stage or not? [Y/N]"; read reply
done
if [[ $reply = "Y" || $reply = "y" ]]; then
result="${molname}_${ori}_Dipole.out"
else
echo "Please input the full name (with extension) of the file containing results:"; read result
fi
molname=$(echo "$(awk 'NR==3 {printf $1}' $result)" | sed 's/_/ /g' | awk '{printf $1}')
ori=$(echo "$(awk 'NR==3 {printf $1}' $result)" | sed 's/_/ /g' | awk '{printf $2}')
iniFF=$(echo "$(awk 'NR==3 {printf $1}' $result)" | sed 's/_/ /g' | awk '{printf $3}')
finFF=$(echo "$(awk 'END {printf $1}' $result)" | sed 's/_/ /g' | awk '{printf $3}')
nstep=$(echo "($(awk 'END {printf NR}' $result)-3)/2" | bc)
stepsize=$(echo "scale=4;($finFF-$iniFF)/$nstep" | bc | awk '{printf "%.4f", $0}')
echo
echo "------------------INFO------------------------"
echo ">> Molecule name   :     $molname"
echo ">> FF orientation  :     $ori"
echo ">> Initial FF      =     $iniFF au"
echo ">> Final FF        =     $finFF au" 
echo ">> Step size       =     $stepsize au" 
echo ">> Step number     =     $nstep"
echo "-----------------------------------------------"
echo
echo "   >>> The minimum FF applied: Gamma_${ori}${ori}${ori}${ori}[$iniFF] <<<"
echo ">>> The second smallest FF applied: Gamma_${ori}${ori}${ori}${ori}[$(echo "$iniFF+$stepsize" | bc | awk '{printf "%.4f", $0}')] <<<"
echo "                            *"
echo "                            *"
echo "   >>> The maximum FF applied: Gamma_${ori}${ori}${ori}${ori}[$(echo "0.5*$finFF" | bc | awk '{printf "%.4f", $0}')] <<<"
echo "                 +++ total $(echo "0.5*($nstep+1)" | bc | awk '{printf "%d", $0}') points +++"
echo
echo
TolRow=$(awk 'END {printf NR}' $result)    ## Total lines in the dipole result file
if [[ $ori = "X" ]]; then
for (( i=1;i<=$TolRow;i++ ))
do
array[i]=$(awk 'NR=='$i' {printf $2}' $result)
done
fi
if [[ $ori = "Y" ]]; then
for (( i=1;i<=$TolRow;i++ ))
do
array[i]=$(awk 'NR=='$i' {printf $3}' $result)
done
fi
if [[ $ori = "Z" ]]; then
for (( i=1;i<=$TolRow;i++ ))
do
array[i]=$(awk 'NR=='$i' {printf $4}' $result)
done
fi
GMinFF=$iniFF
GStepsize=$stepsize
GMaxFF=$(echo "0.5*$finFF" | bc | awk '{printf "%.4f", $0}')
Gpoints=$(echo "0.5*($nstep+1)" | bc | awk '{printf "%d", $0}')
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
printf "%10s %8s %32s\n" "NAME" "FF" "Gamma_${ori}${ori}${ori}${ori} [10^(-36) esu]" > ${molname}_Gamma_${ori}${ori}${ori}${ori}.out
printf "%10s %8s %32s\n" "NAME" "FF" "Gamma_${ori}${ori}${ori}${ori} [10^(-36) esu]"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
for (( j=1;j<=$Gpoints;j++ ))
do
GcurrFF=$(echo "$GMinFF+($j-1)*$GStepsize" | bc | awk '{printf "%.4f", $0}')
a=$(echo "2*$j+1" | bc)      ## F location in array[j]
b=$(echo "2*$j" | bc)     ## -F location in array[j]
c=$(echo "2*$b+1" | bc)      ## 2F location in array[j]
d=$(echo "2*$b" | bc)      ## -2F location in array[j]
A=$(echo "${array[$a]}" | awk '{printf "%.8f", $0}')
B=$(echo "${array[$b]}" | awk '{printf "%.8f", $0}')
C=$(echo "${array[$c]}" | awk '{printf "%.8f", $0}')
D=$(echo "${array[$d]}" | awk '{printf "%.8f", $0}')
Gvalue=$(echo "scale=20; (($C)-2*($A)+2*($B)-($D))/(2*($GcurrFF)^3)*5.0367*10^(-4)" | bc | awk '{printf "%.1f", $0}')      ## FF formula
printf "%10s %10.4f %20.1f\n" "$molname" "$GcurrFF" "$Gvalue" >> ${molname}_Gamma_${ori}${ori}${ori}${ori}.out
printf "%10s %10.4f %20.1f\n" "$molname" "$GcurrFF" "$Gvalue"
done
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo
echo ">>> All the Gamma_${ori}${ori}${ori}${ori} values were saved in the ${molname}_Gamma_${ori}${ori}${ori}${ori}.out file <<<"
echo









