#!/bin/bash

echo "initial omega value(for eg. 0.001,0.184):"
read ini
echo "nsize:"
read nsize
echo "nstep"
read nstep
n=`echo "$nstep+1" | bc`
echo "make sure neutral.com,cation.com and anion.com in the folder or Ctrl-c"
read command
for((i=0;i<$n;i++))
  do
    j=`echo "$ini+$nsize*$i" | bc`
    name="omega_${j}"
    x=`echo "scale=0;$j*1000" | bc`
    y="${x%.*}"
    z=$(echo "$y" | awk '{printf("%03d",$1)}')
    mkdir $name
    cp neutral.com cation.com anion.com $name
    cd $name
    sed -i '4s/.*/iop(3\/107=0'${z}'000000) iop(3\/108=0'${z}'000000)/' *.com
    cp ../qsub.pbs .
    qsub qsub.pbs
    cd ../
  done

