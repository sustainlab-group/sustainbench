from sustainbench import *
import pdb

if __name__ == "__main__":
    dataset = get_dataset('crop_seg')
    img = dataset.get_input(10)
    trainset = dataset.get_subset('train')
    valset = dataset.get_subset('val')
    testset = dataset.get_subset('test')