#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 5
export g16root=/public1/home/shixueliang/software
export PATH=$g16root:$PATH
source $g16root/g16/bsd/g16.profile
export GAUSS_SCRDIR=/public1/home/shixueliang/software/g16/scratch
export GAUSS_EXEDIR=$g16root
srun -c 10 g16 $1
