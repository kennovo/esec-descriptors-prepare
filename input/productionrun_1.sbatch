#!/bin/bash
#SBATCH --job-name=md_1_1
#SBATCH --time=119:50:00
#SBATCH --partition=ampere_gpu
#SBATCH --cpus-per-task=16
#SBATCH --gpus=1
#SBATCH --output %x.sout
#SBATCH --mail-user=pieter.de.gauquier@vub.be
#SBATCH --mail-type=ALL




module load GROMACS/2023.3-foss-2022a-CUDA-11.7.0


/usr/bin/time -v gmx mdrun -nt $SLURM_CPUS_PER_TASK -deffnm $SLURM_JOB_NAME -nb gpu </dev/null >$SLURM_JOB_NAME.oe 2>&1 
