# Deep(er)Cut: Multi Person Pose Estimation

This short documentation describes steps necessary to compile and run the code that implements [DeepCut](http://arxiv.org/abs/1511.06645) and [DeeperCut](http://arxiv.org/abs/1605.03170) papers:	

**Leonid Pishchulin, Eldar Insafutdinov, Siyu Tang, Bjoern Andres, Mykhaylo Andriluka, Peter Gehler, and Bernt Schiele			  
DeepCut: Joint Subset Partition and Labeling for Multi Person Pose Estimation	       
In _IEEE Conference on Computer Vision and Pattern Recognition (CVPR)_, 2016**	       

**Eldar Insafutdinov, Leonid Pishchulin, Bjoern Andres, Mykhaylo Andriluka, and Bernt Schiele   
DeeperCut:  A Deeper, Stronger, and Faster Multi-Person Pose Estimation Model   
In _European Conference on Computer Vision (ECCV)_, 2016**	
For more information visit http://pose.mpi-inf.mpg.de

## Prerequisites
- This code was developed under Linux (Debian wheezy, 64 bit) and was tested only in this environment.
- HDF5 1.8
- CMake
- C++ 11
- CUDA >=7.5
- [Caffe building instructions](http://caffe.berkeleyvision.org/installation.html)
- [Gurobi optimizer 6.0.x](https://user.gurobi.com/download/gurobi-optimizer)

## Installation Instructions

1. Clone repository	
   ```
   $ git clone https://github.com/eldar/deepcut --recursive
   ```

2. Build Caffe and its MATLAB interface after configuring `Makefile.config`	
   ```
   $ cd external/caffe
   $ make -j 4 all matcaffe
   ```

3. Build `liblinear`, specify the path to the MATLAB installation	
   ```
   $ cd external/liblinear-1.94/matlab
   $ CC=gcc CXX=g++ MATLABDIR=/usr/lib/matlab-8.6/ make
   ```

4. Build solver	
   ```
   $ cd external/solver
   $ cmake . -DGUROBI_ROOT_DIR=/path/to/gurobi603/linux64 -DGUROBI_VERSION=60
   $ make solver-callback
   ```

5. Obtain Gurobi license from http://www.gurobi.com/downloads/licenses/license-center
   and place the license file license.lic in data/gurobi or modify parameter 
   p.gurobi_license_file in lib/pose/exp_params.m to point to the license file location

## Download models
```
$ cd data
$ ./download_models.sh
```

## Run Demo	
```
$ cd <root_dir>
$ ./start_matlab.sh
% in MATLAB
>> demo_multiperson
```

## CNN-based part detectors

Access [DeeperCut Part Detectors](https://github.com/eldar/deepcut-cnn) to download stand-alone part detectors that produce dense scoremaps.

## Citing
```
@inproceedings{insafutdinov2016deepercut,
	author = {Eldar Insafutdinov and Leonid Pishchulin and Bjoern Andres and Mykhaylo Andriluka and Bernt Schieke},
	title = {DeeperCut: A Deeper, Stronger, and Faster Multi-Person Pose Estimation Model},
	booktitle = {European Conference on Computer Vision (ECCV)},
	year = {2016},
	url = {http://arxiv.org/abs/1605.03170}
    }
@inproceedings{pishchulin16cvpr,
	author = {Leonid Pishchulin and Eldar Insafutdinov and Siyu Tang and Bjoern Andres and Mykhaylo Andriluka and Peter Gehler and Bernt Schiele},
	title = {DeepCut: Joint Subset Partition and Labeling for Multi Person Pose Estimation},
	booktitle = {IEEE Conference on Computer Vision and Pattern Recognition (CVPR)},
	year = {2016},
	url = {http://arxiv.org/abs/1511.06645}
}
```