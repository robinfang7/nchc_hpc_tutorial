# 容器
Singularity與Apptainer是用於HPC叢集系統的容器。

![Singularity](https://i.meee.com.tw/r2ICmPE.png)

## 使用方式
### 1. 查看容器軟體版本
```bash
# Nano4
[u8880716@25a-lgn01 sif]$ singularity --version
apptainer version 1.4.3-1.el9
[u8880716@25a-lgn01 sif]$ apptainer --version
apptainer version 1.4.3-1.el9

# Nano5
[u8880716@cbi-lgn01 ~]$ singularity --version
singularity-ce version 4.1.2-1.el8
```

### 2. 下載容器
`singularity pull pytorch_25.08-py3.sif docker://nvcr.io/nvidia/pytorch:25.08-py3`  

### 3. 運行容器
```bash
# 背景執行
[u8880716@25a-lgn01 sif]$ singularity exec pytorch_25.08-py3.sif python -c "import torch; print(torch.__version__); print(torch.version.cuda)"
2.8.0a0+34c6371d24.nv25.08
13.0

# 互動式(進入容器內)執行
[u8880716@25a-lgn01 sif]$ singularity exec pytorch_25.08-py3.sif bash
Apptainer> python -c "import torch; print(torch.__version__); print(torch.version.cuda)"
2.8.0a0+34c6371d24.nv25.08
13.0
Apptainer> exit
exit

[u8880716@25a-lgn01 sif]$ singularity shell pytorch_25.08-py3.sif
Apptainer> python -c "import torch; print(torch.__version__); print(torch.version.cuda)"
2.8.0a0+34c6371d24.nv25.08
13.0
Singularity> exit
exit
```

常用的容器參數  
`singularity exec --nv -B /work:/work pytorch_25.08-py3.sif <command>`  
`--nv` 引用宿主機的GPU   
`-B /work:/work` 引用/work的資料。Singularity預設連接/home/$(whoami)的路徑，但是程式和資料放在/work/$(whoami)，就必須綁定/work目錄。  

## 製作客製化容器映像檔
若Docker hub 和Nvidia NGC的容器無法滿足用戶的開發需求，則需要製作客製化容器映像檔。

### 1. 找sudo權限的linux電腦，安裝Singularity
1. 建立客製化容器映像檔需要sudo權限。  
2. 另尋有sudo權限Linux電腦 (例如Windows WSL, VirtualBox，晶創雲的虛擬機器)建立客製化容器映像檔。注意建立容器映像檔的電腦和運行容器的主機的CPU架構要相容，例如x86 or arm 架構。     
3. 安裝相關依賴庫、Go語言與Singularity。注意Go語言與Singularity版本有搭配。     

#### 安裝Singularity過程
```bash
# Ensure repositories are up-to-date
sudo apt-get update
# Install debian packages for dependencies
sudo apt-get install -y \
    build-essential \
    libseccomp-dev \
    uidmap \
    fakeroot \
    cryptsetup \
    tzdata \
    dh-apparmor \
    libsubid-dev \
    pkg-config \
    curl wget git

# Install GO
export GOVERSION=1.23.6 OS=linux ARCH=amd64  # change this as you need

wget -O /tmp/go${GOVERSION}.${OS}-${ARCH}.tar.gz \
  https://dl.google.com/go/go${GOVERSION}.${OS}-${ARCH}.tar.gz

sudo tar -C /usr/local -xzf /tmp/go${GOVERSION}.${OS}-${ARCH}.tar.gz

# add /usr/local/go/bin to the PATH environment variable
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install singulairty
git clone https://github.com/apptainer/apptainer.git
cd apptainer
git checkout v1.4.1

# Compiling Singularity
./mconfig
cd $(/bin/pwd)/builddir 
make -j 4
sudo make install

# Run toy container
singularity run library://godlovedc/funny/lolcow
INFO:      Downloading library image
89.2MiB / 89.2MiB [==============================

 ____________________________________ 
< You will be run over by a bus. >
 ------------------------------------ 
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
[參考來源](https://github.com/apptainer/apptainer/blob/main/INSTALL.md)


### 2. 建立映像檔
#### 方法一：由定義檔(Singulariry Definition File, \*.def)建立映像檔
定義檔格式
```bash
Bootstrap: library
From: ubuntu:22.04
Stage: build

%setup
    touch /file1
    touch ${SINGULARITY_ROOTFS}/file2

%files
    /file1
    /file1 /opt

%environment
    export LISTEN_PORT=54321
    export LC_ALL=C

%post
    apt-get update && apt-get install -y netcat
    NOW=`date`
    echo "export NOW=\"${NOW}\"" >> $SINGULARITY_ENVIRONMENT

%runscript
    echo "Container was created $NOW"
    echo "Arguments received: $*"
    exec echo "$@"

%startscript
    nc -lp $LISTEN_PORT

%test
    grep -q NAME=\"Ubuntu\" /etc/os-release
    if [ $? -eq 0 ]; then
        echo "Container base is Ubuntu as expected."
    else
        echo "Container base is not Ubuntu."
        exit 1
    fi

%labels
    Author myuser@example.com
    Version v0.0.1

%help
    This is a demo container used to illustrate a def file that uses all
    supported sections.
```
1. 標頭 (Header) 定義基底：  
   位於檔案最頂部，用於定義容器的基礎映像檔來源。最核心的參數是 Bootstrap（指定來源介面，如 docker、library 或 localimage）與 From（指定具體的映像檔，如 ubuntu:22.04 或 nvidia/cuda:11.8.0-devel-ubuntu22.04）。  
2. `%files` (檔案傳輸區段)：  
   負責在建置過程中，將宿主機 (Host) 的檔案安全地複製到容器內。這通常用於注入特定的授權檔、自訂的原始碼或預先寫好的組態設定。  
3. `%post` (環境建置區段)：  
   這是 Definition File 中最重要的部分。在此區段內的指令會在容器內部以 root 權限執行，主要用於安裝系統套件（如 apt-get、yum）、編譯軟體（例如從原始碼編譯特定版本的 MPI）以及建立所需的工作目錄。  
4. `%environment` 與 `%runscript` (執行期行為設定)：  
   `%environment` 區塊用於定義容器執行時（而非建置時）生效的環境變數（如 `$PATH` 或 `$LD_LIBRARY_PATH`）。`%runscript` 則定義了當使用者輸入 singularity run 時，容器預設要執行的腳本或指令。  
5. `%labels` 與 `%help` (元資料與文件)：  
   用於提升映像檔的可維護性與易用性。`%labels` 以鍵值對形式記錄映像檔的版本、作者及維護者資訊；`%help` 則可撰寫純文字說明，當使用者執行 singularity run-help 時會顯示此容器的使用指南。  

[參考來源](https://docs.sylabs.io/guides/latest/user-guide/definition_files.html)

範例一：[製作Pytorch with Hororvod](https://github.com/robinfang7/nchc_hpc_tutorial/blob/main/horovod/README.md)    
範例二：Tensorflow for H100  
```bash
Bootstrap: docker
From: nvcr.io/nvidia/tensorflow:23.10-tf2-py3

%help
    此容器用於 CosmoFlow 資料預處理，解決了：
    1. Protobuf 版本不相容問題 (固定於 3.20.3)
    2. H100 GPU (Compute 9.0) 支援
    3. MPI 與 UCX 通訊優化

%post
    # 更新系統並安裝必要工具
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libopenmpi-dev \
        git

    # 強制降級 Protobuf 以符合舊版 TensorFlow 邏輯，避免 TypeError
    pip install --no-cache-dir --upgrade pip
    pip install --no-cache-dir "protobuf<3.21,>=3.20.3"

    # 安裝並行計算與資料處理必要套件
    pip install --no-cache-dir mpi4py numpy

%environment
    # 解決 UCX 速度辨識錯誤的環境變數預設值
    export UCX_TLS=tcp,self,sm
    export UCX_IB_RETRY_COUNT=20
    # 確保 Protobuf 使用 C++ 實作以獲得最佳效能
    export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp

%runscript
    exec python "$@"
```

用sudo權限建立映像檔
`sudo singularity build <image>.sif <definition>.def`

#### 方法二：由Dockerfile建立映像檔
從Github下載的repository有附Dockerfile，可建立本地端電腦的Docker容器映像檔。由Docker容器映像檔轉換成Singularity容器映像檔。


```bash
cd <path/to/Dockerfile>
docker build -t <repository>:<tag> .
sudo singularity build <image>.sif docker-daemon://<repository>:<tag>
```

#### 方法二的延伸：若Docker與Singularity版本差異太大造成失敗，須藉由壓縮檔處理
```bash
docker build -t <repository>:<tag> .
docker save <repository>:<tag> -o <image>.tar
sudo singularity build <image>.sif docker-archive://$(pwd)/<name>.tar
```

範例
1. 在Sudo權限的linxu電腦製作映像檔
```bash
ubuntu@vmcpuvm-5372004-iaas:~$ cd bert_mlperf_3.0
ubuntu@vmcpuvm-5372004-iaas:~/bert_mlperf_3.0$ ls
a30-run_and_time.sh                      Dockerfile
a30.sub                                  extract_features.py
bmm1.py                                  file_utils.py

ubuntu@vmcpuvm-5372004-iaas:~$ docker build -t bert_mlperf:pytorch-2304 .
ubuntu@vmcpuvm-5372004-iaas:~$ docker images
REPOSITORY     TAG             IMAGE ID       CREATED          SIZE
bert_mlperf    pytorch-2304    dd6dc34e6fc8   33 minutes ago   22.5GB

ubuntu@vmcpuvm-5372004-iaas:~$ sudo singularity build bert_mlperf_pytorch_2304.sif docker-daemon://bert_mlperf:pytorch-2304
ubuntu@vmcpuvm-5372004-iaas:~$ ls
bert  bert_mlperf_3.0  bert_mlperf_pytorch_2304.sif  cosmoflow_tf.def

# 用sftp傳送映像檔bert_mlperf_pytorch_2304.sif 到晶創25主機
```

2. 在晶創主機，在Slurm script啟用Singularity映像檔
```bash
#!/bin/bash
#SBATCH -A <projectID>      # iService Project id
#SBATCH -J bert             # job name
#SBATCH -p normal           # partition
#SBATCH --ntasks-per-node=1 # Number of MPI tasks (i.e. processes)
#SBATCH --cpus-per-task=4   # Number of cores per MPI task
#SBATCH --nodes=1           # Maximum number of nodes to be allocated
#SBATCH --gres=gpu:8
#SBATCH -o %x_%j.out        # Path to the standard output file

export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export OMP_NUM_THREADS=1

SIF=/work/$(whoami)/sif/bert_mlperf_pytorch_2304.sif
SINGULARITY="singularity run -B /work:/work --nv $SIF"

```
