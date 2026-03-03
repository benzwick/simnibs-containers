# SimNIBS Singularity Container for Pawsey Setonix

Singularity/Apptainer container packaging [SimNIBS](https://simnibs.github.io/simnibs/) v4.5.0 for headless HPC use on [Pawsey Setonix](https://pawsey.org.au/systems/setonix/).

## How it works

A GitHub Actions workflow builds a Docker image from the `Dockerfile`, converts it to Singularity SIF format, and publishes the SIF as a GitHub Release artifact on pushes to `main`. This follows [Pawsey's recommendation](https://pawsey.atlassian.net/wiki/spaces/US/pages/51925894/Singularity) to build via Docker for compatibility, layer caching, and portability.

The container:
- Uses `continuumio/miniconda3` as the base image
- Installs SimNIBS's conda environment from the upstream `environment_linux.yml`
- Installs the SimNIBS wheel via pip
- Strips GUI dependencies (PyQt5, freeglut) for headless operation
- Sets `MPLBACKEND=Agg` and respects `SLURM_CPUS_PER_TASK` for MKL/OMP threads

## Download

Grab the latest `.sif` from the [Releases](../../releases) page.

## Transfer to Setonix

Store the container in your `$MYSOFTWARE/singularity/` directory, following [Pawsey's recommendations](https://pawsey.atlassian.net/wiki/spaces/US/pages/51925894/Singularity):

```bash
scp simnibs-4.5.0.sif <user>@setonix.pawsey.org.au:/software/projects/<project>/<user>/singularity/
```

For containers shared across a project, use a group repository:

```bash
scp simnibs-4.5.0.sif <user>@setonix.pawsey.org.au:/scratch/<project>/singularity/
```

## Usage on Setonix

SimNIBS does not need host MPI -- its bundled PETSc/petsc4py includes a statically-linked MPICH for single-node parallelism. Use the `singularity/4.1.0-nompi` module. Always pass the `-e` flag (clean environment) to avoid host Python environment pollution, as [recommended by Pawsey for Python containers](https://pawsey.atlassian.net/wiki/spaces/US/pages/51925894/Singularity).

### Interactive

```bash
module load singularity/4.1.0-nompi

CONTAINER="${MYSOFTWARE}/singularity/simnibs-4.5.0.sif"

# Head meshing
singularity exec -e "${CONTAINER}" charm T1w.nii.gz T2w.nii.gz -o output_dir

# Run a simulation
singularity exec -e "${CONTAINER}" simnibs simulation.mat

# Run a custom Python script
singularity exec -e "${CONTAINER}" simnibs_python my_script.py
```

### Batch jobs

Example SLURM scripts are in the `slurm/` directory:

- **`charm_job.sh`** -- Head meshing with `charm` (32 CPUs, 24 GB, 4 hours)
- **`tms_simulation.sh`** -- TMS simulation (8 CPUs, 16 GB, 2 hours)

Edit `--account=<your-pawsey-project>` and file paths, then submit:

```bash
sbatch slurm/charm_job.sh
```

### Bind mounts

The `singularity/4.1.0-nompi` module automatically bind-mounts `/scratch` and `/software`. To mount additional directories:

```bash
singularity exec -e -B /path/on/host:/path/in/container "${CONTAINER}" simnibs_python script.py
```

If a program needs `$HOME`, bind-mount a writable directory as a fake home:

```bash
singularity exec -e -B ${MYSCRATCH}/fakehome:${HOME} "${CONTAINER}" simnibs_python script.py
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
singularity exec -e "${CONTAINER}" simnibs_python my_script.py
```

### Matplotlib "no display" errors

The container sets `MPLBACKEND=Agg` automatically. If you still get display errors, ensure you're not importing `matplotlib.pyplot` before the backend is set, or add `matplotlib.use('Agg')` at the top of your script.

### gmsh not found

If `which gmsh` fails inside the container, the `link_external_progs` step may not have run correctly during the build. Check the build logs.

### Singularity cache quota errors

The singularity module sets the cache to `$MYSCRATCH/.singularity/cache` to avoid `/home` quota issues. If you still get errors, clean the cache:

```bash
singularity cache clean -f
```

## Singularity module flavours

| Module | Use case |
|--------|----------|
| `singularity/4.1.0-nompi` | Applications without MPI (use this for SimNIBS) |
| `singularity/4.1.0-nohost` | Total isolation from host environment |
| `singularity/4.1.0-mpi` | MPI applications (Cray MPICH injected) |
| `singularity/4.1.0-mpi-gpu` | MPI + GPU applications |

## Building locally

You cannot build containers on Setonix (no root access). Build on a local machine or VM, then transfer the SIF file.

```bash
# Build Docker image
docker build -t simnibs:4.5.0 .

# Convert to Singularity SIF
singularity pull simnibs-4.5.0.sif docker-daemon:simnibs:4.5.0
```

Build time is approximately 20-40 minutes depending on network speed. Docker layer caching makes subsequent rebuilds much faster.
