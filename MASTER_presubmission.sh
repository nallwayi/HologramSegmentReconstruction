#! /bin/bash
#
# BASH script to create sub-folder structure, and create .m and .sh files to
# bulk process the images.
#
# Usage:
#   chmod 700 ./presubmission_setup.sh
#   ./presubmission_setup.sh


# Necessary variables
SUB_FOLDER_COUNT=${2}

#\rm -r recon
mkdir recon

# Create sub-folders and files
for x in $(seq -w 01 1 ${SUB_FOLDER_COUNT})
# for x in $(seq -w 02 1 06)
do
  # Create the sub-folder structure
  mkdir -p RF${1}_${x}

  # Create the .cfg file
  sed -e "/path = /s/.*/path = \/home\/nallwayi\/research\/ESCAPE\/RF${1}\/holograms\//g" \
  -e "/localTmp = /s/.*/localTmp = \/home\/nallwayi\/research\/ESCAPE\/RF${1}\/recon\//g" \
  config_RF${1}.cfg > RF${1}_${x}/config_RF${1}.cfg

  # Create .sh file
  sed -e "s/RF_FOLDER/RF${1}/g" \
  -e "s/SUB_FOLDER/${x}/g" qsubFile_RF${1}.sh > RF${1}_${x}/RF${1}_${x}.sh

  # Create .m file
  # Force decimal representation of x (numbers starting with 0 are treated
  # as octal numbers in BASH).
  # LINE_NUMBER = x + 1
  y=$((10#${x}))
  LINE_NUMBER=$((y+1))
  sed -e "s/LINE_NUMBER/${LINE_NUMBER}/g" \
  -e "s/CONFIGFILE/config_RF${1}/g" matlabRunFile_RF${1}.m > RF${1}_${x}/RF${1}_${x}.m

  # Submit the simulation to the queue
  cd RF${1}_${x}
  #\rm -r recon
  #mkdir recon
  rm -f RF${1}_${x}.sh.o*
  rm -f RF${1}_${x}.sh.po*
  #qsub RF${1}_${x}.sh
  cd ../
done
