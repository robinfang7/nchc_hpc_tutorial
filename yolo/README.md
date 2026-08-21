# Training YOLO with 1 H200 GPU on Nano4
第一次上超級電腦的GPU叢集，可以先從訓練YOLO模型上手。YOLO模型非常小，個人電腦可以訓練，移植到超級電腦非常容易，差別在取得計算資源安裝環境。  
方法1. 本範例說明下載YOLO專用的ultralytics容器，透過啟用容器，執行訓練YOLO模型。  
方法2. 本範例說明採用uv安裝ultralytics，執行訓練YOLO模型。  
參考網頁：https://colab.research.google.com/github/EdjeElectronics/Train-and-Deploy-YOLO-Models/blob/main/Train_YOLO_Models.ipynb#scrollTo=8bbpob1gTPlo

## 資料集處理
### 下載與解壓縮資料集candy_data_06JAN25.zip
```bash
[userA@25a-lgn04 ~]$ mkdir -p ~/yolo
[userA@25a-lgn04 ~]$ cd ~/yolo

[userA@25a-lgn04 yolo]$ wget https://s3.us-west-1.amazonaws.com/evanjuras.com/resources/candy_data_06JAN25.zip
[userA@25a-lgn04 yolo]$ unzip -q candy_data_06JAN25.zip -d data

[userA@25a-lgn04 yolo]$ ls data
classes.txt  images  labels  notes.json
```

### 切分資料，訓練集占90%
```bash
[userA@25a-lgn04 yolo]$ python train_val_split.py --datapath=data --train_pct=0.9
Created folder at /home/userA/yolo/data/train/images.
Created folder at /home/userA/yolo/data/train/labels.
Created folder at /home/userA/yolo/data/validation/images.
Created folder at /home/userA/yolo/data/validation/labels.
Number of image files: 162
Number of annotation files: 162
Images moving to train: 145
Images moving to validation: 17

[userA@25a-lgn04 yolo]$ ls data/train data/validation/
data/train:
images  labels  labels.cache

data/validation/:
images  labels  labels.cache
```

### 製作資料集的yaml檔
yaml檔指定資料集的路徑與類別
```bash
# 製作資料的yaml檔
[userA@25a-lgn04 yolo]$ python create_yaml.py

[userA@25a-lgn04 yolo]$ ls -lt
total 272044
-rw-r----- 1 userA TRI1072239       204 Aug  5 14:11 data.yaml
-rw-r----- 1 userA TRI1072239      1075 Aug  5 14:11 create_yaml.py

[userA@25a-lgn04 yolo]$ cat data.yaml
path: /home/userA/yolo/data
train: train/images
val: validation/images
nc: 11
names:
- MMs_peanut
- MMs_regular
- airheads
- gummy_worms
- milky_way
- nerds
- skittles
- snickers
- starbust
- three_musketeers
- twizzlers
```
若資料前處理需要很時間和計算資源，建議在計算節點執行
```bash
[userA@25a-lgn04 ~]$ srun -A <ProjectID> -p dev -N 1 -n 1 --gres=gpu:1 python train_val_split.py --datapath=data --train_pct=0.9
[userA@25a-lgn04 ~]$ srun -A <ProjectID> -p dev -N 1 -n 1 --gres=gpu:1 python create_yaml.py
```
-A <ProjectID> 表示執行此工作job的計畫代碼  
-p dev 表示指定dev partition  
-N 1 表示使用一個計算節點  
-n 1 表示執行一個任務task  
--gres=gpu:1 表示使用一個GPU  

## 方法1：下載ultralytics容器
容器來源：https://hub.docker.com/r/ultralytics/ultralytics
建議適用於資料中心GPU伺服器的版本：ultralytics:8.4.115
```bash
[userA@25a-lgn04 ~]$ singularity pull ultralytics-8.4.115.sif docker://ultralytics/ultralytics:8.4.115
[userA@25a-lgn04 ~]$ mv ultralytics-8.4.115.sif /work/$(whoami)/sif/
```

