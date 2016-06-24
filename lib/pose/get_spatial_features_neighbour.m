function [X_pos, keys_pos, boxes_pos, X_neg, keys_neg, boxes_neg] = get_spatial_features_neighbour(expidx,cidx)

RandStream.setGlobalStream ...
        (RandStream('mt19937ar','seed',42));

p = exp_params(expidx);

allpairs = isfield(p, 'allpairs') && p.allpairs;
if allpairs
    load(p.pairwise_relations, 'graph');
    cidxs = graph(cidx, :);
else
    next_joint = neighbour_joint_list();
    if cidx > length(next_joint)
        return;
    end

    cidxs = sort([cidx next_joint(cidx)]);

    graph = bidirectional_graph();
end

cidx1 = cidxs(1);
cidx2 = cidxs(2);

[~,forward_edge]  = ismember([cidx1 cidx2], graph, 'rows');
[~,backward_edge] = ismember([cidx2 cidx1], graph, 'rows');

if ~allpairs
    is_neighbour = forward_edge ~= 0 && backward_edge ~= 0;
    assert(is_neighbour);
end

% cidxs is an ordered pair of joints. however the first one in the pair is
% not always the origin of the next joint prediction, so in that case we
% set first_is_end to true.

fprintf('cidx: %d - %d\n',cidxs);

