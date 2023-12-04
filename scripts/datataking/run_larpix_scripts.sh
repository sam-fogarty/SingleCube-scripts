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
raw_data=/mount/sda1/SingleCube_092023/warm_fullTPC_noShielding/raw_data
converted_data=/mount/sda1/SingleCube_092023/warm_fullTPC_noShielding/converted_data
metric_plots=plots
mkdir -p $metric_plots

echo " "
echo "This is a helper script for running the LArPix data-taking scripts with a LArTPC. Before running any of these scripts, make sure the TPC is connected to the PACMAN, everything is powered up, and the current draw looks reasonable."
echo " "

echo "Enter a file descriptor to add to the files (no spaces)":
read descriptor

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
    echo "10 - plot_metric.py (plot mean, standard deviation, rate per channel)"
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
	mv power-up*.json $power_up_jsons/

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
                #echo "Please enter a file descriptor (no spaces):"
                #read descriptor

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
                #echo "Enter file descriptor (no spaces):"
                #read descriptor
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
        python3 pedestal_qc.py --controller_config $selected_file --disabled_list $selected_do_not_enable_list
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
                    new_file="${base_name}_trigger-rate_and_pedestal_${descriptor}.png"
                    mv "$selected_file" "$disabled_channel_plots/$new_file"
                    echo "File has been moved to: $disabled_channel_plots/$new_file"
                    echo "Displaying plot. Close plot window to continue."
                    display $disabled_channel_plots/$new_file
                fi
            fi   
                   
        fi
    elif [ "$number" == "7" ]; then
        shopt -s nullglob
        json_files=( $hydra_json_folder/*hydra*.json )
        shopt -u nullglob
        if [ ${#json_files[@]} -eq 0 ]; then
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
        
        #echo "Enter a folder descriptor for asics-configs (folder will be named asics-configs_<file descriptor>): "
	#read asics_descriptor
	mkdir -p $asics_configs/asics-configs_$asics_descriptor
	mv *config*.json $asics_configs/asics-configs_$asics_descriptor/
	echo "Asic config jsons moved to $asics_configs/asics-configs_$asics_descriptor/" 
    elif [ "$number" == "8" ]; then
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
            
            	echo "Enter the number corresponding to datalog/self-trigger file to convert: "
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
		mv tile-id-3-1d-mean_std_rate.png $metric_plots/tile-id-3-1d-self-trigger_mean_std_rate_${timestamp}.png
		echo "Displaying plot, close plot window to continue."
		display $metric_plots/tile-id-3-1d-self-trigger_mean_std_rate_${timestamp}.png
        fi   

    else
        echo "Invalid choice. Please enter 1, 2, 3, 4, 5, 6, 7, 8,  or 'q' to quit."
    fi
done
