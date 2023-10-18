#!/bin/bash

# Output each line as it is executed (-x) and don't stop if any non zero exit codes are seen (+e)
set -x +e
mark-section "download inputs"

samplesheet_part=$(echo $samplesheet_name | grep -o -E "Part[0-9]{1}")
#echo $samplesheet_name

mkdir -p runfolder TSO500_ruo out/logs/logs out/analysis_folder out/results_zip/analysis_folder/ /home/dnanexus/out/fastqs/analysis_folder/Logs_Intermediates/CollapsedReads /home/dnanexus/out/bams_for_coverage/analysis_folder/Logs_Intermediates/StitchedRealigned /home/dnanexus/out/results_vcfs/analysis_folder/Results /home/dnanexus/out/results_zip/results/ /home/dnanexus/out/metrics_tsv/QC /home/dnanexus/out/QC_files/QC/bclconvert/Lane_1$samplesheet_part /home/dnanexus/out/QC_files/QC/bclconvert/Lane_2$samplesheet_part

# download all inputs
dx-download-all-inputs --parallel --except run_folder

unzip $TSO500_ruo_path -d TSO500_ruo
rm $TSO500_ruo_path
# change the owner of the app
chmod 777 TSO500_ruo/TSO500_RUO_LocalApp/
# download the runfolder input and save in directory 'runfolder'
cd runfolder
dx download -r "$project_name":'/'"${runfolder_name}"'/'
ls 
cd ../

# move the docker image into ~
mv TSO500_ruo/TSO500_RUO_LocalApp/trusight-oncology-500-ruo-dockerimage-ruo-*.tar /home/dnanexus/

# load docker image
sudo docker load --input /home/dnanexus/trusight-oncology-500-ruo-dockerimage-ruo-*.tar

# run the shell script, specifying the analysis folder, runfolder, samplesheet, resourcesFolder and any analysis options string given as an input
# pipe stderr into stdout and write this to a file and to screen - this allows a record of the logs to be saved and visible on screen if it goes wrong
sudo bash TSO500_ruo/TSO500_RUO_LocalApp/TruSight_Oncology_500_RUO.sh --analysisFolder /home/dnanexus/out/analysis_folder/analysis_folder --runFolder /home/dnanexus/runfolder/* --sampleSheet $samplesheet_path --resourcesFolder /home/dnanexus/TSO500_ruo/TSO500_RUO_LocalApp/resources $analysis_options 2>&1 | tee /home/dnanexus/out/logs/logs/RUO_stdout.txt

### organise outputs to support use in downstream applications
# check if the results folder exists:
if [[ -d "/home/dnanexus/out/analysis_folder/analysis_folder/Results" ]]
	then 
	# rename metricsoutput.tsv file to include samplesheet part
	# check if file exists before trying to move
	if [[ -e "/home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput.tsv" ]]
		then
		mv /home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput.tsv /home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput$samplesheet_part.tsv
		# copy the metrics_tsv into it's own output so it appears in the /QC folder and can be accessed by downstream tools if required
		cp /home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput$samplesheet_part.tsv /home/dnanexus/out/metrics_tsv/QC/
	fi
	# move to results_zip output
	# make folder per pan number in results_zip output folder
	for pannum in $(ls -d /home/dnanexus/out/analysis_folder/analysis_folder/Results/*/| grep -o -E "Pan[0-9]{1,5}"  | sort --unique)
		do
		#make folder
		mkdir -p /home/dnanexus/out/results_zip/results/$pannum
		# copy the metrics tsv file into the pan number subfolder
		cp /home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput$samplesheet_part.tsv /home/dnanexus/out/results_zip/results/$pannum/
		done
		
	# move to directory containing results folders
	cd /home/dnanexus/out/analysis_folder/analysis_folder/Results;
	# loop through samples, only selecting directories
	for sample in ./*; do
		if [[ -d $sample ]];
			then 
			pannum=$(echo $sample | grep -o -E "Pan[0-9]{1,5}")
			# create a zip folder for that specific sample outside of any output folders - these will be zipped together later
			zip -r /home/dnanexus/out/results_zip/results/$pannum/$sample.zip $sample
		fi
	done
	cd ~
	# check if folder exists before trying to move
	if [[ -d "/home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/CollapsedReads" ]]
		then 
		# move the fastq output so they appear as seperate outputs from app for downstream tools, but go to the same place in the project
		mv /home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/CollapsedReads /home/dnanexus/out/fastqs/analysis_folder/Logs_Intermediates/
	fi
	# check if folder exists before trying to move
	if [[ -d "/home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/StitchedRealigned" ]]
		then
		# mv the bams (for coverage) so they appear as seperate outputs from app for downstream tools, but go to the same place in the project
		mv /home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/StitchedRealigned /home/dnanexus/out/bams_for_coverage/analysis_folder/Logs_Intermediates/
	fi
		# check if folder exists before trying to move
	if [[ -d "/home/dnanexus/out/analysis_folder/analysis_folder/Results" ]]
		then
		# mv the vcf results files (for sompy) so they appear as seperate outputs from app for downstream tools, but go to the same place in the project
		mv /home/dnanexus/out/analysis_folder/analysis_folder/Results /home/dnanexus/out/results_vcfs/analysis_folder/
	fi
	# copy the demultiplex stats - maintain folder structure as files are named the same for each lane and this would break multiqc app (having multiple files with same name)
	if [[ -d "/home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/FastqGeneration/DNA_Reports" ]]
		then 
		# move the contents of the DNA Reports folder (one folder per lane) recursively into /QC/bclconvert (this is for low throughput (LT) runs. path is different for HT, see below)
		cp -r /home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/FastqGeneration/DNA_Reports/* /home/dnanexus/out/QC_files/QC/bclconvert/
	fi
	if [[ -d "/home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/FastqGeneration/Reports" ]]
		then 
		# move the contents of the DNA Reports folder (one folder per lane) recursively into /QC/bclconvert (this is for high throughput (HT) runs. path is different for LT, see above)
		cp -r /home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/FastqGeneration/Reports/Lane_1/* /home/dnanexus/out/QC_files/QC/bclconvert/Lane_1$samplesheet_part/
		cp -r /home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/FastqGeneration/Reports/Lane_2/* /home/dnanexus/out/QC_files/QC/bclconvert/Lane_2$samplesheet_part/
	fi
fi
# upload all outputs
dx-upload-all-outputs --parallel

