#!/bin/sh

curl -O http://datasets.d2.mpi-inf.mpg.de/deepercut-models/pose.tar.gz
tar -zxvf pose.tar.gz

curl -O http://datasets.d2.mpi-inf.mpg.de/deepercut-models/pairwise.tar.gz
tar -zxvf pairwise.tar.gz

mkdir -p caffe-models
cd caffe-models
curl -O http://datasets.d2.mpi-inf.mpg.de/deepercut-models/ResNet-101-mpii-multiperson.caffemodel
cd -

curl -O http://datasets.d2.mpi-inf.mpg.de/deepercut-models/mpii-multiperson-test.tar.gz
tar -zxvf mpii-multiperson-test.tar.gz
