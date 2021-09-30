---
layout: default
title:  Out-of-Domain Land Cover Classification
parent: "SDG 15: Life on Land"
grand_parent: Datasets
---

# Out-of-Domain Land Cover Classification

While ground truth labels are scarce in low-income regions, they can be plentiful in high-income regions. This suggests that a second strategy for increasing performance in label-scarce regions is to transfer knowledge learned from classifying land cover in high-income regions to low-income ones.

<p style="text-align: center">
<img src="{{ site.baseurl }}/assets/images/land_cover_ood_example.png" width="900" title="Two example tasks with example support time series from the MODIS satellite.">
</p>

## Dataset Overview

We release the global dataset of satellite time series from [[1]](#references). The dataset contains data from 692 regions of size 10km x 10km around the globe; for each region, 500 latitude/longitude coordinates are sampled for their satellite time series and land cover type.

<p style="text-align: center">
<img src="{{ site.baseurl }}/assets/images/modis_task_map.png" width="500" title="Global regions split by continent into training, validation, and test sets.">
</p>

### Input
The input is time series from the MODIS satellite over the course of a year. Specifically, in each region, 500 points were sampled uniformly at random. At each point, the MODIS Terra Surface Reflectance 8-Day time series was exported for January 1, 2018 to December 31, 2018. MODIS collects 7 bands and NDVI was computed as an eighth feature, resulting in time series of dimension 8 x 46.

### Output
The output is land cover type at the pixel in 2018. Global land cover labels came from the MODIS Terra+Aqua Combined Land Cover Product, which classifies every 500m-by-500m pixel into one of 17 land cover classes (e.g., grassland, cropland, desert).

### Task
[1] defined a task as 1-shot, 2-way land cover classification tasks in each region. Unlike other classification benchmarks in SustainBench, this benchmark uses the kappa statistic to evaluate models because accuracy and F1-scores can vary widely across regions depending on the class distribution, and it is not clear whether an accuracy or F1-score is good or bad from the values alone.

### Meta-training, meta-validation, and meta-test set splits
The authors in [[1]](#references) sampled 1000 regions uniformly at random from the Earth's land surface, and removed regions that have fewer than 2 unique land cover classes and regions where one land cover type comprises more than 80% of the region's area. This resulted in 692 regions. The authors placed the 103 regions from Sub-Saharan Africa into the meta-test set and split the remainder into 485 meta-train and 104 meta-val regions at random. We provide the user with the option of placing any continent into the meta-test set and splitting the other continents' regions at random between the meta-train and meta-val sets.

We note that, as previously mentioned, existing land cover products tend to be less accurate in low-income regions such as Sub-Saharan Africa than in high-income regions. As a result, the MODIS land cover product used as ground truth will have errors in low-income regions. We suggest users also apply meta-learning and other transfer learning algorithms using other continents (e.g., North America, Europe) as the meta-test set for algorithm evaluation purposes.

## Dataloader Configuration

To load the ``Out-of-Domain Land Cover Classification`` dataset, use ``out_of_domain_land_cover`` in the SustainBench dataloader.

## Download

The data can be downloaded [here](https://drive.google.com/drive/folders/138EeHCXxYJZ_OdNqgcn4olY2-CCxEnVa?usp=sharing).


## Citation

```bibtex
@inproceedings{wang2020meta,
  author={Wang, Sherrie and Rußwurm, Marc and Körner, Marco and Lobell, David B.},
  booktitle={IGARSS 2020 - 2020 IEEE International Geoscience and Remote Sensing Symposium},
  title={Meta-Learning For Few-Shot Time Series Classification},
  year={2020},
  pages={7041-7044},
  doi={10.1109/IGARSS39084.2020.9441016}}
```

## References

[1] S. Wang, M. Rußwurm, M. Körner, and D. B. Lobell. Meta-learning for few-shot time series classification. In IGARSS 2020 - 2020 IEEE International Geoscience and Remote Sensing Symposium, pages 7041–7044, 2020. doi: 10.1109/IGARSS39084.2020.9441016.
