#!/bin/bash

## check the template file and ensure it is the only one
echo
echo "-----------------------stage (1/5)---------------------------"
read -p "Press ENTER to check the *.inp template file..."
counts=$(ls -F | grep ".inp$" | wc -l)
while [[ $counts != 1 ]]
do
  echo "Warning: $counts template files were detected, please delete extra files..."
  read -p "Press ENTER to re-detect"
  counts=$(ls -F | grep ".inp$" | wc -l)
done
file=$(ls -F | grep ".inp$"| awk '{printf $0}')
echo "OK! The ONLY template file called $file is found."
echo
inf=${file%.inp}

## set the FF orientation
echo "-----------------------stage (2/5)---------------------------"
echo "Please input the orientation of applied electric field (X,Y,or Z):"; read ori
until [[ $ori = "X" || $ori = "Y" || $ori = "Z" ]]
do
  echo "Please re-input the direction X,Y,or Z"; read ori
done
echo "OK! ${ori}-direction is chosen!"
echo

## set the initial FF value, stepsize, and Nstep
echo "-----------------------stage (3/5)---------------------------"
echo "Initial FF value (eg. 0.0010,0.184):"; read ini
echo "Step size:"; read nsize
echo "Step number:"; read nstep
n=$(echo "$nstep+1" | bc)
allfiles=$(echo "2*($nstep+1)" | bc)
echo
echo "--------------------------INFO--------------------------------"
echo ">> FF orientation  :     $ori"
echo ">> Initial FF      =     $(printf "%.4f" $ini) au"
echo ">> Final FF        =     $(echo "$ini+$nsize*$nstep" | bc | awk '{printf "%.4f", $0}') au" 
echo ">> Step size       =     $(printf "%.4f" $nsize) au" 
echo ">> Step number     =     $nstep"
echo ">> $allfiles task files will been established..."
echo "--------------------------------------------------------------"
read -p "Press ENTER to continue or abort with Ctrl-C"
echo

## creat batch files
echo "-----------------------stage (4/5)---------------------------"
echo "Creating task files ..."
echo
if [[ $ori = "X" ]]; then
  for((i=0;i<$n;i++))
    do
      j=$(echo "$ini+$nsize*$i" | bc | awk '{printf "%.4f", $0}')
      name1="${inf}_${ori}_${j}"
	  name2="${inf}_${ori}_-${j}"
      mkdir $name1
      cp $inf.inp qsub.pbs $name1
      cd $name1
      sed -i "/EField/{s/.*/    EField $j,0,0/g}" $inf.inp
	  cd ..
	  mkdir $name2
      cp $inf.inp qsub.pbs $name2
      cd $name2
      sed -i "/EField/{s/.*/    EField -$j,0,0/g}" $inf.inp
	  echo The $name1 and $name2 files have been established!
      cd ..
  done
elif [[ $ori = "Y" ]]; then
  for((i=0;i<$n;i++))
    do
      j=$(echo "$ini+$nsize*$i" | bc | awk '{printf "%.4f", $0}')
      name1="${inf}_${ori}_${j}"
	  name2="${inf}_${ori}_-${j}"
      mkdir $name1
      cp $inf.inp qsub.pbs $name1
      cd $name1
      sed -i "/EField/{s/.*/    EField 0,$j,0/g}" $inf.inp
	  cd ..
	  mkdir $name2
      cp $inf.inp qsub.pbs $name2
      cd $name2
      sed -i "/EField/{s/.*/    EField 0,-$j,0/g}" $inf.inp
	  echo The $name1 and $name2 files have been established!
      cd ..
  done
else
 for((i=0;i<$n;i++))
    do
      j=$(echo "$ini+$nsize*$i" | bc | awk '{printf "%.4f", $0}')
      name1="${inf}_${ori}_${j}"
	  name2="${inf}_${ori}_-${j}"
      mkdir $name1
      cp $inf.inp qsub.pbs $name1
      cd $name1
      sed -i "/EField/{s/.*/    EField 0,0,$j/g}" $inf.inp
	  cd ..
	  mkdir $name2
      cp $inf.inp qsub.pbs $name2
      cd $name2
      sed -i "/EField/{s/.*/    EField 0,0,-$j/g}" $inf.inp
	  echo The $name1 and $name2 files have been established!
      cd ..
  done
fi

## whether to submit the tasks or not
echo
echo "-----------------------stage (5/5)---------------------------"
tasks=0
until [[ $tasks = "Y" || $tasks = "N" || $tasks = "y" || $tasks = "n" ]]
do
echo "Whether to submit batch tasks NOW? [Y/N]"; read tasks
done
if [[ $tasks = "Y" || $tasks = "y" ]]; then
  for a in $(ls -F | grep /)
  do
    cd $a
      for b in *.pbs
      do
      echo Running $b ...
      time qsub < $b 
      echo $b is finished
      echo
      done
    cd ..
  done
  echo
  echo "All the $allfiles tasks have been submitted"
else
  echo "The $allfiles tasks have NOT been submitted..."
  echo "You can submit tasks manually, Good Bye~"
  exit 0
fi
  




