
#!/bin/bash

#runlistname="runlist_all.txt"
#runlistname="runlist_new.txt"
runlistname="runlist_all_SingleCube_CSU.txt"
#runlistname="runlist_new_SingleCube_CSU.txt"
#runlistname="runlist_new_SingleCube_CSU_2.txt"
#testname="Module0HV"
testname="SingleCube_CSU"
#testname="Module0"

while IFS=$' ' read -r -a arr; do
    if [[ $1 -eq 1 ]]
    then
	echo "${arr[0]} ${arr[1]}"
	mkdir -p data/$testname/root/E${arr[1]}
	#python raw_to_root.py -i data/$testname/raw/E${arr[1]}/datalog_${arr[0]}.h5 -o data/$testname/root/E${arr[1]}/datalog_${arr[0]}.root
	./H5toROOT data/$testname/raw/E${arr[1]}/datalog_${arr[0]}.h5 data/$testname/root/E${arr[1]}/datalog_${arr[0]}.root
	#python raw_to_root_multitile.py -i data/$testname/raw/E${arr[1]}/datalog_${arr[0]}.h5 -o data/$testname/root/E${arr[1]}/datalog_${arr[0]}.root
	mkdir -p data/$testname/analysis/E${arr[1]}
	./TrackMaker data/$testname/root/E${arr[1]}/datalog_${arr[0]}.root
	#./TrackMakerMultiTile data/$testname/root/E${arr[1]}/datalog_${arr[0]}.root
	mv analysis.root data/$testname/analysis/E${arr[1]}/analysis_${arr[0]}.root
	mkdir -p results/$testname/E${arr[1]}
	mkdir -p results/$testname/E${arr[1]}/${arr[0]}
	./PurityStudy data/$testname/analysis/E${arr[1]}/analysis_${arr[0]}.root ${arr[1]}
	mv *png results/$testname/E${arr[1]}/${arr[0]}/.
	mv results.root results/$testname/E${arr[1]}/${arr[0]}/.
    elif [[ $1 -eq 2 ]]
    then
	mkdir -p results/$testname/E${arr[1]}
	mkdir -p results/$testname/E${arr[1]}/${arr[0]}
	./PurityStudy data/$testname/analysis/E${arr[1]}/analysis_${arr[0]}.root ${arr[1]}
	mv *png results/$testname/E${arr[1]}/${arr[0]}/.
	mv results.root results/$testname/E${arr[1]}/${arr[0]}/.
    fi
done < $runlistname
