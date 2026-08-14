# Run Horovod on Nano5

Horovod 是一個開源的分散式深度學習訓練框架，支援 TensorFlow、Keras、PyTorch 與 Apache MXNet。它的主要目的是讓使用者只修改少量的程式碼，就能將單機訓練快速擴展到多個 GPU 甚至多個節點上進行平行運算。  
以下說明案例  
1. Horovod with Tensorflow 2.x(Keras)  
2. Horovod with Pytorch  

## Horovod with Tensorflow 2.x (Keras)  
下載Tensorflow 容器  
`[userA@cbi-lgn01 ~]$ singularity pull tensorflow_24.05-tf2-py3.sif tensorflow_24.05-tf2-py3.sif`  
`[userA@cbi-lgn01 ~]$ mv tensorflow_24.05-tf2-py3.sif /work/$(whoami)/sif/`  
查看容器內的CUDA版本  
```bash
[userA@cbi-lgn01 ~]$ singularity exec /work/userA/sif/tensorflow_24.05-tf2-py3.sif nvcc --version
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2024 NVIDIA Corporation
Built on Thu_Mar_28_02:18:24_PDT_2024
Cuda compilation tools, release 12.4, V12.4.131
Build cuda_12.4.r12.4/compiler.34097967_0
```
由於Tensorflow容器的CUDA版本為12.4，只能在Nano5使用，不適用Nano4。  

### test_horovod.py
輸出MPI_size、MPI_rank、MPI_local_size、MPI_local_rank、host name  

run_hvd.slurm
```bash
#!/bin/bash
#SBATCH -A <PorjectID>           # iService Project id
#SBATCH -J hvd                 # job name
#SBATCH -p normal              # partition dev, normal normal2
#SBATCH --nodes=2              # Maximum number of nodes to be allocated
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
#export NCCL_SOCKET_IFNAME=ib0               # NCCL use infiniband  if multi-node
#export NCCL_IB_DISABLE=0                    # Enable InfiniBand if multi-node

echo "SLURM_JOB_NODELIST=$SLURM_JOB_NODELIST"

SINGULARITY="singularity exec -B /work:/work --nv \
    /work/$(whoami)/sif/tensorflow_24.05-tf2-py3.sif"
 
CMD="python test_horovod.py"

RUN="srun --mpi=pmix --cpu-bind=cores --nodes=$SLURM_NNODES --ntasks=$SLURM_NTASKS $SINGULARITY $CMD"
echo $RUN; $RUN
```
`--ntasks-per-node`與`--gres=gpu:` 數目要一樣，1個task用1個GPU執行。

提交工作
```bash
[userA@cbi-lgn01 horovod]$ sbatch run_hvd.slurm
Submitted batch job 297171

[userA@cbi-lgn01 horovod]$ cat *297171*
SLURM_JOB_NODELIST=hgpn[18-19]
srun --mpi=pmix --cpu-bind=cores --nodes=2 --ntasks=4 singularity exec -B /work:/work --nv /work/userA/sif/tensorflow_24.05-tf2-py3.sif python test_horovod.py
List of TF visible physical GPUs :  [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU'), PhysicalDevice(name='/physical_device:GPU:1', device_type='GPU')]
MPI_size = 4, MPI_rank = 1, MPI_local_size = 2,  MPI_local_rank = 1 platform = hgpn18
List of TF visible physical GPUs :  [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU'), PhysicalDevice(name='/physical_device:GPU:1', device_type='GPU')]
MPI_size = 4, MPI_rank = 2, MPI_local_size = 2,  MPI_local_rank = 0 platform = hgpn19
List of TF visible physical GPUs :  [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU'), PhysicalDevice(name='/physical_device:GPU:1', device_type='GPU')]
MPI_size = 4, MPI_rank = 0, MPI_local_size = 2,  MPI_local_rank = 0 platform = hgpn18
List of TF visible physical GPUs :  [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU'), PhysicalDevice(name='/physical_device:GPU:1', device_type='GPU')]
MPI_size = 4, MPI_rank = 3, MPI_local_size = 2,  MPI_local_rank = 1 platform = hgpn19
```

