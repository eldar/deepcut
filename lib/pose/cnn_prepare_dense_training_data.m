function cnn_prepare_dense_training_data( expidx, start_idx, text )

if nargin < 2
    start_idx = 0;
end

if nargin < 3
    text = true;
end

p = exp_params(expidx);

pidxs = p.pidxs;
num_joints = length(pidxs);
if p.person_part
    num_joints = num_joints+1;
end
parts = get_parts();

% load annolist
load(p.trainGT);

cache_dir = fullfile(p.expDir, p.shortName, 'data');

% load sizes
sizes_fn = fullfile(cache_dir, 'sizes_train.mat');
if exist(sizes_fn, 'file') ~= 2
    cnn_compute_image_sizes(expidx, 'train');
end
load(sizes_fn);

netsDir = p.netsDir;

input_file = sprintf('%s/pose_data_train.txt', netsDir);

mkdir_if_missing(netsDir);

if (exist(input_file, 'file'))
    warning('file exist: %s\n',input_file);
    return;
end

num_images = length(annolist);
channels = 3; % three channel images

multiperson = isfield(p, 'multiperson') && p.multiperson;
orig_scale = isfield(p, 'orig_scale') && p.orig_scale;

if text
    fid = fopen(input_file, 'wt');
else
    dataset = struct('image',{}, 'size',{}, 'joints', {});
end


for i = 1:num_images
    if mod(i, 100) == 0
        fprintf('processing image %d/%d \n', i, num_images);
    end
    filename = annolist(i).image.name;
    
    joints = zeros(num_joints, 3);
    num_people = length(annolist(i).annorect);
    all_joints = cell(1,1);
    for k = 1:num_people
        joint_list = get_anno_joints(annolist(i).annorect(k), p.pidxs, parts);
        joint_list = augment_joints(p, joint_list);
        
        n = 0;
        for j = 1:num_joints
            jnt = joint_list(j, :);
            if ~isnan(jnt(1))
                n = n + 1;
                joints(n, :) = [j jnt];
            end
        end
        joints = int32(joints(1:n, :));
        all_joints{k} = joints;
    end
    
    if text
        fprintf(fid, '# %d\n', start_idx+i-1);
        if multiperson
            fprintf(fid, 'multi %d\n', num_people);
        end
        if orig_scale
            fprintf(fid, 'scale %f\n', 1.0/annolist(i).annorect(1).scale);
        end
        fprintf(fid, '%s\n', filename);
        fprintf(fid, '%d\n%d\n%d\n', ...
          channels, ...
          sizes(i, 1), ...
          sizes(i, 2));

        for k = 1:num_people
            joints = all_joints{k};
            n = size(joints, 1);
            fprintf(fid, '%d\n', n);
            for j = 1:size(joints, 1)
                fprintf(fid, '%d %d %d\n', ...
                joints(j,1), joints(j,2), joints(j,3));
            end
        end
    else
        entry = struct;
        entry.image = filename;
        entry.size = [channels, sizes(i, 1), sizes(i, 2)];
        entry.joints = all_joints;
        dataset(i) = entry;
    end
end

if text
    fclose(fid);
else
    save(sprintf('%s/train_set', netsDir), 'dataset');
end

end

function [scoremap, max_dist] = compute_scoremap(im_size, joints)

gt_size = 60;
pr_size = 56; %224/4
overlap_threshold = 0.5;
distance_threshold = 18.15;

% for k = 1:size(joints, 1)
%     if joints(k, 1) == joint_no
%         coord = joints(k, 2:3);
%         break;
%     end
% end

coord = int32(joints(:, 2:3));
coord = double(coord);

if ~exist('coord', 'var')
    return;
end

gt_box = [coord-gt_size/2, coord+gt_size/2];

stride = 8;
im_size = im_size(1:2);
new_sz = round_to_stride(im_size, stride);
sc_map_sz = int32(new_sz/stride)+int32([1 1]);
scoremap = zeros(sc_map_sz);

max_dist = 0;

for j = 1:size(scoremap, 1)
    for i = 1:size(scoremap, 2)
        pr_coord = ([i j] - 1)*stride;
        
        if true
            distances = pdist2(coord, pr_coord);
            [d, idx] = min(distances);
            if d < distance_threshold
                scoremap(j, i) = joints(idx, 1);
            end
        else
            pr_box = [pr_coord-pr_size/2, pr_coord+pr_size/2];
            overlaps = boxoverlap(gt_box, pr_box);
            [ov, idx] = max(overlaps);
            if ov > overlap_threshold
               scoremap(j, i) = joints(idx, 1);
               % find corresponding distance threshold
               closest_gt_coord = double(coord(idx, :));
               max_dist = max(norm(closest_gt_coord - pr_coord), max_dist);
            end
        end
    end
end

end

function res = round_to_stride(sz, stride)
res = int32(ceil(sz/stride) * stride);
end