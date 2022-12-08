#!/bin/bash

# Output each line as it is executed (-x) and don't stop if any non zero exit codes are seen (+e)
set -x +e
mark-section "download inputs"

mkdir -p results_temp runfolder TSO500_ruo out/logs/logs out/analysis_folder out/results_zip/analysis_folder/ /home/dnanexus/out/fastqs/analysis_folder/Logs_Intermediates/CollapsedReads /home/dnanexus/out/bams_for_coverage/analysis_folder/Logs_Intermediates/StitchedRealigned /home/dnanexus/out/results_vcfs/analysis_folder/Results /home/dnanexus/out/results_zip/Results/ /home/dnanexus/out/metrics_tsv/QC /home/dnanexus/out/QC_files/QC/demultiplex_stats

# download all inputs
dx-download-all-inputs --parallel 

unzip $TSO500_ruo_path -d TSO500_ruo
rm $TSO500_ruo_path
# change the owner of the app
chmod 777 TSO500_ruo/TSO500_RUO_LocalApp/
# download the runfolder input
runfolder_name=$(echo "$project_name" | sed 's/002_//')
mkdir $runfolder_name
cd $runfolder_name
dx download -r "$project_name":"${runfolder_name}"'/*'
cd ../

# move the docker image into ~
mv TSO500_ruo/TSO500_RUO_LocalApp/trusight-oncology-500-ruo-dockerimage-ruo-*.tar /home/dnanexus/

# load docker image
sudo docker load --input /home/dnanexus/trusight-oncology-500-ruo-dockerimage-ruo-*.tar

# run the shell script, specifying the analysis folder, runfolder, samplesheet, resourcesFolder and any analysis options string given as an input
# pipe stderr into stdout and write this to a file and to screen - this allows a record of the logs to be saved and visible on screen if it goes wrong
sudo bash TSO500_ruo/TSO500_RUO_LocalApp/TruSight_Oncology_500_RUO.sh --analysisFolder /home/dnanexus/out/analysis_folder/analysis_folder --runFolder /home/dnanexus/$runfolder_name --sampleSheet $samplesheet_path --resourcesFolder /home/dnanexus/TSO500_ruo/TSO500_RUO_LocalApp/resources $analysis_options 2>&1 | tee /home/dnanexus/out/logs/logs/RUO_stdout.txt

### organise outputs to support use in downstream applications
# check if the results folder exists:
if [[ -d "/home/dnanexus/out/analysis_folder/analysis_folder/Results" ]]
	then 
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
	
	# We want to create seperate zip folders for each pan number
	# so first get a list of Pan numbers
	for pannum in $(ls -d /home/dnanexus/out/analysis_folder/analysis_folder/Results/*/| grep -o -E "Pan[0-9]{1,5}"  | sort --unique)
		do
		#make folder
		mkdir -p $pannum
		# copy the metrics tsv file into the pan number subfolder
		cp /home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput.tsv ./$pannum/
		# there is one folder in the current working directory for each sample)
		# we want to check if it's the current pan number and if so move it into the subfolder
		for folder in $(ls -d */)
			do 
			# check if sample folder contains the pan number, and also exclude the pan number folder itself
			if [[ "$folder" == *"$pannum"* ]] && [[ "$folder" != "$pannum"* ]] 
			then
				mv $folder ./$pannum/
			fi
			done
		# now all samples have been moved into subfolder create a zip folder in output dir for the pan number
		zip -r /home/dnanexus/out/results_zip/"$pannum"_Results.zip $pannum
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
	# check if file exists before trying to move
	if [[ -e "/home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput.tsv" ]]
		then
		# copy the metrics_tsv into it's own output so it appears in the /QC folder and can be accessed by downstream tools if required
		cp /home/dnanexus/out/analysis_folder/analysis_folder/Results/MetricsOutput.tsv /home/dnanexus/out/metrics_tsv/QC/
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
		# move the contents of the DNA Reports folder (one folder per lane) recursively into /QC/demultiplex_stats
		cp -r /home/dnanexus/out/analysis_folder/analysis_folder/Logs_Intermediates/FastqGeneration/DNA_Reports/* /home/dnanexus/out/QC_files/QC/demultiplex_stats/
	fi
fi
# upload all outputs
dx-upload-all-outputs --parallel

