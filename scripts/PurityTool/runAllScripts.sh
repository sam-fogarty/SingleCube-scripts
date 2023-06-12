#!/bin/bash 
testname="SingleCube_CSU"
data_dir="/home/herogers/SingleCube/data/run3/LAr/selfTriggered"
if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Enter datalog file name (exclude .h5 or .root) for first argument, and Efield in V/cm for second argument."
#elif [[ -z "$2" ]]; then
#	echo "Enter the Efield in V/cm into second argument"
else
	./H5toROOT $data_dir/"$1".h5 "$1".root
	./TrackMaker "$1".root
	./PurityStudy analysis.root "$2"
fi


