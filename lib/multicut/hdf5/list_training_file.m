data_dir = '/scratch/BS/pool2/tang/multicut/pairwise_example/all_sequences/mixed_sp_hdf5/';

file_list = dir([data_dir '*.h5']); 


fid = fopen([data_dir 'all_file_name.txt'],'w');
for i = 1:length(file_list)
    img_name = file_list(i).name;
    fprintf(fid, '%s',  data_dir);
    fprintf(fid, '%s',  img_name);
    fprintf(fid, '\n');
    
end
fclose(fid);
