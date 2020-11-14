#!/home/hurlab/anaconda3/envs/my-rdkit-env/bin/python3.6

# Python script that uses rdkit substructure search to identify certain hyperreactive functional groups in submitted chemicals

from rdkit import Chem
import re
import sys

### APPEND TO THIS LIST ONCE WE KNOW MORE FUNCTIONAL GROUPS TO LOOK OUT FOR ###
# CASRN                                                     COLUMN 0
# SMILES                                                    COLUMN 1
# Nitrile (Cyanide) functional group                        COLUMN 2
g1 = Chem.rdmolfiles.MolFromSmarts("[NX1]#[CX2]")
# Isocyanate functional group                               COLUMN 3
g2 = Chem.rdmolfiles.MolFromSmarts("[NX2]=[CX2]=[OX1]")
# Aldehyde functional group                                 COLUMN 4                             
g3 = Chem.rdmolfiles.MolFromSmarts("[CX3H1](=O)[#6]")
# Epoxide functional group                                  COLUMN 5
g4 = Chem.rdmolfiles.MolFromSmarts("[OX2]1[CX4][CX4]1")
###############################################################################

molFile = open("mols_2_smiles.txt","r")
reacFile = open("mols_2_final.txt","w+")

# write header to output text file
reacFile.write("casrn\tm\tcyanide\tisocyanate\taldehyde\tepoxide\n")

molFileContents = molFile.readlines()

# For each SMILES string in our table, convert it to an Rdkit molecule and run a substructure match search
# The 'mols' table is what we grab similar chemicals from 
for line in molFileContents:
    tmp = line.split("\t")
    print(tmp[0] + "\t" + tmp[1])
    mol = Chem.rdmolfiles.MolFromSmiles(str(tmp[1]).rstrip())
    #print("mol: ")
    #print(mol)
    #check for Nitrile
    m1 = mol.GetSubstructMatch(g1)
    #check for Isocyanate
    m2 = mol.GetSubstructMatch(g2)
    #check for Aldehyde
    m3 = mol.GetSubstructMatch(g3)
    #check for Epoxide
    m4 = mol.GetSubstructMatch(g4)

    r1 = 0
    r2 = 0
    r3 = 0
    r4 = 0

    if len(m1) > 0:
        r1 = 1
    if len(m2) > 0:
        r2 = 1
    if len(m3) > 0:
        r3 = 1
    if len(m4) > 0:
        r4 = 1
    writeStr = str(tmp[0].rstrip() + "\t" + tmp[1].rstrip() + "\t" + str(r1) + "\t" + str(r2) + "\t" + str(r3) + "\t" + str(r4) + "\n")
    #print("writing: ")
    #print(writeStr)
    reacFile.write(writeStr)
molFile.close()
reacFile.close()