#!/bin/bash
echo
echo "************* Running statistics of Gcorr from Gaussian files **************"
echo
j=0
printf "%-8s %-30s %30s\n" "No." "NAME" "Gcorr [au]" > Extract_Gcorr_Gauss.txt
for i in `ls -F |grep /`
do
cd $i
for inf in *.log
do
if ls *.log 1> /dev/null 2>&1;then
  j=$[$j+1]
  echo Entering $(pwd)
  echo Extracting Gibbs Free Energy from ${inf} file ...
  NAME=${inf%.log}
  Gcorr=$(grep "Thermal correction to Gibbs Free Energy" ${inf} | awk '{printf $7}')
  printf "%-8s %-30s %30s\n" $j ${NAME} ${Gcorr} >> ../Extract_Gcorr_Gauss.txt
  echo  "No.$j:      NAME: ${NAME}       Gcorr= ${Gcorr}"
  echo
else
  echo "*.log file is NOT found in $(pwd)"
fi
done
cd ..
done
echo "***********  Total $j files have been processed  ***********"
