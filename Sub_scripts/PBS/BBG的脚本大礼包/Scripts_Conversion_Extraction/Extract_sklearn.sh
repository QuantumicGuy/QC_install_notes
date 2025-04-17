#!/bin/bash
function travel_dir(){
file_counter=0
folder_counter=0
echo
echo "~~~~ Ready to travel all subdirectories in the path below ~~~~"
echo $(pwd)
for dir in $(ls -R | grep :| tr : " ")
do
  cd $dir
  if ls *.$inp_extension 1> /dev/null 2>&1;then
    serial=1
    let folder_counter++
	echo
    echo "*** No.$folder_counter folder *** >>> Entered" $dir
	echo "      V V V V"
	for file in *.$inp_extension
	do
	  echo "[$serial] Loading $file file..."
	  let file_counter++
	  let serial++
	  extr_skl
	done
  fi
  cd $initial_path
done
echo
echo "~~~~ Returned to the initial path... ~~~~"
echo $initial_path
echo
echo "######  Scikit-learn outputs in total $file_counter/$nfiles *.$inp_extension files have been successfully extracted  ######"
}

function extr_skl(){
if grep -wq "Scikit-learn script" $file && grep -wq "Elapsed time:" $file;then
  echo "    ==> The result has been extracted from $file! [$file_counter of $nfiles]"
  if [[ $choice == "r" ]];then 
    best_score=$(grep "Best CV score:" $file | awk 'END{printf $5}')
    MAE_training=$(grep "Mean absolute error (MAE) on the training set:" $file | awk 'END{printf $10}')
	MAE_test=$(grep "Mean absolute error (MAE) on the test set:" $file | awk 'END{printf $10}')
	R2_training=$(grep "R-squared (R^2) value on the training set:" $file | awk 'END{printf $9}')
	R2_test=$(grep "R-squared (R^2) value on the test set:" $file | awk 'END{printf $9}')

    printf "%-8s %-50s %15s %15s %15s %15s %15s\n" $file_counter ${file%.$inp_extension} $best_score $MAE_training $MAE_test $R2_training $R2_test >> $initial_path/Extract_sklearn_results.txt
    echo "        No.$file_counter:    Name: ${file%.$inp_extension}     Best CV Score= $best_score"
    echo "        MAE(training)= $MAE_training    MAE(test)= $MAE_test     R^2(training)= $R2_training     R^2(test)= $R2_test"	
  elif [[ $choice == "c" ]];then
    best_score=$(grep "Best CV score:" $file | awk 'END{printf $5}')
    acc_training=$(grep "Accuracy on the training set:" $file | awk 'END{printf $7}')
	acc_test=$(grep "Accuracy on the test set:" $file | awk 'END{printf $7}')
	score_training=$(grep "Score on the training set:" $file | awk 'END{printf $7}')
	score_test=$(grep "Score on the test set:" $file | awk 'END{printf $7}')
  
    printf "%-8s %-50s %15s %15s %15s %15s %15s\n" $file_counter ${file%.$inp_extension} $best_score $acc_training $acc_test $score_training $score_test >> $initial_path/Extract_sklearn_results.txt
    echo "        No.$file_counter:    Name: ${file%.$inp_extension}     Best CV Score= $best_score"
    echo "        Acc.(training)= $acc_training    Acc.(test)= $acc_test     Score(training)= $score_training     Score(test)= $score_test"	
  fi
	
else
  echo "    --> The $file file doesn't contain scikit-learn outputs! Skipping..."
  printf "%-8s %-50s %15s %15s %15s %15s %15s\n" "X" ${file%.$inp_extension} "N/A" "N/A" "N/A" "N/A" "N/A" >> $initial_path/Extract_sklearn_results.txt
  let file_counter--
fi  
}

echo
echo "************* Extract results from scikit-learn output files **************"
echo
echo "Please input the extention of scikit-learn output files [out/log]:"
read inp_extension
initial_path=$(pwd)
nfiles=$(find -name "*.$inp_extension" | wc -l)
echo "Please input task type: Regression(r) / Classification(c)? [r/c]:"
array_choice=(r c)
read choice
while ! echo "${array_choice[@]}" | grep -wq "$choice" 
do
  echo "Please reinput the choice [r/c]..."
  read choice
done
if [[ $choice == "r" ]];then
  printf "%-8s %-50s %15s %15s %15s %15s %15s\n" "No." "NAME" "Best CV Score" "MAE(training)" "MAE(test)" "R^2(training)" "R^2(test)" > Extract_sklearn_results.txt
elif [[ $choice == "c" ]];then
  printf "%-8s %-50s %15s %15s %15s %15s %15s\n" "No." "NAME" "Best CV Score" "Acc.(training)" "Acc.(test)" "Score(training)" "Score(test)" > Extract_sklearn_results.txt
fi
travel_dir



