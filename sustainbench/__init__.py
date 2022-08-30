from .version import __version__  # noqa
from .get_dataset import get_dataset  # noqa

benchmark_datasets = [
    'poverty',
    'fmow',
    'africa_crop_type_mapping',
    'crop_delineation',
    'crop_type_kenya',
    'brick_kiln'
]

additional_datasets = [
    'crop_yield'
]

supported_datasets = benchmark_datasets + additional_datasets
