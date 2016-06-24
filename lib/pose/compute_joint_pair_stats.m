function [means, std_devs] = compute_joint_pair_stats( expidx )

p = exp_params(expidx);

[~,parts] = util_get_parts24();

% load annolist
load(p.trainGT);

num_images = length(annolist);
pidxs = p.pidxs;

scale_factor = p.scale_factor;

pwIdxsAllrel = build_joint_pairs(p);

num_relations = length(pwIdxsAllrel);

coord = zeros(num_relations, num_images, 2);
nums  = zeros(num_relations, 1);

for i = 1:num_images
    if mod(i, 100) == 0
        fprintf('processing image %d/%d \n', i, num_images);
    end
    
    rect = annolist(i).annorect(1);
    joints = get_anno_joints( rect, pidxs, parts );

    if p.person_part
        joints_f = joints(~isnan(joints(:,1)), :);
        mass_centre = mean(joints_f, 1);
        joints = [joints; mass_centre];
    end
    
    for j = 1:num_relations
        cidx1 = pwIdxsAllrel{j}(1);
        cidx2 = pwIdxsAllrel{j}(2);
        if isnan(joints(cidx1,1)) || isnan(joints(cidx2,1))
            continue;
        end
        dcrd = (joints(cidx2, :) - joints(cidx1, :))*scale_factor;
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

save_dir = fullfile(p.exp_dir, 'data');
mkdir_if_missing(save_dir);
save(fullfile(save_dir, 'all_pairs_stats'), 'means', 'std_devs');

end