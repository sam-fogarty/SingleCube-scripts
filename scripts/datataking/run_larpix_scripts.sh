#!/bin/bash
### Helper script for running the LArPix DAQ scripts
# Author: Sam Fogarty
# samuel.fogarty@colostate.edu

io_group=1
pacman_tile=1
tile_id=3
geometry_yaml=layout-2.4.0.yaml

hydra_json_folder=hydra_network
mkdir -p $hydra_json_folder
hydra_plot_folder=plots
mkdir -p $hydra_plot_folder
trigger_rate_folder=trigger_rate_do_not_enable
mkdir -p $trigger_rate_folder
trigger_rate_no_cut=trigger_rate_no_cut
mkdir -p $trigger_rate_no_cut
pedestal_second_folder=pedestal_disabled_list_second
mkdir -p $pedestal_second_folder
pedestal_first_folder=pedestal_disabled_list_first
mkdir -p $pedestal_first_folder
recursive_pedestal_folder=recursive_pedestal
mkdir -p $recursive_pedestal_folder
trigger_rate_10kHz=trigger_rate_10kHz_cut
mkdir -p $trigger_rate_10kHz
asics_configs=asics-configs
mkdir -p $asics_configs
disabled_channel_plots=plots
mkdir -p $disabled_channel_plots
power_up_jsons=power_up_jsons
mkdir -p $power_up_jsons
pedestal_and_trigger_rate=pedestal_and_trigger_rate
mkdir -p $pedestal_and_trigger_rate
#data_folder=/mount/sda1/SingleCube_Dec2023
data_folder=/mount/sda1/SingleCube_Jan2023/LAr/selfTriggered/18kV
raw_data=${data_folder}/raw_data
#converted_data=${data_folder}/converted_data
converted_data=${data_folder}
cluster_data=${data_folder}/cluster_data
mkdir -p $raw_data
mkdir -p $converted_data
mkdir -p $cluster_data
metric_plots=plots
mkdir -p $metric_plots
larpix_v2_testing_scripts_dir=~/SingleCube/larpix-v2-testing-scripts/event-display
evd_configs=evd_configs
mkdir -p $evd_configs
files_drive_dir=/mount/sda1/SingleCube_files
larpix_monitor_dir=/home/herogers/SingleCube/larpix-monitor
clustering_code_dir=/home/herogers/SingleCube/ndlar_39Ar_reco/charge_reco
hydra_network_file=""

echo " "
echo "This is a helper script for running the LArPix data-taking scripts with a LArTPC. Before running any of these scripts, make sure the TPC is connected to the PACMAN, everything is powered up, and the current draw looks reasonable. Make sure to modify the raw_data and converted_data directories: this script will automatically move all the files to corresponding directories. Make sure to also to use a good file descriptor as most of the files will be labeled with it."
echo " "

# load previous file descriptor
VAR_FILE="larpix_script_data.json"
# check if the JSON file exists
if [ -f "$VAR_FILE" ]; then
    descriptor=$(jq -r '.descriptor' "$VAR_FILE")
    while true; do
        echo "Use previous file descriptor '$descriptor'? (y/n)"
        read use_last_descriptor
        if [ "$use_last_descriptor" == "y" ] || [ "$use_last_descriptor" == "yes" ]; then
            break
        elif [ "$use_last_descriptor" == "n" ] || [ "$use_last_descriptor" == "no" ]; then
            echo "Enter a file descriptor to add to the files (no spaces). Make sure to be descriptive, like warm_TPC_in_cryostat_Dec52023 or LAr_Dec112023:"
            read new_descriptor
            jq --arg new_descriptor "$new_descriptor" '.descriptor = $new_descriptor' "$VAR_FILE" > tmp.json && mv tmp.json "$VAR_FILE"
            descriptor=$new_descriptor
            break
        fi
    done
else
    echo "Enter a file descriptor to add to the files (no spaces). Make sure to be descriptive, like warm_TPC_in_cryostat_Dec52023 or LAr_Dec12023:"
    read descriptor
    echo "{ \"descriptor\": \"$descriptor\" }" > "$VAR_FILE" # update json
fi

