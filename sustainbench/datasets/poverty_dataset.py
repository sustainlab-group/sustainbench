from pathlib import Path
import pickle

import numpy as np
import pandas as pd
import torch
from torch.utils.data import Dataset

from sustainbench.datasets.sustainbench_dataset import SustainBenchDataset
from sustainbench.common.metrics.all_metrics import MSE, PearsonCorrelation
from sustainbench.common.grouper import CombinatorialGrouper
from sustainbench.common.utils import subsample_idxs, shuffle_arr

DATASET = '2009-17'
BAND_ORDER = ['BLUE', 'GREEN', 'RED', 'SWIR1', 'SWIR2', 'TEMP1', 'NIR', 'NIGHTLIGHTS']

SPLITS = {
    'train': [
        'AL', 'BD', 'CD', 'CM', 'GH', 'GU', 'HN', 'IA', 'ID', 'JO', 'KE', 'KM',
        'LB', 'LS', 'MA', 'MB', 'MD', 'MM', 'MW', 'MZ', 'NG', 'NI', 'PE', 'PH',
        'SN', 'TG', 'TJ', 'UG', 'ZM', 'ZW'],
    'val': [
        'BF', 'BJ', 'BO', 'CO', 'DR', 'GA', 'GN', 'GY', 'HT', 'NM', 'SL', 'TD',
        'TZ'],
    'test': [
        'AM', 'AO', 'BU', 'CI', 'EG', 'ET', 'KH', 'KY', 'ML', 'NP', 'PK', 'RW',
        'SZ']
}

# means and standard deviations are calculated over the entire dataset (train + val + test)

MEANS = {
    'BLUE':    0.06547681,
    'GREEN':   0.09543012,
    'RED':     0.10692262,
    'SWIR1':   0.22902039,
    'SWIR2':   0.15596166,
    'TEMP1': 298.51077,
    'NIR':     0.2542566,
    'DMSP':   41.69006032536221,
    'VIIRS':   3.443405293536357
    # 'NIGHTLIGHTS': 20.753946  # nightlights overall
}

STD_DEVS = {
    'BLUE':    0.031534348,
    'GREEN':   0.04290699,
    'RED':     0.06305032,
    'SWIR1':   0.09461683,
    'SWIR2':   0.08886013,
    'TEMP1':   8.608657,
    'NIR':     0.06909249,
    'DMSP':  109.7289863161683,
    'VIIRS':  10.97284745670896
    # 'NIGHTLIGHTS': 76.66724  # nightlights overall
}


def split_by_countries(idxs, ood_countries, metadata):
    countries = np.asarray(metadata['country'].iloc[idxs])
    is_ood = np.any([(countries == country) for country in ood_countries], axis=0)
    return idxs[~is_ood], idxs[is_ood]


