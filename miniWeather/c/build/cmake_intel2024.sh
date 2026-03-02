#!/bin/bash
module purge
module load intel/2024_01_46
export TEST_MPI_COMMAND="mpirun -n 1"
unset CUDAFLAGS
unset CXXFLAGS
PARALLEL_NETCDF_ROOT=$HOME/opt

./cmake_clean.sh

cmake -DCMAKE_CXX_COMPILER=mpicxx                                               \
      -DCXXFLAGS="-Ofast -march=native -mtune=native -DNO_INFORM -std=c++11 -I${PARALLEL_NETCDF_ROOT}/include" \
      -DLDFLAGS="-L${PARALLEL_NETCDF_ROOT}/lib -lpnetcdf"                      \
      -DOPENMP_FLAGS="-fopenmp"                                                 \
      -DNX=200                                                                  \
      -DNZ=100                                                                  \
      -DDATA_SPEC="DATA_SPEC_GRAVITY_WAVES"                                     \
      -DSIM_TIME=1500                                                           \
      ..
