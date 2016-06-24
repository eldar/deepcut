function [feat,idxs_bbox_pair,cb1,cb2] = get_spatial_features_same_part_regr_img(locations,idxs_bbox_pair)

cb1 = locations(idxs_bbox_pair(:,1), :);
cb2 = locations(idxs_bbox_pair(:,2), :);

deltaX = cb2(:,1)-cb1(:,1);
deltaY = cb2(:,2)-cb1(:,2);

feat = cat(2, deltaX, deltaY);