提交工作與訓練YOLO模型  
* 注意1：訓練YOLO模型前，為了驗證有啟用AMP，程式碼會自行下載`yolo26n.pt`。實際訓練的模型為 `model=yolo11x.pt`。  
* 注意2：ultralytics容器的預設工作路徑是`/ultralytics`，在 `singularity exec` 加上 `--pwd $PWD` 參數，強迫容器將執行目錄切換至目前宿主機工作目錄，避免 relative path 定位到 `/ultralytics`。  
```bash
[userA@25a-lgn04 yolo]$ sbatch run.slurm
Submitted batch job 238642
```

訓練過程中，觀察GPU使用率
```bash
[userA@25a-lgn04 yolo]$ squeue -j 238642
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            238642       dev     yolo userA  R       0:11      1 25a-hgpn009
[userA@25a-lgn04 yolo]$ ssh 25a-hgpn009
The authenticity of host '25a-hgpn009 (172.21.100.9)' can't be established.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes

[userA@25a-hgpn009 ~]$ watch nvidia-smi
Every 2.0s: nvidia-smi                                                                                 25a-hgpn009: Fri Aug  7 11:22:46 2026

Fri Aug  7 11:22:46 2026
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.65.06              Driver Version: 580.65.06      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA H200                    On  |   00000000:3A:00.0 Off |                    0 |
| N/A   37C    P0            119W /  700W |   16057MiB / 143771MiB |     92%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A         3829683      C   /usr/bin/python                       16046MiB |
+-----------------------------------------------------------------------------------------+

[userA@25a-hgpn009 ~]$ exit
logout
Connection to 25a-hgpn009 closed.
```

觀察訓練過程與結果
```bash
[userA@25a-lgn02 yolo]$ cat yolo_238642.out
Ultralytics 8.4.115 🚀 Python-3.12.3 torch-2.11.0+cu128 CUDA:0 (NVIDIA H200, 143156MiB)
engine/trainer: agnostic_nms=False, amp=True, angle=1.0, augment=False, auto_augment=randaugment, batch=16, bgr=0.0, box=7.5, cache=False, cfg=None, channels_last=False, classes=None, close_mosaic=10, cls=0.5, cls_pw=0.0, cls_remap=True, compile=False, conf=None, copy_paste=0.0, copy_paste_mode=flip, cos_lr=False, cutmix=0.0, data=data.yaml, degrees=0.0, deterministic=True, device=, dfl=1.5, dgrad=0.5, dis=6.0, distill_model=None, dlam=1.0, dlog=1.0, dnn=False, dropout=0.0, dynamic=False, embed=None, end2end=None, epochs=60, erasing=0.4, exist_ok=False, fliplr=0.5, flipud=0.0, format=torchscript, fraction=1.0, freeze=None, hsv_h=0.015, hsv_s=0.7, hsv_v=0.4, imgsz=640, iou=0.7, keras=False, kobj=1.0, line_width=None, lr0=0.01, lrf=0.01, mask_ratio=4, max_det=300, mixup=0.0, mode=train, model=yolo11x.pt, momentum=0.937, mosaic=1.0, multi_scale=0.0, name=train, nbs=64, nms=False, opset=None, optimize=False, optimizer=auto, overlap_mask=True, patience=100, perspective=0.0, plots=True, pose=12.0, pretrained=True, profile=False, project=/home/userA/yolo/runs, quantize=None, rect=False, resume=False, retina_masks=False, rle=1.0, save=True, save_conf=False, save_crop=False, save_dir=/home/userA/yolo/runs/train, save_frames=False, save_json=False, save_period=-1, save_txt=False, scale=0.5, seed=0, shear=0.0, show=False, show_boxes=True, show_conf=True, show_labels=True, simplify=True, single_cls=False, source=None, split=val, stream_buffer=False, task=detect, time=None, tracker=tracktrack.yaml, translate=0.1, val=True, verbose=True, vid_stride=1, visualize=False, warmup_bias_lr=0.1, warmup_epochs=3.0, warmup_momentum=0.8, weight_decay=0.0005, workers=8, workspace=None

...

Validating /home/userA/yolo/runs/train/weights/best.pt...
Ultralytics 8.4.115 🚀 Python-3.12.3 torch-2.11.0+cu128 CUDA:0 (NVIDIA H200, 143156MiB)
YOLO11x summary (fused): 191 layers, 56,839,729 parameters, 0 gradients, 194.8 GFLOPs
                 Class     Images  Instances      Box(P          R      mAP50  mAP50-95): 100% ━━━━━━━━━━━━ 1/1 5.5it/s 0.2s
                   all         17         59      0.939      0.946      0.978      0.872
            MMs_peanut          4          6      0.935          1      0.995      0.875
           MMs_regular          6          8      0.964          1      0.995      0.917
              airheads          4          7      0.889      0.857      0.855      0.791
           gummy_worms          9          9       0.97          1      0.995      0.907
             milky_way          4          4      0.982          1      0.995      0.937
                 nerds          4          4          1      0.875      0.995      0.882
              skittles          4          4      0.929          1      0.995       0.92
              snickers          3          3       0.92          1      0.995      0.895
              starbust          4          4      0.768          1      0.945      0.843
      three_musketeers          2          2          1      0.669      0.995      0.696
             twizzlers          7          8      0.975          1      0.995      0.926
Speed: 0.0ms preprocess, 1.5ms inference, 0.0ms loss, 0.4ms postprocess per image
Results saved to /home/userA/yolo/runs/train
💡 Learn more at https://docs.ultralytics.com/modes/train
```

