FROM continuumio/miniconda3:24.7.1-0

LABEL version="4.5.0"
LABEL description="SimNIBS v4.5.0 headless container for Pawsey Setonix"

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies in a single layer
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender1 libgomp1 \
       wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and prepare conda environment file
ENV SIMNIBS_VERSION=4.5.0
ENV RELEASE_URL="https://github.com/simnibs/simnibs/releases/download/v${SIMNIBS_VERSION}"

WORKDIR /opt/simnibs

RUN wget -q "${RELEASE_URL}/environment_linux.yml" \
    && sed -i '/freeglut/d' environment_linux.yml \
    && sed -i '/pytest/d' environment_linux.yml \
    && sed -i '/mock/d' environment_linux.yml \
    && sed -i '/jupyterlab/d' environment_linux.yml \
    && sed -i '/setuptools-scm/d' environment_linux.yml \
    && sed -i '/pyqt5/d' environment_linux.yml

# Create conda environment (large layer — cached on rebuild)
RUN conda env create -f environment_linux.yml -n simnibs_env \
    && conda clean --all --yes

# Download and install SimNIBS wheel
RUN wget -q "${RELEASE_URL}/simnibs-${SIMNIBS_VERSION}-cp311-cp311-linux_x86_64.whl" \
    && /opt/conda/envs/simnibs_env/bin/pip install --no-cache-dir \
       simnibs-${SIMNIBS_VERSION}-cp311-cp311-linux_x86_64.whl \
    && rm -f simnibs-${SIMNIBS_VERSION}-cp311-cp311-linux_x86_64.whl

# Link external programs (gmsh, meshfix, etc.)
RUN /opt/conda/envs/simnibs_env/bin/python -c \
    "from simnibs.cli.link_external_progs import main; main()"

# Cleanup
RUN rm -f /opt/simnibs/environment_linux.yml \
    && conda clean --all --yes \
    && find /opt/conda -name "*.pyc" -delete \
    && find /opt/conda -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Environment for headless HPC use
ENV PATH="/opt/conda/envs/simnibs_env/bin:$PATH"
ENV CONDA_PREFIX="/opt/conda/envs/simnibs_env"
ENV CONDA_DEFAULT_ENV="simnibs_env"
ENV MPLBACKEND="Agg"
