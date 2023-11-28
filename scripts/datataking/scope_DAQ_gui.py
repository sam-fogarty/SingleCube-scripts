import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import pyvisa
import time
import os
import pandas as pd
import matplotlib.patches as patches

# Global variables
scope = None
xvalues, yvalues_ch1, yvalues_ch2 = None, None, None
save_folder = ""
data_filepath = ""
t_1, t_2, t_3, Vpeak_c, Vpeak_a, QA_over_QC, electron_lifetime = 0, 0, 0, 0, 0, 0, 0
falling_edge_ch1, rising_edge_ch2, min_y_time_ch1, max_y_time_ch2, y_max = 0, 0, 0, 0, 0
fig = None

# Function to connect to oscilloscope
def connect_to_scope():
    try:
        rm = pyvisa.ResourceManager()
        resources = rm.list_resources()
        if len(resources) == 0:
            return None, "Connection failed: No resources found"
        scope = rm.open_resource(resources[0])
        scope.timeout = 20000  # Timeout in milliseconds
        return scope, "Connection succeeded"
    except Exception as e:
        return None, f"Connection failed: {e}"

# Function to save the plot as a PDF using the waveform data file name
def save_plot_as_pdf():
    global save_folder
    if not save_folder:
        messagebox.showerror("Error", "Save folder not selected")
        return
    if not 'data_filepath' in globals():
        messagebox.showerror("Error", "No filename available for saving plot")
        return

    pdf_filename = os.path.splitext(data_filepath)[0] + '.pdf'
    pdf_path = os.path.join(save_folder, pdf_filename)

    # Save the plot as a PDF
    fig.savefig(pdf_path)
    messagebox.showinfo("Success", f"Plot saved as {pdf_filename}")

# Function to handle the 'Take Multiple Samples' acquisition mode
def take_multiple_samples(scope, num_samples):
    global save_folder
    if not save_folder:
        messagebox.showerror("Error", "Save folder not selected")
        return

    timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
    data_type = data_type_var.get()
    cathode_voltage = cathode_voltage_var.get()
    anode_voltage = anode_voltage_var.get()
    descriptor = descriptor_entry.get().replace(" ", "_")
    note = note_entry.get() + f'. Number of Traces: {num_samples}'
    acq_type = "MultipleSamples"
    samples_folder = f"{data_type}_{cathode_voltage}Vc_{anode_voltage}Va_{descriptor}_{acq_type}_{timestamp}"
    samples_folder_path = os.path.join(save_folder, samples_folder)
    os.makedirs(samples_folder_path, exist_ok=True)

    for i in range(num_samples):
        prompt_scope_for_acquisition(scope, 'SAMPLE', 1)
        time.sleep(0.3)
        xvalues, yvalues_ch1, yvalues_ch2 = acquire_waveform(scope, 'SAMPLE', 1)

        xvalues = np.round(xvalues * 1e6, 5)  # Convert to microseconds and round
        yvalues_ch1 = np.round(yvalues_ch1 * 1e3, 5)  # Convert to millivolts and round
        yvalues_ch2 = np.round(yvalues_ch2 * 1e3, 5)  # Convert to millivolts and round

        sample_filename = f"{data_type}_{cathode_voltage}Vc_{anode_voltage}Va_{descriptor}_{i+1}_{timestamp}.txt"
        sample_filepath = os.path.join(samples_folder_path, sample_filename)
        with open(sample_filepath, 'w', encoding='utf-8') as file:
            file.write("Time (μs),Cathode Voltage (mV),Anode Voltage (mV)\n")
            for t, c, a in zip(xvalues, yvalues_ch1, yvalues_ch2):
                file.write(f"{t},{c},{a}\n")

    # Add an entry to runlist.txt
    runlist_file_path = os.path.join(save_folder, "runlist.txt")
    with open(runlist_file_path, 'a') as runlist_file:
        runlist_entry = f"{samples_folder},{data_type},{cathode_voltage}V,{anode_voltage}V,{descriptor}, {note}\n"
        runlist_file.write(runlist_entry)

    messagebox.showinfo("Success", f"All waveforms saved in {samples_folder_path}")

