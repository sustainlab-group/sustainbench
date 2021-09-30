---
layout: default
title: Field Delineation
parent: "SDG 2: Zero Hunger"
grand_parent: Datasets
---

# Field Delineation (France)

Field delineation is important in developing and managing agricultural-related policies. Given an input satellite image, the goal is to output the delineated boundaries between farm parcels, or the segmentation masks of farm parcels.

<p style="text-align: center">
<img src="{{ site.baseurl }}/assets/images/farmland1.jpg" width="200" title="Sentinel-2 (input)">
<img src="{{ site.baseurl }}/assets/images/farmland2.png" width="200" title="Delineated boundaries">
<img src="{{ site.baseurl }}/assets/images/farmland3.png" width="200" title="Segmentation masks">
</p>


## Details

As introduced in [[1]](#references), the dataset consists of Sentinel-2 satellite imagery in France in 2017. The image has resolution 224x224 corresponding to a 2.24kmx2.24km area on the ground. Each satellite image comes along with the corresponding binary masks of boundaries and areas of farm parcels, which are grey scale images with resolution 224x224. The dataset consists of 1572 training samples, 198 validation samples, and 196 test samples. We use a different data split from Aung et al. to remove overlapping between the train, validation and test split.

## Data format
### Input
The input is an RGB Sentinel-2 image with resolution 224x224.
### Output
The output is a grey scale (single channel) image with resolution 224x224. Depending on the task, the output can be the delineated boundaries between farm parcels or the segmentation masks of farm parcels.

## Dataloader Configuration
To load the ``Field Delineation`` dataset, use ``crop_seg_dataset`` in the SustainBench dataloader.
1. Use ``filled_mask=False`` in the configuration if the task is to predict the delineated boundaries.
2. Use ``filled_mask=True`` if the task is to predict the segmentation masks.

##  Benchmark Details

Given an input satellite image, the goal is to output the delineated boundaries between farm parcels, or the segmentation masks of farm parcels [[1]](#references). Similar to [[1]](#references), given the predicted delineated boundaries of an image, we use the Dice score as the evaluation metric
```math
DICE = 2TP / (2TP + FP + FN)
```
where "TP" denotes True Positive, "FP" denotes False Positive, and "FN" denotes False Negative. As discussed in [[1]](#references), the Dice score Equation has been widely used in image segmentation tasks and is often argued to be a better metric than accuracy when class imbalance between boundary and non-boundary pixels exists.


## Download

The data can be downloaded [here](https://drive.google.com/drive/folders/1GDL1pvlDCcsyEwafe7N41WtS7doFlju3).


## Citation

```bibtex
@inproceedings{aung2020farm,
  title={Farm Parcel Delineation Using Spatio-temporal Convolutional Networks},
  author={Aung, Han Lin and Uzkent, Burak and Burke, Marshall and Lobell, David and Ermon, Stefano},
  booktitle={Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition Workshops},
  pages={76--77},
  year={2020}
}
```

## References

[1] Aung HL, Uzkent B, Burke M, Lobell D, Ermon S. Farm Parcel Delineation Using Spatio-temporal Convolutional Networks. In *Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition Workshops 2020* (pp. 76-77).
