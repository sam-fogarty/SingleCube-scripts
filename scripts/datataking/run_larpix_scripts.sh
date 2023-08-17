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

echo " "
echo "This is a helper script for running the LArPix data-taking scripts with a LArTPC. Before running any of these scripts, make sure the TPC is connected to the PACMAN, everything is powered up, and the current draw looks reasonable."
echo " "

while true; do
    echo "Enter the number of which script you would like to run (q to quit): "
    echo "1 - check_power.py (check current draws)"
    echo "2 - map_uart_links_qc.py (make hydra network)"
    echo "3 - plot_hydra_network_v2a.py (make hydra network plot)"
    echo "4 - multi_trigger_rate_qc.py (make trigger rate disabled channel list)"
    echo "5 - pedestal_qc.py (make pedestal disabled channel list)"
    echo "6 - self-trigger run"
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
            json_files=( *hydra*.json )
            # check if there are any .json files in the directory
            if [ ${#json_files[@]} -eq 0 ]; then
                echo "No .json files found in the current directory, moving on."
                exit 1
            fi
            
            # display the hydra network files in the current directory
            count=1
            echo " "
            echo "Enter the number corresponding to hydra network file to rename: "
            for file in "${json_files[@]}"; do
                echo "$count. $file"
                count=$((count+1))
            done
            read choice   
            if [ "$choice" -ge 1 ] && [ "$choice" -le ${#json_files[@]} ]; then
                selected_file="${json_files[$choice-1]}"
                echo "You selected: $selected_file"

                # Prompt the user for a file descriptor
                echo "Please enter a file descriptor (no spaces):"
                read descriptor

                # Construct the new filename
                base_name=$(basename "$selected_file" .json)
                new_file="${base_name}_${descriptor}.json"

                # Rename the file
                mv "$selected_file" "$hydra_json_folder/$new_file"
                echo "File has been moved to: $hydra_json_folder/$new_file"
            fi
            echo " "
        fi

    elif [ "$number" == "3" ]; then
        shopt -s nullglob
        json_files=( $hydra_json_folder/*hydra*.json )
        shopt -u nullglob
        if [ ${#json_files[@]} -eq 0 ]; then
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
        echo "Script finished, check output."
        echo " "
        echo "To retry, enter 1 and repick plot_hydra_network_v2a.py. Otherwise enter 2 to continue."
        read choice
        if [ "$choice" -eq "2" ]; then
            echo "Enter the number corresponding to hydra network plot for renaming: "
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
                echo "Enter file descriptor (no spaces):"
                read descriptor
                selected_file="${png_files[$choice-1]}"
                base_name=$(basename "$selected_file" .png)
                new_file="${base_name}_${descriptor}.png"
                mv "$selected_file" "$hydra_plot_folder/$new_file"
                echo "File has been moved to: $hydra_plot_folder/$new_file"
		echo "Displaying plot. Close plot window to continue."
		display $hydra_plot_folder/$new_file
            fi
        fi
    elif [ "$number" == "4" ]; then
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
                echo "Enter file descriptor (no spaces):"
                read descriptor
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
        echo "python3 pedestal_qc.py --controller_config $selected_file --disabled_list $selected_do_not_enable_list"
        #python3 pedestal_qc.py --controller_config $selected_file --disabled_list $selected_do_not_enable_list
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
                echo "Enter the number corresponding to the recursive pedestal file you want to rename:"
                count=1
                for file in "${pedestal_second_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
                done
                read choice
                echo "Enter file descriptor (no spaces):"
                read descriptor
                selected_file="${pedestal_second_files[$choice-1]}"
                base_name=$(basename "$selected_file" .json)
                new_file="${base_name}_${descriptor}.json"
                mv "$selected_file" "$pedestal_second_folder/$new_file"
                mv *first*.h5 $pedestal_first_folder/
                echo "File has been moved to: $pedestal_second_folder/$new_file"
                echo " "
            fi
            if [ ${#recursive_pedestal_files[@]} -eq 0 ]; then
                echo "No recursive pedestal files found in current directory, moving on."
                echo " "
            else
                echo "Enter the number corresponding to the pedestal disabled file you want to rename:"
                count=1
                for file in "${recursive_pedestal_files[@]}"; do
                    echo "$count. $file"
                    count=$((count+1))
                done
                read choice
                echo "Enter file descriptor (no spaces):"
                read descriptor
                selected_file="${recursive_pedestal_files[$choice-1]}"
                base_name=$(basename "$selected_file" .json)
                new_file="${base_name}_${descriptor}.json"
                mv "$selected_file" "$recursive_pedestal_folder/$new_file"
                echo "File has been moved to: $recursive_pedestal_folder/$new_file"
                echo " "
            fi
        fi
    elif [ "$number" == "6" ]; then
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
    else
        echo "Invalid choice. Please enter 1, 2, 3, 4, or 'q' to quit."
    fi
done
