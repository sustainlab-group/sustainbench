import sustainbench

def get_dataset(dataset, version=None, **dataset_kwargs):
    """
    Returns the appropriate SustainBench dataset class.
    Input:
        dataset (str): Name of the dataset
        version (str): Dataset version number, e.g., '1.0'.
                       Defaults to the latest version.
        dataset_kwargs: Other keyword arguments to pass to the dataset constructors.
    Output:
        The specified SustainBenchDataset class.
    """
    if version is not None:
        version = str(version)

    if dataset not in sustainbench.supported_datasets:
        raise ValueError(f'The dataset {dataset} is not recognized. Must be one of {sustainbench.supported_datasets}.')

    if dataset == 'poverty':
        if version == '1.0':
            from sustainbench.datasets.archive.poverty_v1_0_dataset import PovertyMapDataset
        else:            
            from sustainbench.datasets.poverty_dataset import PovertyMapDataset
        return PovertyMapDataset(version=version, **dataset_kwargs)

    elif dataset == 'fmow':
        if version == '1.0':
            from sustainbench.datasets.archive.fmow_v1_0_dataset import FMoWDataset
        else:
            from sustainbench.datasets.fmow_dataset import FMoWDataset
        return FMoWDataset(version=version, **dataset_kwargs)

    elif dataset == 'africa_crop_type_mapping':
        from sustainbench.datasets.croptypemapping_dataset import CropTypeMappingDataset
        return CropTypeMappingDataset(version=version, **dataset_kwargs)

    elif dataset == 'crop_seg':
        if version == '1.0':
            from sustainbench.datasets.archive.crop_seg_v1_0_dataset import CropSegmentationDataset
        else:
            from sustainbench.datasets.crop_seg_dataset import CropSegmentationDataset
        return CropSegmentationDataset(version=version, **dataset_kwargs)
    
    elif dataset == 'crop_yield':
        from sustainbench.datasets.crop_yield_dataset import CropYieldDataset
        return CropYieldDataset(version=version, **dataset_kwargs)
    
    elif dataset == 'brick_kiln':
        from sustainbench.datasets.brickkiln_dataset import BrickKilnDataset
        return BrickKilnDataset(version=version, **dataset_kwargs)