### tf2_keras_synthetic_benchmark.py
用視覺辨識模型Resnet50，進行多GPU運算。   
* 單節點
```bash
#!/bin/bash
#SBATCH -A <PorjectID>           # iService Project id
#SBATCH -J hvd                 # job name
#SBATCH -p normal              # partition dev, normal normal2
#SBATCH --nodes=1              # Maximum number of nodes to be allocated
#SBATCH --cpus-per-task=12     # Number of cores per MPI task
#SBATCH --ntasks-per-node=4    # Number of MPI tasks (i.e. processes)
#SBATCH --gres=gpu:4           # same as --ntasks-per-node
#SBATCH -o %x_%j.out           # Path to the standard output file

export TF_ENABLE_ONEDNN_OPTS=0 # disable oneDNN message
export TF_CPP_MIN_LOG_LEVEL=3 # disable tensorflow info & warm message
export PMIX_MCA_gds=hash  # blacklist gds error

#export NCCL_DEBUG=INFO                      # Check NCCL communication
export HOROVOD_GPU_ALLREDUCE=NCCL           # force NCCL for GPU AllReduce
export NCCL_NET_GDR_LEVEL=3                 # Enable GPUDirect RDMA on H100/H200 node
#export NCCL_SOCKET_IFNAME=ib0               # NCCL use infiniband  if multi-node
#export NCCL_IB_DISABLE=0                    # Enable InfiniBand if multi-node

echo "SLURM_JOB_NODELIST=$SLURM_JOB_NODELIST"

SINGULARITY="singularity exec -B /work:/work --nv \
    /work/$(whoami)/sif/tensorflow_24.05-tf2-py3.sif"
 
CMD="python tf2_keras_synthetic_benchmark.py \
    --fp16-allreduce \
    --batch-size 128 \
    --num-batches-per-iter 100"

RUN="srun --mpi=pmix --cpu-bind=cores --nodes=$SLURM_NNODES --ntasks=$SLURM_NTASKS $SINGULARITY $CMD"
echo $RUN; $RUN
```

提交工作
```bash
[userA@cbi-lgn01 horovod]$ sbatch run_hvd.slurm
Submitted batch job 297202

[userA@cbi-lgn01 horovod]$ cat *297202*
SLURM_JOB_NODELIST=hgpn17
srun --mpi=pmix --cpu-bind=cores --nodes=1 --ntasks=2 singularity exec -B /work:/work --nv /work/userA/sif/tensorflow_24.05-tf2-py3.sif python tf2_keras_synthetic_benchmark.py --fp16-allreduce --batch-size 128 --num-batches-per-iter 100
Model: ResNet50
Batch size: 128
Number of GPUs: 2
Iter #0: 448.0 img/sec per GPU
Iter #1: 1486.4 img/sec per GPU
Iter #2: 1487.6 img/sec per GPU
Iter #3: 1486.6 img/sec per GPU
Iter #4: 1488.6 img/sec per GPU
Iter #5: 1489.1 img/sec per GPU
Iter #6: 1487.7 img/sec per GPU
Iter #7: 1487.8 img/sec per GPU
Iter #8: 1489.9 img/sec per GPU
Iter #9: 1489.0 img/sec per GPU
Img/sec per GPU: 1488.1 +-2.2
Total img/sec on 2 GPU(s): 2976.1 +-4.3
```

* 多節點

要啟用節點間InfiniBand通訊的環境變數`NCCL_SOCKET_IFNAME` ，`NCCL_IB_DISABLE`  
```bash
#!/bin/bash
#SBATCH ...

#export NCCL_DEBUG=INFO                      # Check NCCL communication
export HOROVOD_GPU_ALLREDUCE=NCCL           # force NCCL for GPU AllReduce
export NCCL_NET_GDR_LEVEL=3                 # Enable GPUDirect RDMA on H100/H200 node

export NCCL_SOCKET_IFNAME=ib0               # NCCL use infiniband  if multi-node
export NCCL_IB_DISABLE=0                    # Enable InfiniBand if multi-node
...

```

提交工作
```bash
[userA@cbi-lgn01 horovod]$ sbatch run_hvd.slurm
Submitted batch job 297159

[userA@cbi-lgn01 horovod]$ cat *297159*
SLURM_JOB_NODELIST=hgpn[04-05]
srun --mpi=pmix --cpu-bind=cores --nodes=2 --ntasks=2 singularity exec -B /work:/work --nv /work/userA/sif/tensorflow_24.05-tf2-py3.sif python tf2_keras_synthetic_benchmark.py --fp16-allreduce --batch-size 128 --num-batches-per-iter 100
Model: ResNet50
Batch size: 128
Number of GPUs: 2
Iter #0: 446.3 img/sec per GPU
Iter #1: 1478.4 img/sec per GPU
Iter #2: 1477.9 img/sec per GPU
Iter #3: 1476.1 img/sec per GPU
Iter #4: 1478.1 img/sec per GPU
Iter #5: 1476.3 img/sec per GPU
Iter #6: 1472.5 img/sec per GPU
Iter #7: 1474.8 img/sec per GPU
Iter #8: 1473.8 img/sec per GPU
Iter #9: 1474.0 img/sec per GPU
Img/sec per GPU: 1475.8 +-3.9
Total img/sec on 2 GPU(s): 2951.6 +-7.9
```

