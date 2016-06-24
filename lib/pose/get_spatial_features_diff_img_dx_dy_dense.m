function [feat,idxs_bbox_pair,cb1,cb2] = get_spatial_features_diff_img_dx_dy_dense(locations,idxs_bbox_pair,rot_offset,scores)

if (nargin < 3)
    rot_offset = 0;
end


cb1 = locations(idxs_bbox_pair(:,1), :);
cb2 = locations(idxs_bbox_pair(:,2), :);

deltaX = cb1(:,1)-cb2(:,1);
deltaY = cb1(:,2)-cb2(:,2);
angle = atan2(deltaY,deltaX);
angle = angle - rot_offset;
angle = wrapMinusPiPifast(angle);

% feat = cat(2,dist,angle,scores(idxs_bbox_pair(:,1),:),scores(idxs_bbox_pair(:,2),:));
feat = cat(2,deltaX,deltaY,angle,scores(idxs_bbox_pair(:,1),:),scores(idxs_bbox_pair(:,2),:));
