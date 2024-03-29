import plotting_scripts

import numpy as np
import h5py
import fire

def run_analysis(filepath):
    
    file = h5py.File(filepath, 'r')
    clusters = file['clusters']
    hits = file['hits']
    
    # make Delta t histogram
    nbins = 100
    nhit_cut = 1
    upperXLimit = 30
    plotting_scripts.Delta_t(clusters[clusters['nhit'] > nhit_cut], nbins, upperXLimit)


if __name__ == "__main__":
    fire.Fire(run_analysis)
