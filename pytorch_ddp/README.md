# Pytorch DDP Distributed-Data-Parallelism

啟用Pytorch DDP的方式為彈性啟用Elastic Launch(1.9.0以後)與一般啟用(1.9.0以前)兩種。  
1. 彈性啟用Elastic Launch(1.9.0以後)  
在訓練過程中，可動態的調整GPU數量。若訓練過程中斷時，會自動重啟GPU繼續訓練。當GPU數量有變化時，參數權重和batch size for one GPU、learn rate等超參數會自行變換。

```bash
torchrun \
    --nnodes=1:3 \
    --nproc_per_node=4 \
    --max_restarts=3 \
    --rdzv_id=1 \
    --rdzv_backend=c10d \
    --rdzv_endpoint="192.0.0.1:1234" \
    train_elastic.py
```
`--nnodes=1:3` 當前訓練任務至少1個節點、最多3個節點  
`--max_restarts=3` 容錯次數達3次  

2. 一般啟用(1.9.0以前)  
無前述彈性啟動的優勢，只能固定節點數量，且無容錯而自動繼續訓練。  

```bash
torchrun \
    --nnodes=NODE_SIZE \
    --nproc_per_node=TRAINERS_PER_NODE \
    --node_rank=NODE_RANK \
    --master_port=HOST_PORT \
    --master_addr=HOST_NODE_ADDR \
    YOUR_TRAINING_SCRIPT.py (--arg1 ... train script args...) 
```
其中node_rank表示當下節點的編號，需要手動設定。  

## 實作
### 下載容器映像檔
```bash
[userA@25a-lgn05 ~]$ sigularity pull pytorch_25.08-py3.sif docker://nvcr.io/nvidia/pytorch:25.08-py3
[userA@25a-lgn05 ~]$ mv pytorch_25.08-py3.sif /work/$(whoami)sif/pytorch_25.08-py3.sif
```

### 在slurm scirpt編輯彈性啟用`run_elastic.slurm`
```bash
#!/bin/bash
#SBATCH -A <ProjectID>          # iService Project id
#SBATCH -J elastic                # job name
#SBATCH -p dev             # partition dev normal normal2
#SBATCH --nodes=2             # Maximum number of nodes to be allocated
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

echo "$RUN"; $RUN
```

```bash
[userA@25a-lgn05 pytorch_mnist]$ sbatch run_elastic.slurm
Submitted batch job 268439
[userA@25a-lgn05 pytorch_mnist]$ cat elastic_268439.out
SLURM_JOB_NODELIST=25a-hgpn001
srun --mpi=pmi2 --nodes=1 --ntasks=1 singularity exec -B /work:/work --nv /work/userA/sif/pytorch_25.08-py3.sif torchrun --nnodes 1 --nproc_per_node=2 --rdzv_id 268439 --rdzv_backend c10d --rdzv_endpoint 25a-hgpn001:24144 multinode.py 10 10
[GPU1] Epoch 0 | Batchsize: 32 | Steps: 32[GPU0] Epoch 0 | Batchsize: 32 | Steps: 32

[GPU1] Epoch 1 | Batchsize: 32 | Steps: 32
Epoch 0 | Training snapshot saved at snapshot.pt
[GPU0] Epoch 1 | Batchsize: 32 | Steps: 32
...
[GPU0] Epoch 9 | Batchsize: 32 | Steps: 32
[GPU1] Epoch 9 | Batchsize: 32 | Steps: 32

[userA@25a-lgn05 pytorch_mnist]$ sbatch run_elastic.slurm
Submitted batch job 268579
[userA@25a-lgn05 pytorch_mnist]$ cat *268579*
SLURM_JOB_NODELIST=25a-hgpn[058-059]
srun --mpi=pmi2 --nodes=2 --ntasks=2 singularity exec -B /work:/work --nv /work/userA/sif/pytorch_25.08-py3.sif torchrun  --nnodes 2  --nproc_per_node=2  --rdzv_id 268579  --rdzv_backend c10d  --rdzv_endpoint 25a-hgpn058:25216  multinode.py 10 10
[GPU2] Epoch 0 | Batchsize: 32 | Steps: 16
[GPU3] Epoch 0 | Batchsize: 32 | Steps: 16
[GPU0] Epoch 0 | Batchsize: 32 | Steps: 16
[GPU1] Epoch 0 | Batchsize: 32 | Steps: 16
[GPU1] Epoch 1 | Batchsize: 32 | Steps: 16
[GPU3] Epoch 1 | Batchsize: 32 | Steps: 16
Epoch 0 | Training snapshot saved at snapshot.pt
[GPU0] Epoch 1 | Batchsize: 32 | Steps: 16
Epoch 0 | Training snapshot saved at snapshot.pt
[GPU2] Epoch 1 | Batchsize: 32 | Steps: 16
...
[GPU0] Epoch 9 | Batchsize: 32 | Steps: 16
[GPU1] Epoch 9 | Batchsize: 32 | Steps: 16
[GPU2] Epoch 9 | Batchsize: 32 | Steps: 16
[GPU3] Epoch 9 | Batchsize: 32 | Steps: 16
```

