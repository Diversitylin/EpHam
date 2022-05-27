#!/bin/bash
  #PBS -N example
  #PBS -l nodes=1:ppn=24
  #PBS -l walltime=96:00:00

################## DO NOT MODIFY THE LINE BELOW
       if [ "x$1" == "xcore" ]; then
         export PBS_O_WORKDIR="$PWD"
         export NCPUS=$2
         export PBS_JOBID=$3
         export PBS_NODEFILE="$4"
################## END

  # Load modules required by your program
  module load impi/19u5
  module load mkl/19u5

  # Log start timestamp
  date > output.$PBS_JOBID
  # Change it to your own MPI program

  
# Script to run hamonic in w003
  cp openmx/* .
  first_sc=$(sed -n "2, 1p" runiput|awk '{print $1}')
  last_sc=$(sed -n "2, 1p" runiput|awk '{print $2}')
  seedname=$(sed -n "2, 1p" runiput|awk '{print $3}')

  #first_sc=5
  #last_sc=5

  cd configurations

  # Loop over supercells
  for i in `seq $first_sc $last_sc`;
  do

    mkdir Supercell_${i}
    lines=$( awk 'END {print NR}' force_constants.${i}.dat )
    cp force_constants.${i}.dat Supercell_${i}
    cd Supercell_${i}

    # Loop over force constants
    for j in `seq 1 $lines`;
    do

      awk -v awk_line=$j 'NR==awk_line {print}' force_constants.${i}.dat > disp.dat #store first line of  force_constants.${i}.dat
      atom=$(awk '{print $1}' disp.dat) 
      disp=$(awk '{print $2}' disp.dat)
      mkdir atom.${atom}.disp.${disp}
      mkdir atom.${atom}.disp.${disp}/positive atom.${atom}.disp.${disp}/negative
      mv ../$seedname.dat.${i}.${atom}.${disp}.positive atom.${atom}.disp.${disp}/positive/$seedname.dat
      mv ../$seedname.dat.${i}.${atom}.${disp}.negative atom.${atom}.disp.${disp}/negative/$seedname.dat
      mv ../displacement.${i}.${atom}.${disp}.positive atom.${atom}.disp.${disp}/positive/displacement.dat
      mv ../displacement.${i}.${atom}.${disp}.negative atom.${atom}.disp.${disp}/negative/displacement.dat
      mv ../structure.${i}.${atom}.${disp}.positive atom.${atom}.disp.${disp}/positive/structure.dat
      mv ../structure.${i}.${atom}.${disp}.negative atom.${atom}.disp.${disp}/negative/structure.dat
      cd atom.${atom}.disp.${disp}/positive
      cp ../../../../runiput .
      if [ ! -e "finished.txt" ];then
        if [ ! -e "$seedname.out" ];then
          node-balancer 24 $PBS_NODEFILE > node
          mpirun -machinefile node -np $NCPUS /home/zhaol/bin/openmx-3.8 $seedname.dat > met.std
          rm -rf *cube  *rst 
          fetch_forces_openmx.sh
          echo "finished" > finished.txt
        fi
      fi
      cd ../../
      cd atom.${atom}.disp.${disp}/negative
      cp ../../../../runiput .
      if [ ! -e "finished.txt" ];then
        if [ ! -e "$seedname.out" ];then
          node-balancer 24 $PBS_NODEFILE > node
          mpirun -machinefile node -np $NCPUS /home/zhaol/bin/openmx-3.8 $seedname.dat > met.std
          rm -rf *cube  *rst
          fetch_forces_openmx.sh
          echo "finished" > finished.txt
        fi
      fi
      cd ../../

    done
    cd ../

  done


  cd ../ # configurations

date >> output.$PBS_JOBID
################## DO NOT MODIFY LINES BELOW
    else
        NCPUS=$(cat $PBS_NODEFILE | wc -l)
        PBS_JOBID=${PBS_JOBID%%.*}
        ssh `hostname` $"cd \"$PBS_O_WORKDIR\";bash $0 core $NCPUS $PBS_JOBID \"$PBS_NODEFILE\""
    fi


