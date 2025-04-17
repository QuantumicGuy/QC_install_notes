#PBS -N h2
#PBS -j eo
#PBS -q workq
#PBS -V
#PBS -l select=1:ncpus=28




export WORKDIR=/scratch/${PBS_JOBID}
echo $WORKDIR
echo $PBS_O_WORKDIR
echo $PBS_GPUFILE
mkdir -p $WORKDIR
cd $WORKDIR

###############################################################################


cp $PBS_O_WORKDIR/* ./ 


g16 h2.gjf  

###############################################################################

mv * $PBS_O_WORKDIR
rm -r $WORKDIR

