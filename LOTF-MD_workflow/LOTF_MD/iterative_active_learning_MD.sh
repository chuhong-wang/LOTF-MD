# User need to define 
# 1. VASP path, mlp path, LAMMPS path
# 2. training weight energy-force-stress, typical value --energy-weight=100 --force-weight=0.1 --stress-weight=0 for NVT MD 

set -x # print statements as they are executed

# define MD temperature, location of mlp, location of lmp_g++_serial, path to vasp
VASP_Dir="/soft/vasp/5.4.4/bdw/"


set -e  # activate exit if any command fails


## Load mlp compiler modules ##
# convert AIMD OUTCAR to MLIP input file format .cfg
mlp convert-cfg ../AIMD/OUTCAR train.cfg --input-format=vasp-outcar
# initial MTP training 
mpirun mlp train pot.mtp train.cfg --max-iter=100 --energy-weight=100 --force-weight=0.1 --stress-weight=1 --curr-pot-name=pot.mtp --trained-pot-name=pot.mtp

# set maximum training loop 
for i in {0..100}
 do
 ## Load mlp compiler modules ##
 # skip MTP training if first iteration 
 if [ "$i" -gt 0 ]; then
  mpirun mlp train pot.mtp train.cfg --max-iter=100 --energy-weight=100 --force-weight=0.1 --stress-weight=1 --curr-pot-name=pot.mtp --trained-pot-name=pot.mtp
 fi
 # prepare Jacobian matrix for later extrapolation grade computation
 mlp calc-grade pot.mtp train.cfg train.cfg temp.cfg 
 set +e   # deactivate exit if any command fails, because LAMMPS will fail when DFT re-training is triggered. 
 ## Load lmp_serial compiler modules ##
 lmp_g++_serial < input_lmp   # run LOTF-MD on LAMMPS
 set -e   # activate exit if any command fails

 ## Load lmp_serial compiler modules ##
 # LOTF-MD terminated by configuration extrapolation, select the extrapolated config for DFT run in VASP
 mlp select-add pot.mtp train.cfg selected.cfg diff.cfg --select-threshold=1.2  --als-filename=temp.als --selected-filename=active.cfg
 mlp convert-cfg diff.cfg POSCAR --output-format=vasp-poscar
  for j in POSCAR*
   do
   mkdir vasp/$j
   mv $j vasp/$j/POSCAR
   cp vasp/INCAR vasp/$j
   cp vasp/POTCAR vasp/$j
   cp vasp/KPOINTS vasp/$j
   cd vasp/$j
   #echo "run vasp"
   module restore
   mpirun $VASP_Dir/vasp_gam > vasp.out
   module load gcc/8.2.0-g7hppkz 
   mlp convert-cfg OUTCAR append.cfg --input-format=vasp-outcar
   cd ..
   mv $j ${i}_${j}
   cd ..
   done

  #append all new DFT to previous training set
  for j in vasp/*POSCAR*/append.cfg
   do
    cat $j >> train.cfg
   done
  rm vasp/*POSCAR*/append.cfg
 # remove the unconverged VASP run from train.cfg 
 mlp filter-nonconv train.cfg
 done
