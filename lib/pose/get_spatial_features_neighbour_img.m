function [feat,idxs_bbox_pair,cb1,cb2] = get_spatial_features_neighbour_img(locations,idxs_bbox_pair,next_joints)

cb1 = locations(idxs_bbox_pair(:,1), :);
cb2 = locations(idxs_bbox_pair(:,2), :);

deltaX = cb2(:,1)-cb1(:,1);
deltaY = cb2(:,2)-cb1(:,2);

deltaPred_forward = squeeze(next_joints(idxs_bbox_pair(:,1), 1, :));
deltaPred_backward = squeeze(next_joints(idxs_bbox_pair(:,2), 2, :));

if size(deltaPred_forward, 2) == 1
    deltaPred_forward = deltaPred_forward';
    deltaPred_backward = deltaPred_backward';
end

feat = cat(2, deltaX, deltaY, ...
              deltaPred_forward, deltaPred_backward);
