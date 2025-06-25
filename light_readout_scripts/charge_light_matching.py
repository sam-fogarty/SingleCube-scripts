#
#
#

import sys
import numpy as np
import matplotlib.pyplot as plt

# Some events (esp in light) are very fast (<1 ms) compared to actual cosmic rate (~10s of Hz). Likely multitriggers from the same event.
# Filter the subsequent events from associated lists to not throw of matching algorithm.
def filter_timestamps(timestamps):
    filtered = []
    prev_timestamp = None
    
    for time, line_num in timestamps:
        if prev_timestamp is None or (time - prev_timestamp) >= 0.001:
            filtered.append((time, line_num))
            prev_timestamp = time
    
    return filtered

# Read CSV files, Dan has charge files matt has light files
def extract_timestamps(filename):
    timestamps = []
    with open(filename, 'r') as f:
        for line_num, line in enumerate(f, 1):
            try:
                # Split on comma and take the relative time
                relative_time = float(line.strip().split(',')[1])
                timestamps.append((relative_time, line_num))
            except ValueError:
                continue
    return timestamps

# Core function, compares dT patterns between consecutive events. 
def find_matches(file1_times, file2_times):
    if len(file1_times) > len(file2_times):
        file1_times, file2_times = file2_times, file1_times
    
    times1 = np.array([t[0] for t in file1_times])
    times2 = np.array([t[0] for t in file2_times])
    
    dt1 = np.diff(times1)
    dt2 = np.diff(times2)
    
    tolerance = 0.1 # tolerance (s) - max difference between time intervals to be considered the 'same' event
    best_matches = []
    min_sequence_length = 10  # min sequence size to be considered.
    
    
    for start_pair in range(len(dt1)):
        for j in range(len(dt2)):
            current_matches = []
            if abs(dt1[start_pair] - dt2[j]) < tolerance:
                # start matching
                current_matches.append((file1_times[start_pair][1], file2_times[j][1]))
                current_matches.append((file1_times[start_pair+1][1], file2_times[j+1][1]))
                
                # build sequence
                for i in range(start_pair+1, len(dt1)):
                    if j+(i-start_pair) >= len(dt2):
                        break
                    if abs(dt1[i] - dt2[j+(i-start_pair)]) < tolerance:
                        current_matches.append((file1_times[i+1][1], file2_times[j+(i-start_pair)+1][1]))
                    else:
                        break
                
                if len(current_matches) > len(best_matches):
                    best_matches = current_matches
                    
                    # 
                    if len(best_matches) >= min_sequence_length:
                        return best_matches
    
    return best_matches

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python charge_light_match.py file1.txt file2.txt")
        sys.exit(1)
    
    # Load input files, order doesn't matter.
    file1 = sys.argv[1]
    file2 = sys.argv[2]
    
    # Extract and filter timestamps
    file1_times = filter_timestamps(extract_timestamps(file1))
    file2_times = filter_timestamps(extract_timestamps(file2))
    
    # Find Matches
    matches = find_matches(file1_times, file2_times)
    total_possible = min(len(file1_times), len(file2_times))
    
    print(f"Matches: {len(matches)}/{total_possible}")
    # Create matched file
    with open('matches.txt', 'w') as f:
        for match in matches:
            # Find the corresponding timestamps using the line numbers from matches
            charge_line = match[0]
            light_line = match[1]
        
            # Find the timestamps that correspond to these line numbers
            charge_time = next(t[0] for t in file1_times if t[1] == charge_line)
            light_time = next(t[0] for t in file2_times if t[1] == light_line)
        
            # Convert index from 0 for output x_x
            charge_event = charge_line - 1
            light_event = light_line - 1
        
            f.write(f"Charge: {charge_event}, {charge_time:.6f} / Light: {light_event}, {light_time:.6f}\n")
    # Create (dT1 - dT2) plots
    dt_diffs = []
    for i in range(len(matches)-1):
        # Get line numbers from matches
        curr_charge_line = matches[i][0]
        next_charge_line = matches[i+1][0]
        curr_light_line = matches[i][1]
        next_light_line = matches[i+1][1]
        
        # Find corresponding timestamps
        dt1 = next(t[0] for t in file1_times if t[1] == next_charge_line) - next(t[0] for t in file1_times if t[1] == curr_charge_line)
        dt2 = next(t[0] for t in file2_times if t[1] == next_light_line) - next(t[0] for t in file2_times if t[1] == curr_light_line)
        
        dt_diffs.append(dt1 - dt2)
    
    # Create the plot    plt.figure(figsize=(10, 6))
    plt.plot(range(len(dt_diffs)), dt_diffs, 'b-')
    plt.xlabel('Event Number in Sequence')
    plt.ylabel('dT1 - dT2 (seconds)')
    plt.title('Time Difference Comparison')
    plt.grid(True)
    plt.savefig('dt_comparison.png')
    plt.close()
