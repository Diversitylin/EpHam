#!/bin/bash

# Script to calculate quadratic band gap correction

#######################################
####        MAIN   PROGRAM         ####
#######################################


no_sc=$(ls -1d Supercell_* | wc -l)
seedname=$(sed -n "1, 1p" runinput|awk '{print $1}')
sampling_point_init=$( awk 'NR==2 {print $1}' mapping.dat)
sampling_point_final=$( awk 'NR==2 {print $2}' mapping.dat)

mkdir scfout
cp mapping.dat scfout
sed 's/[ ] [ ]*/ /g' ibz.dat > scfout/ibz.dat
cd scfout
sed -i 's/^ *//' ibz.dat
cd ..



# Loop over supercells
kpoint_counter=1
for i in `seq 1 $no_sc`;do

  cd Supercell_$i



  # Collect quadratic results
  no_kpoints=$(ls -1d kpoint.* | wc -l)
  no_atoms=$(awk 'NR==1 {print}' equilibrium.dat)
  no_modes=$(( $no_atoms*3 ))
  no_atoms_sc=$(awk 'NR==1 {print}' super_equilibrium.dat)
  sc_size=$(( $(( $no_atoms_sc/$no_atoms )) | bc ))

    # Loop over k-points
  for j in `seq $kpoint_counter $(( $kpoint_counter+($no_kpoints-1) ))`; do

    cd static
    cat $seedname.out >> $seedname.scfout
    ln $seedname.scfout ../../scfout/MoSe2_$j.0.scfout

    echo $j $sc_size >> ../../scfout/no_atoms.txt

    kx=$(sed -n "2, 1p" KPOINTS.band|awk '{print $1}')
    ky=$(sed -n "2, 1p" KPOINTS.band|awk '{print $2}')
    echo $j $kx $ky >> ../../scfout/k_vector.txt

    cd ../

    cd kpoint.${j}
    cp frequency.*.dat ../../scfout/
    cd configurations

    for k in `seq 1 $no_modes`; do
      for l in `seq $sampling_point_init $sampling_point_final`; do
        if [ -e "mode.${k}.${l}" ]; then
          cd mode.${k}.${l}
          cat $seedname.out >> $seedname.scfout
          ln $seedname.scfout ../../../../scfout/MoSe2_${j}.${k}.${l}.scfout

          cd ../
        fi
      done
    done

    cd ../../
  done # Loop over k-points
  kpoint_counter=$(( $kpoint_counter+$no_kpoints ))
  cd ../

done
