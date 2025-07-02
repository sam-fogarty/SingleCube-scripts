from numpy import fromfile, dtype, float32, uint16, uint32, uint64
import numpy as np
import os
import re
import glob

def get_channel_data(directory_path, channel, max_events=None):
    """
    Gets waveform data for a specific channel.
    
    Returns:
        tuple: (peak_values, waveforms, sampling_period)
            - peak_values: array of peak values from each waveform
            - waveforms: array of full waveform traces
            - sampling_period: sampling period in seconds
    """
    # Look for both .bin and .txt files
    binary_files = glob.glob(os.path.join(directory_path, "*.bin"))
    ascii_files = glob.glob(os.path.join(directory_path, "*.txt"))
    data_files = binary_files + ascii_files

    peak_values = []  # Store peak value from each waveform
    waveforms = []    # Store waveform traces
    sampling_period = None

    for file_path in data_files:
        events = read_waveforms(file_path, max_events)
        # Limit number of events if max_events is specified
        if max_events is not None and max_events > 0:
            events = events[:max_events]

        for event in events:
            sampling_period = event['sampling_period']
            for waveform in event['waveforms']:
                if waveform['channel'] == channel:
                    trace = waveform['trace']

                    # Find peak value (maximum absolute deviation from zero)
                    peak = np.max(np.abs(trace))
                    peak_values.append(peak)
                    waveforms.append(trace)

    # Print diagnostic information
    print(f"Channel {channel}: Found {len(waveforms)} waveforms")
    if len(waveforms) > 0:
        print(f"  Sample waveform length: {len(waveforms[0])}")
        if sampling_period:
            time_window = len(waveforms[0]) * sampling_period * 1e9  # convert to ns
            print(f"  Time window analyzed: {time_window:.2f} ns")

    if len(waveforms) > 0:
        min_length = min(len(w) for w in waveforms)
        waveforms = [w[:min_length] for w in waveforms]

    return np.array(peak_values), np.array(waveforms), sampling_period

def read_waveforms(file_path, max_events=None):
    """Determines file type and reads waveforms accordingly"""
    file_ext = os.path.splitext(file_path)[1].lower()

    if file_ext == '.bin':
        return read_binary_waveforms(file_path, max_events if max_events else 3000)
    elif file_ext == '.txt':
        return read_ascii_waveforms(file_path, max_events if max_events else 3000)
    else:
        print(f"Warning: Unsupported file extension {file_ext}. Trying binary format.")
        return read_binary_waveforms(file_path, max_events if max_events else 3000)

def read_binary_waveforms(filepath, max_events=3000):
    """
    Reads a binary file containing waveform data and organizes it into a nested list.

    Parameters:
        filepath (str): Path to the binary file.
        max_events (int): Maximum number of events to read from the file.

    Returns:
        list: List of event dictionaries containing:
            - event_number: Event identifier
            - timestamp: Event timestamp
            - sampling_period: Sampling period
            - waveforms: List of waveform traces per channel
    """
    dt = dtype(float32)
    events = []

    with open(filepath, 'rb') as file:
        for _ in range(max_events):
            # Read header for event
            event_number = fromfile(file, dtype=uint32, count=1)
            if len(event_number) == 0:
                break  # End of file reached

            event = {
                'event_number': event_number[0],
                'timestamp': fromfile(file, dtype=uint64, count=1)[0],
                'num_samples': fromfile(file, dtype=uint32, count=1)[0],
                'sampling_period': fromfile(file, dtype=uint64, count=1)[0],
                'waveforms': []
            }

            channels = fromfile(file, dtype=uint32, count=1)[0]

            for _ in range(channels):
                channel = fromfile(file, dtype=uint16, count=1)[0]
                trace = fromfile(file, dtype=dt, count=event['num_samples'])
                event['waveforms'].append({
                    'channel': channel,
                    'trace': trace
                })

            events.append(event)

    return events

