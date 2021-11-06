import pandas as pd
import torch
from torch.utils.data import Dataset
import numpy as np
from sustainbench.datasets.sustainbench_dataset import SustainBenchDataset
from sustainbench.common.grouper import CombinatorialGrouper
from sustainbench.common.utils import subsample_idxs, shuffle_arr
import os
import h5py

from sklearn.metrics import precision_score, recall_score, accuracy_score, roc_auc_score

class BrickKilnDataset(SustainBenchDataset):
    """
    Supported `split_scheme`: 'official'

    Input (x):
        64 x 64 x 13 imagery from Sentinel-2. Images are not normalized.

    Output (y):
        y is a binary label representing containing or not containing a brick kiln

    Metadata:
        Metadata contains image lat and long bounds, as well as indices from the original
        tif file the image is from.

    Website: TODO

    Original publication: TODO

    License:
        S2 data is U.S. Public Domain.

    """
    _dataset_name = 'brick_kiln'
    _versions_dict = { # TODO
        '1.0': {
            'download_url': None,
            'compressed_size': None}}

    def __init__(self, version=None, root_dir='data', download=False, split_scheme='official'):
        self._version = version
        self._data_dir = self.initialize_data_dir(root_dir, download)
        
        self._split_dict = {'train': 0, 'val': 1, 'test': 2}
        self._split_names = {'train': 'Train', 'val': 'Validation', 'test': 'Test'}
        
        # Extract splits
        self._split_scheme = split_scheme
        if self._split_scheme not in ['official']:
            raise ValueError(f'Split scheme {self._split_scheme} not recognized')
            
        self.metadata = pd.read_csv(os.path.join(self.data_dir, 'list_eval_partition.csv'))
        self._split_array = self.metadata['partition'].values
        
        self._y_array = torch.from_numpy(self.metadata['y'].values)
        self._y_size = 1
        
        self._metadata_fields = ['y', 'hdf5_file', 'hdf5_idx', 'lon_top_left', 'lat_top_left', 'lon_bottom_right', 'lat_bottom_right', 'indice_x', 'indice_y']
        self._metadata_array = torch.tensor(self.metadata[self.metadata_fields].astype(float).values)

        super().__init__(root_dir, download, split_scheme)
    
    def get_input(self, idx):
        hdf5_loc = self.metadata['hdf5_file'].iloc[idx]
        with h5py.File(os.path.join(self.data_dir, f'examples_{hdf5_loc}.hdf5'), 'r') as f:
            img = f['images'][self.metadata['hdf5_idx'].iloc[idx]]
        
        img = torch.from_numpy(img).float()
        return img
    
    
    def eval(self, y_pred, y_true, metadata, prediction_fn=None):
        """
        Computes all evaluation metrics.
        Args:
            - y_pred (Tensor): Predictions from a model. By default, they are predicted labels (LongTensor).
                               But they can also be other model outputs such that prediction_fn(y_pred)
                               are predicted labels.
            - y_true (LongTensor): Ground-truth labels
            - prediction_fn (function): A function that turns y_pred into predicted labels. If none, y_pred is
              expected to be probability score
        Output:
            - results (dictionary): Dictionary of evaluation metrics
            - results_str (str): String summarizing the evaluation metrics
        """
        if prediction_fn is None:
            precision = precision_score(y_true, y_pred)
            recall = recall_score(y_true, y_pred)
            accuracy = accuracy_score(y_true, y_pred)
            
            results = {'Precision': precision, 'Recall': recall, 'Accuracy': accuracy}
            results_str = f'Precision: {precision}, Recall: {recall}, Accuracy: {accuracy}'
        else:
            precision = precision_score(y_true, prediction_fn(y_pred))
            recall = recall_score(y_true, prediction_fn(y_pred))
            accuracy = accuracy_score(y_true, prediction_fn(y_pred))
            auc = roc_auc_score(y_true, y_pred)
            
            results = {'Precision': precision, 'Recall': recall, 'Accuracy': accuracy, 'AUC': auc}
            results_str = f'Precision: {precision}, Recall: {recall}, Accuracy: {accuracy}, AUC: {auc}'
            
        return results, results_str