def choose_data_file():
    global xvalues, yvalues_ch1, yvalues_ch2, data_filepath
    data_filepath = filedialog.askopenfilename(filetypes=[("Text files", "*.txt")])
    if data_filepath:
        # Read the data from the file
        data = pd.read_csv(data_filepath, skiprows=9, header=None)
        xvalues = data[0].values*1e-6
        yvalues_ch1 = data[1].values*1e-3
        yvalues_ch2 = data[2].values*1e-3
        update_plot(xvalues, yvalues_ch1, yvalues_ch2)

def prompt_scope_for_acquisition(scope, mode, num_samples):
    try:
        print(f"Setting acquisition mode to {mode}, number of samples to {num_samples}")
        if mode == 'SAMPLE':
            scope.write('ACQ:MOD SAMPLE')
        elif mode == 'AVERAGE':
            scope.write('ACQ:MOD AVERAGE')
            scope.write(f'ACQ:NUMAV {num_samples}')
        else:
            raise Exception("Invalid acquisition mode")
        scope.write('ACQ:STOPA SEQUENCE')
        scope.write('ACQ:STATE ON')
    except Exception as e:
        print(f"Error prompting scope for acquisition: {e}")

# Function to acquire data from oscilloscope
def acquire_waveform(scope, mode, num_samples):
    try:
        # Set up for fetching waveform data
        scope.write("HEADER 0")
        scope.write("DAT:ENC SRI")
        scope.write("DAT:WIDTH 1")
        scope.write("DAT:START 1")
        scope.write("DAT:STOP 1e10")
        recordLength = int(scope.query("WFMO:NR_P?"))
        scope.write(f"DAT:STOP {recordLength}")

        def fetch_waveform(channel, first=True):
            scope.write(f"DATA:SOUR {channel}")

            ymult = float(scope.query("WFMO:YMULT?"))
            yzero = float(scope.query("WFMO:YZERO?"))
            yoff = float(scope.query("WFMO:YOFF?"))

            scope.write("curve?")
            rawData = scope.read_binary_values(datatype='b', is_big_endian=False, container=np.ndarray, header_fmt='ieee', expect_termination=True)

            if first:
                xinc = float(scope.query("WFMO:XINCR?"))
                xzero = float(scope.query("WFMO:XZERO?"))
                pt_off = int(scope.query("WFMO:PT_OFF?"))
                t0 = (-pt_off * xinc) + xzero
                xvalues = np.linspace(t0, t0 + xinc * (len(rawData) - 1), len(rawData))
            else:
                xvalues = None
            yvalues = (rawData - yoff) * ymult + yzero

            return xvalues, yvalues

        xvalues, yvalues_ch1 = fetch_waveform("CH1")
        _, yvalues_ch2 = fetch_waveform("CH2", first=False)

        return xvalues, yvalues_ch1, yvalues_ch2
    except Exception as e:
        print(f"Error acquiring waveform: {e}")
        return None, None, None

# Function to update the plot
def update_plot(xvalues, yvalues_ch1, yvalues_ch2):
    global y_max
    ax.clear()

    # Baseline correction
    N = np.argmin(np.abs(xvalues))
    baseline_ch1 = np.mean(yvalues_ch1[:int(N*0.90)])
    baseline_ch2 = np.mean(yvalues_ch2[:int(N*0.90)])
    yvalues_ch1_corrected = yvalues_ch1 - baseline_ch1
    yvalues_ch2_corrected = yvalues_ch2 - baseline_ch2

    # Plot the waveforms
    ax.plot(xvalues * 1e6, yvalues_ch1_corrected * 1e3, label='Cathode', color='yellow')
    ax.plot(xvalues * 1e6, yvalues_ch2_corrected * 1e3, label='Anode', color='blue')

    y_max = max(yvalues_ch2_corrected) * 1.1 * 1e3  # Slightly above max value
    ax.set_title('Waveform Display')
    ax.set_xlabel('Time [μs]')
    ax.set_ylabel('Voltage [mV]')
    ax.legend()
    canvas.draw()

