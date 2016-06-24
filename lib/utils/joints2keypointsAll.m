function joints2keypointsAll(expidx, image_set, joints)

% converts matrix of joints in standard order into keypoints structure
% and saves it at a required location

p = exp_params(expidx);

keypointsAll = struct;
idxs = [1:6, 11:16, 9:10];

num_images = size(joints, 1);

for i = 1:num_images
    %keypointsAll(i,1).imgname = imdb.image_at(i);
    if size(joints, 2) == 14
        det = NaN(16, 3);
        %det(7:8,:)= NaN;
        det(1:6, 1:2) = joints(i, 1:6, :);
        det(11:16, 1:2) = joints(i, 7:12, :);
        det(9:10, 1:2) = joints(i, 13:14, :);
    else
        det = NaN(size(joints, 2), 3);
        det(:, 1:2) = squeeze(joints(i, :, :));
    end
    keypointsAll(i,1).det = det;
end

[pathstr,~,~] = fileparts(p.evalTest);
mkdir_if_missing(pathstr);
save(p.evalTest, 'keypointsAll');