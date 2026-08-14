# Lmod環境管理
Lmod幫助用戶管理各種軟體和應用程式。 由於 HPC 叢集通常會安裝許多不同的軟體套件，包括不同版本的編譯器、函式庫、科學應用程式等等，直接管理這些軟體可能會變得非常複雜，而且容易產生衝突，Lmod就是為了簡化這個複雜性而設計的。  
![Lmod](https://cdn.phototourl.com/free/2026-08-13-2b283185-7eb6-4ce4-9272-0730790b3557.png "Lmod軟體管理")

查看可安裝的軟體 `module avail`  
* 晶創26
```bash
[userA@25a-lgn01 ~]$ module avail

--------------------------------------------- /work/envstack/apps/modulefiles/x86/application ---------------------------------------------
   biology/ADMIXTURE/1.4.0         biology/PLINK2/2.00a7.1LM              biology/nf-core-atacseq/2.1.2
   biology/BEAGLE/4.0.0            biology/R/4.3.3                        biology/nf-core-crisprseq/2.3.0
   biology/BEAST/10.5.0            biology/S-LDXR/0.3-beta                biology/nf-core-nanoseq/3.1.0
   biology/CNVkit/0.9.10           biology/SAIGE/1.5.2                    biology/nf-core-proteinfold/2.0.0
   biology/FastQC/0.11.9           biology/SAMtools/1.18                  biology/nf-core-rnaseq/3.26.0
   biology/GATK/4.2.1.0            biology/SHAPEIT5/5.1.1                 biology/nf-core-sarek/3.9.0
   biology/GATK/4.2.3.0            biology/SuSiEx/20241207                biology/nf-core-scdownstream-dev/dev
   biology/GATK/4.6.2.0     (D)    biology/VCFtools/0.1.16                biology/nf-core-scrnaseq/4.2.0
   biology/HTSlib/1.13             biology/VCFtools/0.1.17         (D)    biology/nfcore_config/1.0
   biology/HTSlib/1.18             biology/WhatsHap/2.8                   biology/qiime2/2026.7
   biology/HTSlib/1.24      (D)    biology/bcftools/1.13                  biology/regenie/4.1
   biology/JDK/26.0.1              biology/bcftools/1.18                  biology/rpy-analysis-console/1.0
   biology/LDSC/1.0.1              biology/bcftools/1.24           (D)    matlab/R2025b
   biology/METAL/20200505          biology/fastp/0.23.2                   matlab/R2026a                        (D)
   biology/Nextflow/26.04.4        biology/igenomes                       starccmp/STAR-CCM_Plus_v2506_edu
   biology/Nextflow/26.04.6 (D)    biology/mamba/2.5.0
   biology/PLINK/1.90b7.11         biology/nf-core-ampliseq/2.18.0

------------------------------------------------ /work/envstack/apps/modulefiles/x86/tools ------------------------------------------------
   cmake/4.0.0    jupyter/jupyterlab    jupyter/miniconda3 (D)    miniconda3/26.1.1    singularity/4.3.7

------------------------------------------------ /work/envstack/apps/modulefiles/x86/cores ------------------------------------------------
   cuda/12.6    cuda/13.0 (D)    gcc/11.5 (D)    gcc/12.2    gcc/13.2    oneapi/2025.1    x86-nvhpc/25.9    x86-nvhpc/26.3 (D)

  Where:
   D:  Default Module

If the avail list is too long consider trying:

"module --default avail" or "ml -d av" to just list the default modules.
"module overview" or "ml ov" to display the number of modules for each name.

Use "module spider" to find all possible modules and extensions.
Use "module keyword key1 key2 ..." to search for all possible modules matching any of the "keys".
```
* 晶創25
```bash
[userA@cbi-lgn01 ~]$ module avail

----------------------------------------------- /work/HPC_software/LMOD/public/modulefiles ------------------------------------------------
   ansys/v251      gcc/8.5.0  (D)    gcc/11.5.0    hwloc/2.7.2           os            singularity/3.7.1
   cmake/3.24.2    gcc/10.5.0        gcc/12.5.0    miniconda3/24.11.1    pmix/4.2.9

----------------------------------------------- /work/HPC_software/LMOD/nvidia/modulefiles ------------------------------------------------
   cuda/11.6    cuda/12.4 (D)    nvhpc-hpcx-cuda12/24.7    openmpi/4.1.6 (D)    ucx/1.16.0
   cuda/12.2    cuda/12.6        nvhpc/24.7                openmpi/5.0.5

------------------------------------------------ /work/HPC_software/LMOD/intel/modulefiles ------------------------------------------------
   advisor/latest                        compiler/2024.2.1      (D)    ifort/latest                       mkl/2024.2    (D)
   advisor/2024.2                 (D)    compiler32/latest             ifort/2024.2.1              (D)    mkl32/latest
   ccl/latest                            compiler32/2024.2.1    (D)    ifort32/latest                     mkl32/2024.2  (D)
   ccl/2021.13.1                  (D)    debugger/latest               ifort32/2024.2.1            (D)    mpi/latest
   compiler-intel-llvm/latest            debugger/2024.2.1      (D)    intel_ipp_ia32/latest              mpi/2021.13   (D)
   compiler-intel-llvm/2024.2.1   (D)    dev-utilities/latest          intel_ipp_ia32/2021.12      (D)    tbb/latest
   compiler-intel-llvm32/latest          dev-utilities/2024.2.0 (D)    intel_ipp_intel64/latest           tbb/2021.13   (D)
   compiler-intel-llvm32/2024.2.1 (D)    dnnl/latest                   intel_ipp_intel64/2021.12   (D)    tbb32/latest
   compiler-rt/latest                    dnnl/3.5.0             (D)    intel_ippcp_ia32/latest            tbb32/2021.13 (D)
   compiler-rt/2024.2.1           (D)    dpct/latest                   intel_ippcp_ia32/2021.12    (D)    vtune/latest
   compiler-rt32/latest                  dpct/2024.2.0          (D)    intel_ippcp_intel64/latest         vtune/2024.2  (D)
   compiler-rt32/2024.2.1         (D)    dpl/latest                    intel_ippcp_intel64/2021.12 (D)
   compiler/latest                       dpl/2022.6             (D)    mkl/latest

  Where:
   D:  Default Module

If the avail list is too long consider trying:

"module --default avail" or "ml -d av" to just list the default modules.
"module overview" or "ml ov" to display the number of modules for each name.

Use "module spider" to find all possible modules and extensions.
Use "module keyword key1 key2 ..." to search for all possible modules matching any of the "keys".

```
查看軟體版本 `module spider <package>`  
```bash
[userA@25a-lgn01 ~]$ module spider openmpi

----------------------------------------------------------------------------------------------------------------------------------------
  openmpi:
----------------------------------------------------------------------------------------------------------------------------------------
    Description:
      openmpi v5.0.10 with gcc 11.5, cuda 13.0

     Versions:
        openmpi/5.0.10-cuda12.6
        openmpi/5.0.10-cuda13.0

----------------------------------------------------------------------------------------------------------------------------------------
  For detailed information about a specific "openmpi" package (including how to load the modules) use the module's full name.
  Note that names that have a trailing (E) are extensions provided by other modules.
  For example:

     $ module spider openmpi/5.0.10-cuda13.0
----------------------------------------------------------------------------------------------------------------------------------------
[userA@25a-lgn01 ~]$ module spider openmpi/5.0.10-cuda13.0

----------------------------------------------------------------------------------------------------------------------------------------
  openmpi: openmpi/5.0.10-cuda13.0
----------------------------------------------------------------------------------------------------------------------------------------
    Description:
      openmpi v5.0.10 with gcc 11.5, cuda 13.0


    You will need to load all module(s) on any one of the lines below before the "openmpi/5.0.10-cuda13.0" module is available to load.

      gcc/11.5
      gcc/13.2

    Help:
          This module loads the openmpi v5.0.10 built with gcc 11.5, cuda 13.0
          The following additional environment variables are defined:
```  
載入軟體 `module load <package>`  
查看已載入軟體 `module list`  
清除已載入軟體 `module purge`  
```bash
[userA@25a-lgn01 ~]$ module list
No modules loaded
[userA@25a-lgn01 ~]$ module load miniconda3
[userA@25a-lgn01 ~]$ module list

Currently Loaded Modules:
  1) miniconda3/26.1.1

[userA@25a-lgn01 ~]$ conda --version
conda 26.1.1
[userA@25a-lgn01 ~]$ module purge

# 引用兩個以上的軟體
[userA@25a-lgn01 ~]$ module load openmpi/5.0.10-cuda13.0
Lmod has detected the following error: These module(s) or extension(s) exist but cannot be loaded as requested: "openmpi/5.0.10-cuda13.0"
   Try: "module spider openmpi/5.0.10-cuda13.0" to see how to load the module(s).
   Or load any one of these options:
      module load gcc/11.5 openmpi/5.0.10-cuda13.0
      module load gcc/13.2 openmpi/5.0.10-cuda13.0

[userA@25a-lgn01 ~]$ module load gcc/11.5 openmpi/5.0.10-cuda13.0
[userA@25a-lgn01 ~]$ module list

Currently Loaded Modules:
  1) gcc/11.5   2) cuda/13.0   3) openmpi/5.0.10-cuda13.0
```
