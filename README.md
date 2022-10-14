This repository is a place to put analysis files for CSU's SingleCube detector.

We use the DUNE ND simulation chain to make simulations for SingleCube. The steps to follow are:

1. Run edep-sim (https://github.com/ClarkMcGrew/edep-sim), which is a wrapper around geant4. This requires making a macro which contains information about the particles, the energies, directions, etc to simulate. CORSIKA is typically used in DUNE ND simulation for cosmic ray generation. edep-sim produces a ROOT file that is used in the detector simulation.

2. Run larnd-sim (https://github.com/DUNE/larnd-sim), which is a python and GPU based program that simulates the near detector and its prototypes (including charge and light propagation, electronics, and light detectors). larnd-sim has a python script cli/dumpTree.py that converts the edep-sim ROOT file to an h5fy h5 file. This file is the type needed for larnd-sim, and is also the same type that is used to format the data from detectors.
