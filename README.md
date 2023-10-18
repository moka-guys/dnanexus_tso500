# TSO500 v1.6.0

## What does this app do?
Runs the Illumina TSO500 local analysis app.
Note: this version of the app has been designed to support the analysis pipeline being run multiple times for a single run, i.e. for a 48 sample run, the samplesheet is split into 3 separate samplesheets containing up to 16 samples each (process handled by https://github.com/moka-guys/automate_demultiplex), and the pipeline set off once for each samplesheet. It therefore renames certain files and outputs to reflect this, e.g. the MetricsOutput.tsv file is renamed to MetricsOutputPart1.tsv. 

## What inputs are required for this app to run?
* TSO500_ruo - a zip file (originally provided by Illumina) containing the TSO500 local analysis app.
* DNAnexus project name- provided as a string. NB input is not the project ID
* runfolder name (string)
* Samplesheet
* analysis_options -  a string which can be passed to the ruo command line

## How does this app work?
* The following command was used to download the files: dx download -r project_name:runfolder_name
* Note: The runfolder is no longer expected to be archived (e.g .tar)
* Once the files are downloaded to a folder, the path is provided to TruSight_Oncology_500_RUO.sh
* Runs the TruSight_Oncology_500_RUO.sh (within the TSO500 local app zip file) providing arguments for analysis folder, runfolder, samplesheet, resourcesFolder and any other analysis options given as an input ($analysis_options)
* output files are organised to allow them to be accessed by downstream analyses such as coverage


## What does this app output
* RUO_stdout.txt - STDout from RUO. Saved into /logs
* The analysis folder. Saved into /analysis_folder
* zipped results folder for each sample
* fastqs - the content of analysis_folder/Logs_Intermediates/CollapsedReads (contains fastqs and all logs)
* stitchedrealigned BAMs - the content of analysis_folder/Logs_Intermediates/StitchedRealigned (contains BAMs and all logs)
* results vcfs - the content of analysis_folder/Results (contains all results vcfs)
* metrics_tsv file - An copy of the MetricsOutput.tsv is output into /QC so it can be accessed by multiqc.
* QC files - MultiQC compatible files saved to /QC (currently bclconvert stats files- the location of these is updated in the current version)

## Notes
* Only tested from starting point of BCLs
* analysis_options is not thoroughly tested.

## This app was made by Synnovis Genome Informatics
