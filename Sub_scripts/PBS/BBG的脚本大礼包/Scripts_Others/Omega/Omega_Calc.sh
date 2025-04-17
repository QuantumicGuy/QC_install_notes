#!/bin/bash

echo "initial omega value(for eg. 0.001,0.184):"
read ini
echo "nsize:"
read nsize
echo "nstep"
read nstep
n=`echo "$nstep+1" | bc`
echo "make sure the calculation all finished or Ctrl-c"
read command
echo "n omega Err_Function" > result.out
for((i=0;i<$n;i++))
  do
    j=`echo "$ini+$nsize*$i" | bc`
    name="omega_${j}"
    cd $name
     if [ -f "anion.log" ] && [ -f "cation.log" ] && [ -f "neutral.log" ];then
      grep "SCF Done" *.log > ${name}_SCF.out
      Ea=$(awk 'NR==1 {printf $6}' ${name}_SCF.out)
      Ec=$(awk 'NR==2 {printf $6}' ${name}_SCF.out)
      En=$(awk 'NR==3 {printf $6}' ${name}_SCF.out)
      IP=`echo "$Ec-($En)" | bc`
      EA=`echo "$En-($Ea)" | bc`
      HOMO0=$(grep "Alpha  occ" neutral.log | awk 'END {printf $NF}')
      LUMO=$(grep "Alpha virt" neutral.log | awk 'NR==1 {printf $5}')
      HOMO1=$(grep "Alpha  occ" anion.log | awk 'END {printf $NF}')
      delta0=`echo "${HOMO0}+$IP" | bc`
      delta1=`echo "${HOMO1}+$EA" | bc`
      J=`echo "${delta0}*${delta0}+${delta1}*${delta1}" | bc`
     echo "$i $j $J" >> ../result.out
     fi
    cd ../
  done

