#!/bin/bash
  #PBS -N diamond
  #PBS -l nodes=1:ppn=24
  #PBS -l walltime=48:00:00

  module load intel/19u5

  ulimit -Ss unlimited
  cd $PBS_O_WORKDIR
  cp $PBS_NODEFILE node
  NCORE=`cat node | wc -l`
  date > output.$PBS_JOBID
  export P4_RSHCOMMAND=/opt/pbs/default/bin/pbs_remsh

  seedname=$(sed -n "1, 1p" runinput|awk '{print $1}')
  no_sc=$(ls -1d Supercell_* | wc -l) #number of supercells
  kpoint_counter=1
  # Loop over static supercells
  for m in `seq 1 $no_sc`;do
    cd Supercell_$m/static
    /home/apps/node-balancer 24 $PBS_NODEFILE > node
    mv $seedname.dat.0 $seedname.dat
	mpirun -machinefile node -np $NCORE /home/zhaol/bin/openmx-3.8 $seedname.dat > met.std
        rm -rf *cube *rst
        
    # Loop over k-points
    cd ..
    no_kpoints=$(ls -1d kpoint.* | wc -l)
    for (( n=$kpoint_counter; n<=$(( $kpoint_counter+($no_kpoints-1) )); n++ )) do
        cd kpoint.$n/configurations
        sampling_point_init=$( awk 'NR==2 {print $1}' mapping.dat)
        sampling_point_final=$( awk 'NR==2 {print $2}' mapping.dat)
        no_atoms=$( awk 'NR==1 {print $1}' equilibrium.dat )
        no_modes=$(( $no_atoms*3 ))

        # Loop over modes
        for i in `seq 1 $no_modes`; do
            for j in `seq $sampling_point_init $sampling_point_final`; do
                if [ -e "$seedname.dat.${i}.${j}" ];then
                    mkdir mode.${i}.${j}
                    mv $seedname.dat.${i}.${j} mode.${i}.${j}/$seedname.dat
                    cd mode.${i}.${j}

                    # Edit this lines:
                    /home/apps/node-balancer 24 $PBS_NODEFILE > node
	                mpirun -machinefile node -np $NCORE /home/zhaol/bin/openmx-3.8 $seedname.dat > met.std
                    rm -rf *cube *rst
      
                    cd ../
                fi
            done
        done
        cd ../../
    done # Loop over k-points
    kpoint_counter=$(( $kpoint_counter+$no_kpoints ))
    cd ../
 done
 


