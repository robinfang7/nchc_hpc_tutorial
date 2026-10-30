#!/bin/bash
#SBATCH -A <ProjectID>         # iService Project id
#SBATCH -J swift               # job name
#SBATCH -p dev                 # partition dev
#SBATCH --nodes=1              # Maximum number of nodes to be allocated
#SBATCH --ntasks-per-node=1    # Number of MPI tasks (i.e. processes)
#SBATCH --cpus-per-task=12     # Number of cores per MPI task
#SBATCH --gres=gpu:1
#SBATCH -o %x_%j.out           # Path to the standard output file
##SBATCH -t 0-06:00:00

source .venv/bin/activate

[-d "output" ] && rm -rf output 

CUDA_VISIBLE_DEVICES=0 \
swift sft \
    --model /work/$(whoami)/llm_models/Qwen3-4B-Instruct-2507 \
    --tuner_type lora \
    --dataset /work/$(whoami)/data/vicgalle_alpaca-gpt4 \
    --torch_dtype bfloat16 \
    --num_train_epochs 1 \
    --per_device_train_batch_size 16 \
    --per_device_eval_batch_size 16 \
    --learning_rate 1e-4 \
    --lora_rank 8 \
    --lora_alpha 32 \
    --target_modules all-linear \
    --gradient_accumulation_steps 16 \
    --eval_steps 500 \
    --save_steps 1000 \
    --save_total_limit 2 \
    --logging_steps 500 \
    --max_length 2048 \
    --output_dir output \
    --warmup_ratio 0.05 \
    --dataloader_num_workers 8 \
    --model_author swift \
    --model_name swift-robot

deactivate