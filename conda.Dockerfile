# Build argumnets
ARG CUDA_VER=11.8.0
ARG UBUNTU_VER=22.04
# Download the base image
FROM nvidia/cuda:${CUDA_VER}-cudnn8-runtime-ubuntu${UBUNTU_VER}
# you can check for all available images at https://hub.docker.com/r/nvidia/cuda/tags

# Install as root
USER root

# Shell
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# miniconda path
ENV CONDA_DIR /opt/miniconda

# conda path
ENV PATH=${CONDA_DIR}/bin:$PATH

ARG DEBIAN_FRONTEND="noninteractive"
ARG USERNAME=coder
ARG USERID=1000
ARG GROUPID=1000

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bash-completion \
    ca-certificates \
    curl \
    git \
    htop \
    nano \
    openssh-client \
    sudo \
    tmux \
    unzip \
    vim \
    wget \ 
    zip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Microsoft's code-server
RUN wget -O- https://aka.ms/install-vscode-server/setup.sh | sh
# Expose port 8000 for code-server
EXPOSE 8000


# Install a VNC server and noVNC
RUN apt-get update && apt-get install -y --no-install-recommends \
    x11vnc \
    novnc \
    websockify && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose port 6080 for noVNC
EXPOSE 6080

# Install a window manager
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    /bin/bash miniconda.sh -b -p ${CONDA_DIR} && \
    rm -rf miniconda.sh && \
# Enable conda autocomplete
sudo wget --quiet https://github.com/tartansandal/conda-bash-completion/raw/master/conda -P /etc/bash_completion.d/

# Add a user `${USERNAME}` so that you're not developing as the `root` user
RUN groupadd -g ${GROUPID} ${USERNAME} && \
    useradd ${USERNAME} \
    --create-home \
    --uid ${USERID} \
    --gid ${GROUPID} \
    --shell=/bin/bash && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd && \
    # Allow running conda as the new user
    groupadd conda && chgrp -R conda ${CONDA_DIR} && chmod 755 -R ${CONDA_DIR} && adduser ${USERNAME} conda && \
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >>/home/${USERNAME}/.profile && \
    # Install mamba
    conda install mamba -n base -c conda-forge && \
    # clean up
    conda clean --all --yes

# Python version
ARG PYTHON_VER=3.10

# Change to your user
USER ${USERNAME}

# Chnage Workdir
WORKDIR /home/${USERNAME}

# Initilize shell for conda/mamba
RUN conda init bash && \
    mamba init bash && \
    source /home/${USERNAME}/.bashrc

# Create deep-learning environment
RUN mamba create --name DL --channel conda-forge python=${PYTHON_VER} --yes && \
    mamba clean --all --yes && \
    # Make new shells activate the DL environment:
    echo "# Make new shells activate the DL environment" >>/home/${USERNAME}/.bashrc && \
    echo "conda activate DL" >>/home/${USERNAME}/.bashrc

# Tensorflow Package version passed as build argument e.g. --build-arg TF_VERSION=2.9.2
# A blank value will install the latest version
ARG TF_VERSION=

# Install packages inside the new environment
RUN conda activate DL && \	
    pip install --upgrade --no-cache-dir pip && \
    pip install --upgrade --no-cache-dir torch torchvision torchaudio torchtext lightning && \
    pip install --upgrade --no-cache-dir \
    ipywidgets \
    jupyterlab \
    matplotlib \
    nltk \
    notebook \
    numpy \
    pandas \
    Pillow \
    plotly \
    PyYAML \
    scipy \
    scikit-image \
    scikit-learn \
    sympy \
    seaborn \
    tensorflow${TF_VERSION:+==${TF_VERSION}} \
    tqdm && \
    pip cache purge && \
    # Set path of python packages
    echo "# Set path of python packages" >>/home/${USERNAME}/.bashrc && \
    echo 'export PATH=$HOME/.local/bin:$PATH' >>/home/${USERNAME}/.bashrc
