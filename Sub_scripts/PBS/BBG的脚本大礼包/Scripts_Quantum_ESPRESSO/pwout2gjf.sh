#!/bin/bash

pwout=$1
dos2unix $pwout 1 > /dev/null 2>&1
title=${pwout%.*}
gjf=$title".gjf"
title=${title##*/}

echo "# hf/6-31g" > $gjf
echo "" >> $gjf
echo "${title}" >> $gjf
echo "Generated with pwout2gjf.sh downloaded from http://bbs.keinsci.com/thread-20166-1-1.html" >> $gjf
echo "" >> $gjf
echo "0 1" >> $gjf

nat=`grep 'number of atoms/cell' $pwout | awk '{print $5}'`
endline=`cat $pwout | grep -n 'End final coordinates' | awk -F ":" '{print $1}'`
startline=$(expr $endline - $nat)
endline=$(expr $endline - 1)
for i in `seq $startline $endline`;do
	echo `sed -n $i"p" $pwout` >> $gjf
done

echo "" >> $gjf
echo "" >> $gjf

#unix2dos $gjf