save_file = [p.pairwiseDir '/feat_spatial_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(2)) '.mat'];
    
if exist(save_file, 'file') == 2
    fprintf('Loading feature file: %s\n', save_file);
    load(save_file);
    fprintf('Loaded %s\n',save_file);
    return;
end

mkdir_if_missing(p.pairwiseDir);

fprintf('Loading annolist %s\n', p.trainGT);
load(p.trainGT,'annolist');
imgidxs = 1:length(annolist);

bVis = false;

nFeatSample = p.nFeatSample;
dist_thresh = 17;
stride = p.stride;
half_stride = stride/2;
scale_factor = p.scale_factor;
inv_scale_factor = 1/scale_factor;
res_net = p.res_net;
scale_mul = sqrt(53);

image_set = 'train';
cache_dir = fullfile(p.scoremaps, image_set);
fprintf('loading scoremaps from %s\n', cache_dir);

pidxs = p.pidxs;
num_joints = length(pidxs);
[~,parts] = util_get_parts24();

if isfield(p, 'neighbor_locref') && p.neighbor_locref
    dim = 8;
else
    dim = 6;
end

neighbor_locref = isfield(p, 'neighbor_locref') && p.neighbor_locref;

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

num_images = 4000;%length(imgidxs);

for i = 1:num_images
    fprintf('pos features %d/%d\n', i, num_images);
    
    im_fn = annolist(i).image.name;
    %imshow(im_fn);
    %pause;
    %continue;
    
    [~,im_name,~] = fileparts(im_fn);
    load(fullfile(cache_dir, [im_name '_nextreg']), 'nextreg_pred');
    load(fullfile(cache_dir, [im_name '_locreg']), 'locreg_pred');

    height = size(nextreg_pred, 1);
    width  = size(nextreg_pred, 2);
    num_candidates = height*width;
    size_2d = size(nextreg_pred(:,:,1));

    locations = zeros(num_candidates, 2);
    next_joints = zeros(num_candidates, 2, 2); % num_candidates, num_edges(forw and backw), num_coords(x and y)
    location_refine = zeros(num_candidates, 2, 2);
    for jj = 1:height
        for ii = 1:width
            ind = sub2ind(size_2d, jj, ii);
            crd = [ii-1, jj-1]*stride;
            if res_net
                crd = crd + half_stride;
            end
            locations(ind, :) = crd*inv_scale_factor;
            next_crd = squeeze(nextreg_pred(jj, ii, [forward_edge backward_edge], :));
            next_joints(ind, :, :) = next_crd/scale_factor;
            location_refine(ind, :, :) = squeeze(locreg_pred(jj, ii, [cidx1 cidx2], :))*scale_mul*inv_scale_factor;
        end
    end
    
    rect = annolist(i).annorect(1);
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
        [p,q] = meshgrid(idxs_bbox1, idxs_bbox2);
        idxAll = [p(:) q(:)];
        nFeat = min(nFeatSample,size(idxAll,1));
        idxs_rnd = randperm(size(idxAll,1));
        idxsPair = idxs_rnd(1:nFeat);
        idxs_bbox_pair = idxAll(idxsPair,:);
        
        if (bVis)
            subplot(1,2,1); hold on;
        end
        
        if neighbor_locref
            featPos = get_spatial_features_neighbour_locref(locations,idxs_bbox_pair,next_joints,location_refine);
        else
            featPos = get_spatial_features_neighbour_img(locations,idxs_bbox_pair,next_joints);
        end
        idxs = n_pos+1:n_pos+size(featPos,1);
        X_pos(idxs,:) = featPos;
        boxes_pos(idxs,:) = [locations(idxs_bbox_pair(:,1),:) locations(idxs_bbox_pair(:,2),:)];
        keys_pos(idxs,:) = [i*ones(size(featPos,1),1) idxs_bbox_pair];
        n_pos = n_pos + size(featPos,1);
    end
    
    [p,q] = meshgrid(1:num_candidates, 1:num_candidates);
    idxAll = [p(:) q(:)];
    
    ovAll = [dists_to_gt(idxAll(:,1),1) dists_to_gt(idxAll(:,2),2)];
    
    idxsNegSep = false(size(ovAll, 1), 3);
    idxsNegSep(:,1) = (ovAll(:,1) <= dist_thresh) & (ovAll(:,2) > dist_thresh);
    idxsNegSep(:,2) = (ovAll(:,1) > dist_thresh)  & (ovAll(:,2) <= dist_thresh);
    idxsNegSep(:,3) = (ovAll(:,1) > dist_thresh)  & (ovAll(:,2) > dist_thresh);
    nSampleNegType = int32(nFeatSample/3);
    
    for k = 1:3
        idxAll_type = idxAll(idxsNegSep(:,k),:);
        if (~isempty(idxAll_type))
            nFeat = min(nSampleNegType,size(idxAll_type,1));
            idxs_rnd = randperm(size(idxAll_type,1));
            idxsPair = idxs_rnd(1:nFeat);
            idxs_bbox_pair = idxAll_type(idxsPair,:);

            if (bVis)
                subplot(1,2,2); hold on;
            end

            if neighbor_locref
                featNeg = get_spatial_features_neighbour_locref(locations,idxs_bbox_pair,next_joints, location_refine);
            else
                featNeg = get_spatial_features_neighbour_img(locations,idxs_bbox_pair,next_joints);
            end
            idxs = n_neg+1:n_neg+size(featNeg,1);
            X_neg(idxs,:) = featNeg;
            boxes_neg(idxs,:) = [locations(idxs_bbox_pair(:,1),:) locations(idxs_bbox_pair(:,2),:)];
            keys_neg(idxs,:) = [i*ones(size(featNeg,1),1) idxs_bbox_pair];
            n_neg = n_neg + size(featNeg,1);
        end
    end
    
    %{
    % Now sample Negatives
    nSampleNegType = int32(nFeatSample/3);

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

        featNeg = get_spatial_features_neighbour_locref(locations,idxs_bbox_pair,next_joints, location_refine);
        idxs = n_neg+1:n_neg+size(featNeg,1);
        X_neg(idxs,:) = featNeg;
        boxes_neg(idxs,:) = [locations(idxs_bbox_pair(:,1),:) locations(idxs_bbox_pair(:,2),:)];
        keys_neg(idxs,:) = [i*ones(size(featNeg,1),1) idxs_bbox_pair];
        n_neg = n_neg + size(featNeg,1);
    end
    %}
    
end

% remove unused bins
X_pos(n_pos+1:end,:) = [];
keys_pos(n_pos+1:end,:) = [];
boxes_pos(n_pos+1:end,:) = [];

X_neg(n_neg+1:end,:) = [];
keys_neg(n_neg+1:end,:) = [];
boxes_neg(n_neg+1:end,:) = [];

save(save_file, 'X_pos', 'keys_pos', 'boxes_pos', 'X_neg', 'keys_neg', 'boxes_neg', '-v7.3');

end

function a = remove_from(a, b)
    for i = 1:length(b)
        a(a==b(i)) = [];
    end
end
