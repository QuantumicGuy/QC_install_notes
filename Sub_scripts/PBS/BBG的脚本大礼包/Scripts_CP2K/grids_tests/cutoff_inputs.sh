#!/bin/bash

cutoffs="200 250 300 350 400 450 500 550 600"

template_file=test.inp
input_file=SIL.inp

rel_cutoff=60

for ii in $cutoffs ; do
    work_dir=cutoff_${ii}Ry
    if [[ ! -d $work_dir ]] ; then
        mkdir $work_dir
    else
        rm -r $work_dir/*
    fi
    sed -e "s/LT_rel_cutoff/${rel_cutoff}/g" \
        -e "s/LT_cutoff/${ii}/g" \
        $template_file > $work_dir/$input_file
done
