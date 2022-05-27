#!/bin/bash

# Script to convert a generic harmonic calculation to:
# CASTEP
# VASP 

echo "What code do you want to use (only for openmx)?"
read code


if [ "$code" = "openmx" ]; then

  if [ ! -d "openmx" ];then
    echo "Error! The directory 'openmx' does not exist." 
    exit 1
  fi 
  echo "What is the openmx seedname?"
  read seedname

  mkdir configurations
  cp openmx/* configurations

  no_sc=$(awk '{print}' no_sc.dat ) #read the value of no_sc

  # Loop over 
  for (( i=1; i<=$no_sc; i++ )) do

    cd Supercell_$i

    echo "Converting supercell" $i

    cp force_constants.dat  ../configurations/force_constants.${i}.dat

  

    while read LINE ; do  #read line by line from the file force_constants.dat
      echo $LINE > disp.dat #inset LINE to disp.dat
      atom=$(awk '{print $1}' disp.dat) #the first value
      disp=$(awk '{print $2}' disp.dat) #the second value
      cd atom.${atom}.disp.${disp} 
      cd positive
      cp ../../../openmx/* .

      sed -n '/<Atoms.UnitVectors/,$p' $seedname.dat |head -4 > lattice.dat
      sed -i '1d' lattice.dat

      #rewrite the atom number
      n=`grep "Species.Number" $seedname.dat |  awk '{printf "%1d \n", $2}'` #get Species.Number
      n1=`grep "Atoms.Number" $seedname.dat |  awk '{printf "%1d \n", $2}'` #get Atoms.Number
      l1=$(sed -n '/Atoms/=' structure.dat |sed -n "1"p)
      l2=$(sed -n '/Symmetry/=' structure.dat |sed -n "1"p)
      N=$(($l2-$l1-1))
      k1=`grep "Atoms.Number" $seedname.dat | head -1 | awk '{printf "%1d \n", $2}'`
      cat $seedname.dat |grep "Atoms.Number">temp
      awk  '{$NF="";print}' temp >temp2
      sed -i "s/$/$N/" temp2
      sed -i '/Atoms.Number/ r temp2' $seedname.dat
      sed -i '/Atoms.Number    /,+0d' $seedname.dat
      rm temp*


      #for OPlattice
      sed 1d structure.dat |head -3|while read LINE;do
      echo $LINE >> temp.dat;done
      awk  '{for(j=1;j<=NF;j+=3)  printf("%12.9f %12.9f %12.9f\n",$j*0.52917721092,$(j+1)*0.52917721092,$(j+2)*0.52917721092) }'  temp.dat >> OPlattice
      rm temp.dat

      #for OPcell
    
      for((j=1;j<=$n;j++));do
      sed -n '/<Definition.of.Atomic.Species/,$p' $seedname.dat |head -$(($j+1)) > temp1
      sed -n '$p' temp1 >temp2
      atom[$j]=$(awk '{print $1}' temp2) 
      rm temp*
      done #${atom[$i]} represent the names of species now

      
      sed 1,5d structure.dat |head -${N}|while read LINE; do  echo $LINE >> temp.dat;done
      awk '{print $1,$3, $4, $5}' temp.dat > temp2
      awk  '{for(j=1;j<=NF;j+=4) printf("%s %12.9f %12.9f %12.9f\n",$j,$(j+1)*0.52917721092,$(j+2)*0.52917721092,$(j+3)*0.52917721092)}'  temp2 >> OPcell
      rm temp*
      for((j=1;j<=$n;j++));do
      sed -n '/<Atoms.SpeciesAndCoordinates/,$p' $seedname.dat |head -$(($N+1))|grep " ${atom[$j]} " |head -1|awk '{printf "%1.1f %1.1f \n",$(NF-1),$NF}' >temp[$j]
      #echo $(awk '{print $1}' temp[$i])
      x[$j]=$(awk '{print $1,$2}' temp[$j])
      #echo ${x[$j]}
      grep "${atom[$j]}" OPcell |sed "s/$/ ${x[$j]}/" >> temp
      done
      mv temp OPcell
      rm temp*
      awk '{printf("%d %s\n",NR,$0)}' OPcell > temp
      mv temp OPcell


      x=$(sed -n '/<Atoms.UnitVectors/=' $seedname.dat |sed -n "1"p)
      sed  $(($x+1)),$(($x+3))d $seedname.dat >temp1
      sed -i '/<Atoms.UnitVectors/ r OPlattice' temp1

      x=$(sed -n '/<Atoms.SpeciesAndCoordinates/=' temp1 |sed -n "1"p)
      sed  $(($x+1)),$(($x+$n1))d temp1 >temp2
      sed -i '/<Atoms.SpeciesAndCoordinates/ r OPcell' temp2
      cp temp2 $seedname.dat 
      rm temp*

      #rrewrite k points
      k1=`grep "scf.Kgrid" $seedname.dat | tail -1 | awk '{printf "%1d \n", $2}'`
      k2=`grep "scf.Kgrid" $seedname.dat | tail -1 | awk '{printf "%1d \n", $3}'`
      k3=`grep "scf.Kgrid" $seedname.dat | tail -1 | awk '{printf "%1d \n", $4}'`
      
      cat > KPOINTS  <<! 
      Automatic generation
      0
      Gamma
      $k1 $k2 $k3
      0  0  0
!
      
      sed -n '/<Atoms.UnitVectors/,$p' $seedname.dat |head -4 > super_lattice.dat
      sed -i '1d' super_lattice.dat
      generate_supercell_kpoint_mesh
      sk1=$(awk '{print $1}' sc_kpoints.dat)
      sk2=$(awk '{print $2}' sc_kpoints.dat)
      sk3=$(awk '{print $3}' sc_kpoints.dat)
      sed -i "/scf.Kgrid/c scf.Kgrid  ${sk1} ${sk2} ${sk3} " $seedname.dat
      sed -i "/Atoms.SpeciesAndCoordinates.Unit/c Atoms.SpeciesAndCoordinates.Unit  Ang " $seedname.dat





      mv $seedname.dat ../../../configurations/$seedname.dat.${i}.${atom}.${disp}.positive
      cp displacement.dat ../../../configurations/displacement.${i}.${atom}.${disp}.positive
      cp structure.dat ../../../configurations/structure.${i}.${atom}.${disp}.positive
      
      
      cd ../



      cd negative
      cp ../../../openmx/* .
      sed -n '/<Atoms.UnitVectors/,$p' $seedname.dat |head -4 > lattice.dat
      sed -i '1d' lattice.dat

      #rewrite the atom number
      n=`grep "Species.Number" $seedname.dat |  awk '{printf "%1d \n", $2}'` #get Species.Number
      n1=`grep "Atoms.Number" $seedname.dat |  awk '{printf "%1d \n", $2}'` #get Atoms.Number
      l1=$(sed -n '/Atoms/=' structure.dat |sed -n "1"p)
      l2=$(sed -n '/Symmetry/=' structure.dat |sed -n "1"p)
      N=$(($l2-$l1-1))
      k1=`grep "Atoms.Number" $seedname.dat | head -1 | awk '{printf "%1d \n", $2}'`
      cat $seedname.dat |grep "Atoms.Number">temp
      awk  '{$NF="";print}' temp >temp2
      sed -i "s/$/$N/" temp2
      sed -i '/Atoms.Number/,+0d' $seedname.dat
      sed -i '/Atoms.SpeciesAndCoordinates.Unit/{h;s/.*/cat temp2/e;G}' $seedname.dat 
      rm temp*


      #for OPlattice
      sed 1d structure.dat |head -3|while read LINE;do
      echo $LINE >> temp.dat;done
      awk  '{for(j=1;j<=NF;j+=3)  printf("%12.9f %12.9f %12.9f\n",$j*0.52917721092,$(j+1)*0.52917721092,$(j+2)*0.52917721092) }'  temp.dat >> OPlattice
      rm temp.dat

      #for OPcell
    
      for((j=1;j<=$n;j++));do
      sed -n '/<Definition.of.Atomic.Species/,$p' $seedname.dat |head -$(($j+1)) > temp1
      sed -n '$p' temp1 >temp2
      atom[$j]=$(awk '{print $1}' temp2) 
      #echo ${atom[$i]}
      rm temp*
      done #${atom[$i]} represent the names of species now

      
      sed 1,5d structure.dat |head -${N}|while read LINE; do  echo $LINE >> temp.dat;done
      awk '{print $1,$3, $4, $5}' temp.dat > temp2
      awk  '{for(j=1;j<=NF;j+=4) printf("%s %12.9f %12.9f %12.9f\n",$j,$(j+1)*0.52917721092,$(j+2)*0.52917721092,$(j+3)*0.52917721092)}'  temp2 >> OPcell
      rm temp*
      for((j=1;j<=$n;j++));do
      sed -n '/<Atoms.SpeciesAndCoordinates/,$p' $seedname.dat |head -$(($N+1))|grep " ${atom[$j]} " |head -1|awk '{printf "%1.1f %1.1f \n",$(NF-1),$NF}' >temp[$j]
      #echo $(awk '{print $1}' temp[$i])
      x[$j]=$(awk '{print $1,$2}' temp[$j])
      #echo ${x[$j]}
      grep "${atom[$j]}" OPcell |sed "s/$/ ${x[$j]}/" >> temp
      done
      mv temp OPcell
      rm temp*
      awk '{printf("%d %s\n",NR,$0)}' OPcell > temp
      mv temp OPcell


      x=$(sed -n '/<Atoms.UnitVectors/=' $seedname.dat |sed -n "1"p)
      sed  $(($x+1)),$(($x+3))d $seedname.dat >temp1
      sed -i '/<Atoms.UnitVectors/ r OPlattice' temp1

      x=$(sed -n '/<Atoms.SpeciesAndCoordinates/=' temp1 |sed -n "1"p)
      sed  $(($x+1)),$(($x+$n1))d temp1 >temp2
      sed -i '/<Atoms.SpeciesAndCoordinates/ r OPcell' temp2
      cp temp2 $seedname.dat 
      rm temp*

            #rrewrite k points
      k1=`grep "scf.Kgrid" $seedname.dat | tail -1 | awk '{printf "%1d \n", $2}'`
      k2=`grep "scf.Kgrid" $seedname.dat | tail -1 | awk '{printf "%1d \n", $3}'`
      k3=`grep "scf.Kgrid" $seedname.dat | tail -1 | awk '{printf "%1d \n", $4}'`
      
      cat > KPOINTS  <<! 
      Automatic generation
      0
      Gamma
      $k1 $k2 $k3
      0  0  0
!
      
      sed -n '/<Atoms.UnitVectors/,$p' $seedname.dat |head -4 > super_lattice.dat
      sed -i '1d' super_lattice.dat
      generate_supercell_kpoint_mesh
      sk1=$(awk '{print $1}' sc_kpoints.dat)
      sk2=$(awk '{print $2}' sc_kpoints.dat)
      sk3=$(awk '{print $3}' sc_kpoints.dat)
      sed -i "/scf.Kgrid/c scf.Kgrid  ${sk1} ${sk2} ${sk3} " $seedname.dat
      sed -i "/Atoms.SpeciesAndCoordinates.Unit/c Atoms.SpeciesAndCoordinates.Unit  Ang " $seedname.dat

      mv $seedname.dat  ../../../configurations/$seedname.dat.${i}.${atom}.${disp}.negative
      cp displacement.dat ../../../configurations/displacement.${i}.${atom}.${disp}.negative
      cp structure.dat ../../../configurations/structure.${i}.${atom}.${disp}.negative
      cd ../

      cd ../ 

    done < force_constants.dat


    cd ../

  done
  echo "Done."


else 

  echo "Error! This code is not supported."

fi
