function [means, std_devs] = compute_adjacent_stats( expidx )

p = exp_params(expidx);

[~,parts] = util_get_parts24();

% load annolist
load(p.trainGT);

num_images = length(annolist);
pidxs = p.pidxs;
num_joints = length(pidxs);

scale_factor = 224/265;

next_joint = neighbour_joint_list();

num_relations = length(next_joint);

coord = zeros(num_relations, num_images, 2);
nums  = zeros(num_relations, 1);

for i = 1:num_images
    if mod(i, 100) == 0
        fprintf('processing image %d/%d \n', i, num_images);
    end
    
    rect = annolist(i).annorect(1);
    joints = get_anno_joints( rect, pidxs, parts );
    
    for j = 1:num_relations
        k = next_joint(j);
        if isnan(joints(j,1)) || isnan(joints(k,1))
            continue;
        end
        dcrd = (joints(k, :) - joints(j, :))*scale_factor;
        nums(j) = nums(j) + 1;
        coord(j, nums(j), :) = dcrd;
    end
end

means = zeros(num_relations, 2);
std_devs = zeros(num_relations, 2);

for j = 1:num_relations
    data = squeeze(coord(j, 1:nums(j), :));
    means(j, :) = mean(data);
    std_devs(j, :) = std(data);
end

save(fullfile(p.exp_dir, 'data', 'next_joint_stats'), 'means', 'std_devs');

end