計算結果的路徑
```bash
[userA@25a-lgn02 yolo_uv]$ ls runs/train
args.yaml        BoxR_curve.png                   results.csv       train_batch2150.jpg  val_batch0_labels.jpg  val_batch2_labels.jpg
BoxF1_curve.png  confusion_matrix_normalized.png  results.png       train_batch2151.jpg  val_batch0_pred.jpg    val_batch2_pred.jpg
BoxP_curve.png   confusion_matrix.png             train_batch0.jpg  train_batch2152.jpg  val_batch1_labels.jpg  weights
BoxPR_curve.png  labels.jpg                       train_batch1.jpg  train_batch2.jpg     val_batch1_pred.jpg
```

## 方法2：用uv安裝ultralytics
安裝uv
```bash
[userA@25a-lgn02 ~]$ cd ~
[userA@25a-lgn02 ~]$ curl -LsSf https://astral.sh/uv/install.sh | sh
downloading uv 0.11.29 x86_64-unknown-linux-gnu
installing to /home/userA/.local/bin
  uv
  uvx
everything's installed!

[userA@25a-lgn02 ~]$ uv --version
uv 0.12.2 (x86_64-unknown-linux-gnu)
```
`/home/<user>/.local/bin` 已在$PATH，表示uv是預設的執行檔。

建立yolo_uv專案，專案資料夾名稱不要用`yolo`，因為安裝ultralytics後的yolo是執行檔，若專案資料夾名稱為yolo，會發生環境異常。  
安裝python 3.11的虛擬環境。  
```bash
[userA@25a-lgn02 ~]$ mkdir yolo_uv && cd yolo_uv
[userA@25a-lgn04 yolo_uv]$ uv venv --python 3.11
Using CPython 3.11.15
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
[userA@25a-lgn04 yolo_uv]$ tree -a
.
└── .venv
    ├── bin
    │   ├── activate
    │   ├── activate.bat
    │   ├── activate.csh
    │   ├── activate.fish
    │   ├── activate.nu
    │   ├── activate.ps1
    │   ├── activate_this.py
    │   ├── activate.xsh
    │   ├── deactivate.bat
    │   ├── pydoc.bat
    │   ├── python -> /home/userA/.local/share/uv/python/cpython-3.11-linux-x86_64-gnu/bin/python3.11
    │   ├── python3 -> python
    │   └── python3.11 -> python
    ├── CACHEDIR.TAG
    ├── .gitignore
    ├── lib
    │   └── python3.11
    │       └── site-packages
    │           ├── _virtualenv.pth
    │           └── _virtualenv.py
    ├── lib64 -> lib
    └── pyvenv.cfg

6 directories, 18 files
```

啟用虛擬環境，查看python版本 
```bash
[userA@25a-lgn04 yolo_uv]$ source .venv/bin/activate
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ python --version
Python 3.11.15
```