def add_calculated_features_to_plot():
    global t_1, t_2, t_3, Vpeak_c, Vpeak_a, electron_lifetime
    global falling_edge_ch1, rising_edge_ch2, min_y_time_ch1, max_y_time_ch2, y_max
    
    # Draw horizontal lines and labels for t_1, t_2, and t_3
    #ax.annotate(f"$t_1$", xy=(falling_edge_ch1, y_max), xytext=(min_y_time_ch1, y_max),color='red')
    #            #arrowprops=dict(arrowstyle="<->", color='red', linestyle='dashed'), color='red')
    #ax.annotate(f"$t_2$", xy=(min_y_time_ch1, y_max), xytext=(rising_edge_ch2, y_max),
    #            arrowprops=dict(arrowstyle="<->", color='red', linestyle='dashed'), color='red')
    #ax.annotate(f"$t_3$", xy=(rising_edge_ch2, y_max), xytext=(max_y_time_ch2, y_max),
    #            arrowprops=dict(arrowstyle="<->", color='red', linestyle='dashed'), color='red')

    # Add a box with Vpeak_c, Vpeak_a, t_1, t_2, t_3, and electron lifetime
    info_text = (f"$V_{{peak\_c}}$: {Vpeak_c:.4f} mV\n"
                 f"$V_{{peak\_a}}$: {Vpeak_a:.4f} mV\n"
                 f"$t_1$: {t_1:.4f} µs\n"
                 f"$t_2$: {t_2:.4f} µs\n"
                 f"$t_3$: {t_3:.4f} µs\n"
                 f"$\\tau$: {electron_lifetime:.4f} µs")
    ax.text(0.7, 0.1, info_text, transform=ax.transAxes, fontsize=10,
            bbox=dict(facecolor='white', alpha=0.5))

    canvas.draw()

# Handle connect button click
def handle_connect():
    global scope
    scope, message = connect_to_scope()
    connection_status_label.config(text=message)

# Modify the handle_acquire function to support the new mode
def handle_acquire():
    global scope
    if scope is not None:
        mode = acq_mode_var.get()
        num_samples = num_samples_var.get()
        if mode == 'TAKE MULTIPLE SAMPLES':
            take_multiple_samples(scope, num_samples)
        else:
            prompt_scope_for_acquisition(scope, mode, num_samples)

def handle_plot():
    global scope, xvalues, yvalues_ch1, yvalues_ch2
    if scope is not None:
        mode = acq_mode_var.get()
        num_samples = num_samples_var.get()
        print(f"Fetching data for mode {mode} with {num_samples} samples")
        xvalues, yvalues_ch1, yvalues_ch2 = acquire_waveform(scope, mode, num_samples)
        if xvalues is not None and yvalues_ch1 is not None and yvalues_ch2 is not None:
            update_plot(xvalues, yvalues_ch1, yvalues_ch2)
        else:
            print("Data acquisition failed or returned empty data")

# Function to choose save folder
def choose_save_folder():
    global save_folder
    save_folder = filedialog.askdirectory()
    if save_folder:
        save_folder_label.config(text=f"Save Folder: {os.path.basename(save_folder)}")
    else:
        save_folder_label.config(text="No folder selected")

