# TSO500 v1.5.0

## What does this app do?
Runs the Illumina TSO500 local analysis app.

## What inputs are required for this app to run?
* TSO500_ruo - a zip file (originally provided by Illumina) containing the TSO500 local analysis app.
* DNAnexus project name
* Samplesheet
* analysis_options -  a string which can be passed to the ruo command line

## How does this app work?
* The project ID is to used to download the required data.
* Runs the TruSight_Oncology_500_RUO.sh (within the TSO500 local app zip file) providing arguments for analysis folder, runfolder, samplesheet, resourcesFolder and any other analysis options given as an input ($analysis_options)


## What does this app output
* RUO_stdout.txt - STDout from RUO. Saved into /logs
* The analysis folder. Saved into /analysis_folder
* results zip folders for each Pan number containing zipped folders for each sample and the metrics.tsv.
* fastqs - the content of analysis_folder/Logs_Intermediates/CollapsedReads (contains fastqs and all logs)
* stitchedrealigned BAMs - the content of analysis_folder/Logs_Intermediates/StitchedRealigned (contains BAMs and all logs)
* results vcfs - the content of analysis_folder/Results (contains all results vcfs)
* metrics_tsv file - An copy of the MetricsOutput.tsv is output into /QC so it can be accessed by multiqc.
* QC files - MultiQC compatible files saved to /QC (currently bclconvert stats files)

## Notes
* Only tested from starting point of BCLs
* analysis_options is not thoroughly tested.
* Samplesheet input could be made optional in future - if not specified the analysis app looks for SampleSheet.csv in top level of runfolder

## This app was made by Viapath Genome Informatics
