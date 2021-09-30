---
layout: default
title: Crop Type Mapping (Ghana and South Sudan)
parent: "SDG 2: Zero Hunger"
grand_parent: Datasets
---

# Crop Type Mapping (Ghana and South Sudan)

Spatially disaggregated crop type maps are needed to assess agricultural diversity and estimate yields. In high-income countries across North America and Europe, crop type maps are produced annually by departments of agriculture using farm surveys and satellite imagery [[1]](#references). However, no such maps are regularly available for middle- and low-income countries. Mapping crop types in the Global South faces challenges of irregularly shaped fields, small fields, sparse ground truth labels, and highly heterogeneous landscapes [[2]](#references).

<p style="text-align: center">
    <img src="{{ site.baseurl }}/assets/images/africa-croptype1.png" width="200" title="Crop Type Mapping Satellite Imagery">
    <img src="{{ site.baseurl }}/assets/images/africa-croptype-truth.png" width="200" title="Crop Type Mapping Semantic Segmentation">
</p>

## Details

We re-release the dataset from Rustowicz et al. [[2]](#references) in Ghana and South Sudan in a format more familiar to the machine learning community. The inputs are growing season time series of imagery from three satellites (Sentinel-1, Sentinel-2, and Planet's PlanetScope) in 2016 and 2017, and the outputs are semantic segmentation of crop types. Ghana samples are labeled for maize, groundnut, rice, and soybean, while South Sudan samples are labeled for maize, groundnut, rice, and sorghum. We use the same train, validation, and test sets as Rustowicz et al. [[2]](#references), which preserve relative percentages of crop types across the splits. We evaluate models by using overall accuracy and macro F1-score obtained by averaging F1-scores across all classes.

## Data Format
### Input
The inputs are growing season variable length time series of imagery from three satellites in 2016 and 2017.
### Output
The outputs are 64x64 pixel semantic segmentations of crop types (one label per series).

## Dataloader Configuration

To load the ``Crop Type Mapping`` dataset, use ``africa_crop_type_mapping`` in the SustainBench dataloader.
1. Use ``split_scheme='ghana'`` in the configuration to load Ghana imagery and ``split_scheme='southsudan'`` to load South Sudan imagery.
2. Use ``calculate_bands=True`` to add additional NDVI and GCVI bands to S2 and PlanetScope Imagery.
3. Use ``normalize=True`` to normalize bands based on precomputed mean and std.
4. Use ``resize_planet=True`` to resize Planetscope imagery to 64x64 pixels (PlanetScope imagery is larger than S1 and S2 imagery by default.)

## Download

The data can be downloaded [here](https://drive.google.com/drive/folders/1WhVObtFOzYFiXBsbbrEGy1DUtv7ov7wF).

## Notes

Sentinel 1 (10m resolution), Sentinel 2 (10m resolution), and Planet's PlanetScope (3m resolution) time series imagery are used as inputs for this task. As described in [[2]](#references), Planet imagery is incorporated to help mitigate issues from high cloud cover and small field sizes. We include three S1 bands (VV, VH, VH/VV), ten S2 bands (blue, green, red, near infrared, four red edge bands, two short wave infared bands), and all four PlanetScope bands (blue, green, red, near infrared). We also construct normalized difference vegetation index (NDVI) and green chlorophyll vegetation index (GCVI) bands for PlanetScope and S2 imagery.

Ground truth labels consist of a 64x64 pixel segmentation map, with each pixel containing a crop label. Ghana locations are labeled for Maize, Groundnut, Rice, and Soya Bean, while South Sudan locations are labeled for Sorghum, Maize, Rice, and Groundnut.

We also highlight key differences between this dataset and the one used in [[2]](#references). We use the same train, validation, and test splits used in [[2]](#references), though we use the full 64x64 imagery provided, while [[2]](#references) further subdivided imagery into 32x32 pixel grids due to memory constraints. We also include variable length time series with zero padding and masking, while [[2]](#references) trimmed the respective time series down to the same length. We include variable length time series with the reasoning that future research should be extendable to variable length time-series imagery. Due to these changes, we do not include baseline models from [[2]](#references) for this iteration of the dataset.

## Citation

```bibtex
@inProceedings{rustowicz2019semantic,
    author = {Rustowicz, Rose and Cheong, Robin and Wang, Lijing and Ermon, Stefano and Burke, Marshall and Lobell, David},
    title = {Semantic Segmentation of Crop Type in Africa: A Novel Dataset and Analysis of Deep Learning Methods},
    booktitle = {Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR) Workshops},
    month = {June},
    year = {2019}
}
```

## References

[1] National Agricultural Statistics Service. USDA National Agricultural Statistics Service Cropland Data Layer. Published crop-specific data layer  [Online]. Available at https://nassgeodata.gmu.edu/CropScape/ (accessed 2019-08-29; verified 2019-08-29), 2018.

[2] R. Rustowicz, R. Cheong, L. Wang, S. Ermon, M. Burke, and D. Lobell. Semantic segmentation of crop type in africa: A novel dataset and analysis of deep learning methods. In *Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR) Workshops*, June 2019.