安裝ultralytics，注意CUDA版本是否接近GPU driver的版本。   
```bash
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ uv pip install ultralytics
Resolved 59 packages in 5.30s
Prepared 59 packages in 2m 24s
Installed 59 packages in 6.72s
 + anyio==4.14.2
 + certifi==2026.7.22
 + charset-normalizer==3.5.1
 + contourpy==1.3.3
 + cuda-bindings==13.3.1
 + cuda-pathfinder==1.6.1
 + cuda-toolkit==13.0.3.0
 + cycler==0.12.1
 + filelock==3.32.3
 + fonttools==4.63.0
 + fsspec==2026.7.0
 + h11==0.16.0
 + httpcore==1.0.9
 + httpx==0.28.1
 + idna==3.19
 + jinja2==3.1.6
 + kiwisolver==1.5.0
 + markupsafe==3.0.3
 + matplotlib==3.11.1
 + mpmath==1.3.0
 + networkx==3.6.1
 + numpy==2.4.6
 + nvidia-cublas==13.1.1.3
 + nvidia-cuda-cupti==13.0.85
 + nvidia-cuda-nvrtc==13.0.88
 + nvidia-cuda-runtime==13.0.96
 + nvidia-cudnn-cu13==9.20.0.48
 + nvidia-cufft==12.0.0.61
 + nvidia-cufile==1.15.1.6
 + nvidia-curand==10.4.0.35
 + nvidia-cusolver==12.0.4.66
 + nvidia-cusparse==12.6.3.3
 + nvidia-cusparselt-cu13==0.8.1
 + nvidia-ml-py==13.610.43
 + nvidia-nccl-cu13==2.29.7
 + nvidia-nvjitlink==13.3.33
 + nvidia-nvshmem-cu13==3.4.5
 + nvidia-nvtx==13.0.85
 + opencv-python==5.0.0.93
 + packaging==26.3
 + pillow==12.3.0
 + polars==1.43.2
 + polars-runtime-32==1.43.2
 + psutil==7.2.2
 + pyparsing==3.3.2
 + python-dateutil==2.9.0.post0
 + pyyaml==6.0.3
 + requests==2.34.2
 + setuptools==84.0.0
 + six==1.17.0
 + sympy==1.14.0
 + torch==2.13.0
 + torchvision==0.28.0
 + triton==3.7.1
 + typing-extensions==4.16.0
 + ultralytics==8.4.124
 + ultralytics-platform==0.1.8
 + ultralytics-thop==2.1.6
 + urllib3==2.7.0
```

查看yolo版本  
```bash
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ yolo version
8.4.124
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ yolo checks
Ultralytics 8.4.124 🚀 Python-3.11.15 torch-2.13.0+cu130 CUDA:0 (NVIDIA H100 NVL, 95320MiB)
Setup complete ✅ (224 CPUs, 503.0 GB RAM, 134.1/1786.3 GB disk)

OS                     Linux-5.14.0-570.116.1.el9_6.x86_64-x86_64-with-glibc2.34
Environment            Linux
Python                 3.11.15
Install                pip
Path                   /home/userA/yolo_uv/.venv/lib/python3.11/site-packages/ultralytics
RAM                    503.03 GB
Disk                   134.1/1786.3 GB
CPU                    Intel Xeon Platinum 8480+
CPU count              224
GPU                    NVIDIA H100 NVL, 95320MiB
GPU count              1
CUDA                   13.0

filelock               ✅ 3.32.3>=3.16.1
numpy                  ✅ 2.4.6>=1.23.0; platform_system != "Darwin"
numpy                  ✅ 2.4.6!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.0,!=2.3.1,!=2.3.2,!=2.3.3,!=2.3.4,>=1.23.0; platform_system == "Darwin"
matplotlib             ✅ 3.11.1>=3.3.0
opencv-python          ✅ 5.0.0.93!=4.13.0.90,>=4.7.0
pillow                 ✅ 12.3.0>=7.1.2
pyyaml                 ✅ 6.0.3>=5.3.1
requests               ✅ 2.34.2>=2.23.0
torch                  ✅ 2.13.0>=1.8.0
torch                  ✅ 2.13.0!=2.4.0,>=1.8.0; sys_platform == "win32"
torchvision            ✅ 0.28.0>=0.9.0
psutil                 ✅ 7.2.2>=5.8.0
polars                 ✅ 1.43.2>=0.20.0
nvidia-ml-py           ✅ 13.610.43>=12.0.0
ultralytics-thop       ✅ 2.1.6>=2.1.6
ultralytics-platform   ✅ 0.1.8>=0.1.3; python_version >= "3.11"
```

