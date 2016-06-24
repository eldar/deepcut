function [feat,idxs_bbox_pair,cb1,cb2] = get_spatial_features_neighbour_locref(locations,idxs_bbox_pair,next_joints, locref)

cb1 = locations(idxs_bbox_pair(:,1), :);
cb2 = locations(idxs_bbox_pair(:,2), :);

delta = cb2 - cb1;

deltaReal_forward = delta + squeeze(locref(idxs_bbox_pair(:,2), 2, :));
deltaReal_backward = -delta + squeeze(locref(idxs_bbox_pair(:,1), 1, :));

deltaPred_forward = squeeze(next_joints(idxs_bbox_pair(:,1), 1, :));
deltaPred_backward = squeeze(next_joints(idxs_bbox_pair(:,2), 2, :));

feat = cat(2, deltaReal_forward, deltaReal_backward, ...
              deltaPred_forward, deltaPred_backward);