## Horovod with Pytorch
### 在有sudo權限的環境，製作映像檔

編輯`pytorch_hvd.def`，引用pytorch容器，附加horovod軟體，與設定環境變數。  
```bash
BootStrap: docker
From: nvcr.io/nvidia/pytorch:23.01-py3

%post
    # 1. 關閉 apt 的互動式詢問介面
    export DEBIAN_FRONTEND=noninteractive
    export TZ=Asia/Taipei

    # 2. 切換為 NCHC 鏡像站以加速下載 (必須放在 apt-get update 之前)
    sed -i 's|http://archive.ubuntu.com/ubuntu/|http://free.nchc.org.tw/ubuntu/|g' /etc/apt/sources.list

    # 3. 確保編譯所需的工具已安裝
    apt-get update && apt-get install -y --no-install-recommends \
        cmake \
        git \
        tzdata
    rm -rf /var/lib/apt/lists/*

    # 4. 設定 Build 階段所需的 Horovod 編譯環境變數
    export HOROVOD_GPU=CUDA
    export HOROVOD_GPU_OPERATIONS=NCCL
    export HOROVOD_NCCL_LINK=SHARED
    export HOROVOD_WITHOUT_GLOO=1
    export HOROVOD_WITH_MPI=1
    export HOROVOD_WITH_PYTORCH=1
    export HOROVOD_WITHOUT_TENSORFLOW=1
    export HOROVOD_WITHOUT_MXNET=1

    # 顯式指定 CUDA / MPI 路徑（NVIDIA NGC 容器預設路徑）
    export HOROVOD_CUDA_HOME=/usr/local/cuda

    # 5. 安裝 Horovod (使用 --no-cache-dir 並加上 --no-build-isolation 以存取既有的 PyTorch)
    pip install --no-cache-dir --no-build-isolation horovod==0.27.0

%environment
    # 6. 設定 Runtime 階段的環境變數 (確保執行時使用正確的 CUDA/NCCL 後端)
    export HOROVOD_GPU=CUDA
    export HOROVOD_GPU_OPERATIONS=NCCL
    export PATH=/usr/local/cuda/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```


在有sudo權限的環境，製作映像檔  
`sudo singularity build pytorch2301_hvd.sif pytorch_hvd.def`
將映像檔傳回晶創26/25主機

### 在晶創26/25主機，執行Horovod with Pytorch運算
run.slurm 多節點
```bash
#!/bin/bash
#SBATCH -A <PorjectID>           # iService Project id
#SBATCH -J hvd                 # job name
#SBATCH -p normal              # partition dev, normal normal2
#SBATCH --nodes=2              # Maximum number of nodes to be allocated
#SBATCH --cpus-per-task=12     # Number of cores per MPI task
#SBATCH --ntasks-per-node=1    # Number of MPI tasks (i.e. processes)
#SBATCH --gres=gpu:1           # same as --ntasks-per-node
#SBATCH -o %x_%j.out           # Path to the standard output file

#export NCCL_DEBUG=INFO                      # Check NCCL communication
export HOROVOD_GPU_ALLREDUCE=NCCL           # force NCCL for GPU AllReduce
export NCCL_NET_GDR_LEVEL=3                 # Enable GPUDirect RDMA on H100/H200 node
export NCCL_SOCKET_IFNAME=ib0               # NCCL use infiniband  if multi-node
export NCCL_IB_DISABLE=0                    # Enable InfiniBand if multi-node

echo "SLURM_JOB_NODELIST=$SLURM_JOB_NODELIST"

SECONDS=0

SINGULARITY="singularity exec -B /work:/work --nv \
    /work/$(whoami)/sif/pytorch2301_hvd.sif"

CMD="python pytorch_synthetic_benchmark.py"


RUN="srun --mpi=pmix --cpu-bind=cores --nodes=$SLURM_NNODES --ntasks=$SLURM_NTASKS $SINGULARITY $CMD"
echo $RUN; $RUN
```
