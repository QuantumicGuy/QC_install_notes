#!/bin/bash

hv_sum=$(grep "f  =" OUTCAR | awk '{print $10}'| paste -sd+ | bc)
printf "ZPE = %.6f eV\n" $(echo "scale=6;$hv_sum/2000"| bc)
im_freq_sum=$(grep "f/i=" OUTCAR | wc -l)
if [[ $im_freq_sum != 0 ]];then
    printf "\n## Warning:  %3d imaginary frequencies were detected in the OUTCAR file:\n" $im_freq_sum
	grep "f/i=" OUTCAR
	im_freq_max=$(grep "f/i=" OUTCAR | awk 'END{print $7}')
	im_freq_min=$(grep "f/i=" OUTCAR | awk 'NR==1{print $7}')
	printf "\n --> The maximum imaginary frequency:  %15s cm-1" $im_freq_max
	printf "\n --> The minimum imaginary frequency:  %15s cm-1\n" $im_freq_min
fi
