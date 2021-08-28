import setuptools
import os
import sys

here = os.path.abspath(os.path.dirname(__file__))
sys.path.insert(0, os.path.join(here, 'SustainBench'))
from version import __version__

print(f'Version {__version__}')

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="SustainBench",
    version=__version__,
    author="SustainLab",
    author_email="temp@cs.stanford.edu", 
    url="https://sustain.stanford.edu",
    description="SustainBench datasets and benchmarks",
    long_description=long_description,
    long_description_content_type="text/markdown",
    install_requires = [
        'numpy>=1.19.1',
        'pandas>=1.1.0',
        'scikit-learn>=0.20.0',
        'pillow>=7.2.0',
        'torch>=1.7.0',
        'tqdm>=4.53.0',
    ],
    license='TBD',
    # packages=setuptools.find_packages(exclude=['dataset_preprocessing', 'examples', 'examples.models', 'examples.models.bert']),
    classifiers=[
        'Topic :: Scientific/Engineering :: Artificial Intelligence',
        'Intended Audience :: Science/Research',
        "Programming Language :: Python :: 3",
        "License :: TBD",
    ],
    python_requires='>=3.6',
)