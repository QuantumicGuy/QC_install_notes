#!/bin/bash

rel_cutoffs="20 30 40 50 60 70 80 90 100"

template_file=test.inp
input_file=SIL.inp

cutoff=250

for ii in $rel_cutoffs ; do
    work_dir=rel_cutoff_${ii}Ry
    if [[ ! -d $work_dir ]]; then
        mkdir $work_dir
    else
        rm -r $work_dir/*
    fi
    sed -e "s/LT_cutoff/${cutoff}/g" \
        -e "s/LT_rel_cutoff/${ii}/g" \
        $template_file > $work_dir/$input_file
done