def save_data():
    global xvalues, yvalues_ch1, yvalues_ch2, save_folder
    global data_filepath
    if xvalues is None or yvalues_ch1 is None or yvalues_ch2 is None:
        messagebox.showerror("Error", "No data to save")
        return
    if not save_folder:
        messagebox.showerror("Error", "Save folder not selected")
        return

    data_type = data_type_var.get()
    cathode_voltage = cathode_voltage_var.get()
    anode_voltage = anode_voltage_var.get()
    descriptor = descriptor_entry.get().replace(" ", "_")
    note = note_entry.get()
    mode = acq_mode_var.get()
    num_samples = num_samples_var.get()

    # Determine acquisition type
    acq_type = "SingleTrace" if mode == 'SAMPLE' else "Average"

    # Generate file name
    timestamp = time.strftime("%m-%d-%Y_%H-%M-%S")
    filename = f"{data_type}_{cathode_voltage}Vc_{anode_voltage}Va_{descriptor}_{acq_type}_{timestamp}.txt"
    filepath = os.path.join(save_folder, filename)
    data_filepath = filepath
    # Check for file existence and avoid overwriting
    counter = 2
    while os.path.exists(filepath):
        filepath = os.path.join(save_folder, f"{filename.rsplit('.', 1)[0]}_{counter}.txt")
        counter += 1

    # Save data
    with open(filepath, 'w', encoding='utf-8') as file:
        # Write headers
        file.write(f"Data Type: {data_type}\n")
        file.write(f"Cathode Voltage: {cathode_voltage} V\n")
        file.write(f"Anode Voltage: {anode_voltage} V\n")
        file.write(f"Descriptor: {descriptor}\n")
        file.write(f"Note: {note}\n")
        file.write(f"Acquisition Type: {acq_type}\n")
        if acq_type == "Average":
            file.write(f"Number of Traces: {num_samples}\n")
        else:
            file.write(f"Number of Traces: 1\n")
        file.write(f"Acquisition Time: {timestamp}\n")
        file.write("Time (μs),Cathode Voltage (mV),Anode Voltage (mV)\n")

        # Write data
        for t, c, a in zip(xvalues * 1e6, yvalues_ch1 * 1e3, yvalues_ch2 * 1e3):
            file.write(f"{t:.5f},{c:.5f},{a:.5f}\n")
    
    # Update runlist.txt
    runlist_file_path = os.path.join(save_folder, "runlist.txt")
    file_exists = os.path.isfile(runlist_file_path)
    
    with open(runlist_file_path, 'a') as runlist_file:
        # Write header if file is being created
        if not file_exists:
            header = "Filename,Data Type,Cathode Voltage,Anode Voltage,Descriptor,Note\n"
            runlist_file.write(header)
        # Write current data
        runlist_entry = f"{os.path.basename(filepath)},{data_type},{cathode_voltage}V,{anode_voltage}V,{descriptor},{note}\n"
        runlist_file.write(runlist_entry)
    
    messagebox.showinfo("Success", f"Data saved to {filename}")

# Functions to find falling and rising edges
def find_falling_edges(signal):
    diff_signal = np.diff(signal)
    falling_edges = np.where(diff_signal == np.min(diff_signal))[0]
    return falling_edges

def find_rising_edges(signal):
    diff_signal = np.diff(signal)
    rising_edges = np.where(diff_signal == np.max(diff_signal))[0]
    return rising_edges

# Function to calculate electron lifetime and related quantities
def calculate_electron_lifetime():
    global xvalues, yvalues_ch1, yvalues_ch2
    global falling_edge_ch1, rising_edge_ch2, min_y_time_ch1, max_y_time_ch2
    global t_1, t_2, t_3, Vpeak_c, Vpeak_a, electron_lifetime
    if xvalues is None or yvalues_ch1 is None or yvalues_ch2 is None:
        messagebox.showerror("Error", "No data available for calculation")
        return

    # Data preparation and baseline correction
    data = pd.DataFrame({
        'Time (µs)': xvalues * 1e6,
        'Channel 1': yvalues_ch1 * 1e3,
        'Channel 2': yvalues_ch2 * 1e3
    })
    N = data['Time (µs)'].sub(0).abs().idxmin()
    baseline_ch1 = data.loc[0:int(N*0.90), 'Channel 1'].mean()
    baseline_ch2 = data.loc[0:int(N*0.90), 'Channel 2'].mean()
    data['Channel 1 Baseline Corrected'] = data['Channel 1'] - baseline_ch1
    data['Channel 2 Baseline Corrected'] = data['Channel 2'] - baseline_ch2

    # Finding edges
    falling_edges_ch1 = find_falling_edges(data['Channel 1 Baseline Corrected'])
    rising_edges_ch2 = find_rising_edges(data['Channel 2 Baseline Corrected'])

    # Calculating the specific times
    falling_edge_ch1 = data.iloc[falling_edges_ch1[0]]['Time (µs)']
    rising_edge_ch2 = data.iloc[rising_edges_ch2[0]]['Time (µs)']

    # Finding the times of minimum and maximum y-values
    min_y_index_ch1 = data['Channel 1 Baseline Corrected'].idxmin()
    max_y_index_ch2 = data['Channel 2 Baseline Corrected'].idxmax()
    min_y_time_ch1 = data.iloc[min_y_index_ch1]['Time (µs)']
    max_y_time_ch2 = data.iloc[max_y_index_ch2]['Time (µs)']
    print(f'min_y_time_ch1, max_y_time_ch2 = {min_y_time_ch1}, {max_y_time_ch2}')
    print(f'falling_edge_ch1, rising_edge_ch2 = {falling_edge_ch1}, {rising_edge_ch2}')
    # Calculate t_1, t_2, t_3
    t_1 = min_y_time_ch1 - falling_edge_ch1
    t_2 = rising_edge_ch2 - min_y_time_ch1
    t_3 = max_y_time_ch2 - rising_edge_ch2

    # Calculate Vpeak_c, Vpeak_a
    Vpeak_c = data['Channel 1 Baseline Corrected'].min()
    Vpeak_a = data['Channel 2 Baseline Corrected'].max()

    # Calculate QA_over_QC and electron lifetime
    gain_ratio = 1.014
    QA_over_QC = gain_ratio * Vpeak_a / Vpeak_c
    electron_lifetime = -1 / np.log(QA_over_QC) * (t_2 + 0.5 * (t_1 + t_3))

    # Updating the GUI with calculated values
    t1_label.config(text=f"t_1: {t_1:.4f} µs")
    t2_label.config(text=f"t_2: {t_2:.4f} µs")
    t3_label.config(text=f"t_3: {t_3:.4f} µs")
    vpeak_c_label.config(text=f"Cathode Vpeak: {Vpeak_c:.4f} mV")
    vpeak_a_label.config(text=f"Anode Vpeak: {Vpeak_a:.4f} mV")
    qa_qc_label.config(text=f"QA/QC: {abs(QA_over_QC):.4f}")
    electron_lifetime_label.config(text=f"Electron Lifetime: {electron_lifetime:.4f} µs")
    add_calculated_features_to_plot()
