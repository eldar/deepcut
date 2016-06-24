function  write2hdf5_all_sequence
% write image data (and simple feature data) from all sequences to hdf5 file 
% positive and negative example mixed

is_sp = 1; % is_sp = 1: use simple feature
sp_dim = 7;

data_dir = '/scratch/BS/pool2/tang/multicut/pairwise_example/';
% save dir
if ~is_sp
    save_dir = '/BS/multicut_tracking/work/Dataset/multicut/pairwise_example/11_train_sequences/mixed_hdf5/';
else
    save_dir = '/BS/multicut_tracking/work/Dataset/multicut/pairwise_example/11_train_sequences/mixed_sp_hdf5/';
end
if ~exist(save_dir)
    mkdir(save_dir);
end
% data set
data_set = {'tud-stadtmitte' ...
            'ETH-Bahnhof' ...
            'ETH-Pedcross2' ...
            'ETH-Sunnyday' ...
            'KITTI-13' ...
            'KITTI-17' ...
            'PETS09-S2L1' ...
            'ADL-Rundle-6' ...
            'ADL-Rundle-8' ...
            'Venice-2'};
frame_rate = [25, 14, 14, 14, 10, 10, 7, 30, 30,30];

% load images for each sequence
num_sequeces = length(data_set);
positive_img_dir = cell(num_sequeces,1);
negative_img_dir = cell(num_sequeces,1);

positive_img_list = cell(num_sequeces,1);
negative_img_list = cell(num_sequeces,1);

rep_positive_dir = cell(num_sequeces,1);
rep_negative_dir = cell(num_sequeces,1);

rep_positive_label = cell(num_sequeces,1);
rep_negative_label = cell(num_sequeces,1);

sp_positive = cell(num_sequeces,1);
sp_positive_name = cell(num_sequeces,1);

sp_negative = cell(num_sequeces,1);
sp_negative_name = cell(num_sequeces,1);
for s = 1:num_sequeces
    positive_img_dir{s} = [data_dir data_set{s} '/positive/'];
    negative_img_dir{s} = [data_dir data_set{s} '/negative/'];
    
    fprintf('Listing all the images for sequence %d...\n',s);
    
    % positive examples
    tmp = dir([positive_img_dir{s} '*.jpg']);
    positive_img_list{s} = {tmp.name}';

    rep_positive_dir{s} = repmat(s, length(positive_img_list{s}),1);
    rep_positive_label{s} = ones(length(positive_img_list{s}),1);
    if is_sp ==1
        load([positive_img_dir{s} 'simple_feature.mat']);
        sp_positive{s} = [simple_feature simple_feature];
        sp_positive_name{s} = [simple_feature_name simple_feature_name];
    end
    
    % negative examples
    tmp = dir([negative_img_dir{s} '*.jpg']);
    negative_img_list{s} = {tmp.name}';

    rep_negative_dir{s} = repmat(s, length(negative_img_list{s}),1);
    rep_negative_label{s} = zeros(length(negative_img_list{s}),1);
    if is_sp ==1
        load([negative_img_dir{s} 'simple_feature.mat']);
        sp_negative{s} = [simple_feature simple_feature];
        sp_negative_name{s} = [simple_feature_name simple_feature_name];
    end
end

positive_img_list_all = cat(1,positive_img_list {:});
rep_positive_dir = cat(1,rep_positive_dir {:});
rep_positive_label = cat(1,rep_positive_label {:});

negative_img_list_all = cat(1,negative_img_list {:});
rep_negative_dir = cat(1,rep_negative_dir {:});
rep_negative_label = cat(1,rep_negative_label {:});

% image name list
img_list = [positive_img_list_all; negative_img_list_all];
% image dir list
rep_dir = [rep_positive_dir; rep_negative_dir];
% image label list
rep_label = [rep_positive_label; rep_negative_label];
% simple feature list
if is_sp == 1
    sp_positive = cat(2,sp_positive {:});
    sp_negative = cat(2,sp_negative {:});
    sp = [sp_positive';sp_negative'];
else
    sp = [];
end

num_img = length(positive_img_list_all) + length(negative_img_list_all);

% randomize
rand_list = randi([1,num_img],num_img,1);rand_list(end:num_img) =1; % make sure rand_list length
img_list = img_list(rand_list);
rep_dir = rep_dir(rand_list);
rep_label = rep_label(rand_list);
if is_sp ==1
    sp = sp(rand_list);
else
    sp = [];
end

% chunk size
chunksz = 1000;
% number of files
num_round = (num_img)/chunksz;
parfor k = 1:num_round
    fprintf('Saving hdf5 file %d out of %d ...\n', k, num_round);
    % must be single format
    batchdata = single(zeros(227,227,3,chunksz));
    
    % if no sp diminsion, all the labels are zeros.
    batchlabs = single(zeros(1+sp_dim,chunksz));
    
    % the end idx of last round
    last_end_img_idx = (k-1)*chunksz;
    % each example
    for i = 1:chunksz
        idx = last_end_img_idx + i;
        
        % current dataset label
        cur_dataset_label = rep_dir(idx);
        
        % current image name
        cur_image_name = img_list{idx};
        
        % current example's label
        cur_class_label = rep_label(idx);
        
        % current example's directory
        if cur_class_label
            cur_img_dir = positive_img_dir{cur_dataset_label};
        else
            cur_img_dir = negative_img_dir{cur_dataset_label};
        end
        % read example
        img = imread([cur_img_dir cur_image_name]);
        % unit to single
        img = imresize(img,[227,227]);
        % change to single format
        img =  single(img);
        % RGB to BGR
        img = img(:,:,[3 2 1]);
        % make row first
        img = permute(img, [2 1 3]);
        %
        % load to batchdata and label
        batchdata(:,:,:,i) = img;
        batchlabs(1,i) = cur_class_label;
        %
        if is_sp == 1
            cur_sp = sp{idx};
            cur_frame_rate = frame_rate(cur_dataset_label);
            % frame rate normalize ratio
            fr_norm = 25/cur_frame_rate;
            feature = compute_simple_feature(cur_sp,fr_norm);
            feature = single(feature);
            batchlabs(2:end,i) = feature;
        end
    end
    % save
    filename = [save_dir sprintf('%06d',last_end_img_idx + 1) '.h5'];
    store2hdf5(filename, batchdata, batchlabs, 1); 
end
end

