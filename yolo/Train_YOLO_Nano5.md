# Training YOLO with 1 H100 GPU on Nano5

## 用uv安裝ultralytics
安裝uv
```
[u8880716@cbi-lgn01 ~]$ cd ~
[u8880716@cbi-lgn01 ~]$ curl -LsSf https://astral.sh/uv/install.sh | sh
downloading uv 0.11.29 x86_64-unknown-linux-gnu
installing to /home/u8880716/.local/bin
  uv
  uvx
everything's installed!

[u8880716@cbi-lgn01 ~]$ uv --version
uv 0.12.2 (x86_64-unknown-linux-gnu)
```
/home/<user>/.local/bin 已在$PATH，表示uv 是預設的執行檔。

建立yolo_uv專案，專案名稱不要用`yolo`，會發生環境異常。  
```
[u8880716@cbi-lgn01 ~]$ mkdir yolo_uv && cd yolo_uv
[u8880716@cbi-lgn01 yolo_uv]$ uv init --python 3.11
Initialized project `yolo-uv`
```

安裝python 3.11
```
[u8880716@cbi-lgn01 yolo_uv]$ uv python install 3.11
Installed Python 3.11.15 in 4.97s
 + cpython-3.11.15-linux-x86_64-gnu (python3.11)
```

安裝指定cuda=12.4的ultralytics，
```
[u8880716@cbi-lgn01 yolo_uv]$ uv add ultralytics --index https://download.pytorch.org/whl/cu124

# 驗證cuda 版本
[u8880716@cbi-lgn01 yolo_uv]$ uv run python -c "import torch; print('PyTorch CUDA:', torch.version.cuda); print('Available:', torch.cuda.is_available())"
PyTorch CUDA: 12.4
Available: True
```

## 資料集處理
### 下載與解壓縮資料集candy_data_06JAN25.zip
```
[u8880716@cbi-lgn01 yolo]$ wget https://s3.us-west-1.amazonaws.com/evanjuras.com/resources/candy_data_06JAN25.zip
[u8880716@cbi-lgn01 yolo]$ unzip -q candy_data_06JAN25.zip -d data
```

### 切分資料，訓練集占90%
```
[u8880716@cbi-lgn01 yolo]$ python train_val_split.py --datapath=data --train_pct=0.9
Created folder at /home/u8880716/yolo/data/train/images.
Created folder at /home/u8880716/yolo/data/train/labels.
Created folder at /home/u8880716/yolo/data/validation/images.
Created folder at /home/u8880716/yolo/data/validation/labels.
Number of image files: 162
Number of annotation files: 162
Images moving to train: 145
Images moving to validation: 17
```

### 製作資料集的yaml檔
yaml檔指定資料集的路徑與類別
```
# 製作資料的yaml檔
[u8880716@cbi-lgn01 yolo]$ uv run create_yaml.py

[u8880716@cbi-lgn01 yolo]$ cat data.yaml
path: /home/u8880716/yolo_uv/data
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

* 執行訓練前，查看運算資料的路徑`runs_dir`  

```
[u8880716@cbi-lgn01 yolo_uv]$ uv run yolo settings
JSONDict("/home/u8880716/.config/Ultralytics/settings.json"):
{
  "settings_version": "0.0.7",
  "datasets_dir": "/home/u8880716/datasets",
  "weights_dir": "/home/u8880716/yolo_uv/weights",
  "runs_dir": "/home/u8880716/yolo_uv/runs",
  "uuid": "9039d9752793871c97a8b1b403dea531e890119f6fb711aeb77a51a973f9ee1c",
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

##　提交工作與執行運算
```
[u8880716@cbi-lgn01 yolo_uv]$ sbatch run_uv.slurm
Submitted batch job 240027
```