# Function to add values to the log file
def add_values_to_log():
    global xvalues, yvalues_ch1, yvalues_ch2, save_folder, data_filepath
    global t_1, t_2, t_3, Vpeak_c, Vpeak_a, QA_over_QC, electron_lifetime
    if save_folder == "":
        messagebox.showerror("Error", "Save folder not selected")
        return
    if xvalues is None or yvalues_ch1 is None or yvalues_ch2 is None:
        messagebox.showerror("Error", "No data available for logging")
        return
    if data_filepath == "":
        messagebox.showerror("Error", "Save data first")
        return
    log_file_path = os.path.join(save_folder, "extracted_values_log.txt")
    file_exists = os.path.isfile(log_file_path)
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    file_name = os.path.basename(data_filepath)

    # Prepare the log entry
    log_entry = f"{file_name},{timestamp},{t_1:.5f},{t_2:.5f},{t_3:.5f},{(t_1+t_2+t_3):.5f},{Vpeak_a:.5f},{Vpeak_c:.5f},{QA_over_QC:.5f},{electron_lifetime:.5f}\n"

    # Write the log entry to the file
    with open(log_file_path, 'a') as log_file:
        if not file_exists:
            header = "File Name, Time, Date, t1 (us), t2 (us), t3 (us), Total Time (us), Vpeak_a (mV), Vpeak_c (mV), QA/QC, Electron Lifetime (us)\n"
            log_file.write(header)
        log_file.write(log_entry)
    data_filepath = ""
    messagebox.showinfo("Success", "Values added to log")

# Create the main window
root = tk.Tk()
root.title("Oscilloscope Data Acquisition")
root.state('zoomed')

# Configure the style of ttk buttons
style = ttk.Style()
style.configure('Large.TButton', font=('TkDefaultFont', 14))

# Create and pack the connect button with the new style
connect_button = ttk.Button(root, text="Connect to Scope", command=handle_connect, style='Large.TButton')
connect_button.pack(fill='x', expand=False)

connection_status_label = ttk.Label(root, text="Not connected")
connection_status_label.pack()

acq_mode_var = tk.StringVar(value='SAMPLE')
acq_mode_dropdown = ttk.OptionMenu(root, acq_mode_var, 'SAMPLE', 'SAMPLE', 'AVERAGE', 'TAKE MULTIPLE SAMPLES')
acq_mode_dropdown.pack()