def read_ascii_waveforms(filepath, max_events=3000):
    """
    Reads an ASCII file containing waveform data and organizes it into a nested list.
    
    Parameters:
        filepath (str): Path to the ASCII file.
        max_events (int): Maximum number of events to read from the file.
        
    Returns:
        list: List of event dictionaries containing:
            - event_number: Event identifier
            - timestamp: Event timestamp
            - num_samples: Number of samples per channel
            - sampling_period: Sampling period in seconds
            - waveforms: List of waveform traces per channel
    """
    events = []
    event_count = 0

    try:
        with open(filepath, 'r') as file:
            lines = file.readlines()

            line_index = 0
            while line_index < len(lines) and event_count < max_events:
                line = lines[line_index].strip()

                # Look for event header like "Event n. 0"
                event_match = re.match(r"Event\s+n\.\s+(\d+)", line)
                if not event_match:
                    line_index += 1
                    continue

                event_number = int(event_match.group(1))

                # Initialize event dict
                event = {
                    'event_number': event_number,
                    'timestamp': 0,
                    'num_samples': 0,
                    'sampling_period': 0,
                    'waveforms': []
                }

                # Parse timestamp - *should* be on the next line
                line_index += 1
                if line_index >= len(lines):
                    break

                timestamp_line = lines[line_index].strip()
                timestamp_match = re.match(r"TimeStamp:\s+(\d+)", timestamp_line)
                if timestamp_match:
                    event['timestamp'] = int(timestamp_match.group(1))



                # Parse samples
                line_index += 1
                if line_index >= len(lines):
                    break

                samples_line = lines[line_index].strip()
                samples_match = re.match(r"Samples:\s+(\d+)", samples_line)
                if samples_match:
                    event['num_samples'] = int(samples_match.group(1))



                # Parse sampling period
                line_index += 1
                if line_index >= len(lines):
                    break

                sampling_line = lines[line_index].strip()
                sampling_match = re.match(r"1\s+Sample\s+=\s+(\d+\.?\d*)\s*(\w+)?", sampling_line)
                if sampling_match:
                    value = float(sampling_match.group(1))
                    unit = sampling_match.group(2) if sampling_match.group(2) else ""

                    # Convert to seconds based on unit
                    if unit.lower() in ['ns']:
                        event['sampling_period'] = value * 1e-9
                    elif unit.lower() in ['us', 'μs']:
                        event['sampling_period'] = value * 1e-6
                    elif unit.lower() in ['ms']:
                        event['sampling_period'] = value * 1e-3
                    else:
                        # Assume seconds if no unit is specified
                        event['sampling_period'] = value

                # Look for channel header on the next line
                line_index += 1
                if line_index >= len(lines):
                    break

                channel_header = lines[line_index].strip().split('\t')
                channel_ids = []

                for ch_item in channel_header[1:]:  # Skip the first column header
                    ch_match = re.match(r"CH:\s*(\d+)", ch_item)
                    if ch_match:
                        channel_ids.append(int(ch_match.group(1)))

                if not channel_ids:

                    line_index += 1
                    continue

                # Initialize traces for each channel
                traces = {ch_id: [] for ch_id in channel_ids}

                # Read samples
                line_index += 1
                sample_count = 0
                while line_index < len(lines) and sample_count < event['num_samples']:
                    sample_line = lines[line_index].strip()

                    # Empty line or new event header indicates end of this event
                    if not sample_line or sample_line.startswith("Event"):
                        break

                    columns = sample_line.split('\t')
                    if len(columns) < len(channel_ids) + 1:
                        line_index += 1
                        continue

                    try:
                        sample_number = int(columns[0])

                        # Add values to each channel's trace
                        for ch_idx, ch_id in enumerate(channel_ids):
                            col_idx = ch_idx + 1
                            if col_idx < len(columns) and columns[col_idx]:
                                try:
                                    traces[ch_id].append(float(columns[col_idx]))
                                except ValueError:

                                    pass

                        sample_count += 1
                    except ValueError:
                        # Line doesn't start with a number, probably not a sample line
                        pass

                    line_index += 1

                # Add waveforms to the event
                for ch_id, trace in traces.items():
                    if trace:  # Only add channels with actual data
                        event['waveforms'].append({
                            'channel': ch_id,
                            'trace': np.array(trace, dtype=np.float32)
                        })

                if event['waveforms']:
                    events.append(event)
                    event_count += 1
        return events

    except Exception as e:
        print(f"Error reading ASCII file {filepath}: {e}")
        return []