### 在slurm scirpt編輯一般啟用`run_ddp.slurm`
```bash
#!/bin/bash
#SBATCH -A <ProjectID>       # iService Project id
#SBATCH -J ddp                # job name
#SBATCH -p dev                # partition gtest gp1d, gpNCHC_LLM
#SBATCH --nodes=2              # Maximum number of nodes to be allocated
#SBATCH --cpus-per-task=12      # Number of cores per MPI task
#SBATCH --ntasks-per-node=1    # Number of MPI tasks (i.e. processes)
#SBATCH --gres=gpu:2
#SBATCH -o %x_%j.out           # Path to the standard output file

export OMP_NUM_THREADS=1
export MASTER_ADDR=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n 1)
export MASTER_PORT=$(($RANDOM % 10000 + 20000)) # random port form 20000 to 29999 
echo "SLURM_JOB_NODELIST=$SLURM_JOB_NODELIST"

[ -f "snapshot.pt" ] && rm "snapshot.pt" # remove snapshot.pt
[ -d "__pycache__" ] && rm -rf "__pycache__" # remove __pycache__

SIF=/work/$(whoami)/sif/pytorch_25.08-py3.sif
export SINGULARITY="singularity exec --nv -B /work:/work $SIF"

export LAUNCHER="torchrun \
--nnodes $SLURM_NNODES \
--nproc_per_node $SLURM_GPUS_ON_NODE \
--master_addr $MASTER_ADDR \
--master_port $MASTER_PORT \
"
export TRAIN="multigpu_torchrun.py 10 10" 
# multigpu_torchrun.py 
# multinode.py not for touchrun multi node

srun --nodes=$SLURM_NNODES --ntasks=$SLURM_NNODES \
bash -c "
    CMD=\"\$SINGULARITY \$LAUNCHER --node_rank \$SLURM_NODEID \$TRAIN\"
    echo \" \$SLURMD_NODENAME \$CMD \"
    exec \$CMD
    "
```
為了顯示每個計算節點各自執行`bash -c "..."`，回傳節點序號`--node_rank \$SLURM_NODEID`、節點名稱`$SLURMD_NODENAME`。  

```bash
[userA@25a-lgn05 pytorch_mnist]$ sbatch run_ddp.slurm
Submitted batch job 268685
[userA@25a-lgn05 pytorch_mnist]$ cat ddp_268685.out
SLURM_JOB_NODELIST=25a-hgpn018
 25a-hgpn018 singularity exec --nv -B /work:/work /work/userA/sif/pytorch_25.08-py3.sif torchrun --nnodes 1 --nproc_per_node 2 --master_addr 25a-hgpn018 --master_port 26478  --node_rank 0 multinode.py 10 10
[GPU0] Epoch 0 | Batchsize: 32 | Steps: 32
Epoch 0 | Training snapshot saved at snapshot.pt
[GPU0] Epoch 1 | Batchsize: 32 | Steps: 32
...
[GPU0] Epoch 8 | Batchsize: 32 | Steps: 32
[GPU0] Epoch 9 | Batchsize: 32 | Steps: 32

[userA@25a-lgn05 pytorch_mnist]$ sbatch run_ddp.slurm
Submitted batch job 268714
[userA@25a-lgn05 pytorch_mnist]$ cat *268714*
SLURM_JOB_NODELIST=25a-hgpn[030-031]
 25a-hgpn031 singularity exec --nv -B /work:/work /work/userA/sif/pytorch_25.08-py3.sif torchrun --nnodes 2 --nproc_per_node 2 --master_addr 25a-hgpn030 --master_port 24174  --node_rank 1 multinode.py 10 10
 25a-hgpn030 singularity exec --nv -B /work:/work /work/userA/sif/pytorch_25.08-py3.sif torchrun --nnodes 2 --nproc_per_node 2 --master_addr 25a-hgpn030 --master_port 24174  --node_rank 0 multinode.py 10 10
[GPU0] Epoch 0 | Batchsize: 32 | Steps: 16
[GPU0] Epoch 0 | Batchsize: 32 | Steps: 16
...
[GPU0] Epoch 9 | Batchsize: 32 | Steps: 16
[GPU0] Epoch 9 | Batchsize: 32 | Steps: 16
```
[程式碼來源](https://pytorch.org/tutorials/beginner/ddp_series_intro.html)
