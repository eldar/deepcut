function keep = nms_dist(points,nms_thresh,refDist)
if (nms_thresh <= 0)
    keep = 1:size(points,1);
    return;
end
[val,idxs] = sort(points(:,3),'descend');
points = points(idxs,:);
idx_curr = 1;
keep = idxs;
while (idx_curr + 1 <= size(points,1))
    top = points(idx_curr,:);
    dist = sqrt(sum((points(idx_curr+1:end,1:2) - repmat(top(1:2),size(points(idx_curr+1:end,:),1),1)).^2,2));
    idx = find(dist./refDist <= nms_thresh);
    keep(idx_curr+idx) = [];
    points(idx_curr+idx,:) = [];
    idx_curr = idx_curr + 1;
end
end