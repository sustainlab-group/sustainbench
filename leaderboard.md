---
layout: page
title: Leaderboard
permalink: /leaderboard/
nav_order: 5
use_math: true
---

# Leaderboard

Below, we list individual leaderboards for each dataset task.

A `**` for the rank of a model indicates that the model was either trained or tested on a similar (but different) dataset from what is included in SustainBench. Results from such models should only be treated as an approximate reference for how well a similar model may perform on SustainBench. More information about such models are given in the notes column.

Jump to:
- [Poverty prediction over space](#poverty-prediction-over-space)
- [Poverty prediction over time](#poverty-prediction-over-time)
- [Weakly supervised cropland classification](#weakly-supervised-cropland-classification)
- [Crop type classification](#crop-type-classification)
- [Crop type mapping](#crop-type-mapping)
- [Crop yield prediction](#crop-yield-prediction)
- [Field delineation](#field-delineation)
- [Child mortality rate](#child-mortality-rate)
- [Women BMI](#women-bmi)
- [Women educational attainment](#women-educational-attainment)
- [Water quality index](#water-quality-index)
- [Sanitation index](#sanitation-index)
- [Brick kiln detection](#brick-kiln-detection)
- [Representation learning for land cover](#representation-learning-for-land-cover)
- [Out-of-domain land cover classification](#out-of-domain-land-cover-classification)
- [References](#references)


## Poverty prediction over space

| Rank | Model | Satellite image inputs? | Street-level image inputs? | Test $$r^2$$ | Reference | Date | Code | Notes |
|:-----|:------|:-----|:-----|:-----|:-----|:-----|:-----|:-----|
| 1    | Baseline: KNN | Yes, mean (scalar) nightlights | No | 0.63 | SustainBench [[1](#references)] | 2021-08-27 | [link](https://github.com/sustainlab-group/sustainbench/blob/main/baseline_models/dhs/knn_baseline.ipynb)


## Poverty prediction over time

| Rank | Model | Test $$r^2$$ | Reference | Date | Code | Notes |
|:-----|:------|:-------------|:----------|:-----|:-----|:------|
| **   | Baseline: modified ResNet-18 using all satellite bands | 0.35 | [[2](#references)] | 2020-05-22 | [link](https://github.com/sustainlab-group/africa_poverty) | The locations and labels used in [[2]](#references) are slightly different from what is included in SustainBench. See the appendix of the SustainBench paper [[1]](#references) for more details on the differences.


## Weakly supervised cropland classification

| Rank | Model | Location | F1 score (pixel label) | F1 score (image label) | Reference | Date | Notes |
|:-----|:------|:---------|:-----------------------|:-----------------------|:----------|:-----|:------|
| 1    | U-Net | United States | 0.88 | 0.80 | [[11](#references)] | 2019-06-01 |


## Crop type classification
<!-- ## Crop type mapping -->

| Rank | Model | Location | Macro F1 | Accuracy | Reference | Date | Notes |
|:-----|:------|:---------|:---------|:---------|:----------|:-----|:------|
| 1    | Rustowicz et al. | Ghana       | 57.3 | 60.9% | [[6](#references)] | 2019-06-01 |
| 1    | Rustowicz et al. | South Sudan | 69.7 | 85.3% | [[6](#references)] | 2019-06-01 |


## Crop yield prediction

| Rank | Model | Train countries | Test country | Test RMSE (t/ha) | Reference | Date | Notes |
|:-----|:------|:----------------|:-------------|:-----------------|:----------|:-----|:------|
| 1    | You et al.  | USA               | USA       | 0.37 | [[7](#references)] | 2021-08-27 |
| 1    | Wang et al. | Argentina         | Argentina | 0.62 | [[6](#references)] | 2021-08-27 |
| 1    | Wang et al. | Argentina, Brazil | Brazil    | 0.42 | [[6](#references)] | 2021-08-27 |


## Field delineation

| Rank | Model | Country | Test Dice score | Reference | Date | Code | Notes |
|:-----|:------|:--------|:----------------|:----------|:-----|:-----|:------|
| 1    | Aung et al. | France | 0.61 |[[3](#references)] | 2021-08-27 | [link](https://github.com/sustainlab-group/ParcelDelineation)


## Child mortality rate

| Rank | Model | Satellite image inputs? | Street-level image inputs? | Test $$r^2$$ | Reference | Date | Code | Notes |
|:-----|:------|:-----|:-----|:-----|:-----|:-----|:-----|:-----|
| 1    | Baseline: KNN | Yes, mean (scalar) nightlights | No | 0.01 | SustainBench [[1](#references)] | 2021-08-27 | [link](https://github.com/sustainlab-group/sustainbench/blob/main/baseline_models/dhs/knn_baseline.ipynb)


## Women BMI

| Rank | Model | Satellite image inputs? | Street-level image inputs? | Test $$r^2$$ | Reference | Date | Code | Notes |
|:-----|:------|:-----|:-----|:-----|:-----|:-----|:-----|:-----|
| 1    | Baseline: KNN | Yes, mean (scalar) nightlights | No | 0.42 | SustainBench [[1](#references)] | 2021-08-27 | [link](https://github.com/sustainlab-group/sustainbench/blob/main/baseline_models/dhs/knn_baseline.ipynb)
| **   | GCN (Lee et al.) | No | Yes | 0.57 (India) | [[8](#references)] | 2021-08-27 | [link](https://github.com/sustainlab-group/mapillarygcn) | This model was only trained and tested on India labels. |


## Women educational attainment

| Rank | Model | Satellite image inputs? | Street-level image inputs? | Test $$r^2$$ | Reference | Date | Code | Notes |
|:-----|:------|:-----|:-----|:-----|:-----|:-----|:-----|:-----|
| 1    | Baseline: KNN | Yes, mean (scalar) nightlights | No | 0.26 | SustainBench [[1](#references)] | 2021-08-27 | [link](https://github.com/sustainlab-group/sustainbench/blob/main/baseline_models/dhs/knn_baseline.ipynb)


## Water quality index

| Rank | Model | Satellite image inputs? | Street-level image inputs? | Test $$r^2$$ | Reference | Date | Code | Notes |
|:-----|:------|:-----|:-----|:-----|:-----|:-----|:-----|:-----|
| 1    | Baseline: KNN | Yes, mean (scalar) nightlights | No | 0.40 | SustainBench [[1](#references)] | 2021-08-27 | [link](https://github.com/sustainlab-group/sustainbench/blob/main/baseline_models/dhs/knn_baseline.ipynb)


## Sanitation index

| Rank | Model | Satellite image inputs? | Street-level image inputs? | Test $$r^2$$ | Reference | Date | Code | Notes |
|:-----|:------|:-----|:-----|:-----|:-----|:-----|:-----|:-----|
| 1    | Baseline: KNN | Yes, mean (scalar) nightlights | No | 0.36 | SustainBench [[1](#references)] | 2021-08-27 | [link](https://github.com/sustainlab-group/sustainbench/blob/main/baseline_models/dhs/knn_baseline.ipynb)


## Brick kiln detection

| Rank | Model | Country | Test Accuracy | Reference | Date | Code | Notes |
|:-----|:------|:--------|:--------------|:----------|:-----|:-----|:------|
| **   | Lee et al. | Bangladesh | 94.2% | [[4](#references)] | 2021-08-27 | [link](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/HVGW8L)| [[4](#references)] used higher res images


## Representation learning for land cover

| Rank | Model | Country | Test Accuracy | Reference | Date | Code | Notes |
|:-----|:------|:--------|:--------------|:----------|:-----|:-----|:------|
| 1    | Tile2Vec with ResNet-50 | United States | 0.55 (n= 1,000) 0.58 (n= 10,000) | [[9](#references)] | 2021-08-27 | [link](https://github.com/ermongroup/tile2vec)


## Out-of-domain land cover classification

| Rank | Model | Country | Test Kappa | Reference | Date | Notes |
|:-----|:------|:--------|:-----------|:----------|:-----|:------|
| 1    | MAML with shallow 1D CNN | Global | 0.32 (1-shot, 2-way) | [[10](#references)] | 2021-08-27 |


## References

[1] C. Yeh, C. Meng, S. Wang, A. Driscoll, E. Rozi, P. Liu, J. Lee, M. Burke, D. Lobell, and S. Ermon. SustainBench: Benchmarks for Monitoring the Sustainable Development Goals with Machine Learning. 2021. URL [https://openreview.net/forum?id=5HR3vCylqD&noteId=FL6Sr6Ks0J](https://openreview.net/forum?id=5HR3vCylqD&noteId=FL6Sr6Ks0J).

[2] C. Yeh, A. Perez, A. Driscoll, G. Azzari, Z. Tang, D. Lobell, S. Ermon, and M. Burke. Using publicly available satellite imagery and deep learning to understand economic well-being in Africa. _Nature Communications_, 11(1), 5 2020. ISSN 2041-1723. doi: 10.1038/s41467-020-58916185-w. URL [https://www.nature.com/articles/s41467-020-16185-w](https://www.nature.com/articles/s41467-020-16185-w).

[3] Aung, Han Lin, et al. "Farm Parcel Delineation Using Spatio-temporal Convolutional Networks." Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition Workshops. 2020. URL [https://arxiv.org/abs/2004.05471](https://arxiv.org/abs/2004.05471).

[4] J. Lee, N. R. Brooks, F. Tajwar, M. Burke, S. Ermon, D. B. Lobell, D. Biswas, and S. P. Luby. Scalable deep learning to identify brick kilns and aid regulatory capacity. Proceedings of the National Academy of Sciences, 118(17), 2021. ISSN 0027-8424. doi: 10.1073/pnas.2018863118. URL [https://www.pnas.org/content/118/17/e2018863118](https://www.pnas.org/content/118/17/e2018863118).

[5] R. Rustowicz, R. Cheong, L. Wang, S. Ermon, M. Burke, and D. Lobell. Semantic segmentation of crop type in africa: A novel dataset and analysis of deep learning methods. InProceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR) Workshops, June 2019.

[6] A. X. Wang, C. Tran, N. Desai, D. Lobell, and S. Ermon. Deep transfer learning for crop yield prediction with remote sensing data. In Proceedings of the 1st ACM SIGCAS Conference on Computing and Sustainable Societies, COMPASS ’18, New York, NY, USA, 2018. Association for Computing Machinery. ISBN 9781450358163. doi: 10.1145/3209811.3212707. URL [https://doi.org/10.1145/3209811.3212707](https://doi.org/10.1145/3209811.3212707).

[7] J. You, X. Li, M. Low, D. Lobell, and S. Ermon. Deep gaussian process for crop yield prediction591based on remote sensing data. 2017. URL [https://aaai.org/ocs/index.php/AAAI/592AAAI17/paper/view/14435](https://cs.stanford.edu/~ermon/papers/cropyield_AAAI17.pdf).

[8] J. Lee, D. Grosz, B. Uzkent, S. Zeng, M. Burke, D. Lobell, and S. Ermon. Predicting Livelihood Indicators from Community-Generated Street-Level Imagery. Proceedings of the AAAI Conference on Artificial Intelligence, 35(1):268–276, 5 2021. ISSN 2374-3468. URL [https://ojs.aaai.org/index.php/AAAI/article/view/16101](https://ojs.aaai.org/index.php/AAAI/article/view/16101).

[9] N. Jean, S. Wang, A. Samar, G. Azzari, D. Lobell, and S. Ermon. Tile2vec: Unsupervised representation learning for spatially distributed data. Proceedings of the AAAI Conference on Artificial Intelligence, 33(01):3967–3974, Jul. 2019. URL [https://arxiv.org/abs/1805.02855](https://arxiv.org/abs/1805.02855)

[10] S. Wang, M. Rußwurm, M. Körner, and D. B. Lobell. Meta-learning for few-shot time series classification. In IGARSS 2020 - 2020 IEEE International Geoscience and Remote Sensing Symposium, pages 7041–7044, 2020. doi: 10.1109/IGARSS39084.2020.9441016. URL [https://ieeexplore.ieee.org/document/9441016](https://ieeexplore.ieee.org/document/9441016)

[11] S. Wang, W. Chen, S. M. Xie, G. Azzari, and D. B. Lobell. Weakly supervised deep learning for segmentation of remote sensing imagery.Remote Sensing, 12(2), 2020. URL [https://www.mdpi.com/2072-4292/12/2/207](https://www.mdpi.com/2072-4292/12/2/207)
