#PBS -N 300
#PBS -j eo
#PBS -q workq
#PBS -l select=1:ncpus=28

export AMBERHOME=/share/home/ylcong/apps/amber/amber18/amber18
source ${AMBERHOME}/amber.sh


export WORKDIR=/scratch/${PBS_JOBID}
echo 'WORKDIR:', $WORKDIR

echo 'PBS_O_WORKDIR:', $PBS_O_WORKDIR

mkdir $WORKDIR
cd $WORKDIR

###############################################################################

cp $PBS_O_WORKDIR/*  . -f
g16 <300.gjf> 300.out

###############################################################################

cp $WORKDIR/* $PBS_O_WORKDIR/ -rf
rm  $WORKDIR -rf

