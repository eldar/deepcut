# Deep(er)Cut: Multi Person Pose Estimation

Here you can find the code that implements [DeepCut](http://arxiv.org/abs/1511.06645)
and [DeeperCut](http://arxiv.org/abs/1605.03170) papers.

## Installation instructions

Only Linux 64bit is supported.

Prerequisites:

- HDF5 1.8
- CMake
- C++ 11
- CUDA >=7.5
- [Caffe building instructions](http://caffe.berkeleyvision.org/installation.html)
- [Gurobi optimizer 6.0.x](https://user.gurobi.com/download/gurobi-optimizer)

```bash
$ git clone https://github.com/eldar/deepcut --recursive

# build Caffe and its Matlab interface, for example, after properly configuring Makefile.config:
$ cd pose/external/caffe
$ make -j 4 all matcaffe

# build liblinear, specify the path to the Matlab installation
$ cd ../liblinear-1.94/matlab
$ CC=gcc CXX=g++ MATLABDIR=/usr/lib/matlab-8.6/ make

$ cd ../../solver
$ cmake . -DGUROBI_ROOT_DIR=/some/path/gurobi603/linux64 -DGUROBI_VERSION=60
$ make solver-callback

# Download models
$ cd <root_dir>/data
$ ./download_models.sh

# Obtain Gurobi license from http://www.gurobi.com/downloads/licenses/license-center
# and place the license file license.lic in data/gurobi or modify parameter 
# p.gurobi_license_file in lib/pose/exp_params.m to point to the license file location

$ cd <root_dir>
$ ./start_matlab.sh
```

In Matlab:

```matlab
% Demo multi person pose estimation
demo_multiperson()
```

## CNN-based part detectors

If you are interested in trying out our part detectors that produce dense confidence maps, check out the respective [project page](https://github.com/eldar/deepcut-cnn).

## Citation
Please cite Deep(er)Cut in your publications if it helps your research:

    @article{insafutdinov2016deepercut,
        author = {Eldar Insafutdinov and Leonid Pishchulin and Bjoern Andres and Mykhaylo Andriluka and Bernt Schiele},
        url = {http://arxiv.org/abs/1605.03170}
        title = {DeeperCut: A Deeper, Stronger, and Faster Multi-Person Pose Estimation Model},
        year = {2016}
    }

    @inproceedings{pishchulin16cvpr,
	    title = {DeepCut: Joint Subset Partition and Labeling for Multi Person Pose Estimation},
	    booktitle = {CVPR'16},
	    url = {},
	    author = {Leonid Pishchulin and Eldar Insafutdinov and Siyu Tang and Bjoern Andres and Mykhaylo Andriluka and Peter Gehler and Bernt Schiele}
    }