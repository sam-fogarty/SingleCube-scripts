from funcs import read_binary_waveforms
import os
from datetime import datetime
import glob
import sys

# Takes a directory of binary files as input
# Sifts through, gathers timing information
# Returns a list of tuples (datetime, relative_time) in a txt file
# Output used in charge_light_match.py with analagous file from charge data. 

def calculate_times(directory_path):
    binary_files = sorted(glob.glob(os.path.join(directory_path, "*.bin")))
    all_events = []
    
    # Get reference timestamp from first file
    # Light data has a reference timestamp, then each event has a timestamp relative to this reference.
    first_file = binary_files[0]
    filename = os.path.basename(first_file)
    datetime_part = filename.split('.bin')[0].split('-')[1]
    datetime_str = datetime_part.split('_')[1]
    reference_datetime = datetime.strptime(datetime_str, '%Y%m%d%H%M%S')
    reference_timestamp = reference_datetime.timestamp() * 1e9

    for file_path in binary_files:
        events = read_binary_waveforms(file_path)
        
        for event in events:
            absolute_time = reference_timestamp + (event['timestamp'] * 8)
            relative_time = event['timestamp'] * 8e-9 # CAEN uses 125MHz clock (8ns ticks), convert to seconds
            dt_object = datetime.fromtimestamp(absolute_time / 1e9)
            all_events.append((dt_object, relative_time))

    all_events.sort(key=lambda x: x[0])
    return all_events

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 dT.py directory_path")
        sys.exit(1)

    directory = sys.argv[1]
    times = calculate_times(directory)

    # Write to text file
    with open('trigger_test_light_timestamps.txt', 'w') as f:
        for dt_object, relative_time in times:
            formatted_time = dt_object.strftime('%Y-%m-%d %H:%M:%S')
            f.write(f"{formatted_time}, {relative_time}\n")

    print("Data written to trigger_test_light_timestamps.txt")
