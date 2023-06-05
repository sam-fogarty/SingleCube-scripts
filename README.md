To run the DUNE ND simulation chain to make simulations for SingleCube, the steps to follow are:

1. Run edep-sim (https://github.com/ClarkMcGrew/edep-sim), which is a wrapper around geant4. This requires making a macro which contains information about the particles, the energies, directions, etc to simulate. CORSIKA is typically used in DUNE ND simulation for cosmic ray generation. edep-sim produces a ROOT file that is used in the detector simulation.

2. Run larnd-sim (https://github.com/DUNE/larnd-sim), which is a python and GPU based program that simulates the near detector and its prototypes (including charge and light propagation, electronics, and light detectors). larnd-sim has a python script cli/dumpTree.py that converts the edep-sim ROOT file to an h5fy h5 file. This file is the type needed for larnd-sim, and is also the same type that is used to format the data from detectors.

3. X reconstruction software

For running larnd-sim and some reconstructions, you may want json files that list the larpix config / pedestals per larpix channel. These can be made by using scripts at https://github.com/larpix/larpix-v2-testing-scripts/tree/master/event-display. In particular:

1. gen_config_json.py creates the larpix config json
2. gen_pedestal_json.py creates the larpix pedestals json

Example of getting config json:
`python3 gen_config_json.py --controller_config ~/SingleCube/larpix-10x10-scripts/tile-id-3-pacman-tile-1-hydra-network.json --vref_dac 185 --vcm_dac 41`
The vref_dac and vcm_dac were picked from the individual asic configuration files. 

Example of getting pedestal json:
`python3 gen_pedestal_json.py --infile ~/SingleCube/larpix-10x10-scripts/tile-id-3-pedestal_2022_12_19_14_31_54_MST____tile-id-3-trigger-rate-DO-NOT-ENABLE-channel-list-2022_12_19_14_27_56_vv1.0.3.h5`
Your pedestal file may have a slightly different name than the example here.
