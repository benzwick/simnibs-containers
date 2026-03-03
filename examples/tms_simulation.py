"""
Example SimNIBS TMS simulation script for Pawsey Setonix.

Copy this script to Setonix and edit the paths/parameters for your data:

    scp tms_simulation.py <user>@setonix.pawsey.org.au:$MYSCRATCH/scripts/

Run interactively:

    module load singularity/4.1.0-nompi
    CONTAINER="${MYSOFTWARE}/singularity/simnibs-4.5.0.sif"
    cd ${MYSCRATCH}/data/sub-01
    singularity exec -e "${CONTAINER}" simnibs_python ${MYSCRATCH}/scripts/tms_simulation.py

Or submit as a batch job:

    sbatch slurm/tms_simulation.sh

See https://simnibs.github.io/simnibs/ for full SimNIBS documentation.
"""
import simnibs

# --- Configure session ---
s = simnibs.sim_struct.SESSION()
s.subpath = "m2m_sub-01"  # Path to charm output (relative to working dir)
s.pathfem = "tms_results"  # Output directory for simulation results

# --- Configure TMS coil ---
tms = s.add_tmslist()
tms.fnamecoil = "Magstim_70mm_Fig8.ccd"  # Coil model

# --- Configure coil position ---
pos = tms.add_position()
# Target left M1 in MNI coordinates, transformed to subject space
pos.centre = simnibs.mni2subject_coords([-37, -21, 58], "m2m_sub-01")
pos.pos_ydir = [0, 1, 0]  # Coil handle pointing anteriorly
pos.distance = 4  # 4 mm above scalp

# --- Run simulation ---
simnibs.run_simnibs(s)