num_samples_var = tk.IntVar(value=100)
num_samples_entry = ttk.Entry(root, textvariable=num_samples_var)
num_samples_entry.pack()

acquire_button = ttk.Button(root, text="Acquire", command=handle_acquire, style='Large.TButton')
acquire_button.pack()

plot_button = ttk.Button(root, text="Plot", command=handle_plot, style='Large.TButton')
plot_button.pack()

# Create a frame for saving waveforms
save_frame = ttk.LabelFrame(root, text="Save Waveforms", padding=(10, 10))
save_frame.pack(side='right', fill='y', expand=False)

# Choose Save Folder
save_folder_button = ttk.Button(save_frame, text="Choose Save Folder", command=choose_save_folder)
save_folder_button.pack()
save_folder_label = ttk.Label(save_frame, text="No folder selected")
save_folder_label.pack()

# Data Type
ttk.Label(save_frame, text="Data Type:").pack()
data_type_var = tk.StringVar(value='LAr')
data_type_dropdown = ttk.OptionMenu(save_frame, data_type_var, 'LAr', 'LAr', 'Vacuum', 'GAr', 'Air')
data_type_dropdown.pack()

# Cathode Voltage
ttk.Label(save_frame, text="Cathode Voltage:").pack()
cathode_voltage_var = tk.IntVar(value=0)
cathode_voltage_entry = ttk.Entry(save_frame, textvariable=cathode_voltage_var)
cathode_voltage_entry.pack()

# Anode Voltage
ttk.Label(save_frame, text="Anode Voltage:").pack()
anode_voltage_var = tk.IntVar(value=0)
anode_voltage_entry = ttk.Entry(save_frame, textvariable=anode_voltage_var)
anode_voltage_entry.pack()

# Descriptor
ttk.Label(save_frame, text="Descriptor:").pack()
descriptor_entry = ttk.Entry(save_frame)
descriptor_entry.pack()
descriptor_note = ttk.Label(save_frame, text="Use underscores or dashes instead of spaces")
descriptor_note.pack()

# Note
ttk.Label(save_frame, text="Note:").pack()
note_entry = ttk.Entry(save_frame)
note_entry.pack()

# Save Data Button
save_button = ttk.Button(save_frame, text="Save Data", command=save_data)
save_button.pack()

# Create a frame for calculating electron lifetime
calc_frame = ttk.LabelFrame(root, text="Calculate Electron Lifetime", padding=(10, 10))
calc_frame.pack(side='right', fill='both', expand=False)

# Create and pack the calculate button
calculate_button = ttk.Button(calc_frame, text="Calculate", command=calculate_electron_lifetime)
calculate_button.pack()

# Labels for displaying calculated values
t1_label = ttk.Label(calc_frame, text="t_1: ")
t1_label.pack()
t2_label = ttk.Label(calc_frame, text="t_2: ")
t2_label.pack()
t3_label = ttk.Label(calc_frame, text="t_3: ")
t3_label.pack()
vpeak_c_label = ttk.Label(calc_frame, text="Vpeak_c: ")
vpeak_c_label.pack()
vpeak_a_label = ttk.Label(calc_frame, text="Vpeak_a: ")
vpeak_a_label.pack()
qa_qc_label = ttk.Label(calc_frame, text="QA/QC: ")
qa_qc_label.pack()
electron_lifetime_label = ttk.Label(calc_frame, text="Electron Lifetime: ")
electron_lifetime_label.pack()

# Add Values to Log Button
add_to_log_button = ttk.Button(calc_frame, text="Add Values to Log", command=add_values_to_log)
add_to_log_button.pack()

# Button to choose data file
choose_file_button = ttk.Button(root, text="Choose Data File", command=choose_data_file)
choose_file_button.pack()

# Button to save the plot as a PDF under the save_frame
save_plot_button = ttk.Button(save_frame, text="Save Plot as PDF", command=save_plot_as_pdf)
save_plot_button.pack()

fig, ax = plt.subplots(figsize=(12, 6)) 
canvas = FigureCanvasTkAgg(fig, master=root)
canvas_widget = canvas.get_tk_widget()
canvas_widget.pack(fill='both', expand=True)

# Start the main loop
root.mainloop()