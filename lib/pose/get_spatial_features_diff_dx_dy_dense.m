% ------------------------------------------------------------------------
function [X_pos, keys_pos, boxes_pos, X_neg, keys_neg, boxes_neg] = get_spatial_features_diff_dx_dy_dense(expidx,cidx)
% -----------------------------------------------------------------------

RandStream.setGlobalStream ...
        (RandStream('mt19937ar','seed',42));

p = exp_params(expidx);

pwIdxsAllrel = build_joint_pairs(p.pidxs);
cidxs = pwIdxsAllrel{cidx};
fprintf('cidx: %d - %d\n',cidxs);

if ~any(p.cidxs == cidxs(1)) || ~any(p.cidxs == cidxs(2))
    return;
end

save_file = [p.pairwiseDir '/feat_spatial_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(2)) '.mat'];
    
if exist(save_file, 'file') == 2
    fprintf('Loading feature file: %s\n', save_file);
    load(save_file);
    fprintf('Loaded %s\n',save_file);
    return;
end

fprintf('Loading annolist %s\n', p.trainGT);
load(p.trainGT,'annolist');
imgidxs = 1:length(annolist);

bVis = false;

nFeatSample = p.nFeatSample;
rot_offset = p.rot_offset;
dist_thresh = 17;
stride = p.stride;
scale_factor = p.scale_factor;
inv_scale_factor = 1/scale_factor;

image_set = 'train';
cache_dir = fullfile(p.exp_dir, 'scoremaps', image_set);
fprintf('loading scoremaps from %s\n', cache_dir);

pidxs = p.pidxs;
num_joints = length(pidxs);
[~,parts] = util_get_parts24();

idpr = false;
if isfield(p, 'idpr')
    idpr = p.idpr;
end

if idpr
    feature_size = 90;
else
    feature_size = 14;
end

dim = 3+2*feature_size;

% initialize the arrays, otherwise too slow when using cat
X_pos = zeros(length(imgidxs)*nFeatSample,dim,'single');
boxes_pos = zeros(length(imgidxs)*nFeatSample,4,'single');
keys_pos = zeros(length(imgidxs)*nFeatSample,3,'single');
X_neg = zeros(length(imgidxs)*nFeatSample,dim,'single');
boxes_neg = zeros(length(imgidxs)*nFeatSample,4,'single');
keys_neg = zeros(length(imgidxs)*nFeatSample,3,'single');

% example counter for each class
n_pos = 0;
n_neg = 0;

for i = 1:length(imgidxs)
    fprintf('pos features %d/%d\n', i, length(imgidxs));
    
    im_fn = annolist(i).image.name;
    [~,im_name,~] = fileparts(im_fn);
    load(fullfile(cache_dir, im_name), 'scoremaps');

    height = size(scoremaps, 1);
    width  = size(scoremaps, 2);
    num_candidates = height*width;
    num_scores = size(scoremaps, 3);
    size_2d = size(scoremaps(:,:,1));

    locations = zeros(num_candidates, 2);
    scores = zeros(num_candidates, num_scores);
    for jj = 1:height
        for ii = 1:width
            ind = sub2ind(size_2d, jj, ii);
            locations(ind, :) = [ii-1, jj-1]*stride*inv_scale_factor;
            scores(ind, :) = scoremaps(jj, ii, :);
        end
    end
    
    num_people = length(annolist(i).annorect);
    if num_people == 1
        nFeatSamplePers = nFeatSample;
    else
        nFeatSamplePers = nFeatSample/5;
    end

    for pers = 1:num_people
        
        rect = annolist(i).annorect(pers);
        joints = get_anno_joints( rect, pidxs, parts);

        gt_joints = joints(cidxs, :);
        if isnan(gt_joints(1,1)) || isnan(gt_joints(2,1))
            continue;
        end

        dists_to_gt = zeros(num_candidates, 2);
        for k = 1:2
            dx = locations(:,1)- gt_joints(k, 1);
            dy = locations(:,2)- gt_joints(k, 2);
            dists_to_gt(:, k) = sqrt(dx.^2 + dy.^2);
        end

        idxs_bbox1 = find(dists_to_gt(:,1) <= dist_thresh);
        idxs_bbox2 = find(dists_to_gt(:,2) <= dist_thresh);

        clear featPos featNeg;

        if (bVis)
            figure(100); clf;
            subplot(1,2,1);
            imagesc(imread(annolist(i).image.name));
            axis equal; hold on;
            subplot(1,2,2);
            imagesc(imread(annolist(i).image.name));
            axis equal; hold on;
        end
        
        if (~isempty(idxs_bbox1) && ~isempty(idxs_bbox2))
            [pp,qq] = meshgrid(idxs_bbox1, idxs_bbox2);
            idxAll = [pp(:) qq(:)];
            nFeat = min(nFeatSamplePers,size(idxAll,1));
            idxs_rnd = randperm(size(idxAll,1));
            idxsPair = idxs_rnd(1:nFeat);
            idxs_bbox_pair = idxAll(idxsPair,:);

            if (bVis)
                subplot(1,2,1); hold on;
            end

            featPos = get_spatial_features_diff_img_dx_dy_dense(locations,idxs_bbox_pair,rot_offset,scores);
            idxs = n_pos+1:n_pos+size(featPos,1);
            X_pos(idxs,:) = featPos;
            boxes_pos(idxs,:) = [locations(idxs_bbox_pair(:,1),:) locations(idxs_bbox_pair(:,2),:)];
            keys_pos(idxs,:) = [i*ones(size(featPos,1),1) idxs_bbox_pair];
            n_pos = n_pos + size(featPos,1);
        end

        % Now sample Negatives
        nSampleNegType = int32(nFeatSamplePers/3);

        for k = 1:3
            idxs_bbox_pair = zeros(nSampleNegType, 2);
            if k == 1
                if isempty(idxs_bbox1)
                    continue;
                end
                r = randi([1 length(idxs_bbox1)], nSampleNegType, 1);
                idxs_bbox_pair(:,1) = idxs_bbox1(r);
                r = randi([1 num_candidates], nSampleNegType*10, 1);
                r = remove_from(r, idxs_bbox2);
                idxs_bbox_pair(:,2) = r(1:nSampleNegType);
            elseif k == 2
                if isempty(idxs_bbox2)
                    continue;
                end
                r = randi([1 length(idxs_bbox2)], nSampleNegType, 1);
                idxs_bbox_pair(:,2) = idxs_bbox2(r);
                r = randi([1 num_candidates], nSampleNegType*10, 1);
                r = remove_from(r, idxs_bbox1);
                idxs_bbox_pair(:,1) = r(1:nSampleNegType);
            else
                r = randi([1 num_candidates], nSampleNegType*10, 1);
                r = remove_from(r, idxs_bbox1);
                idxs_bbox_pair(:,1) = r(1:nSampleNegType); 
                r = randi([1 num_candidates], nSampleNegType*10, 1);
                r = remove_from(r, idxs_bbox2);
                idxs_bbox_pair(:,2) = r(1:nSampleNegType); 
            end
            
            featNeg = get_spatial_features_diff_img_dx_dy_dense(locations,idxs_bbox_pair,rot_offset,scores);
            idxs = n_neg+1:n_neg+size(featNeg,1);
            X_neg(idxs,:) = featNeg;
            boxes_neg(idxs,:) = [locations(idxs_bbox_pair(:,1),:) locations(idxs_bbox_pair(:,2),:)];
            keys_neg(idxs,:) = [i*ones(size(featNeg,1),1) idxs_bbox_pair];
            n_neg = n_neg + size(featNeg,1);
        end
    end
    
end

% remove unused bins
X_pos(n_pos+1:end,:) = [];
keys_pos(n_pos+1:end,:) = [];
boxes_pos(n_pos+1:end,:) = [];

X_neg(n_neg+1:end,:) = [];
keys_neg(n_neg+1:end,:) = [];
boxes_neg(n_neg+1:end,:) = [];

mkdir_if_missing(p.pairwiseDir);
save(save_file, 'X_pos', 'keys_pos', 'boxes_pos', 'X_neg', 'keys_neg', 'boxes_neg', '-v7.3');
end

function a = remove_from(a, b)
    for i = 1:length(b)
        a(a==b(i)) = [];
    end
end
