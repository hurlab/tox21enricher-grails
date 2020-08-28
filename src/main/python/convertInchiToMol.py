#!/home/hurlab/anaconda3/envs/my-rdkit-env/bin/python3.6

# Python script that uses rdkit module to retrieve a molecule from an Inchi ID

from rdkit import Chem
import sys
print(Chem.rdmolfiles.MolToSmiles(Chem.MolFromInchi(sys.argv[1],True,True,None,False)))