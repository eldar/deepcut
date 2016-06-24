function [unLab, unPos] = removeSmallClusters(unLab,minClusSize,unPos,pidxOffset,cidxs)

clusidxs = unLab(unLab(:,1)<1000,2);
clusidxsUniq = unique(clusidxs);
nPointClus = zeros(length(clusidxsUniq),1);

% compute number of points per cluster
for j = 1:length(clusidxsUniq)
    nPointClus(j) = sum((unLab(:,2) == clusidxsUniq(j)));
end

% remove small clusters
idxs = find(nPointClus < minClusSize);
for i=1:length(idxs)
    for j = 1:length(cidxs)
        unPos{pidxOffset+j}(unLab(:,2) == clusidxsUniq(idxs(i)),:) = [];
    end
    unLab(unLab(:,2) == clusidxsUniq(idxs(i)),:) = [];
end

end