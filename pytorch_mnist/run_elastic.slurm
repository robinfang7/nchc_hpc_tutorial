#!/bin/bash
#SBATCH -A <ProjectID>          # iService Project id
#SBATCH -J elastic                # job name
#SBATCH -p dev             # partition dev normal normal2
#SBATCH --nodes=1             # Maximum number of nodes to be allocated
#SBATCH --cpus-per-task=12     # Number of cores per MPI task
#SBATCH --ntasks-per-node=1   # Number of MPI tasks (i.e. processes)
#SBATCH --gres=gpu:2          # GPUS per node
#SBATCH -o %x_%j.out          # Path to the standard output file

export OMP_NUM_THREADS=1
export MASTER_ADDR=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n 1)
export MASTER_PORT=$(($RANDOM % 10000 + 20000)) # random port form 20000 to 29999
echo "SLURM_JOB_NODELIST=$SLURM_JOB_NODELIST"

[ -f "snapshot.pt" ] && rm "snapshot.pt" # remove snapshot.pt
[ -d "__pycache__" ] && rm -rf "__pycache__" # remove __pycache__

SIF=/work/$(whoami)/sif/pytorch_25.08-py3.sif
SINGULARITY="singularity exec -B /work:/work --nv $SIF"

LAUNCHER="torchrun \
 --nnodes $SLURM_NNODES \
 --nproc_per_node=$SLURM_GPUS_ON_NODE \
 --rdzv_id $SLURM_JOBID \
 --rdzv_backend c10d \
 --rdzv_endpoint $MASTER_ADDR:$MASTER_PORT \
"
CMD="multinode.py 10 10"
#multigpu_torchrun.py  not for elastic luanch on multi node
#multinode.py for multi nodes

RUN="srun --mpi=pmi2 --nodes=$SLURM_NNODES --ntasks=$SLURM_NNODES $SINGULARITY $LAUNCHER $CMD"

SECONDS=0

echo "$RUN"; $RUN

RUNTIME=$SECONDS
HOUR=$(($RUNTIME / 3600)) ;MIN=$(((RUNTIME /60)%60)) ;SEC=$((RUNTIME % 60))
echo -e "\n  Done Runtime:$HOUR:$MIN:$SEC\n"