while true; do
    echo "Enter the number of which script you would like to run (q to quit): "
    echo "1 - check_power.py (check current draws)"
    echo "2 - map_uart_links_qc.py (make hydra network)"
    echo "3 - plot_hydra_network_v2a.py (make hydra network plot)"
    echo "4 - multi_trigger_rate_qc.py (make trigger rate disabled channel list)"
    echo "5 - pedestal_qc.py (make pedestal disabled channel list)"
    echo "6 - plot_xy_disabled_channel.py (make disabled channel plots)"
    echo "7 - threshold_qc.py (make thresholds)"
    echo "8 - start_run_log_raw.py (self-trigger run)"
    echo "9 - convert_rawhdf5_to_hdf5.py (convert raw file to packets file)"
    echo "10 - plot_metric.py (plot mean, standard deviation, rate per channel; uses converted h5 file)"
    echo "11 - make pedestal and config json files"
    echo "12 - move files"
    echo "13 - continuous self-trigger runs"
    echo "14 - increment_global.py (raise or lower global CRS threshold)"
    echo "15 - run larpix-monitor (make e.g. 2D mean, std, rate plots, channel rate plot; uses raw h5 files)"
    echo "16 - run clustering on packetized file"
    read number

    # Check if the user wants to quit
    if [ "$number" == "q" ]; then
        echo "Exiting..."
        break
    fi

    # Check the input and run the corresponding command
    if [ "$number" == "1" ]; then
        echo "Running check_power.py script: "
        echo "python3 check_power.py --pacman_tile $pacman_tile --io_group $io_group"
        python3 check_power.py --pacman_tile $pacman_tile --io_group $io_group
        echo "Script finished, check output."
        echo " "
		mv -f power-up*.json $power_up_jsons/
    elif [ "$number" == "2" ]; then
        echo "Running map_uart_links_qc.py script: "
        echo "python3 -u map_uart_links_qc.py --pacman_tile $pacman_tile --tile_id $tile_id --io_group $io_group"
        python3 -u map_uart_links_qc.py --pacman_tile $pacman_tile --tile_id $tile_id --io_group $io_group
        echo "Script finished, check output."
        echo " "
        echo "To retry, enter 1 and repick map_uart_links_qc.py."
        echo "To continue, enter 2."
        read input_hydra
        
        if [ "$input_hydra" == "2" ]; then

            selected_file=tile-id-${tile_id}-pacman-tile-${pacman_tile}-hydra-network.json
            # Construct the new filename
            base_name=$(basename "$selected_file" .json)
            new_file="${base_name}_${descriptor}.json"
  
            # Rename the file
            mv "$selected_file" "$hydra_json_folder/$new_file"
            echo "Hydra network file has been moved to: $hydra_json_folder/$new_file"
            hydra_network_file=$hydra_json_folder/$new_file  
            echo " "
        fi
    elif [ "$number" == "3" ]; then
        shopt -s nullglob
        json_files=( $hydra_json_folder/*hydra*.json )
        shopt -u nullglob
        if [ -n "$hydra_network_file" ]; then
            echo "Using hydra network file ${hydra_network_file}"
        elif [ ${#json_files[@]} -eq 0 ]; then
            echo "No .json files found in $hydra_json_folder, please enter path to hydra network file to use:"
            while true; do
                echo "(You can use ls and pwd commands here to look around)"
                read hydra_network_file

                if [[ $hydra_network_file == ls* ]]; then
                    eval "$hydra_network_file"
                elif [[ $hydra_network_file == pwd* ]]; then
                    eval "$hydra_network_file"
                else
                    break
                fi
            done
        else
            echo "Select a hydra network configuration to use for making plot (enter 0 to manually enter path):"
            count=1
            for file in "${json_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
            done
            read choice
            if [ "$choice" -eq "0" ]; then
                while true; do
                    echo "Please enter the path to hydra network file to use:"
                    echo "(You can use ls and pwd commands here to look around)"
                    read choice_2

                    if [[ $choice_2 == ls* ]]; then
                        eval "$choice_2"
                    elif [[ $choice_2 == pwd* ]]; then
                        eval "$choice_2"
                    else
                        break
                    fi
                done
            fi
	    hydra_network_file="${json_files[$choice-1]}"
        fi
        echo "python3 plot_hydra_network_v2a.py --controller_config $hydra_network_file --geometry_yaml $geometry_yaml --io_group $io_group"
        python3 plot_hydra_network_v2a.py --controller_config $hydra_network_file --geometry_yaml $geometry_yaml --io_group $io_group
        
        mv hydra-network-tile-id-${tile_id}.png ${hydra_plot_folder}/hydra-network-tile-id-${tile_id}_${descriptor}.png
            
        echo "File has been moved to: ${hydra_plot_folder}/hydra-network-tile-id-${tile_id}_${descriptor}.png"
        echo "Displaying plot. Close plot window to continue."
		display ${hydra_plot_folder}/hydra-network-tile-id-${tile_id}_${descriptor}.png
    elif [ "$number" == "4" ]; then
        shopt -s nullglob
        json_files=( $hydra_json_folder/*hydra*.json )
        shopt -u nullglob
        if [ -n "$hydra_network_file" ]; then
            echo "Using hydra network file ${hydra_network_file}"
            selected_file=$hydra_network_file
        elif [ ${#json_files[@]} -eq 0 ]; then
            echo "No .json files found in $hydra_json_folder, please enter path to hydra network file to use:"
            while true; do
                echo "(You can use ls and pwd commands here to look around)"
                read selected_file

                if [[ $selected_file == ls* ]]; then
                    eval "$selected_file"
                elif [[ $selected_file == pwd* ]]; then
                    eval "$selected_file"
                else
                    break
                fi
            done
        else
            echo "Enter the number corresponding to hydra network file to use (enter 0 to manually enter path):"
            count=1
            for file in "${json_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
            done
            read json_choice
            if [ "$json_choice" -eq "0" ]; then
                echo "Please enter path to hydra network file to use:"
                while true; do
                    echo "(You can use ls and pwd commands here to look around)"
                    read selected_file

                    if [[ $selected_file == ls* ]]; then
                        eval "$selected_file"
                    elif [[ $selected_file == pwd* ]]; then
                        eval "$selected_file"
                    else
                        break
                    fi
                done
            else
                selected_file="${json_files[$json_choice-1]}"
            fi
        fi
        echo "python3 multi_trigger_rate_qc.py --controller_config $selected_file"
        python3 multi_trigger_rate_qc.py --controller_config $selected_file
        echo "To retry, enter 1 and repick multi_trigger_rate_qc.py."
        echo "To continue, enter 2."
        read input_trigger_rate
        if [ "$input_trigger_rate" -eq "2" ]; then
            shopt -s nullglob
            trigger_rate_files=( *DO-NOT-ENABLE*.json )
            shopt -u nullglob
            if [ ${#trigger_rate_files[@]} -eq 0 ]; then
                echo "No trigger rate files found in the current directory to rename, moving on."
                echo " "
            else
                echo "Enter the number corresponding to the trigger rate file you want to rename:"
                count=1
                for file in "${trigger_rate_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
                done
                read choice
                #echo "Enter file descriptor (no spaces):"
                #read descriptor
                selected_file="${trigger_rate_files[$choice-1]}"
                base_name=$(basename "$selected_file" .json)
                new_file="${base_name}_${descriptor}.json"
                mv "$selected_file" "$trigger_rate_folder/$new_file"
				mv *10kHz*.h5 $trigger_rate_10kHz/
				mv *no_cut*.h5 $trigger_rate_no_cut/
                echo "File has been moved to: $trigger_rate_folder/$new_file"
                echo " "
            fi
        fi
    elif [ "$number" == "5" ]; then
        shopt -s nullglob
        json_files=( $hydra_json_folder/*hydra*.json )
        shopt -u nullglob
        if [ -n "$hydra_network_file" ]; then
            echo "Using hydra network file ${hydra_network_file}"
            selected_file=$hydra_network_file
        elif [ ${#json_files[@]} -eq 0 ]; then
            echo "No .json files found in $hydra_json_folder, please enter path to hydra network file to use:"
            while true; do
                echo "(You can use ls and pwd commands here to look around)"
                read selected_file

                if [[ $selected_file == ls* ]]; then
                    eval "$selected_file"
                elif [[ $selected_file == pwd* ]]; then
                    eval "$selected_file"
                else
                    break
                fi
            done
        else
            echo "Enter the number corresponding to hydra network file to use (enter 0 to manually enter path):"
            count=1
            for file in "${json_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
            done
            read json_choice
            if [ "$json_choice" -eq "0" ]; then
                echo "Please enter path to hydra network file to use:"
                while true; do
                    echo "(You can use ls and pwd commands here to look around)"
                    read selected_file

                    if [[ $selected_file == ls* ]]; then
                        eval "$selected_file"
                    elif [[ $selected_file == pwd* ]]; then
                        eval "$selected_file"
                    else
                        break
                    fi
                done
            else
                selected_file="${json_files[$json_choice-1]}"
            fi
        fi

        shopt -s nullglob
        trigger_rate_files=( $trigger_rate_folder/*DO-NOT-ENABLE*.json )
        shopt -u nullglob
        if [ ${#trigger_rate_files[@]} -eq 0 ]; then
            echo "No trigger rate DO-NOT-ENABLE files found in $trigger_rate_folder, please enter path to DO-NOT-ENABLE list to use:"
            while true; do
                echo "(You can use ls and pwd commands here to look around)"
                read selected_do_not_enable_list

                if [[ $selected_do_not_enable_list == ls* ]]; then
                    eval "$selected_do_not_enable_list"
                elif [[ $selected_do_not_enable_list == pwd* ]]; then
                    eval "$selected_do_not_enable_list"
                else
                    break
                fi
            done
            echo " "
        else
            echo "Enter the number corresponding to the trigger rate DO-NOT-ENABLE file you want to use (enter 0 to manually specify path):"
            count=1
            for file in "${trigger_rate_files[@]}"; do
                echo "$count. $file"
                count=$((count+1))
            done
            read choice
            if [ "$choice" -eq "0" ]; then
                while true; do
                    echo "Please enter path to trigger rate DO-NOT-ENABLE file you want to use:"
                    echo "(You can use ls and pwd commands here to look around)"
                    read selected_do_not_enable_list

                    if [[ $selected_do_not_enable_list == ls* ]]; then
                        eval "$selected_do_not_enable_list"
                    elif [[ $selected_do_not_enable_list == pwd* ]]; then
                        eval "$selected_do_not_enable_list"
                    else
                        break
                    fi
                done
            else
                selected_do_not_enable_list="${trigger_rate_files[$choice-1]}"
            fi
        fi
        echo " "
        echo "Enter runtime for pedestal run (seconds):"
        read runtime
        echo "python3 pedestal_qc.py --controller_config $selected_file --disabled_list $selected_do_not_enable_list --runtime $runtime" 
        python3 pedestal_qc.py --controller_config $selected_file --disabled_list $selected_do_not_enable_list --runtime $runtime
        mv *pedestal*DO-NOT-ENABLE*.h5 $pedestal_and_trigger_rate/
        echo "To retry, enter 1 and repick pedestal_qc.py."
        echo "To continue, enter 2."
        read input_pedestal
        if [ "$input_pedestal" -eq "2" ]; then
            shopt -s nullglob
            pedestal_second_files=( *second*.json )
            shopt -u nullglob

            shopt -s nullglob
            recursive_pedestal_files=( *recursive-pedestal*.h5 )
            shopt -u nullglob
            if [ ${#pedestal_second_files[@]} -eq 0 ]; then
                echo "No pedestal disabled jsons found in current directory, moving on."
                echo " "
            else
                echo "Enter the number corresponding to the pedestal second file you want to rename:"
                count=1
                for file in "${pedestal_second_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
                done
                read choice
                #echo "Enter file descriptor (no spaces):"
                #read descriptor
                selected_file="${pedestal_second_files[$choice-1]}"
                base_name=$(basename "$selected_file" .json)
                new_file="${base_name}_${descriptor}.json"
                mv "$selected_file" "$pedestal_second_folder/$new_file"
                mv *first*.json $pedestal_first_folder/
                echo "File has been moved to: $pedestal_second_folder/$new_file"
                echo " "
            fi
            if [ ${#recursive_pedestal_files[@]} -eq 0 ]; then
                echo "No recursive pedestal files found in current directory, moving on."
                echo " "
            else
                echo "Enter the number corresponding to the recursive pedestal file you want to rename:"
                count=1
                for file in "${recursive_pedestal_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
                done
                read choice
                #echo "Enter file descriptor (no spaces):"
                #read descriptor
                selected_file="${recursive_pedestal_files[$choice-1]}"
                base_name=$(basename "$selected_file" .h5)
                new_file="${base_name}_${descriptor}.h5"
                mv "$selected_file" "$recursive_pedestal_folder/$new_file"
                echo "File has been moved to: $recursive_pedestal_folder/$new_file"
                echo " "
            fi
        fi
    elif [ "$number" == "6" ]; then
        echo "Choose option for plotting disabled channels:"
        echo "1 - Plot only trigger-rate disabled channels"
        echo "2 - Plot only pedestal disabled channels"
        echo "3 - Plot both trigger-rate and pedestal disabled channels"
        read disabled_channel_choice
        if [ "$disabled_channel_choice" == "1" ]; then
            shopt -s nullglob
            trigger_rate_disabled_files=( $trigger_rate_folder/*.json )
            shopt -u nullglob
            if [ ${#trigger_rate_disabled_files[@]} -eq 0 ]; then
                echo "No .json files found in $trigger_rate_folder, please enter path to trigger-rate disabled channel json file to use:"
                while true; do
                    echo "(You can use ls and pwd commands here to look around)"
                    read selected_file
    
                    if [[ $selected_file == ls* ]]; then
                        eval "$selected_file"
                    elif [[ $selected_file == pwd* ]]; then
                        eval "$selected_file"
                    else
                        break
                    fi
                done
            else 
                echo "Enter the number corresponding to trigger-rate disabled channel json file to use (enter 0 to manually enter path):"
                count=1
                for file in "${trigger_rate_disabled_files[@]}"; do
                        echo "$count. $file"
                        count=$((count+1))
                done
                read json_choice
                if [ "$json_choice" -eq "0" ]; then
                    echo "Please enter path to disabled channel json to use:"
                    while true; do
                        echo "(You can use ls and pwd commands here to look around)"
                        read selected_file

                        if [[ $selected_file == ls* ]]; then
                            eval "$selected_file"
                        elif [[ $selected_file == pwd* ]]; then
                            eval "$selected_file"
                        else
                            break
                        fi
                    done
                else
                    selected_file="${trigger_rate_disabled_files[$json_choice-1]}"
                fi
            fi
            echo "python3 plot_xy_disabled_channel.py --trigger_disabled $selected_file"
            python3 plot_xy_disabled_channel.py --trigger_disabled $selected_file
            echo "Script finished, check output."
            echo " "
            echo "To retry, enter 1 and repick plot_xy_disabled_channel.py. Otherwise enter 2 to continue."
            read choice
            if [ "$choice" -eq "2" ]; then
                echo "Enter the number corresponding to disabled channel plot for renaming: "
                shopt -s nullglob
                png_files=( *.png )
                shopt -u nullglob
                if [ ${#png_files[@]} -eq 0 ]; then
                    echo "No .png files found in the current directory to rename, moving on."
                else
                    count=1
                    for file in "${png_files[@]}"; do
                            echo "$count. $file"
                            count=$((count+1))
                    done
                    read choice
                    #echo "Enter file descriptor (no spaces):"
                    #read descriptor
                    selected_file="${png_files[$choice-1]}"
                    base_name=$(basename "$selected_file" .png)
                    new_file="${base_name}_trigger-rate_${descriptor}.png"
                    mv "$selected_file" "$disabled_channel_plots/$new_file"
                    echo "File has been moved to: $disabled_channel_plots/$new_file"
                    echo "Displaying plot. Close plot window to continue."
                    display $disabled_channel_plots/$new_file
                fi
            fi            
            
        elif [ "$disabled_channel_choice" == "2" ]; then
            shopt -s nullglob
            pedestal_disabled_files=( $pedestal_second_folder/*.json )
            shopt -u nullglob
            if [ ${#pedestal_disabled_files[@]} -eq 0 ]; then
                echo "No .json files found in $pedestal_second_folder, please enter path to pedestal disabled channel json file to use:"
                while true; do
                    echo "(You can use ls and pwd commands here to look around)"
                    read selected_file
    
                    if [[ $selected_file == ls* ]]; then
                        eval "$selected_file"
                    elif [[ $selected_file == pwd* ]]; then
                        eval "$selected_file"
                    else
                        break
                    fi
                done
            else 
                echo "Enter the number corresponding to pedestal disabled channel json file to use (enter 0 to manually enter path):"
                count=1
                for file in "${pedestal_disabled_files[@]}"; do
                        echo "$count. $file"
                        count=$((count+1))
                done
                read json_choice
                if [ "$json_choice" -eq "0" ]; then
                    echo "Please enter path to disabled channel json to use:"
                    while true; do
                        echo "(You can use ls and pwd commands here to look around)"
                        read selected_file

                        if [[ $selected_file == ls* ]]; then
                            eval "$selected_file"
                        elif [[ $selected_file == pwd* ]]; then
                            eval "$selected_file"
                        else
                            break
                        fi
                    done
                else
                    selected_file="${pedestal_disabled_files[$json_choice-1]}"
                fi
            fi
            echo "python3 plot_xy_disabled_channel.py --pedestal_disabled $selected_file"
            python3 plot_xy_disabled_channel.py --pedestal_disabled $selected_file
            echo "Script finished, check output."
            echo " "
            echo "To retry, enter 1 and repick plot_xy_disabled_channel.py. Otherwise enter 2 to continue."
            read choice
            if [ "$choice" -eq "2" ]; then
                echo "Enter the number corresponding to disabled channel plot for renaming: "
                shopt -s nullglob
                png_files=( *.png )
                shopt -u nullglob
                if [ ${#png_files[@]} -eq 0 ]; then
                    echo "No .png files found in the current directory to rename, moving on."
                else
                    count=1
                    for file in "${png_files[@]}"; do
                            echo "$count. $file"
                            count=$((count+1))
                    done
                    read choice
                    #echo "Enter file descriptor (no spaces):"
                    #read descriptor
                    selected_file="${png_files[$choice-1]}"
                    base_name=$(basename "$selected_file" .png)
                    new_file="${base_name}_pedestal_${descriptor}.png"
                    mv "$selected_file" "$disabled_channel_plots/$new_file"
                    echo "File has been moved to: $disabled_channel_plots/$new_file"
                    echo "Displaying plot. Close plot window to continue."
                    display $disabled_channel_plots/$new_file
                fi
            fi
                 
		elif [ "$disabled_channel_choice" == "3" ]; then
		    shopt -s nullglob
		    pedestal_disabled_files=( $pedestal_second_folder/*.json )
		    shopt -u nullglob

		    shopt -s nullglob
		    trigger_rate_disabled_files=( $trigger_rate_folder/*.json )
		    shopt -u nullglob

		    if [ ${#pedestal_disabled_files[@]} -eq 0 ]; then
		        echo "No .json files found in $pedestal_second_folder, please enter path to pedestal disabled channel json file to use:"
		        while true; do
		            echo "(You can use ls and pwd commands here to look around)"
		            read selected_file

		            if [[ $selected_file == ls* ]]; then
		                eval "$selected_file"
		            elif [[ $selected_file == pwd* ]]; then
		                eval "$selected_file"
		            else
		                break
		            fi
		        done
		    else 
		        echo "Enter the number corresponding to pedestal disabled channel json file to use (enter 0 to manually enter path):"
		        count=1
		        for file in "${pedestal_disabled_files[@]}"; do
		                echo "$count. $file"
		                count=$((count+1))
		        done
		        read json_choice
		        if [ "$json_choice" -eq "0" ]; then
		            echo "Please enter path to disabled channel json to use:"
		            while true; do
		                echo "(You can use ls and pwd commands here to look around)"
		                read selected_file

		                if [[ $selected_file == ls* ]]; then
		                    eval "$selected_file"
		                elif [[ $selected_file == pwd* ]]; then
		                    eval "$selected_file"
		                else
		                    break
		                fi
		            done
		        else
		            selected_pedestal_file="${pedestal_disabled_files[$json_choice-1]}"
		        fi
		    fi
		    if [ ${#trigger_rate_disabled_files[@]} -eq 0 ]; then
		        echo "No .json files found in $trigger_rate_folder, please enter path to trigger-rate disabled channel json file to use:"
		        while true; do
		            echo "(You can use ls and pwd commands here to look around)"
		            read selected_file

		            if [[ $selected_file == ls* ]]; then
		                eval "$selected_file"
		            elif [[ $selected_file == pwd* ]]; then
		                eval "$selected_file"
		            else
		                break
		            fi
		        done
		    else 
		        echo "Enter the number corresponding to trigger-rate disabled channel json file to use (enter 0 to manually enter path):"
		        count=1
		        for file in "${trigger_rate_disabled_files[@]}"; do
		                echo "$count. $file"
		                count=$((count+1))
		        done
		        read json_choice
		        if [ "$json_choice" -eq "0" ]; then
		            echo "Please enter path to disabled channel json to use:"
		            while true; do
		                echo "(You can use ls and pwd commands here to look around)"
		                read selected_file

		                if [[ $selected_file == ls* ]]; then
		                    eval "$selected_file"
		                elif [[ $selected_file == pwd* ]]; then
		                    eval "$selected_file"
		                else
		                    break
		                fi
		            done
		        else
		            selected_trigger_file="${trigger_rate_disabled_files[$json_choice-1]}"
		        fi    
		    fi
		    echo "python3 plot_xy_disabled_channel.py --pedestal_disabled $selected_pedestal_file --trigger_disabled $selected_trigger_file"
		    python3 plot_xy_disabled_channel.py --pedestal_disabled $selected_pedestal_file --trigger_disabled $selected_trigger_file
		    mv disabled-xy-map-tile-id-${tile_id}.png $disabled_channel_plots/disabled-xy-map-tile-id-${tile_id}.png            
		    echo "File has been moved to: $disabled_channel_plots/disabled-xy-map-tile-id-${tile_id}.png"
		    echo "Displaying plot. Close plot window to continue."
		    display $disabled_channel_plots/disabled-xy-map-tile-id-${tile_id}.png
		fi
    elif [ "$number" == "7" ]; then
        shopt -s nullglob
        json_files=( $hydra_json_folder/*hydra*.json )
        shopt -u nullglob
        if [ -n "$hydra_network_file" ]; then
            echo "Using hydra network file ${hydra_network_file}"
            hydra_network_selected_file=${hydra_network_file}
        elif [ ${#json_files[@]} -eq 0 ]; then
            echo "No .json files found in $hydra_json_folder, please enter path to hydra network file to use:"
            while true; do
                echo "(You can use ls and pwd commands here to look around)"
                read hydra_network_selected_file
 
                if [[ $hydra_network_selected_file == ls* ]]; then
                    eval "$hydra_network_selected_file"
                elif [[ $hydra_network_selected_file == pwd* ]]; then
                    eval "$hydra_network_selected_file"
                else
                    break
                fi
            done
        else
            echo "Enter the number corresponding to hydra network file to use (enter 0 to manually enter path):"
            count=1
            for file in "${json_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
            done
            read json_choice
            if [ "$json_choice" -eq "0" ]; then
                echo "Please enter path to hydra network file to use:"
                while true; do
                    echo "(You can use ls and pwd commands here to look around)"
                    read hydra_network_selected_file

                    if [[ $hydra_network_selected_file == ls* ]]; then
                        eval "$hydra_network_selected_file"
                    elif [[ $hydra_network_selected_file == pwd* ]]; then
                        eval "$hydra_network_selected_file"
                    else
                        break
                    fi
                done
 
            else
                hydra_network_selected_file="${json_files[$json_choice-1]}"
            fi
        fi

        shopt -s nullglob
    	pedestal_disabled_files=( $pedestal_second_folder/*.json )
		shopt -u nullglob
		if [ ${#pedestal_disabled_files[@]} -eq 0 ]; then
				echo "No .json files found in $pedestal_second_folder, please enter path to pedestal disabled channel json file to use:"
		        while true; do
		            echo "(You can use ls and pwd commands here to look around)"
		            read pedestal_disabled_selected_file

		            if [[ $pedestal_disabled_selected_file == ls* ]]; then
		                eval "$pedestal_disabled_selected_file"
		            elif [[ $pedestal_disabled_selected_file == pwd* ]]; then
		                eval "$pedestal_disabled_selected_file"
		            else
		                break
		            fi
		        done
		else 
	            echo "Enter the number corresponding to pedestal disabled channel json file to use (enter 0 to manually enter path):"
	            count=1
	            for file in "${pedestal_disabled_files[@]}"; do
	                    echo "$count. $file"
	                    count=$((count+1))
	            done
	            read json_choice
	            if [ "$json_choice" -eq "0" ]; then
	                echo "Please enter path to disabled channel json to use:"
	                while true; do
	                    echo "(You can use ls and pwd commands here to look around)"
	                    read pedestal_disabled_selected_file

	                    if [[ $pedestal_disabled_selected_file == ls* ]]; then
	                        eval "$pedestal_disabled_selected_file"
	                    elif [[ $pedestal_disabled_selected_file == pwd* ]]; then
	                        eval "$pedestal_disabled_selected_file"
	                    else
	                        break
	                    fi
	                done
	            else
	                pedestal_disabled_selected_file="${pedestal_disabled_files[$json_choice-1]}"
	            fi
		fi

		shopt -s nullglob
		recursive_pedestal_files=( $recursive_pedestal_folder/*.h5 )
		shopt -u nullglob
		if [ ${#recursive_pedestal_files[@]} -eq 0 ]; then
            echo "No h5 files found in $recursive_pedestal_folder, please enter path to the recursive pedestal h5 file to use:"
            while true; do
                echo "(You can use ls and pwd commands here to look around)"
                read recursive_pedestal_selected_file

                if [[ $recursive_pedestal_selected_file == ls* ]]; then
                    eval "$recursive_pedestal_selected_file"
                elif [[ $recursive_pedestal_selected_file == pwd* ]]; then
                    eval "$recursive_pedestal_selected_file"
                else
                    break
                fi
            done
		else 
            echo "Enter the number corresponding to recursive pedestal h5 file to use (enter 0 to manually enter path):"
            count=1
            for file in "${recursive_pedestal_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
            done
            read h5_choice
            if [ "$h5_choice" -eq "0" ]; then
                echo "Please enter path to recursive pedestal h5 file to use:"
                while true; do
                    echo "(You can use ls and pwd commands here to look around)"
                    read recursive_pedestal_selected_file

                    if [[ $recursive_pedestal_selected_file == ls* ]]; then
                        eval "$recursive_pedestal_selected_file"
                    elif [[ $recursive_pedestal_selected_file == pwd* ]]; then
                        eval "$recursive_pedestal_selected_file"
                    else
                        break
                    fi
                done
            else
                recursive_pedestal_selected_file="${recursive_pedestal_files[$h5_choice-1]}"
            fi
		fi 
        echo "python3 threshold_qc.py --controller_config $hydra_network_selected_file --disabled_list $pedestal_disabled_selected_file --pedestal_file $recursive_pedestal_selected_file"
        python3 threshold_qc.py --controller_config $hydra_network_selected_file --disabled_list $pedestal_disabled_selected_file --pedestal_file $recursive_pedestal_selected_file
		mkdir -p $asics_configs/asics-configs_$descriptor
		mv *config*.json $asics_configs/asics-configs_$descriptor/
		echo "Asic config jsons moved to $asics_configs/asics-configs_$descriptor/" 
	elif [ "$number" == "8" ]; then
	    shopt -s nullglob
	    json_files=( $hydra_json_folder/*hydra*.json )
	    shopt -u nullglob
	    if [ -n "$hydra_network_file" ]; then
	        echo "Using hydra network file ${hydra_network_file}"
	        selected_file=$hydra_network_file
	    elif [ ${#json_files[@]} -eq 0 ]; then
	        echo "No .json files found in $hydra_json_folder, please enter path to hydra network file to use:"
	        while true; do
	            echo "(You can use ls and pwd commands here to look around)"
	            read selected_file
 
	            if [[ $selected_file == ls* ]]; then
	                eval "$selected_file"
	            elif [[ $selected_file == pwd* ]]; then
	                eval "$selected_file"
	            else
	                break
	            fi
	        done
	    else
	        echo "Enter the number corresponding to hydra network file to use (enter 0 to manually enter path):"
	        count=1
	        for file in "${json_files[@]}"; do
	                echo "$count. $file"
	                count=$((count+1))
	        done
	        read json_choice
	        if [ "$json_choice" -eq "0" ]; then
	            echo "Please enter path to hydra network file to use:"
	            while true; do
	                echo "(You can use ls and pwd commands here to look around)"
	                read selected_file

	                if [[ $selected_file == ls* ]]; then
	                    eval "$selected_file"
	                elif [[ $selected_file == pwd* ]]; then
	                    eval "$selected_file"
	                else
	                    break
	                fi
	            done
 
	        else
	            selected_file="${json_files[$json_choice-1]}"
	        fi
	    fi
	    asics_folders=( "$asics_configs"/*/ )
	    asics_folders=( "${asics_folders[@]%/}" ) # trim trailing slashes 
	    if [ ${#asics_folders[@]} -eq 0 ]; then
	        echo "No asics configs found in $asics_configs, please enter path asic folder to use:"
	        while true; do
	            echo "(You can use ls and pwd commands here to look around)"
	            read selected_folder
	            if [[ $selected_folder == ls* ]]; then
	                eval "$selected_folder"
	            elif [[ $selected_folder == pwd* ]]; then
	                eval "$selected_folder"
	            else
	                break
	            fi
	        done
	    else
	        echo "Enter the number corresponding to the asics config folder that you want to use (enter 0 to manually enter path):"
	        count=1
	        for file in "${asics_folders[@]}"; do
	                echo "$count. $file"
	                count=$((count+1))
	        done
	        read asics_choice
	        if [ "$asics_choice" -eq "0" ]; then
	            echo "Please enter path to asics configs folder to use:"
	            while true; do
	                echo "(You can use ls and pwd commands here to look around)"
	                read selected_folder

	                if [[ $selected_folder == ls* ]]; then
	                    eval "$selected_folder"
	                elif [[ $selected_folder == pwd* ]]; then
	                    eval "$selected_folder"
	                else
	                    break
	                fi
	            done
	        else
	            selected_folder="${asics_folders[$asics_choice-1]}"
	        fi
	    fi
	    echo "Enter runtime in seconds:"
	    read runtime
	    echo "python3 start_run_log_raw.py --controller_config $selected_file --config_name $selected_folder --runtime $runtime"
	    python3 start_run_log_raw.py --controller_config $selected_file --config_name $selected_folder --runtime $runtime
		echo "Convert raw file to packets hdf5 file now? (yes/no)"
		read convert_choice
			if [ "$convert_choice" == "yes" ]; then
			shopt -s nullglob
			raw_files=( *raw*.h5 )
			shopt -u nullglob
			        if [ ${#raw_files[@]} -eq 0 ]; then
				echo "No raw h5 files found in current directory, moving on."
			else
				echo "Enter the number corresponding to the raw hdf5 file you want to convert:"
			        	count=1
			        	for file in "${raw_files[@]}"; do
			            		echo "$count. $file"
			            		count=$((count+1))
			        	done
			        	read choice
				selected_file="${raw_files[$choice-1]}"
				file_no_extension=${selected_file%*.h5}
				timestamp=${file_no_extension#*raw_}
				converted_filename=datalog_${timestamp}.h5
				echo "Converting raw file $selected_file to HDF5 file $converted_filename..."
				echo "python3 ../larpix-control/scripts/convert_rawhdf5_to_hdf5.py -i $selected_file -o $converted_filename"
				python3 ../larpix-control/scripts/convert_rawhdf5_to_hdf5.py -i $selected_file -o $converted_data/$converted_filename
				mv $selected_file $raw_data/
				echo "Moved $selected_file to $raw_data/$selected_file"
				echo "Saved converted hdf5 file (if the conversion succeeded) to $converted_data/$converted_filename"
			fi
		else
			mv *raw*.h5 $raw_data/
		fi
    elif [ "$number" == "9" ]; then
		current_dir=$(pwd)
		cd $raw_data
		converter_dir=/home/herogers/SingleCube/larpix-control/scripts
		shopt -s nullglob
		raw_files=( *raw*.h5 )
		shopt -u nullglob
        if [ ${#raw_files[@]} -eq 0 ]; then
			echo "No raw h5 files found in $raw_data, please enter path to file to convert:"
			cd $current_dir
			while true; do
                		echo "(You can use ls, pwd, and cd commands here to look around. Must cd to directory containing file to convert)"
                		read selected_file
                		if [[ $selected_file == ls* ]]; then
                    			eval "$selected_file"
                		elif [[ $selected_file == pwd* ]]; then
                    			eval "$selected_file"
                		elif [[ $selected_file == cd* ]]; then
								eval "$selected_file"
						else
        					break
                		fi
            done
		else
			echo "Enter the number corresponding to the raw hdf5 file you want to convert (enter 0 to manually enter path):"
			count=1
			for file in "${raw_files[@]}"; do
				echo "$count. $file"
				count=$((count+1))
			done
			read h5_choice
			if [ "$h5_choice" -eq "0" ]; then
          			echo "Please enter path to raw hdf5 file to convert:"
            		while true; do
                			echo "(You can use ls, cd, and pwd commands here to look around. Must cd to directory containing file to convert)"
                			read selected_file
							cd $current_dir
                			if [[ $selected_file == ls* ]]; then
                    			eval "$selected_file"
                			elif [[ $selected_file == pwd* ]]; then
                    			eval "$selected_file"
							elif [[ $selected_file == cd* ]]; then
								eval "$selected_file"
	            			else
	                			break
	            			fi
                	done
 
    		else
        		selected_file="${raw_files[$h5_choice-1]}"
    		fi                

			file_no_extension=${selected_file%*.h5}
			timestamp=${file_no_extension#*raw_}
			converted_filename=datalog_${timestamp}.h5
			echo "Converting raw file $selected_file to HDF5 file $converted_filename..."
			echo "python3 $converter_dir/convert_rawhdf5_to_hdf5.py -i $selected_file -o $converted_data/$converted_filename"
			python3 $converter_dir/convert_rawhdf5_to_hdf5.py -i $selected_file -o $converted_data/$converted_filename
			#mv $selected_file $raw_data/
			#echo "Moved $selected_file to $raw_data/$selected_file"
			echo "Saved converted hdf5 file (if the conversion succeeded) to $converted_data/$converted_filename"
		fi
    elif [ "$number" == "10" ]; then
    	echo "Enter number corresponding to type of file to plot (enter 0 to specify path):"
    	echo "1 - Recursive pedestal data"
    	echo "2 - self-trigger data"
    	read plot_choice
    	if [ "$plot_choice" -eq "0" ]; then
              	echo "Please enter path to hdf5 file:"
                while true; do
                    	echo "(You can use ls and pwd commands here to look around.)"
                    	read selected_file
    			
                    	if [[ $selected_file == ls* ]]; then
                        	eval "$selected_file"
                    	elif [[ $selected_file == pwd* ]]; then
                        	eval "$selected_file"
                    	else
                     		break
                    	fi
                done
			 	echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric mean"
				python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric mean
				echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric std"
				python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric std
				echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric rate"
				python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric rate

				rm -f tile-id-3-1d-mean_std_rate.png
				rm -f tile-id-3-xy-mean_std_rate.png
				rm -f tile-id-3-1d-xy-mean_std_rate.png
				convert tile-id-3-1d-mean.png tile-id-3-1d-rate.png tile-id-3-1d-std.png +append tile-id-3-1d-mean_std_rate.png
				convert tile-id-3-1d-mean_std_rate.png -resize x525 tile-id-3-1d-mean_std_rate.png

				convert tile-id-3-xy-mean.png tile-id-3-xy-rate.png tile-id-3-xy-std.png +append tile-id-3-xy-mean_std_rate.png
				convert tile-id-3-xy-mean_std_rate.png -resize x500 tile-id-3-xy-mean_std_rate.png
				rm -f tile-id-3-1d-mean.png
				rm -f tile-id-3-1d-std.png
				rm -f tile-id-3-1d-rate.png
				rm -f tile-id-3-xy-mean.png
				rm -f tile-id-3-xy-std.png
				rm -f tile-id-3-xy-rate.png
				convert tile-id-3-1d-mean_std_rate.png tile-id-3-xy-mean_std_rate.png -append tile-id-3-1d-xy-mean_std_rate.png
				rm -f tile-id-3-1d-mean_std_rate.png
				rm -f tile-id-3-xy-mean_std_rate.png
				selected_filename=$(basename "$selected_file")
				file_no_extension=${selected_filename%*.h5}
				timestamp=${file_no_extension#*}
				mv tile-id-3-1d-xy-mean_std_rate.png $metric_plots/tile-id-3-1d-xy_mean_std_rate_${timestamp}.png
			        	
                                echo "Displaying plot, close plot window to continue."
				display $metric_plots/tile-id-3-1d-xy-mean_std_rate_${timestamp}.png
        elif [ "$plot_choice" -eq "1" ]; then
			shopt -s nullglob
			pedestal_files=( $recursive_pedestal_folder/*.h5 )
			shopt -u nullglob
			
			if [ ${#pedestal_files[@]} -eq 0 ]; then
		            	echo "No .h5 files found in $recursive_pedestal_folder, moving on."
		            	exit 1
		    fi
			count=1
		        
			echo "Enter the number corresponding to recursive pedestal file to convert: "
			for file in "${pedestal_files[@]}"; do
		    	echo "$count. $file"
		    	count=$((count+1))
			done
			read choice 
			selected_file="${pedestal_files[$choice-1]}"
			
			echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric mean"
			python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric mean
			echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric std"
			python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric std
			echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric rate"
			python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric rate
			
			rm -f tile-id-3-1d-mean_std_rate.png
			rm -f tile-id-3-xy-mean_std_rate.png
			rm -f tile-id-3-1d-xy-mean_std_rate.png
			convert tile-id-3-1d-mean.png tile-id-3-1d-rate.png tile-id-3-1d-std.png +append tile-id-3-1d-mean_std_rate.png
			convert tile-id-3-1d-mean_std_rate.png -resize x525 -geometry +500 tile-id-3-1d-mean_std_rate.png

			convert tile-id-3-xy-mean.png tile-id-3-xy-rate.png tile-id-3-xy-std.png +append tile-id-3-xy-mean_std_rate.png
			convert tile-id-3-xy-mean_std_rate.png -resize x500 tile-id-3-xy-mean_std_rate.png
			rm -f tile-id-3-1d-mean.png
			rm -f tile-id-3-1d-std.png
			rm -f tile-id-3-1d-rate.png
			rm -f tile-id-3-xy-mean.png
			rm -f tile-id-3-xy-std.png
			rm -f tile-id-3-xy-rate.png
			convert tile-id-3-1d-mean_std_rate.png tile-id-3-xy-mean_std_rate.png -append tile-id-3-1d-xy-mean_std_rate.png
			rm -f tile-id-3-1d-mean_std_rate.png
			rm -f tile-id-3-xy-mean_std_rate.png
			selected_filename=$(basename "$selected_file")
			file_no_extension=${selected_filename%*.h5}
			timestamp=${file_no_extension#*recursive-pedestal_}
			mv tile-id-3-1d-xy-mean_std_rate.png $metric_plots/tile-id-3-1d-xy-mean_std_rate_recursive-pedestal_${timestamp}.png
			echo "Displaying plot, close plot window to continue."
			display $metric_plots/tile-id-3-1d-xy-mean_std_rate_recursive-pedestal_${timestamp}.png	
		elif [ "$plot_choice" -eq "2" ]; then
			shopt -s nullglob
			datalog_files=( $converted_data/*.h5 )
			shopt -u nullglob
			
			if [ ${#datalog_files[@]} -eq 0 ]; then
		            	echo "No .h5 files found in $converted_data, moving on."
		            	exit 1
		    fi
			count=1
		        
        	echo "Enter the number corresponding to datalog/self-trigger file to use: "
        	for file in "${datalog_files[@]}"; do
            	echo "$count. $file"
            	count=$((count+1))
        	done
        	read choice 
			selected_file="${datalog_files[$choice-1]}"
			echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric mean"
			python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric mean
			echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric std"
			python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric std
			echo "python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric rate"
			python3 plot_metric.py --filename $selected_file --geometry_yaml layout-2.4.0.yaml --metric rate

			rm -f tile-id-3-1d-mean_std_rate.png
			rm -f tile-id-3-xy-mean_std_rate.png
			rm -f tile-id-3-1d-xy-mean_std_rate.png
			convert tile-id-3-1d-mean.png tile-id-3-1d-rate.png tile-id-3-1d-std.png +append tile-id-3-1d-mean_std_rate.png
			convert tile-id-3-1d-mean_std_rate.png -resize x525 tile-id-3-1d-mean_std_rate.png

			convert tile-id-3-xy-mean.png tile-id-3-xy-rate.png tile-id-3-xy-std.png +append tile-id-3-xy-mean_std_rate.png
			convert tile-id-3-xy-mean_std_rate.png -resize x500 tile-id-3-xy-mean_std_rate.png
			rm -f tile-id-3-1d-mean.png
			rm -f tile-id-3-1d-std.png
			rm -f tile-id-3-1d-rate.png
			rm -f tile-id-3-xy-mean.png
			rm -f tile-id-3-xy-std.png
			rm -f tile-id-3-xy-rate.png
			convert tile-id-3-1d-mean_std_rate.png tile-id-3-xy-mean_std_rate.png -append tile-id-3-1d-xy-mean_std_rate.png
			rm -f tile-id-3-1d-mean_std_rate.png
			rm -f tile-id-3-xy-mean_std_rate.png
			selected_filename=$(basename "$selected_file")
			file_no_extension=${selected_filename%*.h5}
			timestamp=${file_no_extension#*self-trigger_}
			#mv tile-id-3-1d-mean_std_rate.png $metric_plots/tile-id-3-1d-self-trigger_mean_std_rate_${timestamp}.png
			mv tile-id-3-1d-xy-mean_std_rate.png $metric_plots/tile-id-3-1d-self-trigger_mean_std_rate_${timestamp}.png
                        echo "Displaying plot, close plot window to continue."
			display $metric_plots/tile-id-3-1d-self-trigger_mean_std_rate_${timestamp}.png
		fi   
    elif [ "$number" == "11" ]; then
    	asics_folders=( "$asics_configs"/*/ )
        asics_folders=( "${asics_folders[@]%/}" ) # trim trailing slashes 
        if [ ${#asics_folders[@]} -eq 0 ]; then
            echo "No asics configs found in $asics_configs, please enter path asic folder to use:"
            while true; do
                echo "(You can use ls and pwd commands here to look around)"
                read selected_folder
                if [[ $selected_folder == ls* ]]; then
                    eval "$selected_folder"
                elif [[ $selected_folder == pwd* ]]; then
                    eval "$selected_folder"
                else
                    break
                fi
            done
        else
            echo "Enter the number corresponding to the asics config folder that you want to use (enter 0 to manually enter path):"
            count=1
            for file in "${asics_folders[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
            done
            read asics_choice
            if [ "$asics_choice" -eq "0" ]; then
                echo "Please enter path to asics configs folder to use:"
                while true; do
                    echo "(You can use ls and pwd commands here to look around)"
                    read selected_folder

                    if [[ $selected_folder == ls* ]]; then
                        eval "$selected_folder"
                    elif [[ $selected_folder == pwd* ]]; then
                        eval "$selected_folder"
                    else
                        break
                    fi
                done
            else
                selected_folder="${asics_folders[$asics_choice-1]}"
            fi
        fi

        # find the first json file in directory.
        first_json_file=$(find "$selected_folder" -type f -name "*.json" | head -n 1)
        # Check if a JSON file was found
        if [ -n "$first_json_file" ]; then
             echo "First JSON file in $json_directory: $first_json_file"
    
             # Use jq to extract values from the first JSON file
             vref_dac=$(jq -r '.register_values.vref_dac' "$first_json_file")
             vcm_dac=$(jq -r '.register_values.vcm_dac' "$first_json_file")
             
             # Print the extracted values
             echo "vref_dac: $vref_dac"
             echo "vcm_dac: $vcm_dac"
        else
             echo "No JSON files found in $json_directory"
        fi
        shopt -s nullglob
        json_files=( $hydra_json_folder/*hydra*.json )
        shopt -u nullglob
        if [ ${#json_files[@]} -eq 0 ]; then
            echo "No .json files found in $hydra_json_folder, please enter path to hydra network file to use:"
            while true; do
                echo "(You can use ls and pwd commands here to look around)"
                read selected_file

                if [[ $selected_file == ls* ]]; then
                    eval "$selected_file"
                elif [[ $selected_file == pwd* ]]; then
                    eval "$selected_file"
                else
                    break
                fi
            done
        else
            echo "Enter the number corresponding to hydra network file to use (enter 0 to manually enter path):"
            count=1
            for file in "${json_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
            done
            read json_choice
            if [ "$json_choice" -eq "0" ]; then
                echo "Please enter path to hydra network file to use:"
                while true; do
                    echo "(You can use ls and pwd commands here to look around)"
                    read selected_file
                    if [[ $selected_file == ls* ]]; then
                        eval "$selected_file"
                    elif [[ $selected_file == pwd* ]]; then
                        eval "$selected_file"
                    else
                        break
                    fi
                done
            else
                selected_file="${json_files[$json_choice-1]}"
            fi
        fi
        python3 ${larpix_v2_testing_scripts_dir}/gen_config_json.py --controller_config $selected_file --vref_dac $vref_dac --vcm_dac $vcm_dac
        mv evd_config*.json $evd_configs
        echo "Moved evd config file to the ${evd_configs} folder."
    elif [ "$number" == "12" ]; then
        mv -f asics-configs/* ${files_drive_dir}/asics-configs/
        mv -f hydra_network/* ${files_drive_dir}/hydra_network/
        mv -f pedestal_and_trigger_rate/* ${files_drive_dir}/pedestal_and_trigger_rate/
        mv -f pedestal_disabled_list_first/* ${files_drive_dir}/pedestal_disabled_list_first/
        mv -f pedestal_disabled_list_second/* ${files_drive_dir}/pedestal_disabled_list_second/
        mv -f plots/* ${files_drive_dir}/plots/
        mv -f power_up_jsons/* ${files_drive_dir}/power_up_jsons/
        mv -f recursive_pedestal/* ${files_drive_dir}/recursive_pedestal/
        mv -f trigger_rate_10kHz_cut/* ${files_drive_dir}/trigger_rate_10kHz_cut/
        mv -f trigger_rate_do_not_enable/* ${files_drive_dir}/trigger_rate_do_not_enable/
        mv -f trigger_rate_no_cut/* ${files_drive_dir}/trigger_rate_no_cut/
        echo "Moved files from folders to ${files_drive_dir}"
    elif [ "$number" == "13" ]; then
        echo "Enter the runtime of each run in seconds:"
        read runtime
        
        # pick hydra network file
        shopt -s nullglob
	    json_files=( $hydra_json_folder/*hydra*.json )
	    shopt -u nullglob
	    if [ -n "$hydra_network_file" ]; then
	        echo "Using hydra network file ${hydra_network_file}"
	        selected_file=$hydra_network_file
	    elif [ ${#json_files[@]} -eq 0 ]; then
	        echo "No .json files found in $hydra_json_folder, please enter path to hydra network file to use:"
	        while true; do
	            echo "(You can use ls and pwd commands here to look around)"
	            read selected_file
 
	            if [[ $selected_file == ls* ]]; then
	                eval "$selected_file"
	            elif [[ $selected_file == pwd* ]]; then
	                eval "$selected_file"
	            else
	                break
	            fi
	        done
	    else
	        echo "Enter the number corresponding to hydra network file to use (enter 0 to manually enter path):"
	        count=1
	        for file in "${json_files[@]}"; do
	                echo "$count. $file"
	                count=$((count+1))
	        done
	        read json_choice
	        if [ "$json_choice" -eq "0" ]; then
	            echo "Please enter path to hydra network file to use:"
	            while true; do
	                echo "(You can use ls and pwd commands here to look around)"
	                read selected_file

	                if [[ $selected_file == ls* ]]; then
	                    eval "$selected_file"
	                elif [[ $selected_file == pwd* ]]; then
	                    eval "$selected_file"
	                else
	                    break
	                fi
	            done
 
	        else
	            selected_file="${json_files[$json_choice-1]}"
	        fi
	    fi
        
        # pick asics-configs folder
        asics_folders=( "$asics_configs"/*/ )
	    asics_folders=( "${asics_folders[@]%/}" ) # trim trailing slashes 
	    if [ ${#asics_folders[@]} -eq 0 ]; then
	        echo "No asics configs found in $asics_configs, please enter path asic folder to use:"
	        while true; do
	            echo "(You can use ls and pwd commands here to look around)"
	            read selected_folder
	            if [[ $selected_folder == ls* ]]; then
	                eval "$selected_folder"
	            elif [[ $selected_folder == pwd* ]]; then
	                eval "$selected_folder"
	            else
	                break
	            fi
	        done
	    else
	        echo "Enter the number corresponding to the asics config folder that you want to use (enter 0 to manually enter path):"
	        count=1
	        for file in "${asics_folders[@]}"; do
	                echo "$count. $file"
	                count=$((count+1))
	        done
	        read asics_choice
	        if [ "$asics_choice" -eq "0" ]; then
	            echo "Please enter path to asics configs folder to use:"
	            while true; do
	                echo "(You can use ls and pwd commands here to look around)"
	                read selected_folder

	                if [[ $selected_folder == ls* ]]; then
	                    eval "$selected_folder"
	                elif [[ $selected_folder == pwd* ]]; then
	                    eval "$selected_folder"
	                else
	                    break
	                fi
	            done
	        else
	            selected_folder="${asics_folders[$asics_choice-1]}"
	        fi
	    fi
	    while true; do
	    	echo "Starting self-trigger run with runtime of $runtime seconds."
		    echo "python3 start_run_log_raw.py --controller_config $selected_file --config_name $selected_folder --runtime $runtime"
			python3 start_run_log_raw.py --controller_config $selected_file --config_name $selected_folder --runtime $runtime
			mv *raw*.h5 $raw_data/
			echo "Raw file moved to $raw_data"
			seconds_to_wait=10
			echo "Waiting $seconds_to_wait seconds until starting next run. If you want to cancel the script, do it now with ctrl-c."
			sleep $seconds_to_wait
		done
    elif [ "$number" == "14" ]; then
            # pick asics-configs folder
            asics_folders=( "$asics_configs"/*/ )
	    asics_folders=( "${asics_folders[@]%/}" ) # trim trailing slashes 
	    if [ ${#asics_folders[@]} -eq 0 ]; then
	        echo "No asics configs found in $asics_configs, please enter path asic folder to use:"
	        while true; do
	            echo "(You can use ls and pwd commands here to look around)"
	            read selected_folder
	            if [[ $selected_folder == ls* ]]; then
	                eval "$selected_folder"
	            elif [[ $selected_folder == pwd* ]]; then
	                eval "$selected_folder"
	            else
	                break
	            fi
	        done
	    else
	        echo "Enter the number corresponding to the asics config folder that you want to use (enter 0 to manually enter path):"
	        count=1
	        for file in "${asics_folders[@]}"; do
	                echo "$count. $file"
	                count=$((count+1))
	        done
	        read asics_choice
	        if [ "$asics_choice" -eq "0" ]; then
	            echo "Please enter path to asics configs folder to use:"
	            while true; do
	                echo "(You can use ls and pwd commands here to look around)"
	                read selected_folder

	                if [[ $selected_folder == ls* ]]; then
	                    eval "$selected_folder"
	                elif [[ $selected_folder == pwd* ]]; then
	                    eval "$selected_folder"
	                else
	                    break
	                fi
	            done
	        else
	            selected_folder="${asics_folders[$asics_choice-1]}"
	        fi
	    fi
        
        echo "Pick option you would like to use:"
        echo "1 - Change thresholds for all chips"
        echo "2 - Change threshold for a single chip"
        echo "3 - Change threshold for a single channel"
        echo "4 - Disable or enable a channel"
        read threshold_option

        if [ "$threshold_option" -eq "1" ]; then
            echo "Enter value to raise or lower global threshold by (e.g. -1 to lower by 1, 1 to raise by 1)"
            read global_threshold_shift
            python3 increment_global.py ${selected_folder}/* --inc $global_threshold_shift
        elif [ "$threshold_option" -eq "2" ]; then
            while true; do
                echo "Enter chip id:"
                read chip_id
                echo "Enter value to raise or lower global threshold by (e.g. -1 to lower by 1, 1 to raise by 1)"
                read global_threshold_shift
                pattern="[0-9]*-[0-9]*-${chip_id}"
                asic_file=$(find ${selected_folder} -type f -regex ".*$pattern.*\.json")
                current_threshold_global=$(jq -r '.register_values.threshold_global' "$asic_file")
                new_global_threshold=$((current_threshold_global + global_threshold_shift))
                python3 increment_global.py $asic_file --inc $global_threshold_shift
                #jq --arg new_global_threshold "$new_global_threshold" '.register_values.threshold_global = $new_global_threshold' "$asic_file" > tmp.json && mv tmp.json "$asic_file"
                echo "Changed global threshold for chip ID ${chip_id} from ${current_threshold_global} to ${new_global_threshold} at ${selected_folder}"
                echo "Change another chip? (y/n)"
                read change_another_chip
                if [ $change_another_chip == "n" ]; then
                    break
                fi
            done
        fi
    elif [ "$number" == "15" ]; then
		shopt -s nullglob
		raw_files=( $raw_data/*.h5 )
		shopt -u nullglob
			
		if [ ${#raw_files[@]} -eq 0 ]; then
	            	echo "No .h5 files found in $raw_data, moving on."
	            	exit 1
		fi
		count=1
		        
        	echo "Enter the number corresponding to raw data file to use for plotting:"
        	for file in "${raw_files[@]}"; do
            		echo "$count. $file"
            		count=$((count+1))
        	done
        	read choice 
		selected_file="${raw_files[$choice-1]}"
    
        	python3 $larpix_monitor_dir/run_monitor.py --once $selected_file
        	echo "Plots can be found in $larpix_monitor_dir/plots"
    elif [ "$number" == "16" ]; then
                 shopt -s nullglob
                 converted_files=( $converted_data/*.h5 )
                 shopt -u nullglob
 
                 if [ ${#converted_files[@]} -eq 0 ]; then
                         echo "No .h5 files found in $converted_data, moving on."
                         exit 1
                 fi
                 count=1
 
                 echo "Enter the number corresponding to packet file to use:"
                 for file in "${converted_files[@]}"; do
                         echo "$count. $file"
                         count=$((count+1))
                 done
                 read choice
                 selected_file="${converted_files[$choice-1]}"
                 selected_filename=$(basename "${selected_file}" .h5)
                 home_dir=$(pwd)
                 cd ${clustering_code_dir}
                 python3 charge_clustering.py SingleCube ${selected_file} ${cluster_data}/${selected_filename}_clusters.h5 --save_hits=True
                 cd ${home_dir}
    else
        echo "Invalid choice."
    fi
    

done
