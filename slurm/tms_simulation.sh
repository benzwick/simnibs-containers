#!/bin/bash -l
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

module load singularity/4.1.0-nompi

CONTAINER="${MYSOFTWARE}/singularity/simnibs-4.5.0.sif"

srun -N 1 -n 1 -c ${SLURM_CPUS_PER_TASK} singularity exec -e "${CONTAINER}" \
    simnibs_python "${MYSCRATCH}/scripts/tms_simulation.py"
