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
`/home/<user>/.local/bin` 已在$PATH，表示uv 是預設的執行檔。


建立yolo_uv專案，專案名稱不要用`yolo`，會發生環境異常。  
```bash
[userA@25a-lgn02 ~]$ mkdir yolo_uv && cd yolo_uv
[userA@25a-lgn02 yolo_uv]$ uv init --python 3.11
Initialized project `yolo-uv`
[userA@25a-lgn02 yolo_uv]$ ls
pyproject.toml  README.md  src
```

安裝python 3.11
```bash
[userA@25a-lgn02 yolo_uv]$ uv python install 3.11
Installed Python 3.11.15 in 4.97s
 + cpython-3.11.15-linux-x86_64-gnu (python3.11)
```

安裝ultralytics
```bash
[userA@25a-lgn02 yolo_uv]$ uv add ultralytics
Using CPython 3.11.15
Creating virtual environment at: .venv
Resolved 56 packages in 5.16s
      Built yolo-uv @ file:///home/userA/yolo_uv                                                                                         Prepared 55 packages in 1m 52s
Installed 55 packages in 6.75s
 + certifi==2026.7.22
 + charset-normalizer==3.4.9
 + contourpy==1.3.3
 + cuda-bindings==13.3.1
 + cuda-pathfinder==1.6.0
 + cuda-toolkit==13.0.3.0
 + cycler==0.12.1
 + filelock==3.32.2
 + fonttools==4.63.0
 + fsspec==2026.7.0
 + idna==3.18
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
 + setuptools==83.0.0
 + six==1.17.0
 + sympy==1.14.0
 + torch==2.13.0
 + torchvision==0.28.0
 + triton==3.7.1
 + typing-extensions==4.16.0
 + ultralytics==8.4.115
 + ultralytics-thop==2.1.6
 + urllib3==2.7.0
 + yolo-uv==0.1.0 (from file:///home/userA/yolo_uv)

[userA@25a-lgn02 yolo_uv]$ ls -a
.  ..  .git  .gitignore  pyproject.toml  .python-version  README.md  src  uv.lock  .venv
[userA@25a-lgn02 yolo_uv]$ ls .venv
bin  CACHEDIR.TAG  lib  lib64  pyvenv.cfg  share

[userA@25a-lgn02 yolo_uv]$ uv run yolo version
8.4.115
[userA@25a-lgn02 yolo_uv]$ uv run python -c "import torch; print(torch.cuda.is_available())"
True
```

`python create_yaml.py`改成`uv run create_yaml.py`  

 * 執行訓練前，先修改運算資料的路徑`runs_dir`
```bash
[userA@25a-lgn02 yolo_uv]$ uv run yolo settings
JSONDict("/home/userA/.config/Ultralytics/settings.json"):
{
  "settings_version": "0.0.7",
  "datasets_dir": "/ultralytics/datasets",
  "weights_dir": "/ultralytics/weights",
  "runs_dir": "/ultralytics/runs",
  "uuid": "f9edcf00ea1db2d07058a2bf843073420a4673bb3b9154c43d210fe8c5f3f6a5",
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

重設路徑
```bash
[userA@25a-lgn02 yolo_uv]$ uv run yolo settings reset
Settings reset successfully
JSONDict("/home/userA/.config/Ultralytics/settings.json"):
{
  "settings_version": "0.0.7",
  "datasets_dir": "/home/userA/datasets",
  "weights_dir": "/home/userA/yolo_uv/weights",
  "runs_dir": "/home/userA/yolo_uv/runs",
  "uuid": "d4edd4ffb825057647b10a1f6001adad0d2f9fca0643c991440f96d1d2a29b74",
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

```

data.yaml可沿用方法一的data.yaml複製做來進行訓練

提交工作與執行運算
```bash
[userA@25a-lgn02 yolo_uv]$ sbatch run_uv.slurm
Submitted batch job 240027
```
