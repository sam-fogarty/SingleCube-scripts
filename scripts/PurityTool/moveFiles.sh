#!/bin/bash
testname="SingleCube_CSU"
if [[ -z "$1" ]]; then
	echo "Enter datalog file name (exclude .h5 or .root)"
else
	mkdir -p data/$testname/root/$1/
	mkdir -p data/$testname/analysis/$1/
	mkdir -p data/$testname/results/$1/
	mkdir -p data/$testname/plots/$1/
	mv *.png /home/herogers/SingleCube/SCPurityTool/data/SingleCube_CSU/plots/$1/
	mv analysis.root /home/herogers/SingleCube/SCPurityTool/data/SingleCube_CSU/analysis/$1/
	mv results.root /home/herogers/SingleCube/SCPurityTool/data/SingleCube_CSU/results/$1/
	mv $1.root /home/herogers/SingleCube/SCPurityTool/data/SingleCube_CSU/root/$1/
fi

