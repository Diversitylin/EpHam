#!/bin/bash
#
 #PBS -N TMD-ife
#PBS -l nodes=1:ppn=24
#####PBS -l Qlist=n24_96
#PBS -l walltime=1:00:00

cd $PBS_O_WORKDIR
cp $PBS_NODEFILE node
NCORE=`cat node | wc -l`
export OMP_NUM_THREADS=1 
PBS_JOBID=${PBS_JOBID%%.*}

stdbuf -oL getmem &> mem.$PBS_JOBID &

# Change version here according to the library used during compilation!!!
module load impi
module load intel

#grep LSCALAPACK INCAR | grep ".FALSE." || (echo "Warning! Please disable scalapack in INCAR." && exit 1)

date > output.$PBS_JOBID


declare -r CALC_DETAIL_LOG='Output.log'
#declare -r ENERGY_FACTOR=27.21138386 # Hatree -> eV
#declare -r HOP_PATH=$(readlink -f /home/linzz/apps)

  

### TideBird.openmx Generate ###
#cat openmx.scfout > Hop.openmx
#cat openmx.out >> Hop.openmx

### TideBird Run ### ${HOP_PATH}
cp $PBS_NODEFILE node
/home/linzz/apps/julia-1.4.2/bin/julia -p 24 \
      -e "@everywhere using Pkg;
          include(\"./selective_eta2e.jl\")" \
      >> ${CALC_DETAIL_LOG}
date >> output.$PBS_JOBID
