<img src="https://kenno.org/esec-descriptors/esec-logo1web.png" width="587" height="329" style="display:block;margin-left:auto;margin-right:auto">

# Overview
This repository is a collection of scripts to facilitate running explicit solvent Molecular Dynamics (MD) simulations on small organic molecules for the purpose of calculating Ensemble Steric and Electrostatic Chirality (ESEC) descriptors. The end product of this workflow consists of:
* A .prop file which is a space-separated plain text table containing, for each atom of the small organic molecule, its mass, CGenFF charge, Gasteiger charge and CGenFF atom type.
* A .traj.xyz file which is a raw trajectory of the molecule, consisting only of Cartesian coordinates (in the same order as the .prop file and repeated as many times as there are trajectory frames). The format is also space-separated plain text.

These two files can then be submitted to [kenno.org/esec-descriptors](https://kenno.org/esec-descriptors/) to obtain the final descriptor values.

The MD workflow is based on GROMACS, but since the input for the web interface is simple and software-agnostic, the workflow can straightforwardly be adapted to other programs.

The following can be found in this repository:
* the present **README.md** file, the remainder of which describes the workflow step by step
* the **scripts** directory: the necessary scripts and data files for the workflow
* the **input** directory, with all necessary files for preparing and running GROMACS on the example of (protonated) noradrenaline directory in 40% acetonitrile
* the **output** directory, containing the corresponding MD output
* **nora_descr.txt** , the descriptor file obtained from submitting output/nora.prop and output/nora.traj.xyz to the web interface

# Workflow
Prerequisite: a Unix-like shell with access to python3, obabel and the GROMACS tool set.

Note: in this description of the workflow, the molecule name (nora in the case of noradrenaline) is generalized to "**mol**".

## Adapt the .mol2 file
Within the .mol2 file, adjust "*****" on line 2 to a name that refers to your molecule, but ensure it is no more than 4 characters long. 

## Create a CGenFF .str file
...either with the CGenFF web app or a local CGenFF binary. Both are available at [cgenff.com](https://cgenff.com) and free-of-charge for academic use.

## Generate files from the .mol2 and .str files

    python3 cgenff_charmm2gmx_py3_nx25.py mol mol.mol2 mol.str charmm36.ff 2>&1 | tee mol.pyo
    
    cgenff_charmm2gmx_py3_nx25.py derives from the MacKerell Lab website http://mackerell.umaryland.edu/charmm_ff.shtml

## Add text to the .top file
Add the text below to line 15-16 of the generated topology ".top" file.

    ; Include acetonitrile topology
    #include "acn.itp"
 
## Create .itp files

    gmx genrestr -f mol_ini.pdb -o mol_ini_posres.itp

Select group 2 after executing.

## Add text to the .top file
Add the text below to line 8-11 of the generated .top file.

    ; Include Position restraint file
    #ifdef POSRES
    #include "mol_ini_posres.itp"
    #endif
 
## Define a box

    tee box.gro.in | gmx editconf -f mol_ini.pdb -o box.gro -bt cubic -d 1.0 2>&1 | tee box.gro.oe

## Solvate
### Add water

    gmx solvate -cp box.gro -cs -o water_solv.gro -p mol.top
&nbsp;
<details>
<summary>Optional steps for solvent mixtures (for the example of water:ACN 60:40)</summary>

### Add ACN to obtain a certain water/ACN ratio
Number of water molecules added in previous step = 1000 (as an example)

For 40% ACN: 
- 1000 / 6.02 10<sup>23</sup> /mol = 1.661 10<sup>-21</sup> mol
- Divide by molecular mass of water: 1.661 10<sup>-21</sup> mol / 18 g/mol = 2.990 10<sup>-20</sup> g
- Because density of water is 1 g/ml, 2.990 10<sup>-20</sup> g water = 2.990 10<sup>-20</sup> ml water
- Multiply with 40%: 2.990 10<sup>-20</sup> ml * 0.4 = 1.196 10<sup>-20</sup> ml
- Multiply with the density of ACN: 1.196 10<sup>-20</sup> ml * 0.786 g/ml = 9.401 10<sup>-21</sup> g
- Divide by molecular mass of ACN: 9.401 10<sup>-21</sup> g / 41 g/mol = 2.293 10<sup>-22</sup> mol
- Multiply with constant of Avogadro: 2.293 10<sup>-22</sup> mol * 6.02 10<sup>23</sup> /mol = 138 molecules

Add the number of ACN molecules to the code:

    tee newbox.gro.in | gmx insert-molecules -ci acn.pdb -f box.gro -nmol 138 -o newbox.gro 2>&1 | tee newbox.gro.oe


### Delete the originally added water molecules...
...by removing the line of the .top file that specifies the number of water molecules (**SOL**; line 27 in this example).

### Fill the remaining empty space with water molecules

    tee solvated-neutral.gro.in | gmx solvate -cp newbox.gro -cs -o solvated-neutral.gro -p mol.top 2>&1 | tee solvated-neutral.gro.oe

### Check the water/ACN ratio
If the original number of water molecules (before adding ACN) was 1000 and the final number of water molecules (from the previous step) is 605, then the ratio is 605 / 1000 = 0,605 ~ 60% (fraction of available volume occupied by water). This is a rough estimate, but if it deviates too much from the target ratio, the number of ACN molecules may need to be adjusted.

### Add the number of ACN molecules to the .top file
Add the number of ACN molecules to the appropriate line (line 34 in this example) of the .top file.

Example:

    [ molecules ]
    ; Compound        #mols
    mol         1
    ACN         138
    SOL         605

</details>
&nbsp;

## When the molecule is ionized:

    tee ions.tpr.in |gmx grompp -f ions.mdp -c solvated-neutral.gro -p mol.top -o ions.tpr | tee ions.tpr.oe

    tee solvated-neutral.in |gmx genion -s ions.tpr -o solvated-neutral.gro -p mol.top -pname SOD -nname CLA -neutral -rmin 0.5 | tee solvated-neutral.oe

-> Choose the number linked to "SOL", then the ions will be added. 

## Adapt the gromacs.sh file
Adapt line 19 in the gromacs.sh file by adding the directory names of the molecules to be simulated.

## Change the name of the .top file
(Alternatively, the gromacs.sh can be made to point to the correct mol.top for each directory it processes.)

    mv mol.top top.top

## Run energy minimization and equilibration

    nohup time nice -n 16 ./gromacs.sh </dev/null >gromacs.oe 2>&1 &

## Start the MD simulation

    gmx mdrun -deffnm md_1 -nb gpu 

## Add additional atomic properties (such as Gasteiger charge) for each molecule

    ./addprops2 mol1 mol2 mol3 ...

## Remove solvent, skip the first 200 frames and convert to "flat" trajectory file

    ./gmx2xyz.sh 200 >gmx2xyz.sho 2>&1 &
