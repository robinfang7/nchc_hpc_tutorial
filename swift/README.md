# 用SWIFT框架進行LLM微調
[SWIFT](https://github.com/modelscope/ms-swift)是大語言模型訓練、推論、佈署的框架。

## 用uv安裝swift
```bash
# 新增專案資料夾
[userA@25a-lgn02 ~]$ mkdir swift_uv && cd swift_uv

# 建立python3.12的虛擬環境
[userA@25a-lgn02 swift_uv]$ uv venv --python 3.12
Using CPython 3.12.13
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate

# 啟用虛擬環境
[userA@25a-lgn02 swift_uv]$ source .venv/bin/activate

# 安裝swift套件
(swift_uv) [userA@25a-lgn02 swift_uv]$ uv pip install ms-swift -U --torch-backend=auto
```
[已安裝套件清單]() 

## 下載Huggingface模型與資料集
### 套件清單有huggingface-hub，選用access token登入
```bash
(swift_uv) [userA@25a-lgn05 swift_uv]$ hf auth login
? How would you like to log in?  [Use arrows, Enter to confirm]
  Log in with your browser
> Paste an access token

    To log in, `huggingface_hub` requires a token generated from https://huggingface.co/settings/tokens .
Enter your token (input will not be visible):
Token is valid (permission: read).
The token `BLOOM` has been saved to /home/userA/.cache/huggingface/stored_tokens
Your token has been saved to /home/userA/.cache/huggingface/token
Login successful.
The current active token is: `BLOOM`
(swift_uv) [userA@25a-lgn05 swift_uv]$ hf auth whoami
✓ Logged in
  user: ybfang
```

### 在HFS新增模型與資料的路徑， 下載模型Qwen/Qwen3-4B-Instruct-2507與資料集vicgalle/alpaca-gpt4
```bash
(swift_uv) [userA@25a-lgn02 swift_uv]$ mkdir -p /work/$(whoami)/llm_models
(swift_uv) [userA@25a-lgn02 swift_uv]$ hf download Qwen/Qwen3-4B-Instruct-2507 --local-dir /work/userA/llm_models/Qwen3-4B-Instruct-2507
Fetching 13 files: 100%|███████████████████████████████████████████████████████████████████████████████████| 13/13 [00:00<00:00, 69.94it/s]  
Download complete: :                                                          |  0.00B            ✓ Downloadedion complete:    
  path: /work/userA/llm_models/Qwen3-4B-Instruct-2507
Download complete: :                                                                                                   |  0.00B
Reconstruction complete: |                                                                                    |  0.00B /  0.00B
(swift_uv) [userA@25a-lgn02 swift_uv]$ ls /work/userA/llm_models/Qwen3-4B-Instruct-2507
config.json             merges.txt                        model-00003-of-00003.safetensors  tokenizer_config.json
generation_config.json  model-00001-of-00003.safetensors  model.safetensors.index.json      tokenizer.json
LICENSE                 model-00002-of-00003.safetensors  README.md                         vocab.json

(swift_uv) [userA@25a-lgn02 swift_uv]$ mkdir -p /work/$(whoami)/data
(swift_uv) [userA@25a-lgn02 swift_uv]$ hf download --repo-type dataset vicgalle/alpaca-gpt4 --local-dir /work/userA/data/vicgalle_alpaca-gpt4
Fetching 3 files: 100%|██████████████████████████████████████████████████████████████████████████████████████| 3/3 [00:03<00:00,  1.28s/it]  
Download complete: : █████████████████████████████████████████████████████████████| 48.2MB, 48.0MB/s  ✓ Downloadedion complete: 100%  
  path: /work/userA/data/vicgalle_alpaca-gpt4
Download complete: : █████████████████████████████████████████████████████████████████████████████████████████████| 48.2MB, 48.0MB/s
Reconstruction complete: 100%|███████████████████████████████████████████████████████████████████████████| 48.4MB / 48.4MB, 14.4MB/s
(swift_uv) [userA@25a-lgn02 swift_uv]$ ls /work/userA/data/vicgalle_alpaca-gpt4
data  README.md
```

## 用一張H200對Qwen3-4B模型微調
### 編輯腳本`run.slurm`
```bash
#!/bin/bash
#SBATCH -A <ProjectID>         # iService Project id
#SBATCH -J swift               # job name
#SBATCH -p dev                 # partition dev
#SBATCH --nodes=1              # Maximum number of nodes to be allocated
#SBATCH --ntasks-per-node=1    # Number of MPI tasks (i.e. processes)
#SBATCH --cpus-per-task=12     # Number of cores per MPI task
#SBATCH --gres=gpu:1
#SBATCH -o %x_%j.out           # Path to the standard output file

[-d "output" ] && rm -rf output
SECONDS=0

CUDA_VISIBLE_DEVICES=0 \
swift sft \
    --model /work/userA/llm_models/Qwen3-4B-Instruct-2507 \
    --tuner_type lora \
    --dataset /work/userA/data/vicgalle_alpaca-gpt4 \
    --torch_dtype bfloat16 \
    --num_train_epochs 1 \
    --per_device_train_batch_size 1 \
    --per_device_eval_batch_size 1 \
    --learning_rate 1e-4 \
    --lora_rank 8 \
    --lora_alpha 32 \
    --target_modules all-linear \
    --gradient_accumulation_steps 16 \
    --eval_steps 50 \
    --save_steps 50 \
    --save_total_limit 2 \
    --logging_steps 5 \
    --max_length 2048 \
    --output_dir output \
    --warmup_ratio 0.05 \
    --dataloader_num_workers 4 \
    --model_author swift \
    --model_name swift-robot

deactivate
```

提交作業
```bash
[userA@25a-lgn05 swift_uv]$ sbatch run.slurm
Submitted batch job 287023
[userA@25a-lgn05 swift_uv]$ squeue -u userA
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            287023       dev    swift userA  R       4:12      1 25a-hgpn001
[userA@25a-lgn05 swift_uv]$ ssh 25a-hgpn001
Last login: Wed Aug  5 15:46:05 2026 from 172.21.x.x
[userA@25a-hgpn001 ~]$ watch nvidia-smi
Every 2.0s: nvidia-smi                                       25a-hgpn001: Fri Aug 21 14:00:46 2026

Fri Aug 21 14:00:46 2026
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.65.06              Driver Version: 580.65.06      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA H200                    On  |   00000000:DA:00.0 Off |                    0 |
| N/A   59C    P0            607W /  700W |  127253MiB / 143771MiB |    100%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A         1082305      C   ...16/swift_uv/.venv/bin/python3      12724... |
+-----------------------------------------------------------------------------------------+

[userA@25a-hgpn001 ~]$ exit
logout
Connection to 25a-hgpn001 closed.
[userA@25a-lgn05 swift_uv]$
```