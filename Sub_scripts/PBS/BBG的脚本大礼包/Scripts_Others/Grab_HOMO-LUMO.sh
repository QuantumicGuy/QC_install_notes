#!/bin/bash
printf "%-15s %-15s %-15s\n" "NAME" "HOMO [au]" "LUMO [au]" > result.out
for i in $(ls -F |grep /)
do
cd $i
for inf in *.log
do
echo "Extracting HOMO and LUMO energy from ${inf} file ..."
line_number=$(grep -n "The electronic state" ${inf} | tail -1 | cut -d: -f 1)
echo ${line_number}
HOMO=$(sed -n "${line_number},$ p" ${inf} | grep "Alpha  occ" | awk 'END {printf $NF}')
LUMO=$(sed -n "${line_number},$ p" ${inf} | grep "Alpha virt"  | awk 'NR==1 {printf $5}')
NAME=${inf%.log}
printf "%-15s %-15s %-15s\n" ${NAME} ${HOMO} ${LUMO} >> ../result.out
echo "The compound is [${NAME}], and the HOMO energy is [${HOMO} Hartree] while the LUMO energy is [${LUMO} Hartree] !"
echo
done
cd ..
done
