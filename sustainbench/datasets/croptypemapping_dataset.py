import pandas as pd
import torch
from torch.utils.data import Dataset
import numpy as np
from sustainbench.datasets.sustainbench_dataset import SustainBenchDataset
from sustainbench.common.grouper import CombinatorialGrouper
from sustainbench.common.utils import subsample_idxs, shuffle_arr
import os
import json

import torchvision.transforms as transforms
from sklearn.metrics import f1_score, accuracy_score

# BAND STATS

BANDS = { 's1': { 'VV': 0, 'VH': 1, 'RATIO': 2},
          's2': { '10': {'BLUE': 0, 'GREEN': 1, 'RED': 2, 'RDED1': 3, 'RDED2': 4, 'RDED3': 5, 'NIR': 6, 'RDED4': 7, 'SWIR1': 8, 'SWIR2': 9},
                   '4': {'BLUE': 0, 'GREEN': 1, 'RED': 2, 'NIR': 3}}, 
          'planet': { '4': {'BLUE': 0, 'GREEN': 1, 'RED': 2, 'NIR': 3}}}

MEANS = { 's1': { 'ghana': torch.Tensor([-10.50, -17.24, 1.17]), 
                  'southsudan': torch.Tensor([-9.02, -15.26, 1.15])},
          's2': { 'ghana': torch.Tensor([2620.00, 2519.89, 2630.31, 2739.81, 3225.22, 3562.64, 3356.57, 3788.05, 2915.40, 2102.65]),
                  'southsudan': torch.Tensor([2119.15, 2061.95, 2127.71, 2277.60, 2784.21, 3088.40, 2939.33, 3308.03, 2597.14, 1834.81])},
          'planet': { 'ghana': torch.Tensor([1264.81, 1255.25, 1271.10, 2033.22]),
                      'southsudan': torch.Tensor([1091.30, 1092.23, 1029.28, 2137.77])},
          's2_cldfltr': { 'ghana': torch.Tensor([1362.68, 1317.62, 1410.74, 1580.05, 2066.06, 2373.60, 2254.70, 2629.11, 2597.50, 1818.43]),
                  'southsudan': torch.Tensor([1137.58, 1127.62, 1173.28, 1341.70, 1877.70, 2180.27, 2072.11, 2427.68, 2308.98, 1544.26])} }

STDS = { 's1': { 'ghana': torch.Tensor([3.57, 4.86, 5.60]),
                 'southsudan': torch.Tensor([4.49, 6.68, 21.75])},
         's2': { 'ghana': torch.Tensor([2171.62, 2085.69, 2174.37, 2084.56, 2058.97, 2117.31, 1988.70, 2099.78, 1209.48, 918.19]),
                 'southsudan': torch.Tensor([2113.41, 2026.64, 2126.10, 2093.35, 2066.81, 2114.85, 2049.70, 2111.51, 1320.97, 1029.58])},
         'planet': { 'ghana': torch.Tensor([602.51, 598.66, 637.06, 966.27]),
                     'southsudan': torch.Tensor([526.06, 517.05, 543.74, 1022.14])},
         's2_cldfltr': { 'ghana': torch.Tensor([511.19, 495.87, 591.44, 590.27, 745.81, 882.05, 811.14, 959.09, 964.64, 809.53]),
                 'southsudan': torch.Tensor([548.64, 547.45, 660.28, 677.55, 896.28, 1066.91, 1006.01, 1173.19, 1167.74, 865.42])} }

# OTHER PER COUNTRY CONSTANTS
NUM_CLASSES = { 'ghana': 4,
                'southsudan': 4}

GRID_SIZE = { 'ghana': 256, 
              'southsudan': 256}

CM_LABELS = { 'ghana': [0, 1, 2, 3], 
              'southsudan': [0, 1, 2, 3]}

CROPS = { 'ghana': ['groundnut', 'maize', 'rice', 'soya bean'], 
          'southsudan': ['sorghum', 'maize', 'rice', 'groundnut']}

IMG_DIM = 64

PLANET_DIM = 212

