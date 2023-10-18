import csv
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime
import tkinter as tk
from tkinter import messagebox, ttk
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

def plot_temperatures():
    """Function to plot temperatures."""
    fig = plt.Figure(figsize=(12, 6))
    ax = fig.add_subplot(111)

    ax.plot(time_objects, top_getter_temperature, marker='o', linestyle='-', label='Top Getter')
    ax.plot(time_objects, middle_getter_temperature, marker='o', linestyle='-', label='Middle Getter')
    ax.plot(time_objects, bottom_getter_temperature, marker='o', linestyle='-', label='Bottom Getter')
    ax.plot(time_objects, bottom_mol_siv_temperature, marker='o', linestyle='-', label='Bottom Mol Siv')
    ax.plot(time_objects, exhaust_temperature, marker='o', linestyle='-', label='Exhaust')
    ax.plot(time_objects, gas_in_temperature, marker='o', linestyle='-', label='Gas In')

    # Setting x-axis to display in month/day hour:minute format
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%m/%d %H:%M'))
    
    # Adjust y-axis limits
    ymin = min(min(top_getter_temperature), min(middle_getter_temperature), min(bottom_getter_temperature), min(bottom_mol_siv_temperature), min(exhaust_temperature), min(gas_in_temperature))
    ymax = max(max(top_getter_temperature), max(middle_getter_temperature), max(bottom_getter_temperature), max(bottom_mol_siv_temperature), max(exhaust_temperature), max(gas_in_temperature))
    ax.set_ylim(ymin - ymin*0.1, ymax + ymax*0.25)

    # Draw vertical line at the specified time
    h2_start_time = datetime.strptime("10/18 13:30", "%m/%d %H:%M")
    ax.axvline(x=h2_start_time, color='r', linestyle='--')
    ax.text(datetime.strptime("10/18 13:35", "%m/%d %H:%M"), ymax + ymax*0.026, r'$H_2$ flow started', rotation=90, color='k', fontsize=8)
    
    # Providing title and labels
    ax.set_title("Filter Activation Temperatures Over Time [Oct 17-18]")
    ax.set_xlabel("Time (Month/Day Hour:Minute)")
    ax.set_ylabel("Temperature (°C)")
    ax.grid(True)
    ax.legend()

    return fig

