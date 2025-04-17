#!/bin/bash
#SBATCH -N 1
#SBATCH -n 128
#SBATCH -p amd_256
source /public1/soft/modules/module.sh 
module load orca/5.0.1-shared-openmpi-4.1.1
export PATH=$PATH:/public1/soft/orca/5.0.1
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/public1/soft/orca/5.0.1
/public1/soft/orca/5.0.1/orca xxx.inp > xxx.out
