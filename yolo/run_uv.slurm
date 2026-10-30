#!/bin/bash
#SBATCH -A <ProjectID>         # iService Project id
#SBATCH -J yolo                # job name
#SBATCH -p dev                 # partition dev 
#SBATCH --nodes=1              # Maximum number of nodes to be allocated
#SBATCH --ntasks-per-node=1    # Number of MPI tasks (i.e. processes)
#SBATCH --cpus-per-task=12     # Number of cores per MPI task
#SBATCH --gres=gpu:1
#SBATCH -o %x_%j.out           # Path to the standard output file

export CUDA_VISIBLE_DEVICES=0

SECONDS=0

uv run yolo detect train data=data.yaml model=yolo11x.pt epochs=60 imgsz=640 project=$SLURM_SUBMIT_DIR/runs

RUNTIME=$SECONDS
HOUR=$(($RUNTIME / 3600)) ;MIN=$(((RUNTIME /60)%60)) ;SEC=$((RUNTIME % 60))
echo -e "\n DONE Runtime:$HOUR:$MIN:$SEC\n"
