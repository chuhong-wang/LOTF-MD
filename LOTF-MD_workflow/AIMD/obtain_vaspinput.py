import shutil
import sys

from pymatgen.ext.matproj import MPRester
from pymatgen.io.vasp.sets import MPRelaxSet,MPMDSet,MITMDSet
from pymatgen import Structure

structure=Structure.from_file("POSCAR")

b=MPMDSet(structure,start_temp=1000,end_temp=1000,nsteps=7500,spin_polarized=structure.composition.contains_element_type("transition_metal"))
for para in ["ADDGRID","KBLOCK","NELM","LSCALU","NISM"]:b._config_dict["INCAR"].pop(para, None)
b._config_dict["INCAR"]['MAXMIX']=80
b._config_dict["INCAR"]['ENCUT']=400

b.incar.write_file('INCAR')
b.poscar.write_file('POSCAR')
b.kpoints.write_file('KPOINTS')
with open('POTCAR', 'wb') as outFile:
        for poscar_element in b.potcar_symbols:
                with open('/home/cwang122/data-tmuelle5/chuhong/PBE.5.2/'+poscar_element+'/POTCAR', 'rb') as com:
                        shutil.copyfileobj(com, outFile)
