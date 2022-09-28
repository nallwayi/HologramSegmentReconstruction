#! /bin/bash
#
# BASH scriot to prepare files for reconstruction at Superior
#
# Usage: ESCAPE_Reconstruction_bashScript.sh FlightNumber
# 

  if [ "$#" -ne 1 ]; then
    echo "Enter the Flight number"
    exit
  fi

  echo " This is a bash script to prepare files for reconstruction at Superior"

  # Running matlab script to select segments
  #matlab -nosplash -nodisplay -r ESCAPE_holodec_Reconstruction_Prep_Script -logfile ESCAPE_holodec_Reconstruction_Prep_Script_log.txt
  #sleep 20

  flightReconstructionFolder=/drives/g/My\ Drive/Research_LaptopFiles/ESCAPE/FlightData/RF11
  folderSuperior=/home/nallwayi/research/ESCAPE/RF11/


  ssh ${SUPERIOR2} "mkdir -p ${folderSuperior}"
  
  flightNumber=${1}
  numberSegments=$(head -n 1 "${flightReconstructionFolder}/hologramstoReconstruct.txt")

  sed -e "s/\${1}/${flightNumber}/g" \
    -e "s/\${2}/${numberSegments}/g" \
      MASTER_presubmission.sh > presubmission_RF${1}.sh

  rsync -ave ssh -hPz presubmission_RF${1}.sh  ${SUPERIOR2}:${folderSuperior}/presubmission_RF${1}.sh
  rm presubmission_RF${1}.sh
  rsync -ave ssh -hPz MASTER_qsubFile.sh  ${SUPERIOR2}:${folderSuperior}/qsubFile_RF${1}.sh
  rsync -ave ssh -hPz MASTER_matlabRunFile.m  ${SUPERIOR2}:${folderSuperior}/matlabRunFile_RF${1}.m
  rsync  -ave ssh -hPz "${flightReconstructionFolder}/config_RF${1}.cfg" ${SUPERIOR2}:${folderSuperior}/config_RF${1}.cfg


  sed 1d "${flightReconstructionFolder}/hologramstoReconstruct.txt" | while read -r line
  do
    echo "$line"
    line=$(echo $line | sed 's/\\/\//g')
    line=$(echo $line | sed 's/E:/\/drives\/e\//g')
    rsync -ave ssh -hPz $line ${SUPERIOR2}:${folderSuperior}/holograms/
  done 
 
