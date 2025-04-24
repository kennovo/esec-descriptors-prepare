#!/bin/bash

# Define a function to run GROMACS commands
run_gromacs_commands() {
    # Run GROMACS commands in the current directory
    echo "Running GROMACS commands in directory: $(pwd)"

    # Run grompp and mdrun commands
    gmx grompp -f minim.mdp -c solvated-neutral.gro -p top.top -o em.tpr
    gmx mdrun -v -deffnm em
    gmx grompp -f nvt.mdp -c em.gro -r em.gro -p top.top -o nvt.tpr
    gmx mdrun -deffnm nvt
    gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p top.top -o npt.tpr
    gmx mdrun -deffnm npt
    gmx grompp -f md_1.mdp -c npt.gro -r npt.gro -t npt.cpt -p top.top -o md_1_1.tpr
}

# List of directories where you want to run GROMACS commands
directories=("nora")  # Add your directory names here

# Loop through directories and run GROMACS commands
for dir in "${directories[@]}"; do
    pushd "$dir" || exit 1  # Change to the directory or exit if it fails
    run_gromacs_commands
    popd || exit 1  # Return to the previous directory or exit if it fails
done
