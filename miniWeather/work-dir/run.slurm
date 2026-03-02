#!/bin/bash
#SBATCH --account=<ProjectID>      # (-A) iService Project ID
#SBATCH --job-name=p2node4mpi        # (-J) Job name
#SBATCH --partition=ct112    # (-p) Slurm partition development, ct112
#SBATCH --nodes=2                  # (-N) Maximum number of nodes to be allocated
#SBATCH --cpus-per-task=1          # (-c) Number of cores per MPI task
#SBATCH --ntasks-per-node=2        # Maximum number of tasks on each node
##SBATCH --time=00:30:00            # (-t) Wall time limit (days-hrs:min:sec)
#SBATCH --output=%x_%j.out        # (-o) Path to the standard output file
##SBTACH --nodelist=icpnq155

module purge
module load intel/2024_01_46

export OMP_NUM_THREADS=1 
export LD_LIBRARY_PATH=$HOME/opt/lib:$LD_LIBRARY_PATH # import PnetCDF library
export PATH=$HOME/opt/bin:$PATH # import PnetCDF executable file

srun --mpi=pmix_v4 ./mpi
echo "Job completed"

