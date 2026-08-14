#!/bin/bash
#SBATCH -A <ProjectID>           # iService Project id
#SBATCH -J hvd                 # job name
#SBATCH -p normal              # partition dev, normal normal2
#SBATCH --nodes=1              # Maximum number of nodes to be allocated
#SBATCH --cpus-per-task=12     # Number of cores per MPI task
#SBATCH --ntasks-per-node=2    # Number of MPI tasks (i.e. processes)
#SBATCH --gres=gpu:2           # same as --ntasks-per-node
#SBATCH -o %x_%j.out           # Path to the standard output file

export TF_ENABLE_ONEDNN_OPTS=0 # disable oneDNN message
export TF_CPP_MIN_LOG_LEVEL=3 # disable tensorflow info & warm message
export PMIX_MCA_gds=hash  # blacklist gds error

#export NCCL_DEBUG=INFO                      # Check NCCL communication
export HOROVOD_GPU_ALLREDUCE=NCCL           # force NCCL for GPU AllReduce
export NCCL_NET_GDR_LEVEL=3                 # Enable GPUDirect RDMA on H100/H200 node
#export NCCL_SOCKET_IFNAME=ib0               # NCCL use infiniband if multi-node
#export NCCL_IB_DISABLE=0                    # Enable InfiniBand if multi-node

echo "SLURM_JOB_NODELIST=$SLURM_JOB_NODELIST"

SECONDS=0

SINGULARITY="singularity exec -B /work:/work --nv \
    /work/$(whoami)/sif/tensorflow_24.05-tf2-py3.sif"
# pytorch2301_hvd.sif
#tensorflow_24.05-tf2-py3.sif

#CMD="python test_horovod.py"
#CMD="python tf2_keras_mnist.py"
#CMD="python pytorch_synthetic_benchmark.py"
CMD="python tf2_keras_synthetic_benchmark.py \
    --fp16-allreduce \
    --batch-size 128 \
    --num-batches-per-iter 100 "

RUN="srun --mpi=pmix --cpu-bind=cores --nodes=$SLURM_NNODES --ntasks=$SLURM_NTASKS $SINGULARITY $CMD"
echo $RUN; $RUN

RUNTIME=$SECONDS
HOUR=$(($RUNTIME / 3600)) ;MIN=$(((RUNTIME /60)%60)) ;SEC=$((RUNTIME % 60))
echo -e "\n Done Runtime:$HOUR:$MIN:$SEC\n"
