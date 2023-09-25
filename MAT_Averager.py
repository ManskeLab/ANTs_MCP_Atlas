from scipy import io
import argparse
import os
import numpy as np

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("input_dir", type=str)
    parser.add_argument("output_path", type=str)
    args = parser.parse_args()

    input_dir = args.input_dir
    output_path = args.output_path

    averaged_transform = False
    count = 0
    key_name = False

    for transform in os.listdir(input_dir):
        if 'mat' in transform:
            transform_path = os.path.join(input_dir, transform)
            transform_mat = io.loadmat(transform_path)

            if not key_name: 
                for key in transform_mat:
                    if 'Transform' in key:
                        key_name = key
                        if not averaged_transform:
                            averaged_transform = transform_mat.copy()
                            averaged_transform[key] = np.zeros(averaged_transform[key].shape)

            averaged_transform[key_name] += transform_mat[key_name]
            count += 1
    
    averaged_transform[key_name] = averaged_transform[key_name]/count

    io.savemat(output_path, averaged_transform)
                    


