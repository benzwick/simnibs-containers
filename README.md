# SimNIBS Singularity Container for Pawsey Setonix

Singularity/Apptainer container packaging [SimNIBS](https://simnibs.github.io/simnibs/) v4.5.0 for headless HPC use on [Pawsey Setonix](https://pawsey.org.au/systems/setonix/).

## How it works

A GitHub Actions workflow builds the container image (`.sif` file) from `simnibs.def` using Apptainer. On pushes to `main`, the SIF is published as a GitHub Release artifact.

The container:
- Uses `continuumio/miniconda3` as the base image
- Installs SimNIBS's conda environment from the upstream `environment_linux.yml`
- Installs the SimNIBS wheel via pip
- Strips GUI dependencies (PyQt5, freeglut) for headless operation
- Sets `MPLBACKEND=Agg` and respects `SLURM_CPUS_PER_TASK` for MKL/OMP threads

## Download

Grab the latest `.sif` from the [Releases](../../releases) page.

## Transfer to Setonix

```bash
scp simnibs-4.5.0.sif <user>@setonix.pawsey.org.au:/software/<project>/<user>/containers/
```

## Usage on Setonix

### Interactive

```bash
module load singularity/4.1.0-slurm

CONTAINER="/software/${PAWSEY_PROJECT}/${USER}/containers/simnibs-4.5.0.sif"

# Head meshing
singularity exec "${CONTAINER}" charm T1w.nii.gz T2w.nii.gz -o output_dir

# Run a simulation
singularity exec "${CONTAINER}" simnibs simulation.mat

# Run a custom Python script
singularity exec "${CONTAINER}" simnibs_python my_script.py
```

### Batch jobs

Example SLURM scripts are in the `slurm/` directory:

- **`charm_job.sh`** -- Head meshing with `charm` (32 CPUs, 24 GB, 4 hours)
- **`tms_simulation.sh`** -- TMS simulation (8 CPUs, 16 GB, 2 hours)

Edit `--account=<your-pawsey-project>` and file paths, then submit:

```bash
sbatch slurm/charm_job.sh
```

## Available CLI tools

| Command | Description |
|---------|-------------|
| `charm` | Head mesh generation from MRI |
| `simnibs` | Run simulations from `.mat` session files |
| `simnibs_python` | Python interpreter with SimNIBS available |
| `mni2subject_coords` | Transform MNI coordinates to subject space |
| `subject2mni_coords` | Transform subject coordinates to MNI space |
| `eeg_positions` | Get EEG electrode positions on a head model |
| `meshmesh` | Mesh operations |
| `dwi2cond` | Estimate conductivity tensors from DWI |

## Troubleshooting

### MKL threading on AMD EPYC

The container sets `MKL_NUM_THREADS` and `OMP_NUM_THREADS` from `SLURM_CPUS_PER_TASK` (defaults to 1 outside SLURM). Override if needed:

```bash
export MKL_NUM_THREADS=16
singularity exec "${CONTAINER}" simnibs_python my_script.py
```

### Matplotlib "no display" errors

The container sets `MPLBACKEND=Agg` automatically. If you still get display errors, ensure you're not importing `matplotlib.pyplot` before the backend is set, or add `matplotlib.use('Agg')` at the top of your script.

### gmsh not found

If `which gmsh` fails inside the container, the `link_external_progs` step may not have run correctly during the build. Check the build logs.

## Building locally

Requires [Apptainer](https://apptainer.org/) (or Singularity >= 3.0):

```bash
apptainer build simnibs-4.5.0.sif simnibs.def
```

Build time is approximately 20-40 minutes depending on network speed.
