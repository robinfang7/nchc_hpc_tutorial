# 國網中心超級電腦使用教學

本專案說明國網中心超級電腦晶創26/25(GPU叢集系統)、創進一號(CPU叢集系統)的使用方式。

## 專案說明
- yolo：YOLO是小型模型，可以在個人電腦上進行訓練。此專案說明如何移植到晶創主機訓練YOLO模型。若用戶對超級電腦沒概念，先從yolo上手。
- hpc_software：說明晶創主機的主要軟體層，Slurm任務調度管理，Lmod環境管理，容器封裝環境設定。
- horovod：Horovod分散式框架加速Tenslorflow、Pytorch模型於多GPU、多節點環境加速運算。
- pytorch_ddp：Pytorch的分散式訓練(DDP)實作。
- swift：大語言模型微調實作。
- hpc_benchmarks：HPL, HPCG, HPL-MxP實作。
- old_slider：過去的教育訓練講義。