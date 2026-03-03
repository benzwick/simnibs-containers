#!/bin/bash -l
#SBATCH --job-name=simnibs-charm
#SBATCH --account=<your-pawsey-project>
#SBATCH --partition=work
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

module load singularity/4.1.0-nompi

CONTAINER="${MYSOFTWARE}/singularity/simnibs-4.5.0.sif"
T1="${MYSCRATCH}/data/sub-01/T1w.nii.gz"
T2="${MYSCRATCH}/data/sub-01/T2w.nii.gz"
OUTDIR="${MYSCRATCH}/data/sub-01/simnibs"

mkdir -p "${OUTDIR}"

srun -N 1 -n 1 -c ${SLURM_CPUS_PER_TASK} singularity exec -e "${CONTAINER}" \
    charm "${T1}" "${T2}" \
    --forcerun \
    -o "${OUTDIR}"
