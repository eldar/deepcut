function compute_mpii_crop_size(expidx)

% mpii 654
p = exp_params(expidx);

pidxs = p.pidxs;
num_joints = length(pidxs);
parts = get_parts();

% load annolist
load(p.trainGT);

num_images = length(annolist);

data = zeros(num_images, 6);

for i = 1:num_images
    if mod(i, 100) == 0
        fprintf('processing image %d/%d \n', i, num_images);
    end
    %filename = annolist(i).image.name;
    
    joint_list = get_anno_joints(annolist(i).annorect(1), p.pidxs, parts);
    joints = zeros(num_joints, 2);
    n = 0;
    for j = 1:num_joints
        jnt = joint_list(j, :);
        if ~isnan(jnt(1))
            n = n + 1;
            joints(n, :) = [jnt];
        end
    end
    joints = joints(1:n, :);
    data(i, :) = [mean(joints, 1) min(joints, [], 1) max(joints, [], 1)];
end

% [mean_x mean_y left_x top_y right_x bottom_y]

out_dir = fullfile(p.expDir, p.shortName, 'data', 'crop_sizes.mat');
save(out_dir, 'data');

end