查看runs的路徑。若runs不在目前路徑下，用`yolo settings reset`重新設定
```bash
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ yolo settings
JSONDict("/home/userA/.config/Ultralytics/settings.json"):
{
  "settings_version": "0.0.7",
  "datasets_dir": "/home/userA/datasets",
  "weights_dir": "/home/userA/yolo_uv/weights",
  "runs_dir": "/home/userA/yolo_uv/runs",
  "uuid": "a7580d324d0b644dbf787fe740a7b9540563bb9c0a3844faab97319a46af9fa2",
  "sync": true,
  "api_key": "",
  "openai_api_key": "",
  "clearml": true,
  "comet": true,
  "dvc": true,
  "mlflow": true,
  "neptune": true,
  "raytune": true,
  "tensorboard": false,
  "wandb": false,
  "vscode_msg": true,
  "openvino_msg": true
}
💡 Learn more about Ultralytics Settings at https://docs.ultralytics.com/quickstart/#ultralytics-settings

(yolo_uv) [userA@25a-lgn04 yolo_uv]$ yolo settings reset
Settings reset successfully
JSONDict("/home/userA/.config/Ultralytics/settings.json"):
{
  "settings_version": "0.0.7",
  "datasets_dir": "/home/userA/yolo_uv/datasets",
  "weights_dir": "weights",
  "runs_dir": "runs",
  "uuid": "ebe50968e8ba139707201743be1d0a1a21ead3ceb962aecae987502daea3c806",
  "sync": true,
  "api_key": "",
  "openai_api_key": "",
  "clearml": true,
  "comet": true,
  "dvc": true,
  "mlflow": true,
  "neptune": true,
  "raytune": true,
  "tensorboard": false,
  "wandb": false,
  "vscode_msg": true,
  "openvino_msg": true
}
💡 Learn more about Ultralytics Settings at https://docs.ultralytics.com/quickstart/#ultralytics-settings
```

複製方法一的data.yaml  
```bash
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ cp ~/yolo/data.yaml data.yaml
```

編輯Slurm script `run_uv.slurm`  
```bash
#!/bin/bash
#SBATCH -A <ProjectID>           # iService Project id
#SBATCH -J yolo                # job name
#SBATCH -p dev                # partition dev normal normal2
#SBATCH --nodes=1              # Maximum number of nodes to be allocated
#SBATCH --ntasks-per-node=1    # Number of MPI tasks (i.e. processes)
#SBATCH --cpus-per-task=12      # Number of cores per MPI task
#SBATCH --gres=gpu:1
#SBATCH -o %x_%j.out          # Path to the standard output file
##SBATCH -t 0-06:00:00

export CUDA_VISIBLE_DEVICES=0
source .venv/bin/activate

yolo detect train data=data.yaml model=yolo11x.pt epochs=60 imgsz=640 project=$SLURM_SUBMIT_DIR/runs
deactivate
```

