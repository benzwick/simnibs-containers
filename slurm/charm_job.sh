#!/bin/bash
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

module load singularity/4.1.0-slurm

CONTAINER="/software/${PAWSEY_PROJECT}/${USER}/containers/simnibs-4.5.0.sif"
T1="${MYSCRATCH}/data/sub-01/T1w.nii.gz"
T2="${MYSCRATCH}/data/sub-01/T2w.nii.gz"
OUTDIR="${MYSCRATCH}/data/sub-01/simnibs"

mkdir -p "${OUTDIR}"

singularity exec "${CONTAINER}" \
    charm "${T1}" "${T2}" \
    --forcerun \
    -o "${OUTDIR}"
