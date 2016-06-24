function [feat,idxs_bbox_pair,cb1,cb2] = get_spatial_features_diff_img_hist_dist(boxes,idxs_bbox_pair,rot_offset,class_id,bVis,lab)

if (nargin < 3)
    rot_offset = 0;
end

if (nargin < 5)
    bVis = false;
end

if (nargin < 6)
    lab = ones(size(boxes,1),1);
end

cb1 = [mean(boxes(idxs_bbox_pair(:,1),[1 3]),2) mean(boxes(idxs_bbox_pair(:,1),[2 4]),2)];
cb2 = [mean(boxes(idxs_bbox_pair(:,2),[1 3]),2) mean(boxes(idxs_bbox_pair(:,2),[2 4]),2)];

deltaX = cb1(:,1)-cb2(:,1);
deltaY = cb1(:,2)-cb2(:,2);

dist = sqrt(sum((cb1-cb2).^2,2));
angle = atan2(deltaY,deltaX);
angle = angle - rot_offset;
angle = wrapMinusPiPifast(angle);

feat = cat(2,dist,angle);
% feat = cat(2,dist,angle,deltaX,deltaY);

if (bVis)
    idxs = 1:min(size(cb1,1),100);
%     figure(100);clf; 
        
    plot(cb1(idxs,1),cb1(idxs,2),'b+','MarkerSize',10);
    plot(cb2(idxs,1),cb2(idxs,2),'g+','MarkerSize',10);
    
    for i = 1:length(idxs)
        if (lab(idxs(i)) == 1)
            plot([cb1(idxs(i),1); cb2(idxs(i),1)],[cb1(idxs(i),2); cb2(idxs(i),2)],'r-','lineWidth',1);
        else
            plot([cb1(idxs(i),1); cb2(idxs(i),1)],[cb1(idxs(i),2); cb2(idxs(i),2)],'b-','lineWidth',1);
        end
    end
    
    legendName = {['pidx ' num2str(class_id(1)) '-' num2str(class_id(2))]};
    legend(legendName);
end