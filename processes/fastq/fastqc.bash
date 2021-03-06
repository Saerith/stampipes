# Dependencies
source $MODULELOAD
module load java/jdk1.7.0_05
module load picard/1.118
module load FastQC/0.11.3

export FASTQ_NAME=${FLOWCELL}_${SAMPLE_NAME}
export R1_FASTQ=${FASTQ_NAME}_R1.fastq.gz
export R2_FASTQ=${FASTQ_NAME}_R2.fastq.gz
export R1_FASTQC=${FASTQ_NAME}_R1_fastqc.zip
export R2_FASTQC=${FASTQ_NAME}_R2_fastqc.zip
export TOP_UMIS=${SAMPLE_NAME}.topumis.txt.gz

cd $FASTQ_DIR

if [ ! -e "$R1_FASTQC" -o ! -e "$R2_FASTQC" ]; then

PROCESS_NAME=".fq${SAMPLE_NAME}_${FLOWCELL}_LANE#${FLOWCELL_LANE_ID}"

qsub -N ".fq${SAMPLE_NAME}" -V -cwd -S /bin/bash > /dev/stderr << __SCRIPT__
  set -x -e -o pipefail

  echo "Hostname: "
  hostname

  echo "START: "
  date

  cd $FASTQ_DIR
  make -f $STAMPIPES/makefiles/fastqc.mk FASTQ_FILE=$R1_FASTQ FASTQC_FILE=$R1_FASTQC
  make -f $STAMPIPES/makefiles/fastqc.mk FASTQ_FILE=$R2_FASTQ FASTQC_FILE=$R2_FASTQC

  if [ "$UMI" = "True" ]; then
      echo "Tallying up top UMI tags seen in R1"
      zcat ${R1_FASTQ} | grep "^@" | cut -f 2 -d "+" | sort | uniq -c | sort -n -r | gzip -c > ${TOP_UMIS}
  fi

  if [ "$PAIRED" = "True" ]; then
      python3 ${STAMPIPES}/scripts/lims/upload_data.py -f ${FLOWCELL} --flowcell_lane_id=${FLOWCELL_LANE_ID} \
	  --fastqcfile $R1_FASTQC --fastqcfile $R2_FASTQC
  else
      python3 ${STAMPIPES}/scripts/lims/upload_data.py -f ${FLOWCELL} --flowcell_lane_id=${FLOWCELL_LANE_ID} \
	  --fastqcfile $R1_FASTQC
  fi

  bash $STAMPIPES/scripts/fastq/attachfiles.bash

  echo "FINISH: "
  date
__SCRIPT__
fi

