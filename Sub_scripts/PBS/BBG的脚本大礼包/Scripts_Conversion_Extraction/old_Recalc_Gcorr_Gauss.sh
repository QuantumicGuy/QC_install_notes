#!/bin/bash
echo
echo "************* Recalculating Gcorr from Gaussian files by freqchk tool **************"
echo
j=0
printf "%-8s %-30s %30s\n" "No." "NAME" "Gcorr [au]" > Recalc_Gcorr_Gauss.txt
echo "Generating the inputstream.txt file..."
cat << EOF > inputstream.txt  # temperature (K) is set in the second line
n
423
1
1
y
n

EOF
for i in `ls -F |grep /`
do
cd $i
for inf in *.fchk
do
if ls *.fchk 1> /dev/null 2>&1;then
  j=$[$j+1]
  echo Entering $(pwd)
  echo Recalculating Gcorr from ${inf} file by using freqchk tool ...
  freqchk $inf < ../inputstream.txt > temp_out.txt
  NAME=${inf%.fchk}
  Gcorr=$(grep "Thermal correction to Gibbs Free Energy" temp_out.txt | awk '{printf $7}')
  printf "%-8s %-30s %30s\n" $j ${NAME} ${Gcorr} >> ../Recalc_Gcorr_Gauss.txt
  echo  "No.$j:      NAME: ${NAME}       Gcorr= ${Gcorr}"
  echo
  rm temp_out.txt
else
  echo "*.fchk file is NOT found in $(pwd)"
  echo
fi
done
cd ..
done
echo "***********  Total $j files have been processed  ***********"
rm inputstream.txt

