function marray_save(file_name, dataset_name, M, write_mode)
%
% saves a MATLAB array as a dataset in an HDF5 file
% and adds the attribute reverse-shape = 1 to that
% dataset
%
% write_mode
% 'overwrite' (default)
% 'append' (file must exist)
%
if nargin == 3
    write_mode = 'overwrite';
end

hdf5write(file_name, dataset_name, M, 'WriteMode', write_mode);

file_id = H5F.open(file_name, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
dataset_id = H5D.open(file_id, dataset_name);
dataspace_id = H5S.create_simple(1, 1, []);
attribute_id = H5A.create(dataset_id, 'reverse-shape', 'H5T_STD_U8LE', ...
    dataspace_id, 'H5P_DEFAULT');
H5A.write(attribute_id, 'H5ML_DEFAULT', uint8(1));
H5A.close(attribute_id);
H5S.close(dataspace_id);
H5D.close(dataset_id);
H5F.close(file_id);
%
end