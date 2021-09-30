---
layout: default
title: Get Started
nav_order: 3
---

# Overview

SustainBench is an open-source Python package that provides a standardized interface for sustainability datasets. It contains data loaders which handle data download, processing, and splits, and dataset evaluators which standardize model evaluation. The SustainBench dataloader structure is heavily inspired by [WILDS](https://wilds.stanford.edu).

## Installation

We recommend installing SustainBench from the GitHub source:
```bash
git clone https://github.com/sustainlab-group/sustainbench.git
```

## Requirements

This code was tested on a system with the following specifications:

```
operating system: Ubuntu 16.04.7 LTS
CPU: Intel(R) Xeon(R) CPU E5-2620 v4
memory (RAM): 125 GB
disk storage: 5 TB
GPU: NVIDIA P100 GPU
```

The main software requirements are Python 3.7 with TensorFlow r1.15, PyTorch 1.9, and R 4.1. The complete list of required packages and library are listed in the two conda environment YAML files (``env_create.yml`` and ``env_bench.yml``), which are meant to be used with conda (version 4.10). See [here](https://docs.conda.io/projects/conda/en/latest/user-guide/install/) for instructions on installing conda via Miniconda. Once conda is installed, run one of the following commands to set up the desired conda environment:

```bash
conda env update -f env_create.yml --prune
conda env update -f env_bench.yml --prune
```

The conda environment files default to CPU-only packages. If you have a GPU, please comment/uncomment the appropriate lines in the environment files; you may need to also install CUDA 10 or 11 and cuDNN 7.

## Downloading and training on SustainBench

If running these scripts for the first time, you may need to download the datasets. Due to a quota on data downloads on Google Drive, we have disabled automatic download for SustainBench datasets. Manual download instructions for datasets are provided in each respective dataset web page.

### Evaluate trained models

We use a similar evaluation script as [WILDS](https://wilds.stanford.edu) which aggregates prediction CSV files and reports on combined evaluation. To use this, run

```bash
python examples/evaluate.py <predictions_dir> <output_dir> --root-dir <root_dir>
```

## Using the SustainBench package
### Data
SustainBench provides a standardized interface for all datasets in the benchmark.

```python
>>> from sustainbench import get_dataset
>>> from sustainbench.common.data_loaders import get_train_loader
>>> import torchvision.transforms as transforms

# Load the full dataset, and download it if necessary
>>> dataset = get_dataset(dataset='dhs_dataset')

# Get the training set
>>> train_data = dataset.get_subset('train')

# Prepare the standard data loader
>>> train_loader = get_train_loader('standard', train_data, batch_size=16)

# Train loop
>>> for x, y_true, metadata in train_loader:
...   ...
```

### Evaluators

SustainBench standardizes evaulation for each dataset.

```python
>>> from sustainbench.common.data_loaders import get_eval_loader

# Get the test set
>>> test_data = dataset.get_subset('test')

# Prepare the data loader
>>> test_loader = get_eval_loader('standard', test_data, batch_size=16)

# Get predictions for the full test set
>>> for x, y_true, metadata in test_loader:
...   y_pred = model(x)
...   [accumulate y_true, y_pred, metadata]

# Evaluate
>>> dataset.eval(all_y_pred, all_y_true, all_metadata)
{'recall_macro_all': 0.66, ...}
```