#!/bin/sh -x
#PBS -N test
#PBS -l nodes=1:ppn=24
#PBS -q hpc001
#PBS -j oe

### Modify the Gaussian gjf file name here! ###

GJF="test.gjf"

####################

export GAUSS_SCRDIR=/home/feng/temp
export g09root=/opt/gaussian

. $g09root/g09/bsd/g09.profile

cd $PBS_O_WORKDIR

JOBNAME='basename "$GJF" .gjf'
$g09root/g09/g09 <$GJF> "$JOBNAME.log"