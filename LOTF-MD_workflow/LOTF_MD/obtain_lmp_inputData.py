from pymatgen.io.lammps.data import LammpsData,structure_2_lmpdata
from pymatgen.core.structure import Structure

import shutil
import sys
import pymatgen as mg

from pymatgen.ext.matproj import MPRester
from pymatgen.io.vasp.sets import MPRelaxSet

structure=Structure.from_file("../AIMD/POSCAR")

l=structure_2_lmpdata(structure,atom_style="atomic")
l.write_file('start.inp')

