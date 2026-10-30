#!/bin/bash
#SBATCH -A <ProjectID>        # iService Project id
#SBATCH -J pytorch            # job name
#SBATCH -p dev                # partition dev normal normal2
#SBATCH --nodes=1             # Maximum number of nodes to be allocated
#SBATCH --cpus-per-task=12    # Number of cores per MPI task
#SBATCH --ntasks-per-node=1   # Number of MPI tasks (i.e. processes)
#SBATCH --gres=gpu:1          # GPUS per node
#SBATCH -o %x_%j.out          # Path to the standard output file

[ -f "snapshot.pt" ] && rm "snapshot.pt" # remove snapshot.pt
[ -d "__pycache__" ] && rm -rf "__pycache__"

SIF=/work/$(whoami)/sif/pytorch_25.08-py3.sif # cuda 13.0 Nano5
SINGULARITY="singularity exec -B /work:/work --nv $SIF"

$SINGULARITY python single_gpu.py 32 10

echo "Job finished"