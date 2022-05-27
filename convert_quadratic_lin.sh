#!/bin/bash

# Script to convert a generic quadratic calculation to:
# CASTEP
# VASP 

echo "What code do you want to use (only openmx)?"
read code

###for openmx
if [ "$code" = "openmx" ]; then

  if [ ! -d "openmx" ];then
    echo "Error! The directory 'openmx' does not exist." 
    exit 1
  fi 
  echo "What is the openmx seedname?"
  read seedname

  sampling_point_init=$( awk 'NR==2 {print $1}' mapping.dat)
  sampling_point_final=$( awk 'NR==2 {print $2}' mapping.dat)

  
  # Loop over supercells
  no_sc=$(ls -1d Supercell_* | wc -l)
  echo $no_sc
  kpoint_counter=1
  for (( i=1; i<=$no_sc; i++ )) do

    cd Supercell_$i

    echo "Converting supercell" $i

    no_atoms=$( awk 'NR==1 {print $1}' equilibrium.dat )
    no_modes=$(( $no_atoms*3 ))

    cd static
    cp ../../openmx/* .
    if [ -e "../../openmx/bs_path.dat" ];then
      cp ../../openmx/bs_path.dat .
    fi
    cp ../*lattice.dat .
    cp ../supercell.dat .
      # Generate supercell kpoint mesh for openmx
    if [ -e "../../openmx/$seedname.dat" ];then
        
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
        
      generate_supercell_kpoint_mesh
      sk1=$(awk '{print $1}' sc_kpoints.dat)
      sk2=$(awk '{print $2}' sc_kpoints.dat)
      sk3=$(awk '{print $3}' sc_kpoints.dat)
      sed -i "/scf.Kgrid/c scf.Kgrid  ${sk1} ${sk2} ${sk3} " $seedname.dat 

      cp $seedname.dat $seedname.dat.0
    fi

    if [ -e "bs_path.dat" ];then
        generate_sc_path
        cp sc_bs_path.dat KPOINTS.band

        x=$(sed -n '/<Band.kpath/=' $seedname.dat |sed -n "1"p)
        sed -i  $(($x+1)),$(($x+1))d $seedname.dat 

        echo `cat KPOINTS.band` >temp1
        sed -i 's/^/2 /'  temp1
        sed -i 's/$/ X Y/' temp1
        sed -i '/<Band.kpath/ r  temp1' $seedname.dat
        rm temp1
    fi
      
    rm lattice.dat super_lattice.dat
    # Generate supercell position coordinates for openmx
    
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
    awk  '{for(z=1;z<=NF;z+=3)  printf("%12.9f %12.9f %12.9f\n",$z*0.52917721092,$(z+1)*0.52917721092,$(z+2)*0.52917721092) }'  temp.dat >> OPlattice
    rm temp.dat

    #for OPcell
    
    for((z=1;z<=$n;z++));do
    sed -n '/<Definition.of.Atomic.Species/,$p' $seedname.dat |head -$(($z+1)) > temp1
    sed -n '$p' temp1 >temp2
    atom[$z]=$(awk '{print $1}' temp2) 
    rm temp*
    done #${atom[$i]} represent the names of species now

      
    sed 1,5d structure.dat |head -${N}|while read LINE; do  echo $LINE >> temp.dat;done
    awk '{print $1,$3, $4, $5}' temp.dat > temp2
    awk  '{for(z=1;z<=NF;z+=4) printf("%s %12.9f %12.9f %12.9f\n",$z,$(z+1)*0.52917721092,$(z+2)*0.52917721092,$(z+3)*0.52917721092)}'  temp2 >> OPcell
    rm temp*
    for((z=1;z<=$n;z++));do
    sed -n '/<Atoms.SpeciesAndCoordinates/,$p' $seedname.dat |head -$(($N+1))|grep " ${atom[$z]} " |head -1|awk '{printf "%1.1f %1.1f \n",$(NF-1),$NF}' >temp[$z]
    #echo $(awk '{print $1}' temp[$i])
    x[$z]=$(awk '{print $1,$2}' temp[$z])
    #echo ${x[$j]}
    grep "${atom[$z]}" OPcell |sed "s/$/ ${x[$z]}/" >> temp
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
    sed -i "/Atoms.SpeciesAndCoordinates.Unit/c Atoms.SpeciesAndCoordinates.Unit  Ang " $seedname.dat
    rm temp*
    mv $seedname.dat $seedname.dat.0
    rm OP*

    cd ..

    # Loop over k-points
    no_kpoints=$(ls -1d kpoint.* | wc -l)
    for (( j=$kpoint_counter; j<=$(( $kpoint_counter+($no_kpoints-1) )); j++ )) do
      cd kpoint.$j
      cd configurations
      cp ../mapping.dat ../../equilibrium.dat .
      cp ../../../openmx/* .
      cp ../../*lattice.dat .
      cp ../../supercell.dat .
      
      if [ -e "../../static/KPOINTS" ];then
        cp ../../static/KPOINTS* .
      fi
      generate_supercell_kpoint_mesh
      sk1=$(awk '{print $1}' sc_kpoints.dat)
      sk2=$(awk '{print $2}' sc_kpoints.dat)
      sk3=$(awk '{print $3}' sc_kpoints.dat)
      sed -i "/scf.Kgrid/c scf.Kgrid  ${sk1} ${sk2} ${sk3} " $seedname.dat 
      

      if [ -e "../../static/bs_path.dat" ];then
      cp ../../static/bs_path.dat .
      generate_sc_path
      cp sc_bs_path.dat KPOINTS.band

      x=$(sed -n '/<Band.kpath/=' $seedname.dat |sed -n "1"p)
      sed -i  $(($x+1)),$(($x+1))d $seedname.dat 

      echo `cat KPOINTS.band` >temp1
      sed -i 's/^/2 /'  temp1
      sed -i 's/$/ X Y/' temp1
      sed -i '/<Band.kpath/ r  temp1' $seedname.dat
      rm temp1
    fi

      cp $seedname.dat $seedname.dat.0
     
      # Loop over number of modes
      for (( k=1; k<=$no_modes; k++ )) do
 
        for l in `seq $sampling_point_init $sampling_point_final`; do

          if [ -e "structure.${k}.${l}.dat" ];then
            cp structure.${k}.${l}.dat structure.dat
            cp $seedname.dat.0 $seedname.dat
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
            awk  '{for(z=1;z<=NF;z+=3)  printf("%12.9f %12.9f %12.9f\n",$z*0.52917721092,$(z+1)*0.52917721092,$(z+2)*0.52917721092) }'  temp.dat >> OPlattice
            rm temp.dat

            #for OPcell
    
            for((z=1;z<=$n;z++));do
            sed -n '/<Definition.of.Atomic.Species/,$p' $seedname.dat |head -$(($z+1)) > temp1
            sed -n '$p' temp1 >temp2
            atom[$z]=$(awk '{print $1}' temp2) 
            rm temp*
            done #${atom[$i]} represent the names of species now

      
            sed 1,5d structure.dat |head -${N}|while read LINE; do  echo $LINE >> temp.dat;done
            awk '{print $1,$3, $4, $5}' temp.dat > temp2
            awk  '{for(z=1;z<=NF;z+=4) printf("%s %12.9f %12.9f %12.9f\n",$z,$(z+1)*0.52917721092,$(z+2)*0.52917721092,$(z+3)*0.52917721092)}'  temp2 >> OPcell
            rm temp*
            for((z=1;z<=$n;z++));do
            sed -n '/<Atoms.SpeciesAndCoordinates/,$p' $seedname.dat |head -$(($N+1))|grep " ${atom[$z]} " |head -1|awk '{printf "%1.1f %1.1f \n",$(NF-1),$NF}' >temp[$z]
            #echo $(awk '{print $1}' temp[$i])
            x[$z]=$(awk '{print $1,$2}' temp[$z])
            #echo ${x[$j]}
            grep "${atom[$z]}" OPcell |sed "s/$/ ${x[$z]}/" >> temp
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
            sed -i "/Atoms.SpeciesAndCoordinates.Unit/c Atoms.SpeciesAndCoordinates.Unit  Ang " $seedname.dat
            rm temp*
            mv $seedname.dat $seedname.dat.${k}.${l}
            rm OP*
          fi
        
        done # Loop over sampling points

      done # Loop over modes
      
      cd ../
      cd ../

    done # Loop over k-points
    kpoint_counter=$(( $kpoint_counter+$no_kpoints ))
    
    cd ../

  done # Loop over supercells
    
fi
