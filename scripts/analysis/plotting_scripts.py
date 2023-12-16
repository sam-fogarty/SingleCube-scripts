import numpy as np
import plotly.graph_objects as go

def Delta_t(clusters, nbins, upperXLimit):
    # Compute the time difference
    time_diff = (np.array(clusters['t_max']) - np.array(clusters['t_min'])) / 1e3
    
    # Create the histogram
    fig = go.Figure(data=[go.Histogram(x=time_diff, nbinsx=nbins)])
    
    # Set the plot labels
    fig.update_layout(
            title='Timestamp duration of charge clusters',
            xaxis_title=r'$\Delta t [\mu s]$',
            yaxis_title='Cluster Count',
            font=dict(
                size=18  # Set the fontsize of the title
                )
        )
    # Set the x-axis limits
    xaxis_limits = [0, upperXLimit]  # Set the desired x-axis limits
    fig.update_xaxes(range=xaxis_limits, tickmode='linear', dtick=10)

    # Set the fontsize of xaxis and yaxis tick labels
    fontsize_ticks = 14
    fig.update_xaxes(tickfont=dict(size=fontsize_ticks))  # Set the fontsize of xaxis tick labels
    fig.update_yaxes(tickfont=dict(size=fontsize_ticks))  # Set the fontsize of yaxis tick labels

    
    # Show the plot
    fig.show()

