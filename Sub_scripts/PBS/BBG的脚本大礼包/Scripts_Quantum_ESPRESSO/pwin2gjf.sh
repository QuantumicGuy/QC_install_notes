#!/bin/bash

pwin=$1
dos2unix $pwin 1 > /dev/null 2>&1
title=${pwin%.*}
gjf=$title".gjf"
title=${title##*/}

echo "# hf/6-31g" > $gjf
echo "" >> $gjf
echo "${title}" >> $gjf
echo "Generated with pwin2gjf.sh downloaded from http://bbs.keinsci.com/thread-20166-1-1.html" >> $gjf
echo "" >> $gjf
echo "0 1" >> $gjf

nat=`grep 'nat' $pwin | awk '{print $3}'`
startline=`cat $pwin | grep -n 'ATOMIC_POSITIONS' | awk -F ":" '{print $1}'`
let endline=$startline+$nat
let startline=$startline+1

for i in `seq $startline $endline`;do
	echo `sed -n $i"P" $pwin` >> $gjf
done
echo "" >> $gjf
echo "" >> $gjf

#unix2dos $gjf 1 > /dev/null 2>&1



