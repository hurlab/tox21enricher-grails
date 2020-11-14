#!/home/hurlab/anaconda3/envs/my-rdkit-env/bin/python3.6

# Python script that uses rdkit substructure search to identify certain hyperreactive functional groups in submitted chemicals

from rdkit import Chem
import sys

mol = Chem.rdmolfiles.MolFromSmiles(sys.argv[1])

### APPEND TO THIS LIST ONCE WE KNOW MORE FUNCTIONAL GROUPS TO LOOK OUT FOR ###
#Nitrile (Cyanide) functional group
g1 = Chem.rdmolfiles.MolFromSmarts("[NX1]#[CX2]")
#Isocyanate functional group
g2 = Chem.rdmolfiles.MolFromSmarts("[NX2]=[CX2]=[OX1]")
#Aldehyde functional group                                        
g3 = Chem.rdmolfiles.MolFromSmarts("[CX3H1](=O)[#6]")
#Epoxide functional group
g4 = Chem.rdmolfiles.MolFromSmarts("[OX2]1[CX4][CX4]1")
###############################################################################

#check for Nitrile
m1 = mol.GetSubstructMatch(g1)
#check for Isocyanate
m2 = mol.GetSubstructMatch(g2)
#check for Aldehyde
m3 = mol.GetSubstructMatch(g3)
#check for Epoxide
m4 = mol.GetSubstructMatch(g4)

results = ""

if len(m1) > 0:
    #res = Chem.rdmolfiles.MolFragmentToSmiles(mol,m1)
    results = results + str(1) + ","
else:
    results = results + str(0) + ","
if len(m2) > 0:
    #res = Chem.rdmolfiles.MolFragmentToSmiles(mol,m2)
    results = results + str(1) + ","
else:
    results = results + str(0) + ","
if len(m3) > 0:
    #res = Chem.rdmolfiles.MolFragmentToSmiles(mol,m3)
    results = results + str(1) + ","
else:
    results = results + str(0) + ","
if len(m4) > 0:
    #res = Chem.rdmolfiles.MolFragmentToSmiles(mol,m4)
    results = results + str(1) + ","
else:
    results = results + str(0) + ","
print(results)