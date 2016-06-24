function  write2hdf5
% write image data (and simple feature data) from one sequence to hdf5 file 
% positive and negative example seperate
% IMPORTANT!!!
% All the data and labels saved into hdf5 should be sing
data_dir = '/scratch/BS/pool2/tang/multicut/pairwise_example/';
data_set = 'TownCenter-Sample';%'tud-crossing';%'ETH-Bahnhof';%'ETH-Pedcross2';%

chunksz = 1000;

positive_img_dir  = [data_dir data_set '/positive/'];
negative_img_dir  = [data_dir data_set '/negative/'];
save_dir = [data_dir data_set '/mixed_hdf5/'];
if ~exist(save_dir)
    mkdir(save_dir);
end

fprintf('Listing all the images ...\n')
positive_img_list = dir([positive_img_dir '*.jpg']); 
negative_img_list = dir([negative_img_dir '*.jpg']); 

num_img = length(positive_img_list) + length(negative_img_list);
num_round = (num_img/2)/chunksz;
parfor k = 1:num_round
    fprintf('Saving hdf5 file %d ...\n', k);
    last_end_img_idx = (k-1)*chunksz;
    
    batchdata = single(zeros(227,227,3,chunksz*2));
    batchlabs = single(zeros(1,chunksz*2));

    
    filename = [save_dir sprintf('%05d',last_end_img_idx + 1) '.h5'];
    count = 0;
    for i = 1:chunksz
        idx = last_end_img_idx + i;
        positive_img_name  = positive_img_list(idx);
        img = imread([ positive_img_dir positive_img_name.name]);
        % unit to single
        img = imresize(img,[227,227]);
        
        img =  single(img);
%         img(:,120:end,1) = 255;
        %
        img = img(:,:,[3 2 1]);
        %
        img = permute(img, [2 1 3]);
        %
        
        count = count +1;
        batchdata(:,:,:,count) = img;
        batchlabs(count) = 1;
        
        negative_img_name  = negative_img_list(idx);
        img = imread([ negative_img_dir negative_img_name.name]);
        % unit to single
        img = imresize(img,[227,227]);
        img =  single(img);
        %
        img = img(:,:,[3 2 1]);
        %
        img = permute(img, [2 1 3]);
        
        count = count +1;
        batchdata(:,:,:,count) = img;
        batchlabs(count) = 0;
    end
    curr_dat_sz=store2hdf5(filename, batchdata, batchlabs, 1); 
end
end