class PovertyMapDataset(SustainBenchDataset):
    """The PovertyMap poverty measure prediction dataset.

    This is a processed version of LandSat 5/7/8 Surface Reflectance,
    DMSP-OLS, and VIIRS Nightlights satellite imagery originally
    from Google Earth Engine under the names
        Landsat 8: `LANDSAT/LC08/C01/T1_SR`
        Landsat 7: `LANDSAT/LE07/C01/T1_SR`
        Landsat 5: `LANDSAT/LT05/C01/T1_SR`
         DMSP-OLS: `NOAA/DMSP-OLS/CALIBRATED_LIGHTS_V4`
            VIIRS: `NOAA/VIIRS/DNB/MONTHLY_V1/VCMCFG`.
    The labels come from surveys conducted through the DHS Program:
        https://dhsprogram.com/data/available-datasets.cfm

    All of the images and surveys are processed in a manner similar to
        https://github.com/sustainlab-group/africa_poverty

    Supported `split_scheme`:
        'official' and `countries`, which are equivalent

    Input (x):
        224 x 224 x 8 satellite image, with 7 channels from Landsat and
        1 nighttime light channel from DMSP/VIIRS. These images have not been
        mean / std normalized.

    Output (y):
        y is a real-valued asset wealth index. Higher value corresponds to more
        asset wealth.

    Metadata:
        Each image is annotated with location coordinates (lat/lon, noised for
        anonymity), survey year, urban/rural classification, country.

    Website: https://github.com/sustainlab-group/africa_poverty

    Original publication:
    @article{yeh2020using,
        author = {Yeh, Christopher and Perez, Anthony and Driscoll, Anne and
                  Azzari, George and Tang, Zhongyi and Lobell, David and
                  Ermon, Stefano and Burke, Marshall},
        day = {22},
        doi = {10.1038/s41467-020-16185-w},
        issn = {2041-1723},
        journal = {Nature Communications},
        month = {5},
        number = {1},
        title = {{Using publicly available satellite imagery and deep learning to
                  understand economic well-being in Africa}},
        url = {https://www.nature.com/articles/s41467-020-16185-w},
        volume = {11},
        year = {2020}
    }

    License:
        LandSat/DMSP/VIIRS data is U.S. Public Domain.
    """
    _dataset_name = 'poverty'
    _versions_dict = {
        '1.0': {
            'download_urls': {
                {'url': 'dhs_AL_DR.tar.gz',
                 'size': 16_472_693_417},
                {'url': 'dhs_EG_HT.tar.gz',
                 'size': 13_579_206_686},
                {'url': 'dhs_IA_IA.tar.gz',
                 'size': 24_046_259_399},
                {'url': 'dhs_ID_MZ.tar.gz',
                 'size': 18_386_761_224},
                {'url': 'dhs_NG_SZ.tar.gz',
                 'size': 18_911_963_362},
                {'url': 'dhs_TD_ZW.tar.gz',
                 'size':  9_024_655_370},
                {'url': 'dhs_final_labels.csv',
                 'size':     19_356_345}
            }
        }
    }

    def __init__(self, version=None, root_dir='data', download=False,
                 split_scheme='official',
                 no_nl=False, fold='A', oracle_training_set=False,
                 use_ood_val=True,
                 cache_size=100):
        self._version = version
        self._data_dir = self.initialize_data_dir(root_dir, download)

        self._split_dict = {'train': 0, 'id_val': 1, 'id_test': 2, 'val': 3, 'test': 4}
        self._split_names = {'train': 'Train', 'id_val': 'ID Val', 'id_test': 'ID Test', 'val': 'OOD Val', 'test': 'OOD Test'}

        if split_scheme=='official':
            split_scheme = 'countries'
        self._split_scheme = split_scheme
        if self._split_scheme != 'countries':
            raise ValueError("Split scheme not recognized")

        self.oracle_training_set = oracle_training_set

        self.no_nl = no_nl
        if fold not in {'A', 'B', 'C', 'D', 'E'}:
            raise ValueError("Fold must be A, B, C, D, or E")

        self.root = Path(self._data_dir)
        self.metadata = pd.read_csv(self.root / 'dhs_metadata.csv')
        # country folds, split off OOD
        country_folds = SURVEY_NAMES[f'2009-17{fold}']

        self._split_array = -1 * np.ones(len(self.metadata))

        incountry_folds_split = np.arange(len(self.metadata))
        # take the test countries to be ood
        idxs_id, idxs_ood_test = split_by_countries(incountry_folds_split, country_folds['test'], self.metadata)
        # also create a validation OOD set
        idxs_id, idxs_ood_val = split_by_countries(idxs_id, country_folds['val'], self.metadata)
        for split in ['test', 'val', 'id_test', 'id_val', 'train']:
            # keep ood for test, otherwise throw away ood data
            if split == 'test':
                idxs = idxs_ood_test
            elif split == 'val':
                idxs = idxs_ood_val
            else:
                idxs = idxs_id
                num_eval = 2000
                # if oracle, do 50-50 split between OOD and ID
                if split == 'train' and self.oracle_training_set:
                    idxs = subsample_idxs(incountry_folds_split, num=len(idxs_id), seed=ord(fold))[num_eval:]
                elif split != 'train' and self.oracle_training_set:
                    eval_idxs = subsample_idxs(incountry_folds_split, num=len(idxs_id), seed=ord(fold))[:num_eval]
                elif split == 'train':
                    idxs = subsample_idxs(idxs, take_rest=True, num=num_eval, seed=ord(fold))
                else:
                    eval_idxs  = subsample_idxs(idxs, take_rest=False, num=num_eval, seed=ord(fold))

                if split != 'train':
                    if split == 'id_val':
                        idxs = eval_idxs[:num_eval//2]
                    else:
                        idxs = eval_idxs[num_eval//2:]
            self._split_array[idxs] = self._split_dict[split]

        if not use_ood_val:
            self._split_dict = {'train': 0, 'val': 1, 'id_test': 2, 'ood_val': 3, 'test': 4}
            self._split_names = {'train': 'Train', 'val': 'ID Val', 'id_test': 'ID Test', 'ood_val': 'OOD Val', 'test': 'OOD Test'}

        self._y_array = torch.from_numpy(np.asarray(self.metadata['wealthpooled'])[:, np.newaxis]).float()
        self._y_size = 1

        # add country group field
        country_to_idx = {country: i for i, country in enumerate(DHS_COUNTRIES)}
        self.metadata['country'] = [country_to_idx[country] for country in self.metadata['country'].tolist()]
        self._metadata_map = {'country': DHS_COUNTRIES}
        self._metadata_array = torch.from_numpy(self.metadata[['urban', 'wealthpooled', 'country']].astype(float).to_numpy())
        # rename wealthpooled to y
        self._metadata_fields = ['urban', 'y', 'country']

        self._eval_grouper = CombinatorialGrouper(
            dataset=self,
            groupby_fields=['urban'])

        super().__init__(root_dir, download, split_scheme)

    def get_input(self, idx):
        """
        Returns x for a given idx.
        """
        img = np.load(self.root / 'images' / f'landsat_poverty_img_{idx}.npz')['x']
        if self.no_nl:
            img[-1] = 0
        img = torch.from_numpy(img).float()

        return img

    def eval(self, y_pred, y_true, metadata, prediction_fn=None):
        """
        Computes all evaluation metrics.
        Args:
            - y_pred (Tensor): Predictions from a model
            - y_true (LongTensor): Ground-truth values
            - metadata (Tensor): Metadata
            - prediction_fn (function): Only None supported
        Output:
            - results (dictionary): Dictionary of evaluation metrics
            - results_str (str): String summarizing the evaluation metrics
        """
        assert prediction_fn is None, "PovertyMapDataset.eval() does not support prediction_fn"

        metrics = [MSE(), PearsonCorrelation()]

        all_results = {}
        all_results_str = ''
        for metric in metrics:
            results, results_str = self.standard_group_eval(
                metric,
                self._eval_grouper,
                y_pred, y_true, metadata)
            all_results.update(results)
            all_results_str += results_str
        return all_results, all_results_str
