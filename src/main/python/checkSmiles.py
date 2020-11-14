#!/home/hurlab/anaconda3/envs/my-rdkit-env/bin/python3.6

# Python script that uses rdkit to check if a SMILES string is valid

from rdkit import Chem
import sys

mol = Chem.rdmolfiles.MolFromSmiles(sys.argv[1])
print(mol)