提交作業與查看計算節點的GPU使用量 
```bash
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ sbatch run_uv.slurm
Submitted batch job 286542

(yolo_uv) [userA@25a-lgn04 yolo_uv]$ squeue -u userA
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            286542       dev     yolo userA  R       0:46      1 25a-hgpn008
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ ssh 25a-hgpn008

[userA@25a-hgpn008 ~]$ watch nvidia-smi
Every 2.0s: nvidia-smi                                                                                25a-hgpn008: Fri Aug 21 09:40:39 2026

Fri Aug 21 09:40:39 2026
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.65.06              Driver Version: 580.65.06      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA H200                    On  |   00000000:CA:00.0 Off |                    0 |
| N/A   49C    P0            461W /  700W |   16079MiB / 143771MiB |     99%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A         2740463      C   ...716/yolo_uv/.venv/bin/python3      16068MiB |
+-----------------------------------------------------------------------------------------+
[userA@25a-hgpn008 ~]$ exit
logout
Connection to 25a-hgpn008 closed.

(yolo_uv) [userA@25a-lgn04 yolo_uv]$ tail *286542*
      54/60        15G     0.3647     0.2928     0.8508          5        640: 100% ━━━━━━━━━━━━ 10/10 8.5it/s 1.2s
                 Class     Images  Instances      Box(P          R      mAP50  mAP50-95): 100% ━━━━━━━━━━━━ 1/1 5.7it/s 0.2s
                   all         17         75      0.954       0.94      0.965      0.883

      Epoch    GPU_mem   box_loss   cls_loss   dfl_loss  Instances       Size
      55/60        15G     0.3588     0.3004     0.8677          5        640: 100% ━━━━━━━━━━━━ 10/10 8.7it/s 1.2s
                 Class     Images  Instances      Box(P          R      mAP50  mAP50-95): 100% ━━━━━━━━━━━━ 1/1 5.6it/s 0.2s
                   all         17         75      0.955      0.931      0.964      0.886

      Epoch    GPU_mem   box_loss   cls_loss   dfl_loss  Instances       Size
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ tail *286542*
              snickers          5          6      0.972          1      0.995      0.871
              starbust          2          2      0.912          1      0.995      0.945
      three_musketeers          4          4      0.763      0.815      0.895      0.763
             twizzlers          5          6          1      0.973      0.995      0.979
Speed: 0.0ms preprocess, 1.4ms inference, 0.0ms loss, 0.4ms postprocess per image
Results saved to /home/userA/yolo_uv/runs/train
💡 Learn more at https://docs.ultralytics.com/modes/train
```


## 使用多GPU進行訓練，以兩張GPU為例
編輯Slurm script `run_uv.slurm`  
```bash
#!/bin/bash
#SBATCH -A <ProjectID>           # iService Project id
#SBATCH -J yolo                # job name
#SBATCH -p dev                # partition dev normal normal2
#SBATCH --nodes=1              # Maximum number of nodes to be allocated
#SBATCH --ntasks-per-node=1    # Number of MPI tasks (i.e. processes)
#SBATCH --cpus-per-task=12      # Number of cores per MPI task
#SBATCH --gres=gpu:2
#SBATCH -o %x_%j.out          # Path to the standard output file
##SBATCH -t 0-06:00:00

export CUDA_VISIBLE_DEVICES=0,1
source .venv/bin/activate

yolo detect train data=data.yaml model=yolo11x.pt epochs=60 imgsz=640 project=$SLURM_SUBMIT_DIR/runs device=0,1

deactivate
```
提交作業與查看計算節點的GPU使用量  
```bash
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ squeue -u userA -o "%.9i %.9P %.12j %.10u %.2t %.10M %.6D %.16R %b"
    JOBID PARTITION         NAME       USER ST       TIME  NODES NODELIST(REASON) TRES_PER_NODE
   286562       dev         yolo   userA  R       1:18      1      25a-hgpn002 gres/gpu:2
(yolo_uv) [userA@25a-lgn04 yolo_uv]$ ssh 25a-hgpn002
[userA@25a-hgpn002 ~]$ watch nvidia-smi
Every 2.0s: nvidia-smi                                                                                25a-hgpn002: Fri Aug 21 09:48:50 2026

Fri Aug 21 09:48:50 2026
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.65.06              Driver Version: 580.65.06      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA H200                    On  |   00000000:3A:00.0 Off |                    0 |
| N/A   47C    P0            329W /  700W |   11349MiB / 143771MiB |     85%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+
|   1  NVIDIA H200                    On  |   00000000:BA:00.0 Off |                    0 |
| N/A   46C    P0            322W /  700W |   10223MiB / 143771MiB |     79%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A         1623268      C   ...716/yolo_uv/.venv/bin/python3      11340MiB |
|    1   N/A  N/A         1623269      C   ...716/yolo_uv/.venv/bin/python3      10214MiB |
+-----------------------------------------------------------------------------------------+

[userA@25a-hgpn002 ~]$ exit
logout
Connection to 25a-hgpn002 closed.
```
