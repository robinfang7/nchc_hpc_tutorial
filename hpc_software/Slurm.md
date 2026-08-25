# Slurm
### 簡介
Slurm是一個用於 Linux 和 Unix 內核系統的自由開源的任務調度工具，Top500超級電腦廣泛採用。  
Slurm 具有三個關鍵功能：  
1. 它為使用者分配一段時間內對資源（計算節點）的獨佔或非獨佔存取權限，以便使用者執行工作。
2. 它提供了一個框架，用於在已指派的節點集上啟動、執行和監控工作（通常是平行運算的作業）。
3. 它透過管理待處理工作佇列來協調資源爭用。  

![Slurm](https://cdn.phototourl.com/free/2026-08-13-71dc800a-658c-4f15-bf1a-dcbc450df090.png)

### Slurm 架構
* **slurmctld**是叢集的總管，負責監控資源狀態與調度作業。  
* 每個計算節點有**slurmd**，負責執行**slurmctld**交代的任務。  
* 用戶發出查詢資源、提交作業的指令，**slurmctld**會跟計算節點溝通，看看有沒有閒置的資源，或是正在跑的作業。   
* **slurmdbd**記錄所有歷史作業、帳號配額與帳單資訊。

![Slurm components](https://cdn.phototourl.com/free/2026-08-25-fa56d4f8-ca63-4c95-894a-bb1de52f82a5.png)

### Slurm Entities
* Node 計算節點  
   - 叢集中的伺服器。 這些是實際執行使用者作業的硬體資源。  
* Partition分區  
   - 分區將叢集中的節點按照用途、硬體配置或管理政策劃分為不同群組，類似於工作隊列。  
   - 用戶在提交作業時需要指定目標分區，每個分區可以設定不同的資源限制與排程政策。  
* Job 作業
   - 用戶提交的計算任務，記錄了資源需求、作業狀態、提交時間、執行時間、輸出檔案等資訊。
   - 每個作業都有一個唯一的作業識別碼（Job ID），系統根據該識別碼追蹤作業進度。
* Job steps 
   - 作業可以進一步細分為一個或多個作業步驟，每個步驟通常對應一次 srun 命令的執行。
   - 這允許同一個作業內部進行序列或平行計算，並分別監控每個步驟的狀態與資源使用情形。
* Tasks
   - 一個job step可以包含一個或多個tasks，每個task代表一個要在計算節點上執行的工作。
   - 在平行計算中，tasks通常用於執行同一個任務的多個實例，從而加速計算的進行。

![Slurm Entities](https://cdn.phototourl.com/free/2026-08-25-d5d0ed1c-0426-40da-b7bd-35e7f8306a37.png)

## Partition
* 晶創26  

| 佇列     | 單一計畫（account）可用 GPU 總數 | 最少須使用 GPU 數 | 單一作業（job）最長執行時間（小時） | 同一時間內每位用戶（user）可執行（running）作業總量 | 同一時間內每位用戶（user）可等候（pending）作業總量 |
| ------ | ---------------------: | ----------: | ------------------: | ------------------------------: | ------------------------------: |
| dev    |                     32 |           1 |                   4 |                              10 |                              10 |
| 8gpus  |                     32 |           1 |                  48 |                               8 |                              10 |
| 16gpus |                     32 |           8 |                  48 |                               6 |                               8 |
| 32gpus |                     32 |          16 |                  24 |                               4 |                               6 |
| 64gpus |                     64 |          32 |                  24 |                               2 |                               4 |


* 晶創25  

| 佇列名稱    | 每個計劃最多可用 GPU 總數 | 每個 Job 最大執行時間 | 每個計畫同一時間最多可執行 Job 的數量 | 每個計畫同一時間最多可進到主機排隊的 Job 數量 | 備註   |
| ------- | --------------: | ------------: | --------------------: | ------------------------: | ---- |
| dev     |               8 |         2（小時） |                     2 |                         2 | H100 |
| normal  |              16 |        48（小時） |                     2 |                         2 | H100 |
| normal2 |              16 |        48（小時） |                     2 |                         2 | H200 |
| 4nodes  |              32 |        12（小時） |                     2 |                         2 | H100 |


### 查看Partition `sinfo`
```bash
[userA@25a-lgn01 ~]$ sinfo -s
PARTITION     AVAIL  TIMELIMIT   NODES(A/I/O/T) NODELIST
dev              up    4:00:00      99/29/0/128 25a-hgpn[001-124,142-145]
8gpus            up 2-00:00:00      99/29/0/128 25a-hgpn[001-124,142-145]
16gpus           up 2-00:00:00      99/29/0/128 25a-hgpn[001-124,142-145]
32gpus           up 1-00:00:00      99/29/0/128 25a-hgpn[001-124,142-145]
64gpus           up 1-00:00:00      99/29/0/128 25a-hgpn[001-124,142-145]
256gpus          up   12:00:00      99/29/0/128 25a-hgpn[001-124,142-145]
[userA@25a-lgn01 ~]$ sinfo
PARTITION     AVAIL  TIMELIMIT  NODES  STATE NODELIST
dev              up    4:00:00     99    mix 25a-hgpn[001-035,060-084,090-124,142-145]
dev              up    4:00:00     29   idle 25a-hgpn[036-059,085-089]
8gpus            up 2-00:00:00     99    mix 25a-hgpn[001-035,060-084,090-124,142-145]
8gpus            up 2-00:00:00     29   idle 25a-hgpn[036-059,085-089]
16gpus           up 2-00:00:00     99    mix 25a-hgpn[001-035,060-084,090-124,142-145]
16gpus           up 2-00:00:00     29   idle 25a-hgpn[036-059,085-089]
32gpus           up 1-00:00:00     99    mix 25a-hgpn[001-035,060-084,090-124,142-145]
32gpus           up 1-00:00:00     29   idle 25a-hgpn[036-059,085-089]
64gpus           up 1-00:00:00     99    mix 25a-hgpn[001-035,060-084,090-124,142-145]
64gpus           up 1-00:00:00     29   idle 25a-hgpn[036-059,085-089]
256gpus          up   12:00:00     99    mix 25a-hgpn[001-035,060-084,090-124,142-145]
256gpus          up   12:00:00     29   idle 25a-hgpn[036-059,085-089]
```
idle: 整台節點是閒置  
mix: 節點已使用(未確定完全佔用)  
drain: 維護中  

```bash
[userA@25a-lgn05 ~]$ scontrol show partition dev
PartitionName=dev
   AllowGroups=ALL DenyAccounts=mst109178 AllowQos=ALL
   AllocNodes=ALL Default=NO QoS=p_dev
   DefaultTime=NONE DisableRootJobs=NO ExclusiveUser=NO ExclusiveTopo=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=04:00:00 MinNodes=0 LLN=NO MaxCPUsPerNode=UNLIMITED MaxCPUsPerSocket=UNLIMITED
   Nodes=25a-hgpn[001-124,142-145]
   PriorityJobFactor=1 PriorityTier=15 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=OFF
   State=UP TotalCPUs=14336 TotalNodes=128 SelectTypeParameters=NONE
   JobDefaults=(null)
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED
   TRES=cpu=13312,mem=237500G,node=128,billing=13312,gres/gpu=1024

[userA@25a-lgn05 ~]$ scontrol show partition 8gpus
PartitionName=8gpus
   AllowGroups=ALL DenyAccounts=mst109178 AllowQos=ALL
   AllocNodes=ALL Default=NO QoS=p_8gpus
   DefaultTime=NONE DisableRootJobs=NO ExclusiveUser=NO ExclusiveTopo=NO GraceTime=0 Hidden=NO
   MaxNodes=UNLIMITED MaxTime=2-00:00:00 MinNodes=0 LLN=NO MaxCPUsPerNode=UNLIMITED MaxCPUsPerSocket=UNLIMITED
   Nodes=25a-hgpn[001-124,142-145]
   PriorityJobFactor=1 PriorityTier=1 RootOnly=NO ReqResv=NO OverSubscribe=NO
   OverTimeLimit=NONE PreemptMode=OFF
   State=UP TotalCPUs=14336 TotalNodes=128 SelectTypeParameters=NONE
   JobDefaults=DefMemPerGPU=204800
   DefMemPerNode=UNLIMITED MaxMemPerNode=UNLIMITED
   TRES=cpu=13312,mem=237500G,node=128,billing=13312,gres/gpu=1024
```
dev's MaxTime=04:00:00, 8gpus's MaxTime=2-00:00:00

### 查看QOS
```bash
[userA@cbi-lgn01 ~]$ sacctmgr show qos format=name,priority
      Name   Priority
---------- ----------
    normal          1
     p_dev          0
  p_normal          0
   p_taide          0
   p_trust         10
     aicoe         20
```

### 查看節點資訊
```bash 
[userA@cbi-lgn01 ~]$ scontrol show node hgpn01
NodeName=hgpn01 Arch=x86_64 CoresPerSocket=56
   CPUAlloc=9 CPUEfctv=104 CPUTot=112 CPULoad=37.41
   AvailableFeatures=(null)
   ActiveFeatures=(null)
   Gres=gpu:H100:8(S:0-1)
   NodeAddr=hgpn01 NodeHostName=hgpn01 Version=23.11.11
   OS=Linux 4.18.0-553.144.1.el8_10.x86_64 #1 SMP Mon Jul 13 11:33:25 EDT 2026
   RealMemory=1900000 AllocMem=327680 FreeMem=1107433 Sockets=2 Boards=1
   CoreSpecCount=8 CPUSpecList=52-55,108-111
   State=MIXED ThreadsPerCore=1 TmpDisk=0 Weight=1 Owner=N/A MCS_label=N/A
   Partitions=dev
   BootTime=2026-07-31T12:05:24 SlurmdStartTime=2026-07-31T12:41:41
   LastBusyTime=2026-08-12T13:06:41 ResumeAfterTime=None
   CfgTRES=cpu=104,mem=1900000M,billing=104,gres/gpu=8
   AllocTRES=cpu=9,mem=320G,gres/gpu=2
   CapWatts=n/a
   CurrentWatts=0 AveWatts=0
   ExtSensorsJoules=n/a ExtSensorsWatts=0 ExtSensorsTemp=n/a
```
查看AllocTRES這行，`gres/gpu=2` 表示此節點使用兩個GPU  

### 查看計算節點的閒置GPU數量`check_idle_gpu.sh`
```bash
[userA@cbi-lgn01 ~]$ chmod +x check_idle_gpu.sh
[userA@cbi-lgn01 ~]$ ./check_idle_gpu.sh
節點: hgpn01          | 總共: 8 張 | 已用: 3 張 | 👉 剩餘閒置: 5 張
節點: hgpn04          | 總共: 8 張 | 已用: 7 張 | 👉 剩餘閒置: 1 張
節點: hgpn06          | 總共: 8 張 | 已用: 2 張 | 👉 剩餘閒置: 6 張
```

### 查看目前Job的狀態
```bash
[userA@cbi-lgn01 ~]$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            300101       dev ev-adapt a3xxx810 PD       0:00      1 (Dependency)
            300085       dev ev-adapt a3xxx810 PD       0:00      1 (Dependency)
            300081       dev ev-adapt a3xxx810  R       0:01      1 hgpn01
            300222       dev mc-mirag u7xxx029  R       0:43      1 hgpn06
```
R: Running 運算中  
PD: Pending等待中  

### 查看目前Job的索取的GPU數量
```bash
[userA@cbi-lgn01 ~]$ squeue -o "%.9i %.9P %.12j %.10u %.2t %.10M %.6D %.16R %b"
    JOBID PARTITION         NAME       USER ST       TIME  NODES NODELIST(REASON) TRES_PER_NODE
   300198       dev         bash crixxxxlvl  R      15:46      1           hgpn01 gres/gpu:1
   300130    normal  cbsft-blind thuxxxxi98  R    1:03:08      1           hgpn20 gres/gpu:1
   299834    normal avse_sehl_si jinxxxxu19  R    4:40:05      1           hgpn18 gres/gpu:4
   299942   normal2      run_RDO kcxxxxmy00  R    3:15:28      1           hgpn41 gres/gpu:1
   295723   normal2       8xH200 seanxxxx27  R 1-13:10:14      1           hgpn43 gres/gpu:8
   295722   normal2       4xH200 seanxxxx27  R 1-13:10:14      1           hgpn45 gres/gpu:4
```
%b 表示GPU數量

## 三種執行運算的方式
* sbatch：編輯索取資源與執行運算的腳本，之後提交作業(Submit Job)。   
* surn：以一行指令取得資源與執行運算。    
* salloc：先取得資源，進入計算節點，在命令列上逐一執行運算指令，最後關閉作業。  

### sbatch
編輯腳本`run.slurm`，包含索取資源、設定環境、執行運算。  
```bash
#!/bin/bash
## 索取資源
#SBATCH --account=<PROJECT_ID>        # (-A) iService Project ID
#SBATCH --job-name=test               # (-J) Job name
#SBATCH --partition=dev               # (-p) Slurm partition
#SBATCH --nodes=2                     # (-N) Maximum number of nodes to be allocated
#SBATCH --cpus-per-task=12             # (-c) Number of cores per MPI task
#SBATCH --ntasks-per-node=1           # Maximum number of tasks on each node
#SBATCH –gres=gpu:2                   # GPU per node
#SBATCH --time=0-00:30:00             # (-t) Wall time limit (days-hrs:min:sec)
#SBATCH --output=%x-%j.out            # (-o) Path to the standard output file, %x is job name, %j is job id 
#SBATCH --error=%x-%j.err             # (-e) Path to the standard error file
#SBATCH --mail-type=END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=user@example.com  # Where to send mail.  Set this to your email address

# 引用模組
module purge
module load intel/....

# 引用容器
SIF="/path/openmpi.sif"
SINGULARITY="singularity run -B /work:/work --nv $SIF"

# 執行運算
srun --mpi=pmix -n 4 $SINGULARITY ./hello
mpiexec ./hello
```
Nano4/5的--cpus-per-task範圍是1~12。  

提交作業   
`sbatch <slurm.scirpt>`  
查尋作業狀態  
`squeue -u <主機帳號>`  
`squeue -j <JobID>`  
刪除作業  
`scancel <JobID>`  

### srun
`srun -A <ProjectID> -p <partition> -N 1 -n 1 --gres=gpu:1 <commamd>`  
-A 計畫代碼  
-p partition  
-N 取得節點數量  
-n 作業的task數量  
--gres=gpu: 索取節點內的GPU數量  

* 查詢計算節點的GPU驅動程式、CUDA版本  
```bash
[userA@cbi-lgn01 ~]$ srun -A <ProjectID> -p normal -N 1 -n 1 --gpus-per-node=1 bash -c "hostname; nvidia-smi"
hgpn19
Wed Aug 12 10:50:31 2026
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.127.08             Driver Version: 550.127.08     CUDA Version: 12.4     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA H100 80GB HBM3          On  |   00000000:C3:00.0 Off |                    0 |
| N/A   26C    P0             75W /  700W |       1MiB /  81559MiB |      0%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
[userA@cbi-lgn01 ~]$ srun -A <ProjectID> -p normal2 -N 1 -n 1 --gpus-per-node=1 bash -c "hostname; nvidia-smi"
hgpn39
Wed Aug 12 10:50:46 2026
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.127.08             Driver Version: 550.127.08     CUDA Version: 12.4     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA H200                    On  |   00000000:CA:00.0 Off |                    0 |
| N/A   24C    P0             74W /  700W |       1MiB / 143771MiB |      0%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```
* 查詢Nano4計算節點的GPU拓樸架構  
```bash
[userA@25a-lgn01 ~]$ srun -A <ProjectID> -p 8gpus -N 1 -n 1 --gres=gpu:8 nvidia-smi topo -m
srun: job 249826 queued and waiting for resources
srun: job 249826 has been allocated resources
        GPU0    GPU1    GPU2    GPU3    GPU4    GPU5    GPU6    GPU7    NIC0    NIC1    NIC2    NIC3    NIC4    NIC5    NIC6    NIC7    NIC8    NIC9    CPU Affinity    NUMA Affinity   GPU NUMA ID
GPU0     X      NV18    NV18    NV18    NV18    NV18    NV18    NV18    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE            0               N/A
GPU1    NV18     X      NV18    NV18    NV18    NV18    NV18    NV18    NODE    NODE    NODE    PIX     NODE    NODE    NODE    NODE    NODE    NODE            0               N/A
GPU2    NV18    NV18     X      NV18    NV18    NV18    NV18    NV18    NODE    NODE    NODE    NODE    PIX     NODE    NODE    NODE    NODE    NODE            0               N/A
GPU3    NV18    NV18    NV18     X      NV18    NV18    NV18    NV18    NODE    NODE    NODE    NODE    NODE    PIX     NODE    NODE    NODE    NODE            0               N/A
GPU4    NV18    NV18    NV18    NV18     X      NV18    NV18    NV18    NODE    NODE    NODE    NODE    NODE    NODE    PIX     NODE    NODE    NODE    56      1               N/A
GPU5    NV18    NV18    NV18    NV18    NV18     X      NV18    NV18    NODE    NODE    NODE    NODE    NODE    NODE    NODE    PIX     NODE    NODE    56      1               N/A
GPU6    NV18    NV18    NV18    NV18    NV18    NV18     X      NV18    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    PIX     NODE    56      1               N/A
GPU7    NV18    NV18    NV18    NV18    NV18    NV18    NV18     X      NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    PIX     56      1               N/A
NIC0    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE     X      NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE
NIC1    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE     X      PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE
NIC2    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    PIX      X      NODE    NODE    NODE    NODE    NODE    NODE    NODE
NIC3    NODE    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE     X      NODE    NODE    NODE    NODE    NODE    NODE
NIC4    NODE    NODE    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE     X      NODE    NODE    NODE    NODE    NODE
NIC5    NODE    NODE    NODE    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE     X      NODE    NODE    NODE    NODE
NIC6    NODE    NODE    NODE    NODE    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE     X      NODE    NODE    NODE
NIC7    NODE    NODE    NODE    NODE    NODE    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE     X      NODE    NODE
NIC8    NODE    NODE    NODE    NODE    NODE    NODE    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE     X      NODE
NIC9    NODE    NODE    NODE    NODE    NODE    NODE    NODE    PIX     NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE    NODE     X

Legend:

  X    = Self
  SYS  = Connection traversing PCIe as well as the SMP interconnect between NUMA nodes (e.g., QPI/UPI)
  NODE = Connection traversing PCIe as well as the interconnect between PCIe Host Bridges within a NUMA node
  PHB  = Connection traversing PCIe as well as a PCIe Host Bridge (typically the CPU)
  PXB  = Connection traversing multiple PCIe bridges (without traversing the PCIe Host Bridge)
  PIX  = Connection traversing at most a single PCIe bridge
  NV#  = Connection traversing a bonded set of # NVLinks

NIC Legend:

  NIC0: mlx5_0
  NIC1: mlx5_1
  NIC2: mlx5_2
  NIC3: mlx5_3
  NIC4: mlx5_4
  NIC5: mlx5_5
  NIC6: mlx5_6
  NIC7: mlx5_7
  NIC8: mlx5_8
  NIC9: mlx5_9
```

* 互動式執行
```bash
[userA@25a-lgn05 ~]$ srun -A <ProjectID> -p dev -N 1 -n 1 --gres=gpu:1 --pty bash
[userA@25a-hgpn026 ~]$ squeue -u userA
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            258131       dev     bash userA  R       0:09      1 25a-hgpn026
[userA@25a-hgpn026 ~]$ hostname
25a-hgpn026
[userA@25a-hgpn026 ~]$ exit
exit
```

### salloc

```bash
[userA@25a-lgn05 ~]$ salloc -A <ProjectID> -p dev -N 1 -n 1 --gres=gpu:1
salloc: Granted job allocation 258152
salloc: Nodes 25a-hgpn026 are ready for job

[userA@25a-lgn05 salloc_258152 ~]$ ssh 25a-hgpn026
Register this system with Red Hat Insights: rhc connect

Example:
# rhc connect --activation-key <key> --organization <org>

The rhc client and Red Hat Insights will enable analytics and additional
management capabilities on your system.
View your connected systems at https://console.redhat.com/insights

You can learn more about how to register your system
using rhc at https://red.ht/registration

[userA@25a-hgpn026 ~]$ hostname
25a-hgpn026
[userA@25a-hgpn026 ~]$ nvidia-smi
Thu Aug 13 15:48:07 2026
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.65.06              Driver Version: 580.65.06      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA H200                    On  |   00000000:3A:00.0 Off |                    0 |
| N/A   36C    P0             79W /  700W |       0MiB / 143771MiB |      0%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
[userA@25a-hgpn026 ~]$ exit
logout
Connection to 25a-hgpn026 closed.
[userA@25a-lgn05 salloc_258152 ~]$ exit
exit
salloc: Relinquishing job allocation 258152
[userA@25a-lgn05 ~]$ squeue -u userA
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
[userA@25a-lgn05 ~]$
```

## Slurm環境變數
提交作業後，產生Slurm的環境變數，可做為平行運算的參數。以下是常見的環境變數。  

| 變數名稱                                  | 描述                                     |
| ---------------------------------------- | ---------------------------------------- |
| `SLURM_JOB_ID`                           | Job ID                                   |
| `SLURM_JOB_NAME`                         | Job name                                 |
| `SLURM_JOB_ACCOUNT`                      | Project id                               |
| `SLURM_JOB_NUM_NODES`<br>`SLURM_NNODES`  | Number of nodes allocated to job         |
| `SLURM_JOB_NODELIST`<br>`SLURM_NODELIST` | Nodes assigned to job                    |
| `SLURM_NTASKS_PER_NODE`                  | Number of tasks requested per node.      |
| `SLURM_NTASKS`                           | Total tasks in job                       |
| `SLURM_GPUS_ON_NODE`                     | Number of GPUs per node                  |


取得作業的所有Slurm環境變數
```bash
[userA@25a-lgn05 ~]$ srun -A <ProjectID> -p dev -N 1 -n 1 --gres=gpu:2 printenv | grep SLURM
SLURM_CONF=/etc/slurm/slurm.conf
SLURM_PRIO_PROCESS=0
SLURM_UMASK=0027
SLURM_CLUSTER_NAME=hpc
SLURM_SUBMIT_DIR=/home/userA
SLURM_SUBMIT_HOST=25a-lgn05
SLURM_JOB_NAME=printenv
SLURM_JOB_CPUS_PER_NODE=1
SLURM_MEM_PER_NODE=409600
SLURM_NTASKS=1
SLURM_NPROCS=1
SLURM_DISTRIBUTION=cyclic,pack
SLURMD_DEBUG=2
SLURM_JOB_ID=258187
SLURM_JOBID=258187
SLURM_STEP_ID=0
SLURM_STEPID=0
SLURM_NNODES=1
SLURM_JOB_NUM_NODES=1
SLURM_NODELIST=25a-hgpn026
SLURM_JOB_PARTITION=dev
SLURM_TASKS_PER_NODE=1
SLURM_JOB_UID=12409
SLURM_JOB_USER=userA
SLURM_JOB_GID=18361
SLURM_JOB_GROUP=TRI1072239
SLURM_JOB_ACCOUNT=<ProjectID>
SLURM_JOB_QOS=normal
SLURM_JOB_NODELIST=25a-hgpn026
SLURM_STEP_NODELIST=25a-hgpn026
SLURM_STEP_NUM_NODES=1
SLURM_STEP_NUM_TASKS=1
SLURM_STEP_TASKS_PER_NODE=1
SLURM_STEP_LAUNCHER_PORT=46441
SLURM_SRUN_COMM_PORT=46441
SLURM_SRUN_COMM_HOST=172.21.103.15
SLURM_GPUS_ON_NODE=2
SLURM_STEP_GPUS=1,3
SLURM_TOPOLOGY_ADDR=root.ibsw-h200.25a-hgpn026
SLURM_TOPOLOGY_ADDR_PATTERN=switch.switch.node
SLURM_CPUS_ON_NODE=1
SLURM_CPU_BIND=quiet,mask_cpu:0x0000000000000400000000000000
SLURM_CPU_BIND_LIST=0x0000000000000400000000000000
SLURM_CPU_BIND_TYPE=mask_cpu:
SLURM_CPU_BIND_VERBOSE=quiet
SLURM_OOM_KILL_STEP=0
SLURM_JOB_END_TIME=1786621922
SLURM_JOB_START_TIME=1786607522
SLURM_TASK_PID=4193906
SLURM_NODEID=0
SLURM_PROCID=0
SLURM_LOCALID=0
SLURM_LAUNCH_NODE_IPADDR=172.21.103.15
SLURM_GTIDS=0
SLURMD_NODENAME=25a-hgpn026
```
