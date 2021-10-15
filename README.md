[**Datasets**](https://sustainlab-group.github.io/sustainbench/docs/datasets/) |
[**Website**](https://sustainlab-group.github.io/sustainbench/) |
[**Raw Data**](https://drive.google.com/drive/folders/1jyjK5sKGYegfHDjuVBSxCoj49TD830wL?usp=sharing) |
[**OpenReview**](https://openreview.net/forum?id=5HR3vCylqD)

# SustainBench: Benchmarks for Monitoring the Sustainable Development Goals with Machine Learning

[Christopher Yeh](https://chrisyeh96.github.io/), [Chenlin Meng](https://cs.stanford.edu/~chenlin/), [Sherrie Wang](http://stanford.edu/~sherwang/), Anne Driscoll, [Erik Rozi](https://www.linkedin.com/in/erik-rozi/), Patrick Liu, [Jihyeon Lee](https://jlee24.github.io/), [Marshall Burke](http://web.stanford.edu/~mburke/), [David B. Lobell](https://fse.fsi.stanford.edu/people/david_lobell), [Stefano Ermon](https://cs.stanford.edu/~ermon/)

**California Institute of Technology, Stanford University, and UC Berkeley**

SustainBench is a collection of 15 benchmark tasks across 7 SDGs, including tasks related to economic development, agriculture, health, education, water and sanitation, climate action, and life on land. **Datasets for 11 of the 15 tasks are released publicly for the first time.** Our goals for SustainBench are to
1. lower the barriers to entry for the machine learning community to contribute to measuring and achieving the SDGs;
2. provide standard benchmarks for evaluating machine learning models on tasks across a variety of SDGs; and
3. encourage the development of novel machine learning methods where improved model performance facilitates progress towards the SDGs.


## Table of Contents

* [Overview](#overview)
* [Dataloaders](#dataloaders)
* [Running Baseline Models](#running-baseline-models)
* [Dataset Preprocessing](#dataset-preprocessing)
* [Computing Requirements](#computing-requirements)
* [Code Formatting and Type Checking](#code-formatting-and-type-checking)
* [Citation](#citation)


## Overview

SustainBench provides datasets and standardized benchmarks for 15 SDG-related tasks, listed below. Details for each dataset and task can be found in our [**paper**](https://openreview.net/forum?id=5HR3vCylqD) and on our [**website**](https://sustainlab-group.github.io/sustainbench/). The raw data can be downloaded from [**Google Drive**](https://drive.google.com/drive/folders/1jyjK5sKGYegfHDjuVBSxCoj49TD830wL?usp=sharing) and is released under a [CC-BY-SA 4.0 license](https://creativecommons.org/licenses/by-sa/4.0/).

<img src="https://github.com/sustainlab-group/sustainbench/blob/gh-pages/assets/images/fig1.png" width="600">

- **SDG 1: No Poverty**
  - [Task 1A](https://sustainlab-group.github.io/sustainbench/docs/datasets/dhs.html): Predicting poverty over space
  - [Task 1B](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg1/change_in_poverty.html): Predicting change in poverty over time
- **SDG 2: Zero Hunger**
  - [Task 2A](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg2/weakly_supervised_cropland.html): Cropland mapping
  - [Task 2B1](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg2/crop_type_mapping_ghana-ss.html): Crop type mapping, in Ghana in South Sudan
  - [Task 2B2](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg2/crop_type_mapping_kenya.html): Crop type mapping, in Kenya
  - [Task 2C](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg2/crop_yield.html): Crop yield prediction
  - [Task 2D](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg2/field_delineation.html): Field delineation
- **SDG 3: Good Health and Well-being**
  - [Task 3A](https://sustainlab-group.github.io/sustainbench/docs/datasets/dhs.html): Child mortality rate
  - [Task 3B](https://sustainlab-group.github.io/sustainbench/docs/datasets/dhs.html): Women BMI
- **SDG 4: Quality Education**
  - [Task 4A](https://sustainlab-group.github.io/sustainbench/docs/datasets/dhs.html): Women educational attainment
- **SDG 6: Clean Water and Sanitation**
  - [Task 6A](https://sustainlab-group.github.io/sustainbench/docs/datasets/dhs.html): Clean water
  - [Task 6B](https://sustainlab-group.github.io/sustainbench/docs/datasets/dhs.html): Sanitation
- **SDG 13: Climate Action**
  - [Task 13A](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg13/brick_kiln.html): Brick kiln classification
- **SDG 15: Life on Land**
  - [Task 15A](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg15/land_cover_representation.html): Feature learning for land cover classification
  - [Task 15B](https://sustainlab-group.github.io/sustainbench/docs/datasets/sdg15/out_of_domain_land_cover.html): Out-of-domain land cover classification


## Dataloaders

For each dataset, we provide Python dataloaders that load the data as PyTorch tensors. Please see the `sustainbench` folder as well as our [website](https://sustainlab-group.github.io/sustainbench/) for detailed documentation.


## Running Baseline Models

We provide baseline models for many of the benchmark tasks included in SustainBench. See the `baseline_models` folder for the code and detailed instructions to reproduce our results.


## Dataset Preprocessing

11 of the 15 SustainBench benchmark tasks involve data that is being publicly released for the first time. We release the processed versions of our datasets on [Google Drive](https://drive.google.com/drive/folders/1jyjK5sKGYegfHDjuVBSxCoj49TD830wL?usp=sharing). However, we also provide code and detailed instructions for how we preprocessed the datasets in the `dataset_preprocessing` folder. You do NOT need anything from the `dataset_preprocessing` folder for downloading the processed datasets or running our baseline models.


## Computing Requirements

This code was tested on a system with the following specifications:

- operating system: Ubuntu 16.04.7 LTS
- CPU: Intel(R) Xeon(R) CPU E5-2620 v4
- memory (RAM): 125 GB
- disk storage: 5 TB
- GPU: NVIDIA P100 GPU

The main software requirements are Python 3.7 with TensorFlow r1.15, PyTorch 1.9, and R 4.1. The complete list of required packages and library are listed in the two conda environment YAML files (`env_create.yml` and `env_bench.yml`), which are meant to be used with `conda` (version 4.10). See [here](https://docs.conda.io/projects/conda/en/latest/user-guide/install/) for instructions on installing conda via Miniconda. Once conda is installed, run one of the following commands to set up the desired conda environment:

```bash
conda env update -f env_create.yml --prune
conda env update -f env_bench.yml --prune
```

The conda environment files default to CPU-only packages. If you have a GPU, please comment/uncomment the appropriate lines in the environment files; you may need to also install CUDA 10 or 11 and cuDNN 7.


## Code Formatting and Type Checking

This repo uses [flake8](https://flake8.pycqa.org/) for Python linting and [mypy](https://mypy.readthedocs.io/) for type-checking. Configuration files for each are included in this repo: `.flake8` and `mypy.ini`.

To run either code linting or type checking, set the current directory to the repo root directory. Then run any of the following commands:

```bash
# LINTING
# =======

# entire repo
flake8

# all modules within utils directory
flake8 utils

# a single module
flake8 path/to/module.py

# a jupyter notebook - ignore these error codes, in addition to the ignored codes in .flake8:
# - E305: expected 2 blank lines after class or function definition
# - E402: Module level import not at top of file
# - F404: from __future__ imports must occur at the beginning of the file
# - W391: Blank line at end of file
jupyter nbconvert path/to/notebook.ipynb --stdout --to script | flake8 - --extend-ignore=E305,E402,F404,W391


# TYPE CHECKING
# =============

# entire repo
mypy .

# all modules within utils directory
mypy -p utils

# a single module
mypy path/to/module.py

# a jupyter notebook
mypy -c "$(jupyter nbconvert path/to/notebook.ipynb --stdout --to script)"
```


## Citation

Please cite this article as follows, or use the BibTeX entry below.

> C. Yeh, C. Meng, S. Wang, A. Driscoll, E. Rozi, P. Liu, J. Lee, M. Burke, D. B. Lobell, and S. Ermon, "SustainBench: Benchmarks for Monitoring the Sustainable Development Goals with Machine Learning," in _Thirty-fifth Conference on Neural Information Processing Systems Datasets and Benchmarks Track (Round 2)_, Dec. 2021. [Online]. Available: [https://openreview.net/forum?id=5HR3vCylqD](https://openreview.net/forum?id=5HR3vCylqD).

```tex
@inproceedings{
    yeh2021sustainbench,
    title = {{SustainBench: Benchmarks for Monitoring the Sustainable Development Goals with Machine Learning}},
    author = {Christopher Yeh and Chenlin Meng and Sherrie Wang and Anne Driscoll and Erik Rozi and Patrick Liu and Jihyeon Lee and Marshall Burke and David B. Lobell and Stefano Ermon},
    booktitle = {Thirty-fifth Conference on Neural Information Processing Systems Datasets and Benchmarks Track (Round 2)},
    year = {2021},
    month = {12},
    url = {https://openreview.net/forum?id=5HR3vCylqD}
}
```
