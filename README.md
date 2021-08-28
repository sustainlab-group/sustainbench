# SustainBench

This repository includes the code and data necessary to reproduce the results and figures for the article "SustainBench: Benchmarks for Monitoring the Sustainable Development Goals with Machine Learning" submitted to the 2021 NeurIPS Conference, Datasets and Benchmarks Track on [OpenReview](https://openreview.net/forum?id=5HR3vCylqD).

Please cite this article as follows, or use the BibTeX entry below.

> citation

```tex
@article{
    TODO
}
```


## Table of Contents

* [Computing Requirements](#computing-requirements)
* [Running Baseline Models](#running-baseline-models)
* [Dataset Preprocessing](#dataset-preprocessing)
* [Code Formatting and Type Checking](#code-formatting-and-type-checking)


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


## Running Baseline Models

We provide baseline models for many of the benchmark tasks included in SustainBench. See the `baseline_models` folder for the code and detailed instructions to reproduce our results.


## Dataset Preprocessing

11 of the 15 SustainBench benchmark tasks involve data that is being publicly released for the first time. We already release the processed versions of our dataset on [Google Drive](https://drive.google.com/drive/folders/1jyjK5sKGYegfHDjuVBSxCoj49TD830wL?usp=sharing). However, we also provide code and detailed instructions for downloading and processing the data in the `dataset_preprocessing` folder. This is NOT necessary for running our baseline models.


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
