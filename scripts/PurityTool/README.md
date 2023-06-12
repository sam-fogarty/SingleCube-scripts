This code uses cosmic ray muons detected in a SingleCube LArTPC to calculate the electron lifetime. There are multiple scripts that need to be run one after another. Note that this method will not work if the electron lifetime is too low (LAr purity is too bad) such that there are no anode-cathode crossing tracks. Code written by Mike Mooney (CSU) intended for use on SingleCube data.

Then adjust scanRadius and minClusterSize in TrackMaker.cpp.
Before running the tool, run `make`.

Then convert raw h5 file to ROOT by running ./H5toROOT
    `./H5toROOT <h5 file full address> <output root file>`

Example:
    `./H5toROOT ~/SingleCube/data/run3/LAr/selfTriggered/datalog_2021_04_16_22_16_58_MDT_.h5 datalog_2021_04_16_22_16_58_MDT_.root`
Then run TrackMaker script by running `./TrackMaker`
    `./TrackMaker datalog_2021_04_16_22_16_58_MDT_.root`
    
Output: analysis.root

Then run PurityStudy:
    `./PurityStudy analysis.root <Efield in V/cm>`
Output: results.root, pngs.

To move files to directories dedicated to each datalog file, run
    `source moveFiles.sh`

To run all scripts in one fell swoop, run
    `source runAllScripts.sh <datalog filename [exclude .h5 ending]> <Efield in V/cm>`
    
Example: `source runAllScripts.sh datalog_2021_04_16_22_16_58_MDT_ 554`
Note: make sure to edit the data directory variable in `runAllScripts.sh`