% ------------------------------------------------------------------------
function [X_pos, keys_pos, boxes_pos, X_neg, keys_neg, boxes_neg] = get_spatial_features_diff_dx_dy(imgidxs, p, gt_roidb, cidxs, bVis, annolist)
% -----------------------------------------------------------------------

scale = p.scale;
nFeatSample = p.nFeatSample;
pos_ovr_thresh = p.pos_ovr_thresh;
neg_ovr_thresh = p.neg_ovr_thresh;
rot_offset = p.rot_offset;
detDir = p.outputDir;

dim = 31;

% initialize the arrays, otherwise too slow when using cat
X_pos = zeros(length(imgidxs)*nFeatSample,dim,'single');
boxes_pos = zeros(length(imgidxs)*nFeatSample,8,'single');
keys_pos = zeros(length(imgidxs)*nFeatSample,3,'single');
X_neg = zeros(length(imgidxs)*nFeatSample,dim,'single');
boxes_neg = zeros(length(imgidxs)*nFeatSample,8,'single');
keys_neg = zeros(length(imgidxs)*nFeatSample,3,'single');

% example counter for each class
n_pos = 0;
n_neg = 0;

for i = 1:length(imgidxs)
    fprintf('pos features %d/%d\n', i, length(imgidxs));
      
    detFilename = [detDir '/detections_', padZeros(num2str(i-1),5)];%
    load(detFilename,'boxes');
    boxesAllParts = boxes;
    
    assert(norm(boxesAllParts{2}(1,1:4)-boxesAllParts{3}(1,1:4)) < 1e-4);
    
    roi_boxes = boxesAllParts{cidxs(1)+1};
    gt_boxes = double(gt_roidb{i}.boxes);
    
    if (scale ~= 1)
        roi_boxes(:,1:4) = scale_bbox(roi_boxes(:,1:4),1.0/scale,inf,inf);
    end
    
%     assert(norm(gt_boxes - roi_boxes(1:size(gt_boxes,1),1:4)) < 1e-3);
    
%     boxes = double([gt_boxes; roi_boxes(:,1:4)]);
    boxes = double(roi_boxes(:,1:4));
    
    overlap = zeros(size(boxes,1),size(boxesAllParts,1)-1);
    
    gt_boxes_idxs = gt_roidb{i}.gt_classes;
    for j = 1:length(gt_boxes_idxs)
        overlap(:, gt_boxes_idxs(j)) = ...
            max(overlap(:, gt_boxes_idxs(j)), boxoverlap(boxes, gt_boxes(j, :)));
    end

    scores = zeros(size(overlap));
    for j = 1:length(boxesAllParts)-1
        scores(:,j) = boxesAllParts{j+1}(:,5);
    end
    
    idxs_bbox1 = find(overlap(:,cidxs(1)) >= pos_ovr_thresh);
    idxs_bbox2 = find(overlap(:,cidxs(2)) >= pos_ovr_thresh);
        
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
        
        featPos = get_spatial_features_diff_img_dx_dy(boxes,idxs_bbox_pair,rot_offset,scores,cidxs,bVis);
        idxs = n_pos+1:n_pos+size(featPos,1);
        X_pos(idxs,:) = featPos;
        boxes_pos(idxs,:) = [boxes(idxs_bbox_pair(:,1),:) boxes(idxs_bbox_pair(:,2),:)];
        keys_pos(idxs,:) = [i*ones(size(featPos,1),1) idxs_bbox_pair];
        n_pos = n_pos + size(featPos,1);
    end
    
    [p,q] = meshgrid(1:size(overlap,1),1:size(overlap,1));
    idxAll = [p(:) q(:)];
    
    ovAll = [overlap(idxAll(:,1),cidxs(1)) overlap(idxAll(:,2),cidxs(2))];
    
    idxsNeg = ((ovAll(:,1) >= pos_ovr_thresh) & (ovAll(:,2) < neg_ovr_thresh) | ...
               (ovAll(:,1) < neg_ovr_thresh)  & (ovAll(:,2) >= pos_ovr_thresh) | ...
               (ovAll(:,1) < neg_ovr_thresh)  & (ovAll(:,2) < neg_ovr_thresh));

    idxAll = idxAll(idxsNeg,:);
                 
    if (~isempty(idxAll))
        nFeat = min(nFeatSample,size(idxAll,1));
        idxs_rnd = randperm(size(idxAll,1));
        idxsPair = idxs_rnd(1:nFeat);
        idxs_bbox_pair = idxAll(idxsPair,:);
        
        if (bVis)
            subplot(1,2,2); hold on;
        end
        
        featNeg = get_spatial_features_diff_img_dx_dy(boxes,idxs_bbox_pair,rot_offset,scores,cidxs,bVis);
        idxs = n_neg+1:n_neg+size(featNeg,1);
        X_neg(idxs,:) = featNeg;
        boxes_neg(idxs,:) = [boxes(idxs_bbox_pair(:,1),:) boxes(idxs_bbox_pair(:,2),:)];
        keys_neg(idxs,:) = [i*ones(size(featNeg,1),1) idxs_bbox_pair];
        n_neg = n_neg + size(featNeg,1);
    end
end

% remove unused bins
X_pos(n_pos+1:end,:) = [];
keys_pos(n_pos+1:end,:) = [];
boxes_pos(n_pos+1:end,:) = [];

X_neg(n_neg+1:end,:) = [];
keys_neg(n_neg+1:end,:) = [];
boxes_neg(n_neg+1:end,:) = [];