---
layout: default
title: Crop Type Mapping (Kenya)
parent: "SDG 2: Zero Hunger"
grand_parent: Datasets
---

# Crop Type Mapping in Kenya

Spatially disaggregated crop type maps are needed to assess agricultural diversity and estimate yields. While crop type maps are produced annually by departments of agriculture in high-income countries across North America and Europe, they are currently not available for middle- and low-income countries. Mapping crop types in smallholder regions faces challenges of small fields, sparse ground truth labels, intercropping, and highly heterogeneous landscapes.

<p style="text-align: center">
<img src="{{ site.baseurl }}/assets/images/crop_type_kenya_example.png" width="600" title="Sentinel-2 time series">
</p>

## Dataset Overview

We release the dataset of crop types in Kenya from [[1]](#references) and [[2]](#references) for the first time. The dataset was collected in the main growing season of 2017 and spans the Bungoma, Busia, and Siaya regions. There are 5,693 fields in total and 39,568 Sentinel-2 satellite pixels (10m spatial resolution). The breakdown by region is summarized in the table below.

|               | Bungoma | Busia  | Siaya | Total  |
|:--------------|--------:|-------:|------:|-------:|
| # fields      |   2,098 |  1,957 | 1,638 |  5,693 |
| # time series |  17,039 | 13,123 | 9,406 | 39,568 |

### Input
The inputs are time series of Sentinel-2 satellite observations at single pixels for the entire year. We release a dataset of single pixels instead of images for Sentinel-2 because the resolution of Sentinel-2 (10m) is coarse relative to the field sizes in the region.

### Output
The labels are crop type obtained through ground surveys completed in 2017. There are nine classes: banana, beans, cassava, groundnut, maize, non-crop, other, sugarcane, and sweet potatoes.

### Training, validation, and test set splits
We offer the user a few options for train, validation, and test set splits. The first is a random split at the field level; this split is appropriate for algorithms seeking simply to classify crop type from satellite time series in a smallholder system like Kenya. The second is splitting along regions, as done in [[1]](#references). One region (e.g., Bungoma) comprises the train/val sets and the other two comprise the test set. This split is appropriate for developing and evaluating transfer learning algorithms, which are needed in these label-scarce settings to create large-scale crop type maps.

## Dataloader Configuration

To load the ``Crop Type Mapping (Kenya)`` dataset, use ``crop_type_kenya`` in the SustainBench dataloader. Use ``training_set='Bungoma'`` to set the training set to Bungoma (likewise for Busia and Siaya). To set a random field-level split, use ``training_set='random'``.

## Download

The data can be downloaded [here](https://drive.google.com/drive/folders/1Rq1F-ys-rkjftAUnbdGJ1T6udsZWnEyo?usp=sharing).


## Citation

Please cite Kluger et al. (2021) for the baseline model.
```bibtex
@article{kluger2021two,
  Author = {Dan M. Kluger and Sherrie Wang and David B. Lobell},
  Journal = {Remote Sensing of Environment},
  Pages = {112488},
  Title = {Two shifts for crop mapping: Leveraging aggregate crop statistics to improve satellite-based maps in new regions},
  Volume = {262},
  Year = {2021}}
```

## References

[1] D. M. Kluger, S. Wang, and D. B. Lobell. Two shifts for crop mapping: Leveraging aggregate crop statistics to improve satellite-based maps in new regions. Remote Sensing of Environment, 262:112488, 2021.

[2] Z. Jin, G. Azzari, C. You, S. Di Tommaso, S. Aston, M. Burke, and D. B. Lobell. Smallholder maize area and yield mapping at national scales with google earth engine.Remote Sensing of Environment, 228:115–128, 2019.
