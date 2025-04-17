#!/bin/bash

gjf=$1
dos2unix $gjf 1 > /dev/null 2>&1
title=${gjf%.*}
pwin=$title".in"
title=${title##*/}

nline=`awk 'END{print NR}' $gjf`
i=1
n=0
while [ $i -le $nline ];do
	thisline=`cat $gjf | sed -n $i"P"`
	if [[ -z $thisline ]];then
		let n++
	fi
	if [ $n -eq 2 ];then
		let i++
		let i++
		break
	else
		let i++
	fi
done
while [ $i -le $nline ];do
	thisline=`cat $gjf | sed -n $i"P"`
	if [[ -z $thisline ]];then
		break
	else
		echo "$thisline" >> tmp
		let i++
	fi
done

settings=$2
dos2unix $settings 1 > /dev/null 2>&1
nat=`grep 'nat' $settings | awk '{print $3}'`
nline=`awk 'END{print NR}' $settings`
echo '! Generated with gjf2pwin.sh downloded from http://bbs.keinsci.com/thread-20166-1-1.html' > $pwin
j=1
while [ $j -le $nline ];do
	thisline=`cat $settings | sed -n $j"P"`
	thislinecut=`echo $thisline | awk '{print $1}'`
	if [[ $thislinecut != 'ATOMIC_POSITIONS' ]];then
		echo $thisline >> $pwin
		let j++
	else
		let j++
		let j=j+$nat
		echo "ATOMIC_POSITIONS {angstrom}" >> $pwin
		nline=`awk 'END{print NR}' tmp`
		for i in `seq 1 $nline`;do
			echo `sed -n $i"P" tmp` >> $pwin
		done
	fi
done

nat=$nline
line=`cat $pwin | grep -n 'nat' | awk -F ":" '{print $1}'`
sed -i "$line"c" nat = $nat" $pwin

rm tmp

#unix2dos $pwin 1 > /dev/null 2>&1

