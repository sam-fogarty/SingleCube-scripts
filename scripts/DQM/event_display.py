import dash
from dash import dcc
from dash import html
from dash.dependencies import Input, Output
import plotly.graph_objs as go
from plotly.subplots import make_subplots
import numpy as np
import pandas as pd
import h5py
from sklearn.cluster import DBSCAN
import argparse

# Parse command-line arguments
parser = argparse.ArgumentParser(description='Specify path to clusters file made with ndlar_39Ar_reco')
parser.add_argument('filepath', type=str, help='Path to clusters file made with ndlar_39Ar_reco')
args = parser.parse_args()

# open filepath with charge clusters and hits
# excepts a file made by ndlar_39Ar_reco
f = h5py.File(args.filepath, 'r')

# get clusters and hits from file
nhit_cut = 5
clusters = np.array(f['clusters'])
clusters_indices = np.arange(0, len(clusters), 1)
clusters_indices = clusters_indices[clusters['nhit'] > nhit_cut]
clusters = clusters[clusters['nhit'] > nhit_cut]
cluster_t = np.array(clusters['t_mid'])
hits = np.array(f['hits'])

# cluster the clusters with timestamps to build events
eps = 200000 # nsec
min_samples = 1
ts = []
for t in cluster_t:
    ts.append([t])
db = DBSCAN(eps=eps, min_samples=min_samples).fit(ts)
labels = np.array(db.labels_)
unique_labels = np.unique(labels)

# Initialize the Dash app
app = dash.Dash(__name__)

# Define the app layout
app.layout = html.Div([
    dcc.Graph(id='graph'),
    dcc.Input(id='input-eventID', type='number', value=0, min=0)
])

@app.callback(
    Output('graph', 'figure'),
    [Input('input-eventID', 'value')]
)

def update_graph(eventID):
    # get cluster ids corresponding to eventID
    cluster_IDs = clusters_indices[np.where(labels == unique_labels[eventID])[0]]
    
    # Accumulate data for all clusters before plotting
    all_x_data = []
    all_y_data = []
    all_t_data = []
    all_weights = []
    gain = 221 # mV/e
    for cluster_ID in cluster_IDs:
        x_data = hits[hits['cluster_index'] == cluster_ID]['x']
        y_data = hits[hits['cluster_index'] == cluster_ID]['y']
        t_data = hits[hits['cluster_index'] == cluster_ID]['t']*1e-3
        weights = hits[hits['cluster_index'] == cluster_ID]['q'] * gain * 1e-3

        all_x_data.extend(x_data)
        all_y_data.extend(y_data)
        all_t_data.extend(t_data)
        all_weights.extend(weights)

    # Create subplots with 1 row and 2 columns (one for 2D and one for 3D)
    fig = make_subplots(rows=1, cols=2, specs=[[{'type': 'xy'}, {'type': 'surface'}]])
    x_range = (-152.973, 152.973)
    y_range = (-152.973, 152.973)
    # Add 2D histogram to subplot
    fig.add_trace(go.Histogram2d(
        x=all_x_data,
        y=all_y_data,
        z=all_weights,
        histfunc='sum',  # Set the function to sum the weights
        colorscale='Viridis',
        zmin=0,
        xbins=dict(start=x_range[0], end=x_range[1], size=4.434),
        ybins=dict(start=y_range[0], end=y_range[1], size=4.434),
        colorbar=dict(title="q [ke-]", x=0.45),
        hovertemplate='x: %{x}<br>y: %{y}<br>weight: %{z}<extra></extra>'  # custom hover template
    ), row=1, col=1)


    # Add 3D scatter plot to subplot
    fig.add_trace(go.Scatter3d(
        x=all_t_data-np.min(all_t_data),
        y=all_x_data,
        z=all_y_data,
        mode='markers',
        marker=dict(
            size=3,
            color=all_weights,
            colorscale='Viridis',
            cmin=0,
            colorbar=dict(title="q [ke-]"),
            opacity=0.8
        ),
        name='3D Scatter',
        hovertemplate='x: %{x}<br>y: %{y}<br>z: %{z}<br>weight: %{marker.color}<extra></extra>'  # custom hover template
    ), row=1, col=2)

    zoom_value = 1.5 # set how much the 3D plot is zoomed initially
    fig.update_layout(
        title=f'Event: {eventID}',
        width=1000,
        height=500,
        xaxis_title="x [mm]",
        yaxis_title="y [mm]",
        scene=dict(
            xaxis_title="Timestamp - min(timestamp) [us]",
            yaxis_title="x [mm]",
            zaxis_title="y [mm]",
            yaxis_range=[x_range[0], x_range[1]],  # Set x range
            zaxis_range=[y_range[0], y_range[1]],  # Set y range
            camera=dict(
            eye=dict(x=zoom_value, y=zoom_value, z=zoom_value)  # Adjust these values as needed to control the zoom level
        )
        )
    )

    return fig

if __name__ == '__main__':
    app.run_server(host='127.0.0.1', port='8050', debug=True)
