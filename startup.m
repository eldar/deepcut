if (~isdeployed)
    addpath('lib/pose');
    addpath('lib/pose/multicut');
    addpath('lib/utils');
    addpath('lib/vis');
    addpath('lib/eval');
    addpath('lib/multicut');
    addpath('lib/multicut/hdf5');
    caffe_dir = 'external/caffe/matlab/';
    if exist(caffe_dir) 
        addpath(caffe_dir);
    else
        warning('Please install Caffe in ./external/caffe');
    end
    addpath('external/liblinear-1.94/matlab/')
    fprintf('Pose startup done\n');
end