class CropTypeMappingDataset(SustainBenchDataset):
    """
    Supported `split_scheme`:
        'official' - same as 'ghana'
        'south-sudan'

    Input (x):
        List of three satellites, each containing C x 64 x 64 x T satellite image, 
        with 12 channels from S2, 2 channels from S1, and 6 from Planet. 
        Additional bands such as NDVI and GCVI are computed for Planet and S2. 
        For S1, VH/VV is also computed. Time series are zero padded to 256.
        Mean/std applied on bands excluding NDVI and GCVI. Paper uses 32x32 
        imagery but the public dataset/splits use 64x64 imagery, which is
        thusly provided. Bands are as follows:
            
        S1 - [VV, VH, RATIO]
        S2 - [BLUE, GREEN, RED, RDED1, RDED2, RDED3, NIR, RDED4, SWIR1, SWIR2, NDVI, GCVI]
        PLANET - [BLUE, GREEN, RED, NIR, NDVI, GCVI]

    Output (y):
        y is a 64x64 tensor with numbers for locations with a crop class.

    Metadata:
        Metadata contains integer in format {Year}{Month}{Day} for each image in 
        respective time series. Zero padded to 256, can be used to derive a mask.

    Website: https://github.com/roserustowicz/crop-type-mapping

    Original publication:
    @InProceedings{Rustowicz_2019_CVPR_Workshops,
        author = {M Rustowicz, Rose and Cheong, Robin and Wang, Lijing and Ermon, Stefano and Burke, Marshall and Lobell, David},
        title = {Semantic Segmentation of Crop Type in Africa: A Novel Dataset and Analysis of Deep Learning Methods},
        booktitle = {Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR) Workshops},
        month = {June},
        year = {2019}
    }

    License:
        S1/S2 data is U.S. Public Domain.

    """
    _dataset_name = 'africa_crop_type_mapping'
    _versions_dict = { # TODO
        '1.0': {
            'download_url': None,
            'compressed_size': None}}

    def __init__(self, version=None, root_dir='data', download=False, split_scheme='official', 
                 resize_planet=False, calculate_bands=True, normalize=True):
        """
        Args:
            resize_planet: True if Planet imagery will be resized to 64x64
            calculate_bands: True if aditional bands (NDVI and GCVI) will be calculated on the fly and appended
            normalize: True if bands (excluding NDVI and GCVI) wll be normalized
        """
        self._resize_planet = resize_planet
        self._calculate_bands = calculate_bands
        self._normalize = normalize
        
        self._version = version
        self._data_dir = self.initialize_data_dir(root_dir, download)
        
        self._split_dict = {'train': 0, 'val': 1, 'test': 2}
        self._split_names = {'train': 'Train', 'val': 'Validation', 'test': 'Test'}
        
        # Extract splits
        self._split_scheme = split_scheme
        if self._split_scheme not in ['official', 'ghana', 'southsudan']:
            raise ValueError(f'Split scheme {self._split_scheme} not recognized')
        if self._split_scheme in ['official', 'ghana']:
            self._country = 'ghana'
        if self._split_scheme in ['southsudan']:
            self._country = 'southsudan'
            
        split_df = pd.read_csv(os.path.join(self.data_dir, self._country, 'list_eval_partition.csv'))
        self._split_array = split_df['partition'].values
        
        # y_array stores idx ids corresponding to location. Actual y labels are
        # tensors that are loaded separately.
        self._y_array = torch.from_numpy(split_df['id'].values)
        self._y_size = (IMG_DIM, IMG_DIM)
        
        self._metadata_fields = ['y']
        self._metadata_array = torch.from_numpy(split_df['id'].values)

        super().__init__(root_dir, download, split_scheme)

    def __getitem__(self, idx):
        # Any transformations are handled by the SustainBenchSubset
        # since different subsets (e.g., train vs test) might have different transforms
        x = self.get_input(idx)
        y = self.get_label(idx)
        metadata = self.get_metadata(idx)
        return x, y, metadata
    
    def pad(self, tensor):
        '''
        Right pads or crops tensor to GRID_SIZE. 
        '''
        pad_size = GRID_SIZE[self.country] - tensor.shape[-1]
        tensor = torch.nn.functional.pad(input=tensor, pad=(0, pad_size), value=0)
        return tensor
    
    def get_input(self, idx):
        """
        Returns X for a given idx.
        """
        loc_id = f'{self.y_array[idx]:06d}'
        images = np.load(os.path.join(self.data_dir, self.country, 'npy', f'{self.country}_{loc_id}.npz'))
        
        s1 = images['s1']
        s2 = images['s2']
        planet = images['planet']
        
        s1 = torch.from_numpy(s1)
        s2 = torch.from_numpy(s2.astype(np.int32))
        planet = torch.from_numpy(planet.astype(np.int32))

        if self.resize_planet:
            planet = planet.permute(3, 0, 1, 2)
            planet = transforms.Resize(IMG_DIM)(planet)
            planet = planet.permute(1, 2, 3, 0)
        else:
            planet = planet.permute(3, 0, 1, 2)
            planet = transforms.CenterCrop(PLANET_DIM)(planet)
            planet = planet.permute(1, 2, 3, 0)

        # Include NDVI and GCVI for s2 and planet, calculate before normalization and numband selection
        if self.calculate_bands:
            ndvi_s2 = (s2[BANDS['s2']['10']['NIR']] - s2[BANDS['s2']['10']['RED']]) / (s2[BANDS['s2']['10']['NIR']] + s2[BANDS['s2']['10']['RED']])
            ndvi_planet = (planet[BANDS['planet']['4']['NIR']] - planet[BANDS['planet']['4']['RED']]) / (planet[BANDS['planet']['4']['NIR']] + planet[BANDS['planet']['4']['RED']])

            gcvi_s2 = (s2[BANDS['s2']['10']['NIR']] / s2[BANDS['s2']['10']['GREEN']]) -1
            gcvi_planet = (planet[BANDS['planet']['4']['NIR']] / planet[BANDS['planet']['4']['GREEN']]) - 1
        
        if self.normalize:
            s1 = self.normalization(s1, 's1')
            s2 = self.normalization(s2, 's2')
            planet = self.normalization(planet, 'planet')
            
        # Concatenate calculated bands
        if self.calculate_bands:
            s2 = torch.cat((s2, torch.unsqueeze(ndvi_s2, 0), torch.unsqueeze(gcvi_s2, 0)), 0)
            planet = torch.cat((planet, torch.unsqueeze(ndvi_planet, 0), torch.unsqueeze(gcvi_planet, 0)), 0)
        
        s1 = self.pad(s1)
        s2 = self.pad(s2)
        planet = self.pad(planet)

        return {'s1': s1, 's2': s2, 'planet': planet}
    
    def get_label(self, idx):
        """
        Returns y for a given idx.
        """
        loc_id = f'{self.y_array[idx]:06d}'
        label = np.load(os.path.join(self.data_dir, self.country, 'truth', f'{self.country}_{loc_id}.npz'))['truth']
        label = torch.from_numpy(label)
        return label
    
    def get_dates(self, json_file):
        """
        Converts json dates into tensor containing dates
        """
        dates = np.array(json_file['dates'])
        dates = np.char.replace(dates, '-', '')
        dates = torch.from_numpy(dates.astype(np.int))
        return dates
    
    def get_metadata(self, idx):
        """
        Returns metadata for a given idx. 
        Dates are returned as integers in format {Year}{Month}{Day}
        """
        loc_id = f'{self.y_array[idx]:06d}'
        
        s1_json = json.loads(open(os.path.join(self.data_dir, self.country, 's1', f's1_{self.country}_{loc_id}.json'), 'r').read())
        s1 = self.get_dates(s1_json)
        
        s2_json = json.loads(open(os.path.join(self.data_dir, self.country, 's2', f's2_{self.country}_{loc_id}.json'), 'r').read())
        s2 = self.get_dates(s2_json)
        
        planet_json = json.loads(open(os.path.join(self.data_dir, self.country, 'planet', f'planet_{self.country}_{loc_id}.json'), 'r').read())
        planet = self.get_dates(planet_json)
        
        s1 = self.pad(s1)
        s2 = self.pad(s2)
        planet = self.pad(planet)
        
        return {'s1': s1, 's2': s2, 'planet': planet}
    
    def normalization(self, grid, satellite):
        """ Normalization based on values defined in constants.py
        Args: 
          grid - (tensor) grid to be normalized
          satellite - (str) describes source that grid is from ("s1" or "s2")
        Returns:
          grid - (tensor) a normalized version of the input grid
        """
        num_bands = grid.shape[0]
        means = MEANS[satellite][self.country]
        stds = STDS[satellite][self.country]
        grid = (grid-means[:num_bands].reshape(num_bands, 1, 1, 1))/stds[:num_bands].reshape(num_bands, 1, 1, 1)

        if satellite not in ['s1', 's2', 'planet']:
            raise ValueError("Incorrect normalization parameters")
        return grid
        
    def crop_segmentation_metrics(self, y_true, y_pred):
        y_true = y_true.flatten()
        y_pred = y_pred.flatten()
        assert (y_true.shape == y_pred.shape)
        y_true = y_true.int()
        y_pred = y_pred.int()
        f1 = f1_score(y_true, y_pred, average='macro')
        acc = accuracy_score(y_true, y_pred)
        print('Macro Dice/ F1 score:', f1)
        print('Accuracy score:', acc)
        return f1, acc
    
    def eval(self, y_pred, y_true, metadata):
        """
        Computes all evaluation metrics.
        Args:
            - y_pred (Tensor): Predictions from a model
            - y_true (Tensor): Ground-truth values
            - metadata (Tensor): Metadata
        Output:
            - results (dictionary): Dictionary of evaluation metrics
            - results_str (str): String summarizing the evaluation metrics
        """
        f1, acc = self.crop_segmentation_metrics(y_true, y_pred)
        results = [f1, acc]
        results_str = f'Dice/ F1 score: {f1}, Accuracy score: {acc}'
        return results, results_str
    
    @property
    def normalize(self):
        """
        True if images will be normalized. 
        """
        return self._normalize
    
    @property
    def country(self):
        """
        String containing the country pertaining to the dataset. 
        """
        return self._country
    
    @property
    def resize_planet(self):
        """
        True if planet satellite imagery will be resized to other satellite sizes.
        """
        return self._resize_planet
    
    @property
    def calculate_bands(self):
        """
        True if aditional bands (NDVI and GCVI) will be calculated on the fly and appended
        """
        return self._calculate_bands