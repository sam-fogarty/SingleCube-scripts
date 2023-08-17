#!/bin/bash

# check power parameters
io_group=1
pacman_tile=1
tile_id=3
geometry_yaml=layout-2.4.0.yaml

hydra_json_folder=hydra_network_jsons
mkdir -p $hydra_json_folder
hydra_plot_folder=hydra_network_images
mkdir -p $hydra_plot_folder

echo " "
echo "This is a helper script for running the LArPix data-taking scripts with a LArTPC. Before running any of these scripts, make sure the TPC is connected to the PACMAN, everything is powered up, and the current draw looks reasonable."
echo " "

while true; do
    echo "Enter the number of which script you would like to run (q to quit): "
    echo "1 - check_power.py (check current draws)"
    echo "2 - map_uart_links_qc.py (make hydra network)"
    echo "3 - plot_hydra_network_v2a.py (make hydra network plot)"
    #echo "4 - multi_trigger_rate_qc.py (make trigger rate disabled channel list)"
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
            json_files=( *.json )
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
        echo "Select a hydra network configuration to use for making plot:"
        json_files=( $hydra_json_folder/*.json )
        count=1
        for file in "${json_files[@]}"; do
                echo "$count. $file"
                count=$((count+1))
        done
        read hydra_network_file
        echo " "
        echo "python3 plot_hydra_network_v2a.py --controller_config $hydra_network_file --geometry_yaml $geometry_yaml --io_group $io_group"
        python3 plot_hydra_network_v2a.py --controller_config $hydra_network_file --geometry_yaml $geometry_yaml --io_group $io_group
        echo "Script finished, check output."
        echo " "
        echo "Enter the number corresponding to hydra network plot for renaming: "
        png_files=( *.png )
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

    else
        echo "Invalid choice. Please enter 1, 2, 3, or 'q' to quit."
    fi
done
