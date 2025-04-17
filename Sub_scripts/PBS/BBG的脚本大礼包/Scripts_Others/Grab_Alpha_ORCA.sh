#!/bin/bash
printf "%-15s %20s %20s %20s\n" "NAME" "XX [au]" "YY [au]" "ZZ [au]" > alpha.out
for i in `ls -F |grep /`
do
cd $i
for inf in *.out
do
echo Extracting Relaxed Alpha tensor from ${i%/} file ...
NAME=${i%/}
XX=$(grep -A3 "The raw cartesian tensor" ${inf} | awk 'NR==12 {printf $1}')
YY=$(grep -A3 "The raw cartesian tensor" ${inf} | awk 'NR==13 {printf $2}')
ZZ=$(grep -A3 "The raw cartesian tensor" ${inf} | awk 'NR==14 {printf $3}')
printf "%-15s %20.12e %20.12e %20.12e\n" ${NAME} ${XX} ${YY} ${ZZ} >> ../alpha.out
echo XX= ${XX}, YY= ${YY}, ZZ= ${ZZ}.
echo
done
cd ..
done