def update_plot():
    """Function to update plot and text file based on GUI input."""
    try:
        # Fetching user input
        new_month = month_entry.get() if month_entry.get() else last_month.get()
        new_day = day_entry.get() if day_entry.get() else last_day.get()
        new_date = f"{new_month}/{new_day} {time_entry.get()}"
        new_top_temp = float(top_getter_entry.get())
        new_mid_temp = float(middle_getter_entry.get())
        new_bot_temp = float(bottom_getter_entry.get())
        new_bot_mol_temp = float(bottom_mol_siv_entry.get())
        new_exhaust_temp = float(exhaust_entry.get())
        new_gas_in_temp = float(gas_in_entry.get())

        # Convert new date to datetime object
        new_time_obj = datetime.strptime(new_date, "%m/%d %H:%M")

        # Update data
        time_objects.append(new_time_obj)
        times.append(new_date)
        top_getter_temperature.append(new_top_temp)
        middle_getter_temperature.append(new_mid_temp)
        bottom_getter_temperature.append(new_bot_temp)
        bottom_mol_siv_temperature.append(new_bot_mol_temp)
        exhaust_temperature.append(new_exhaust_temp)
        gas_in_temperature.append(new_gas_in_temp)
        
        # Update the text file with new values
        with open('temperature_data.txt', 'a', newline='') as file:
            writer = csv.writer(file, delimiter=',')
            writer.writerow([new_date, new_top_temp, new_mid_temp, new_bot_temp, new_bot_mol_temp, new_exhaust_temp, new_gas_in_temp])
        
        # Update the last time plotted label
        last_time_label.config(text=f"Last Time Plotted: {new_date}")

        # Set the last month and day variables
        last_month.set(new_month)
        last_day.set(new_day)

        # Clear old plot and embed the updated one
        for widget in plot_frame.winfo_children():
            widget.destroy()

        fig = plot_temperatures()
        canvas = FigureCanvasTkAgg(fig, master=plot_frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

        # Clear the input boxes (retaining the month and day entries)
        time_entry.delete(0, tk.END)
        top_getter_entry.delete(0, tk.END)
        middle_getter_entry.delete(0, tk.END)
        bottom_getter_entry.delete(0, tk.END)
        bottom_mol_siv_entry.delete(0, tk.END)
        exhaust_entry.delete(0, tk.END)
        gas_in_entry.delete(0, tk.END)

    except Exception as e:
        messagebox.showerror("Error", f"An error occurred: {str(e)}\nPlease check your inputs and try again.")

# Reading data from the text file
times = []
top_getter_temperature = []
middle_getter_temperature = []
bottom_getter_temperature = []
bottom_mol_siv_temperature = []
exhaust_temperature = []
gas_in_temperature = []

with open('temperature_data.txt', 'r') as file:
    reader = csv.reader(file, delimiter=',')
    next(reader)  # Skip the header row
    for row in reader:
        times.append(row[0])
        top_getter_temperature.append(float(row[1]))
        middle_getter_temperature.append(float(row[2]))
        bottom_getter_temperature.append(float(row[3]))
        bottom_mol_siv_temperature.append(float(row[4]))
        exhaust_temperature.append(float(row[5]))
        gas_in_temperature.append(float(row[6]))

# Convert string times to datetime objects
time_objects = [datetime.strptime(t, "%m/%d %H:%M") for t in times]

# Setting up the GUI
root = tk.Tk()
root.title("Enter New Temperature Data")

# Creating frame for plot
plot_frame = ttk.Frame(root)
plot_frame.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

# Embed initial plot if data exists
if times:
    fig = plot_temperatures()
    canvas = FigureCanvasTkAgg(fig, master=plot_frame)
    canvas.draw()
    canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

# Creating Labels and Entry widgets
input_frame = ttk.Frame(root)
input_frame.pack(side=tk.BOTTOM)

last_month = tk.StringVar(value=times[-1].split("/")[0] if times else "")
last_day = tk.StringVar(value=times[-1].split("/")[1].split(" ")[0] if times else "")

month_label = ttk.Label(input_frame, text="Month (MM)")
month_label.grid(row=0, column=0)
month_entry = ttk.Entry(input_frame, textvariable=last_month)
month_entry.grid(row=0, column=1)

day_label = ttk.Label(input_frame, text="Day (DD)")
day_label.grid(row=1, column=0)
day_entry = ttk.Entry(input_frame, textvariable=last_day)
day_entry.grid(row=1, column=1)

time_label = ttk.Label(input_frame, text="Time [hr:min]")
time_label.grid(row=2, column=0)
time_entry = ttk.Entry(input_frame)
time_entry.grid(row=2, column=1)

top_getter_label = ttk.Label(input_frame, text="Top Getter Temperature [°C]")
top_getter_label.grid(row=0, column=2)
top_getter_entry = ttk.Entry(input_frame)
top_getter_entry.grid(row=0, column=3)

middle_getter_label = ttk.Label(input_frame, text="Middle Getter Temperature [°C]")
middle_getter_label.grid(row=1, column=2)
middle_getter_entry = ttk.Entry(input_frame)
middle_getter_entry.grid(row=1, column=3)

bottom_getter_label = ttk.Label(input_frame, text="Bottom Getter Temperature [°C]")
bottom_getter_label.grid(row=2, column=2)
bottom_getter_entry = ttk.Entry(input_frame)
bottom_getter_entry.grid(row=2, column=3)

bottom_mol_siv_label = ttk.Label(input_frame, text="Bottom Mol Siv Temperature [°C]")
bottom_mol_siv_label.grid(row=3, column=2)
bottom_mol_siv_entry = ttk.Entry(input_frame)
bottom_mol_siv_entry.grid(row=3, column=3)

exhaust_label = ttk.Label(input_frame, text="Exhaust Temperature [°C]")
exhaust_label.grid(row=4, column=2)
exhaust_entry = ttk.Entry(input_frame)
exhaust_entry.grid(row=4, column=3)

gas_in_label = ttk.Label(input_frame, text="Gas In Temperature [°C]")
gas_in_label.grid(row=5, column=2)
gas_in_entry = ttk.Entry(input_frame)
gas_in_entry.grid(row=5, column=3)

submit_button = ttk.Button(input_frame, text="Submit Data", command=update_plot)
submit_button.grid(row=6, column=0, columnspan=4)

last_time_label = ttk.Label(input_frame, text=f"Last Time Plotted: {times[-1] if times else 'N/A'}")
last_time_label.grid(row=7, column=0, columnspan=4)

root.mainloop()