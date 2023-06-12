#!/bin/bash
###############################
CONTROLLER_CONFIG='tile-id-3-pacman-tile-1-hydra-network-warm-in-tpc_4.json'
ASIC_CONFIGS='asics-configs_Jan11_warm_in_TPC/'
N_RUNS=5
RUNTIME=30 # in s
# NOTE: If sda1 is not mounted, run 'sudo mount /dev/sda1 /mount/sda1' (without quotes)
OUTDIR='/mount/sda1/SingleCube_Jan2023/warm_shielding/successiveRunTest' 
###############################

for ((i=0; i<=$N_RUNS; i++)); do
    echo "Run number $i" 
    echo "Run time: $RUNTIME"
    #python3 start_run_log_raw.py --controller_config $CONTROLLER_CONFIG --config_name $ASIC_CONFIGS --runtime $RUNTIME --outdir $OUTDIR
    python3 start_run_log_raw.py --controller_config $CONTROLLER_CONFIG \
    --config_name $ASIC_CONFIGS \ 
    --runtime $RUNTIME \
    
    # Manually moving the output file because start_run_log_raw's --outdir parameter doesn't work now?
    mv tile-id-3-raw_2023_01_*h5 /mount/sda1/SingleCube_Jan2023/LAr/selfTriggered/
done
