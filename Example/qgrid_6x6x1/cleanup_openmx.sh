#!/bin/bash

# Script to run hamonic in TCM cluster
#attemp to move some files to directory supercell*

cd configurations
#mv *monserrat/Supercell_* .
no_sc=$(ls -1d Supercell_* | wc -l) #count the number of Supercell

# Loop over supercells
for i in `seq 1 $no_sc`;
do

  if [ -d Supercell_$i ];then
  cd Supercell_$i

  lines=$( awk 'END {print NR}' force_constants.${i}.dat ) #get the umber of lines

  # Loop over force constants
  for j in `seq 1 $lines`;
  do

    awk -v awk_line=$j 'NR==awk_line {print}' force_constants.${i}.dat > disp.dat
    atom=$(awk '{print $1}' disp.dat)
    disp=$(awk '{print $2}' disp.dat)
    cd atom.${atom}.disp.${disp}/positive/
    seedname=$(sed -n "2, 1p" runiput|awk '{print $3}') 
    cd ../../
    cp atom.${atom}.disp.${disp}/positive/$seedname.dat  atom.${atom}.disp.${disp}/positive/forces.dat ../../Supercell_${i}/atom.${atom}.disp.${disp}/positive
    cp atom.${atom}.disp.${disp}/negative/$seedname.dat  atom.${atom}.disp.${disp}/negative/forces.dat ../../Supercell_${i}/atom.${atom}.disp.${disp}/negative

  done

  cd ../
  fi

done

cd ../
#rm -r configurations

