# 國網中心超級電腦使用教學

本專案說明國網中心超級電腦晶創26/25(GPU叢集系統)、創進一號(CPU叢集系統)的使用方式。  

## 專案說明
* hpc_software：說明晶創主機的主要軟體層，Slurm任務調度管理，Lmod環境管理，容器封裝環境設定。  
* yolo：YOLO是小型模型，可以在個人電腦上進行訓練。此專案說明如何移植到晶創主機訓練YOLO模型。  
* horovod：Horovod分散式框架加速Tenslorflow、Pytorch模型於多GPU、多節點環境加速運算。  
* pytorch_ddp：Pytorch的分散式訓練(DDP)實作。  
* miniWeather：在CPU叢集的小型流體力學實作。  

## 最新課程
[晶創26/25 GPU叢集主機教育訓練-進階(線上課程)](https://edu.nchc.org.tw/course/one_course_introduction.asp?lms_auto_course_id=4153&from_course_list_url=homepage)  
[![slider](https://cdn.phototourl.com/free/2026-08-21-c2c8b352-8990-4fe4-a1cb-a2dc38bb5582.png)](https://github.com/robinfang7/nchc_hpc_tutorial/blob/main/20260826_Nano4_slide.pdf)  
上課時間：2026/8/26 (三) 13:30 - 16:30  
上課地點：透過視訊會議系統進行線上教學  
課程介紹：  
本課程教授晶創26與晶創25兩座GPU叢集主機，幫助使用者加速HPC/AI應用程式開發。因應叢集系統的擴展能力，本課程著重多GPU與多節點的調用與運算。  

參加對象：  
 一般使用者，在linux系統進行AI、科學/工程計算的經驗尤佳。  

課程內容：  
1. 從0到1，用超級電腦訓練YOLO網路
2. 國網中心的GPU叢集系統介紹  
   1. 晶創26、晶創25  
   2. iService計算資源服務網  
3. 叢集系統的軟體  
   1. Slurm任務調度
   2. Lmod軟體管理
   3. Singularity/Apptainer容器
4. 實作展示   
5. 問題與討論
