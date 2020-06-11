# TSO500 v1.0

## What does this app do?
Runs the Illumina TSO500 local analysis app.

## What inputs are required for this app to run?
* TSO500_ruo - a zip file (originally provided by Illumina) containing the local app.
* Runfolder.tar - a tarred runfolder
* samplesheet
* analysis_options -  a string which can be passed to the ruo command line

## How does this app work?
Downloads and unzips/untars the TSO500 local analysis app and runfolder
Runs the TruSight_Oncology_500_RUO.sh (within the TSO500 local app zip file) providing arguments for analysis folder, runfolder, samplesheet, resourcesFolder and any other analysis options given as an input ($analysis_options)


## What does this app output
* RUO_stdout.txt - STDout from RUO. Saved into /logs
* The analysis folder. Saved into /analysis_folder

## Notes
* Only tested from starting point of BCLs
* analysis_options not thoroughly tested.
* Recommended instance type not yet tested - instance type in json (mem1_ssd1_x32) provides 60382MB memory and 639GB SSD storage.

## This app was made by Viapath Genome Informatics
