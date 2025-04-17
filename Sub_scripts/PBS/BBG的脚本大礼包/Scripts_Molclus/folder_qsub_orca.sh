#!/bin/bash
echo
echo "*************  Running PBS batch script  **************"
echo
j=0
for i in `ls -F |grep /`
do
cd $i
inf=molclus_orca.pbs
j=$[$j+1]
echo Entering $(pwd)
echo Running ${inf} ...
qsub < ${inf} 
echo "######  No.$j: ${inf} is submitted ######"
echo
cd ..
done
echo "***********  Total $j tasks have been submitted  ***********"
echo
