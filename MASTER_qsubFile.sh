#! /bin/bash
# 
# This file contains critical settings for appropriate submission and execution
# of the simulation. Editing this file [and/or its bulk (re-)generation]
# without explicit permission of (or discussion with) the administrators can
# lead to improper use of resources, extended wait times in the queue, etc.,
# and will be grounds for removing your account from the HPC infrastructure.
#
# Refer to HPC 101 Training Camp (https://mtu.instructure.com/courses/1208210)
# for additional information.

#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -q epssi.q
#$ -pe openmp 16
# Not an array simulation
#$ -M nallwayi@mtu.edu
#$ -m abes
# No dependent simulation
#$ -hard -l mem_free=2G
#$ -hard -l matlab_lic=.0625000000
# Uses traditional CPU
#
#$ -notify

# Load and list modules
source ${HOME}/.bashrc
module load matlab/R2021a
module list

# Input/Outuput files
INPUT_FOLDER="${PWD}"
INPUT_FILE="RF_FOLDER_SUB_FOLDER"
OUTPUT_FILE="RF_FOLDER_SUB_FOLDER"
ARRAY_TASK_ID=""
ADDITIONAL_OPTIONS=""
MATLABPATH="/research/nallwayi"
MATLAB_PREFDIR="${PWD}/matlab_${JOB_ID}/prefs"

# Prevent com.mathworks.util.ShutdownRuntimeException error
# https://www.mathworks.com/matlabcentral/answers/248345-com-mathworks-util-shutdownruntimeexception-error
if [ ! -e "finish.m" ]
then
  ln -sf /research/apps/matlab/R2021a/finish.m
fi

# Run the simulation
mkdir -p ${MATLAB_PREFDIR}
RUN_COUNT=1
RUN_COUNT_MAX=5
while [ ${RUN_COUNT} -le ${RUN_COUNT_MAX} ]
do
  ${MATLAB}/bin/matlab -nodisplay -nosplash -r ${INPUT_FILE} -logfile ${OUTPUT_FILE}.log
  RUN_COUNT=$(expr ${RUN_COUNT} + 1)
  sleep 300
done
\rm -r ${MATLAB_PREFDIR}

# List modules
module unload matlab/R2021a
module list
