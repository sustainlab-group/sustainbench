---
layout: default
title: Brick Kiln Classification
parent: Datasets
---
# Brick Kiln Classification (Bangladesh)

Monitoring compliance with environmental regulations is a key step to combat climate change. In South Asia, brick manufacturing is a major source of pollution, but because it is an informal industry, it is difficult to monitor and regulate, especially for low-income governments [1]. Automatically identifying brick kilns from satellite imagery is a low-cost, scalable approach to monitor sources of pollution and study their effect on nearby populations.

<p style="text-align: center">
    <img src="{{ site.baseurl }}/assets/images/yeskiln.png" width="200" title="Example of a 'Yes Kiln' (Class 1) Image">
    <img src="{{ site.baseurl }}/assets/images/nokiln.png" width="200" title="Example of a 'No Kiln' (Class 2) Image">
</p>

## Details

Lee, Brooks, et al. [1] developed a model to classify high-resolution imagery as containing a brick kiln or not (and used gradient attribution to identify the exact location of the kiln). We focus on the task of classification, where "no kiln" (class 0) means no kiln is present in the image and "yes kiln" class 1 means there is a kiln present. The high-res imagery used in [1] was not released publicly because it was proprietary, so we provide a low-resolution alternative using Sentinel-2 imagery from Google Earth Engine. We retrieve 13 bands, B1 through B12, as documented in the [Earth Engine catalog](https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S2_SR#bands). The imagery is from October 2018 to May 2019, matching the time period from which the ground truth kiln locations were found [1]. There are 6,329 positive examples and 67,284 negative examples total. We provide a train, validation, and test split of 80-10-10 that preserves the relative proportions of classes across the splits. We evaluate models by using overall accuracy, precision, recall, and AUC score.


## Data Format
### Input
64x64 crops of Sentinel-2 imagery from October 2018 - May 2019 covering Bangladesh.
### Output
A predicted class of 0 'no kiln' or 1 'yes kiln'.

## Dataloader Configuration
To load the ``Brick Kiln Classification`` dataset, use ``brick_kiln`` in the SustainBench dataloader.

## Download
The data can be downloaded [here](https://drive.google.com/drive/folders/1VvDQHTorD8sa6YJ6_Z9UoEFGu7QpR2dT).

## Notes

Sentinel 2 (10m resolution) imagery is used as input for this task. We retrieve 13 bands, B1 through B12, as documented in the [Earth Engine catalog](https://developers.google.com/earth-engine/datasets/catalog/COPERNICUS_S2_SR#bands). To use blue, green, and red data, refer to bands B2, B3, and B4, respectively. Labels have been generated automatically from the brick kiln coordinate locations provided in [1].

## Citation
```
@article{lee2021scalable,
	author = {Lee, Jihyeon and Brooks, Nina R. and Tajwar, Fahim and Burke, Marshall and Ermon, Stefano and Lobell, David B. and Biswas, Debashish and Luby, Stephen P.},
	title = {Scalable deep learning to identify brick kilns and aid regulatory capacity},
	volume = {118},
	number = {17},
	elocation-id = {e2018863118},
	year = {2021},
	doi = {10.1073/pnas.2018863118},
	publisher = {National Academy of Sciences},
	issn = {0027-8424},
	URL = {https://www.pnas.org/content/118/17/e2018863118},
	eprint = {https://www.pnas.org/content/118/17/e2018863118.full.pdf},
	journal = {Proceedings of the National Academy of Sciences}
}
```

## References
[1] J. Lee, N. R. Brooks, F. Tajwar, M. Burke, S. Ermon, D. B. Lobell, D. Biswas, and S. P. Luby. Scalable deep learning to identify brick kilns and aid regulatory capacity. Proceedings of the National Academy of Sciences, 118(17), 2021. ISSN 0027-8424. doi: 10.1073/pnas.2018863118.  URL https://www.pnas.org/content/118/17/e2018863118.

