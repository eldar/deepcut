function [feat_norm,feat_min,feat_max]= getFeatNorm(feat,feat_min,feat_max)

if (nargin == 1)
    feat_min = min(feat);
    feat_max = max(feat);
end

feat_norm = (feat - repmat(feat_min,size(feat,1),1))./repmat(feat_max - feat_min,size(feat,1),1);

end