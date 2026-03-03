#!/bin/bash
#SBATCH --job-name=simnibs-tms
#SBATCH --account=<your-pawsey-project>
#SBATCH --partition=work
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

module load singularity/4.1.0-slurm

CONTAINER="/software/${PAWSEY_PROJECT}/${USER}/containers/simnibs-4.5.0.sif"

singularity exec "${CONTAINER}" \
    simnibs_python "${MYSCRATCH}/scripts/tms_simulation.py"
