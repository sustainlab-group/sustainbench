---
layout: default
title: Representation Learning for Land Cover
parent: "SDG 15: Life on Land"
grand_parent: Datasets
---

# Representation Learning for Land Cover Classification

Existing state-of-the-art land cover maps are significantly more accurate in high-income regions than low-income ones, as the latter have few ground truth labels. One approach to increase the performance of land cover classification in regions with few labels is to use unsupervised or self-supervised learning to improve satellite/aerial image representations, so that downstream tasks require fewer labels to perform well.

<p style="text-align: center">
<img src="{{ site.baseurl }}/assets/images/tile2vec_examples.jpg" width="400" title="NAIP image and label examples">
</p>

## Dataset Overview

We release the full high-resolution aerial imagery dataset from [[1]](#references), which covers a 2500 square kilometer (12 billion pixel) area of Central Valley, CA in the United States. The study region spans latitudes [36.45, 37.05] and longitudes [-120.25, -119.65].

<p style="text-align: center">
<img src="{{ site.baseurl }}/assets/images/tile2vec_study_region.png" width="600" title="Study area in Central Valley, CA, USA">
</p>

### Input
The input uses imagery from the USDA's National Agriculture Imagery Program (NAIP), which provides aerial imagery for public use that has four spectral bands (red (R), green (G), blue (B), and infrared (N)) at 0.6 m ground resolution. The test set input is tiles of size 100x100 px with four channels.

### Output
The output is image-level land cover classification (66 possible classes), where labels are generated from a high-quality USDA dataset [[2]](#references). Since our 100x100 px NAIP tiles and the USDA land cover dataset are not perfectly aligned, the land cover class used for the label is the mode across pixels in the tile.

### Training, validation, and test set splits
The region is divided in geographically-continuous blocks into train, validation, and test sets. The user is free to use the training imagery in any way to learn representations, and we provide a test set of up to 200,000 tiles (100x100 px) for evaluation. The evaluation metrics are overall accuracy and macro F1-score.

## Dataloader Configuration
To load the ``Representation Learning for Land Cover Classification`` dataset, use ``land_cover_representation`` in the SustainBench dataloader.

## Download
The data can be downloaded [here](https://drive.google.com/drive/folders/1BMLTD8rFMzMF-GpjvwQ3HB4Hx6fzTxxF?usp=sharing).


## Citation

```bibtex
@article{jean2019tile2vec,
    Author = {Jean, Neal and Wang, Sherrie and Samar, Anshul and Azzari, George and Lobell, David and Ermon, Stefano},
    Journal = {Proceedings of the AAAI Conference on Artificial Intelligence},
    Month = {Jul.},
    Number = {01},
    Pages = {3967-3974},
    Title = {Tile2Vec: Unsupervised Representation Learning for Spatially Distributed Data},
    Volume = {33},
    Year = {2019}}
```

## References

[1] N. Jean, S. Wang, A. Samar, G. Azzari, D. Lobell, and S. Ermon. Tile2vec: Unsupervised representation learning for spatially distributed data. Proceedings of the AAAI Conference on Artificial Intelligence, 33(01):3967–3974, Jul. 2019.

[2] National Agricultural Statistics Service. USDA National Agricultural Statistics Service Cropland Data Layer. Published crop-specific data layer [Online], 2018. URL [https://nassgeodata.594gmu.edu/CropScape/](https://nassgeodata.594gmu.edu/CropScape/).
