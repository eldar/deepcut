function [X_pos, keys_pos, boxes_pos, X_neg, keys_neg, boxes_neg] = get_spatial_features_same_part_regr(expidx,cidx)

RandStream.setGlobalStream ...
        (RandStream('mt19937ar','seed',42));

p = exp_params(expidx);

fprintf('cidx: %d\n',cidx);

save_file = [p.pairwiseDir '/feat_spatial_cidx_' num2str(cidx) '.mat'];
    
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
dist_thresh = 25;%17;
sz = 50;
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
[~,parts] = util_get_parts24();

dim = 2;

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
    load(fullfile(cache_dir, [im_name '_locreg']), 'locreg_pred');

    height = size(locreg_pred, 1);
    width  = size(locreg_pred, 2);
    num_candidates = height*width;
    size_2d = size(locreg_pred(:,:,1));

    locations2d = zeros(height, width);
    locations = zeros(num_candidates, 2);
    location_refine = zeros(num_candidates, 2);
    for jj = 1:height
        for ii = 1:width
            ind = sub2ind(size_2d, jj, ii);
            crd = [ii-1, jj-1]*stride;
            if res_net
                crd = crd + half_stride;
            end
            locations2d(jj, ii) = ind;
            locations(ind, :) = crd*inv_scale_factor;
            location_refine(ind, :) = squeeze(locreg_pred(jj, ii, cidx, :))*scale_mul*inv_scale_factor;
        end
    end
    
    locations_refined = locations + location_refine;
    
    num_people = length(annolist(i).annorect);
    positive_samples = cell(num_people, 1);
    gt_joints = zeros(num_people, 2);
    
    for k=1:num_people
        rect = annolist(i).annorect(k);
        joints = get_anno_joints( rect, pidxs, parts);

        gt_joint = joints(cidx, :);
        if isnan(gt_joint(1))
            continue;
        end
        gt_joints(k, :) = gt_joint;

        dx = locations(:,1)- gt_joint(1);
        dy = locations(:,2)- gt_joint(2);
        dists_to_gt = sqrt(dx.^2 + dy.^2);

        idxs_bbox = find(dists_to_gt <= dist_thresh);
        positive_samples{k} = idxs_bbox;
    end
        
    clear featPos featNeg;
    
    if (bVis)
        figure(101); clf;
        imagesc(imread(annolist(i).image.name));
        axis equal; hold on;
    end
    
    for k=1:num_people
        idxs_bbox = positive_samples{k};
        [p,q] = meshgrid(idxs_bbox, idxs_bbox);
        idxsAll = [p(:) q(:)];
        
        idxsExc = idxsAll(:,1) >= idxsAll(:,2);
        %idxsSameAll = idxsAll(~idxsExc,:);
        idxSameAllrel = idxsAll(~idxsExc,:);
        
        nFeat = min(ceil(nFeatSample/(num_people*2)),size(idxSameAllrel,1));
        %nFeat = min(10,size(idxAll,1));
        idxs_rnd = randperm(size(idxSameAllrel,1));
        idxsPair = idxs_rnd(1:nFeat);
        idxs_bbox_pair = idxSameAllrel(idxsPair,:);
        if bVis
            cb1 = locations_refined(idxs_bbox_pair(:, 1), :);
            cb2 = locations_refined(idxs_bbox_pair(:, 2), :);
            for j = 1:size(idxs_bbox_pair, 1)
                %plot(cb1(:,1),cb1(:,2),'b+');
                line([cb1(j,1); cb2(j,1)], [cb1(j,2); cb2(j,2)], 'Color', 'b', 'LineWidth', 1);
            end
        end
       
        featPos = get_spatial_features_same_part_regr_img(locations_refined,idxs_bbox_pair);

        idxs = n_pos+1:n_pos+size(featPos,1);
        X_pos(idxs,:) = featPos;
        boxes_pos(idxs,:) = [locations_refined(idxs_bbox_pair(:,1),:) locations_refined(idxs_bbox_pair(:,2),:)];
        keys_pos(idxs,:) = [i*ones(size(featPos,1),1) idxs_bbox_pair];
        n_pos = n_pos + size(featPos,1);
    end

    for k = 1:num_people
        num_of_neg = ceil(nFeatSample/(2*num_people));
        gt_pt = gt_joints(k, :);
        left = gt_pt(1)-sz;
        top = gt_pt(2)-sz;
        right = gt_pt(1)+sz;
        bot = gt_pt(2)+sz;
        r = double([left top right bot]);
        r = r*scale_factor;
        if res_net
            r = r-half_stride;
        end
        r = round(r/stride);
        r(1) = max(r(1), 1);
        r(2) = max(r(2), 1);
        r(3) = min(r(3), width);
        r(4) = min(r(4), height);
        
        sample_area = locations2d(r(2):r(4), r(1):r(3));
        sample_area = sample_area(:);
        idxs_bbox1 = positive_samples{k};
        
        negatives = zeros(size(locations, 1), 1);
        negatives(sample_area) = 1;
        positives = zeros(size(locations, 1), 1);
        positives(idxs_bbox1) = 1;
        negatives = negatives & ~positives;
        idxs_bbox2 = find(negatives);
        
                
        [p,q] = meshgrid(idxs_bbox1, idxs_bbox2);
        idxAll = [p(:) q(:)];
        nFeat = min(num_of_neg, size(idxAll,1));
        %nFeat = min(10,size(idxAll,1));
        idxs_rnd = randperm(size(idxAll,1));
        idxsPair = idxs_rnd(1:nFeat);
        idxs_bbox_pair = idxAll(idxsPair,:);
       
        if bVis
            cb1 = locations_refined(idxs_bbox_pair(:, 1), :);
            cb2 = locations_refined(idxs_bbox_pair(:, 2), :);
            for j = 1:size(idxs_bbox_pair, 1)
                %plot(cb1(:,1),cb1(:,2),'b+');
                line([cb1(j,1); cb2(j,1)], [cb1(j,2); cb2(j,2)], 'Color', 'r', 'LineWidth', 1);
            end
        end
        
        featNeg = get_spatial_features_same_part_regr_img(locations_refined,idxs_bbox_pair);

        idxs = n_neg+1:n_neg+size(featNeg,1);
        X_neg(idxs,:) = featNeg;
        boxes_neg(idxs,:) = [locations_refined(idxs_bbox_pair(:,1),:) locations_refined(idxs_bbox_pair(:,2),:)];
        keys_neg(idxs,:) = [i*ones(size(featNeg,1),1) idxs_bbox_pair];
        n_neg = n_neg + size(featNeg,1);
    end
    
    %{
    % find closest pairs of GT joints
    num_pairs = nchoosek(num_people, 2);
    dists = zeros(num_pairs, 1);
    idxs = zeros(num_pairs, 2);
    counter = 1;
    for j = 1:(num_people-1)
        for k = j+1:num_people
            pt1 = gt_joints(j, :);
            pt2 = gt_joints(k, :);
            dists(counter) = sqrt(sum((pt1-pt2).^2));
            idxs(counter, :) = [j, k];
            counter = counter+1;
        end
    end

    [~,I] = sort(dists);
    closest_pair = idxs(I(1), :);
    
    if num_people > 1
        num_type1 = ceil(nFeatSample/(2*2));
        num_type2 = ceil(nFeatSample/(2*2));
    else
        num_type1 = 0;
        num_type2 = ceil(nFeatSample/2);
    end
    
    if num_type1 > 0 % sample negatives type 1
        k1 = closest_pair(1);
        k2 = closest_pair(2);
        idxs_bbox1 = positive_samples{k1};
        idxs_bbox2 = positive_samples{k2};
        [p,q] = meshgrid(idxs_bbox1, idxs_bbox2);
        idxAll = [p(:) q(:)];
        nFeat = min(num_type1, size(idxAll,1));
        %nFeat = min(10,size(idxAll,1));
        idxs_rnd = randperm(size(idxAll,1));
        idxsPair = idxs_rnd(1:nFeat);
        idxs_bbox_pair = idxAll(idxsPair,:);
       
        if bVis
            cb1 = locations_refined(idxs_bbox_pair(:, 1), :);
            cb2 = locations_refined(idxs_bbox_pair(:, 2), :);
            for j = 1:size(idxs_bbox_pair, 1)
                %plot(cb1(:,1),cb1(:,2),'b+');
                line([cb1(j,1); cb2(j,1)], [cb1(j,2); cb2(j,2)], 'Color', 'r', 'LineWidth', 1);
            end
        end
        
        featNeg = get_spatial_features_same_part_regr_img(locations_refined,idxs_bbox_pair);

        idxs = n_neg+1:n_neg+size(featNeg,1);
        X_neg(idxs,:) = featNeg;
        boxes_neg(idxs,:) = [locations_refined(idxs_bbox_pair(:,1),:) locations_refined(idxs_bbox_pair(:,2),:)];
        keys_neg(idxs,:) = [i*ones(size(featNeg,1),1) idxs_bbox_pair];
        n_neg = n_neg + size(featNeg,1);
    end
    
    if num_type2 > 0
        idxs_bbox1 = [];
        for j = 1:num_people
            idxs_bbox1 = [idxs_bbox1; positive_samples{j}];
        end

        negatives = ones(size(locations, 1), 1);
        negatives(idxs_bbox1) = 0;
        idxs_bbox2 = find(negatives);
        idxs_rnd = randperm(size(idxs_bbox2,1));
        idxs_bbox2 = idxs_bbox2(idxs_rnd(1:200));
        
        [p,q] = meshgrid(idxs_bbox1, idxs_bbox2);
        idxAll = [p(:) q(:)];
        nFeat = min(num_type2, size(idxAll,1));
        %nFeat = min(10,size(idxAll,1));
        idxs_rnd = randperm(size(idxAll,1));
        idxsPair = idxs_rnd(1:nFeat);
        idxs_bbox_pair = idxAll(idxsPair,:);
       
        if bVis
            cb1 = locations_refined(idxs_bbox_pair(:, 1), :);
            cb2 = locations_refined(idxs_bbox_pair(:, 2), :);
            for j = 1:size(idxs_bbox_pair, 1)
                %plot(cb1(:,1),cb1(:,2),'b+');
                line([cb1(j,1); cb2(j,1)], [cb1(j,2); cb2(j,2)], 'Color', 'r', 'LineWidth', 1);
            end
        end
        
        featNeg = get_spatial_features_same_part_regr_img(locations_refined,idxs_bbox_pair);

        idxs = n_neg+1:n_neg+size(featNeg,1);
        X_neg(idxs,:) = featNeg;
        boxes_neg(idxs,:) = [locations_refined(idxs_bbox_pair(:,1),:) locations_refined(idxs_bbox_pair(:,2),:)];
        keys_neg(idxs,:) = [i*ones(size(featNeg,1),1) idxs_bbox_pair];
        n_neg = n_neg + size(featNeg,1);
    end
    %}
    
    if bVis
        pause;
    end
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
