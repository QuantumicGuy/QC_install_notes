#!/bin/bash
printf "%-15s %20s %20s %20s\n" "NAME" "X [au]" "Y [au]" "Z [au]" > dipole.out
for i in `ls -F |grep /`
do
cd $i
for inf in *.fchk
do
echo Extracting Dipole moment from ${inf} file ...
NAME=${inf%.log}
X=$(grep -A1 "Dipole Moment" ${inf} | awk 'END {printf $1}')
Y=$(grep -A1 "Dipole Moment" ${inf} | awk 'END {printf $2}')
Z=$(grep -A1 "Dipole Moment" ${inf} | awk 'END {printf $3}')
printf "%-15.8s %20.8e %20.8e %20.8e\n" ${NAME} ${X} ${Y} ${Z} >> ../dipole.out
echo X= ${X}, Y= ${Y}, Z= ${Z}.
echo
done
cd ..
done
