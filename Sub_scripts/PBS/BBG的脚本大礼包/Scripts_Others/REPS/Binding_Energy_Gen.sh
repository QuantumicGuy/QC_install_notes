#!/bin/bash
grep "SCF Done" *_*_?.log >> Energy.out
grep "SCF Done" *_*_??.log >> Energy.out
echo "nstep?"
read nstep
echo "nsize?"
read nsize
echo "monomer energy(au)"
read monomer
i=1
a=0
for ID in $(cat Energy.out)
do
 NUM=$i
 energy=$(awk '{$6=($6-2*'$monomer')*627.51} NR=='$NUM' {print $6}' Energy.out)
 d=`awk -v x=$i -v y=$nsize 'BEGIN{printf x*y}'`
 echo $d $energy >> Binding_Energy.out
 ((i++))
  if [ $i -gt $nstep ]
   then break
  fi
done

