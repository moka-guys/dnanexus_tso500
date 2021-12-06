#!/bin/bash

# Output each line as it is executed (-x) and don't stop if any non zero exit codes are seen (+e)
set -x +e
mark-section "download inputs"

mkdir -p results_temp runfolder TSO500_ruo out/logs/logs out/analysis_folder out/results_zip/analysis_folder/ /home/dnanexus/out/fastqs/analysis_folder/Logs_Intermediates/CollapsedReads /home/dnanexus/out/bams_for_coverage/analysis_folder/Logs_Intermediates/StitchedRealigned /home/dnanexus/out/results_zip/Results/ /home/dnanexus/out/metrics_tsv/QC

# download all inputs
dx-download-all-inputs --parallel --except run_folder

unzip $TSO500_ruo_path -d TSO500_ruo
rm $TSO500_ruo_path
# change the owner of the app
chmod 777 TSO500_ruo/TSO500_RUO_LocalApp/
# download the runfolder input, decompress and save in directory 'runfolder'
dx cat "$run_folder" | tar xf - -C runfolder

# move the docker image into ~
mv TSO500_ruo/TSO500_RUO_LocalApp/trusight-oncology-500-ruo-dockerimage-ruo-*.tar /home/dnanexus/

# load docker image
sudo docker load --input /home/dnanexus/trusight-oncology-500-ruo-dockerimage-ruo-*.tar

# run the shell script, specifying the analysis folder, runfolder, samplesheet, resourcesFolder and any analysis options string given as an input
# pipe stderr into stdout and write this to a file and to screen - this allows a record of the logs to be saved and visible on screen if it goes wrong
sudo bash TSO500_ruo/TSO500_RUO_LocalApp/TruSight_Oncology_500_RUO.sh --analysisFolder /home/dnanexus/out/analysis_folder/analysis_folder --runFolder /home/dnanexus/runfolder/* --sampleSheet $samplesheet_path --resourcesFolder /home/dnanexus/TSO500_ruo/TSO500_RUO_LocalApp/resources $analysis_options 2>&1 | tee /home/dnanexus/out/logs/logs/RUO_stdout.txt

# create a zip folder for each individual sample
# first, to ensure each zip folder doesn't contain the full file tree cd into the results folder
cd  /home/dnanexus/out/analysis_folder/analysis_folder/Results;
# loop through samples, only selecting directories
for sample in ./*; do
	if [[ -d $sample ]];
		then 
		# create a zip folder for that specific sample outside of any output folders - these will be zipped together later
		zip -r /home/dnanexus/results_temp/$sample.zip $sample
	fi
done
cd /home/dnanexus/results_temp/
# create a zip folder containing zipped folders for each sample
zip -r /home/dnanexus/out/results_zip/Results.zip .
cd ~

# move the fastq output so they appear as seperate outputs from app for downstream tools, but go to the same place in the project
mv /home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/CollapsedReads /home/dnanexus/out/fastqs/analysis_folder/Logs_Intermediates/
# mv the bams (for coverage) so they appear as seperate outputs from app for downstream tools, but go to the same place in the project
mv /home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/StitchedRealigned /home/dnanexus/out/bams_for_coverage/analysis_folder/Logs_Intermediates/
# copy the metrics_tsv into it's own output so it appears in the /QC folder and can be accessed by downstream tools if required
cp /home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput.tsv /home/dnanexus/out/metrics_tsv/QC/
# upload all outputs
dx-upload-all-outputs --parallel

