function [feat,idxs_bbox_pair,cb1,cb2,o] = get_spatial_features_same_img(locs,idxs_bbox_pair,scores,class_id,bVis)

if (nargin < 3)
    scores = [];
end

if (nargin < 5)
    bVis = false;
end

if (nargin < 6)
    lab = ones(size(locs,1),1);
end

half_size = 132;

xs = locs(:, 1);
ys = locs(:, 2);
boxes = [xs-half_size, ys-half_size, xs+half_size, ys+half_size];

cb1 = [mean(boxes(idxs_bbox_pair(:,1),[1 3]),2) mean(boxes(idxs_bbox_pair(:,1),[2 4]),2)];
cb2 = [mean(boxes(idxs_bbox_pair(:,2),[1 3]),2) mean(boxes(idxs_bbox_pair(:,2),[2 4]),2)];

h1 = boxes(idxs_bbox_pair(:,1),4) - boxes(idxs_bbox_pair(:,1),2);
h2 = boxes(idxs_bbox_pair(:,2),4) - boxes(idxs_bbox_pair(:,2),2);
assert(any(h1>0));
assert(any(h2>0));

h_m = (h1+h2)/2;
offset = abs(cb1 - cb2)./[h_m h_m];
sc = abs(h1 - h2)./h_m;
offsetM = offset(:,1).*offset(:,2);
[o,o2,o3] = boxoverlapMx(boxes(idxs_bbox_pair(:,1),:), boxes(idxs_bbox_pair(:,2),:));

feat = cat(2, offset, offsetM, sc, o, o2, o3, ...
            offset.^2, offsetM.^2, sc.^2, o.^2, o2.^2, o3.^2, ...
            exp(-offset), exp(-offsetM), exp(-sc), exp(-o), exp(-o2), exp(-o3));
if (~isempty(scores))
    scores1 = scores(idxs_bbox_pair(:,1),:);
    scores2 = scores(idxs_bbox_pair(:,2),:);
    feat = cat(2, feat, scores1, scores2);
end

if (bVis)
    idxs = 1:min(size(cb1,1),100);
    
    plot(cb1(idxs,1),cb1(idxs,2),'b+','MarkerSize',10);
    plot(cb2(idxs,1),cb2(idxs,2),'g+','MarkerSize',10);
    
    for i = 1:length(idxs)
        if (lab(idxs(i)) == 1)
            plot([cb1(idxs(i),1); cb2(idxs(i),1)],[cb1(idxs(i),2); cb2(idxs(i),2)],'r-','lineWidth',1);
        else
            plot([cb1(idxs(i),1); cb2(idxs(i),1)],[cb1(idxs(i),2); cb2(idxs(i),2)],'b-','lineWidth',1);
        end
    end
    
    legendName = {['pidx' num2str(class_id)]};
    legend(legendName);
end