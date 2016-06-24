function keypointsAll = multicut2keypoints(unLab,unProb,unPos,pidxOffset)

idxs = find(unLab(:,1) < 1000);
lc_uniq = unique(unLab(idxs,2));
keypointsAll = cell(size(unPos,1),length(lc_uniq));

for j = 1:length(lc_uniq)
    lc = lc_uniq(j);
    idxsc = find(unLab(:,2) == lc & unLab(:,1) < 1000);
    lp_uniq = unique(unLab(idxsc,1));
    
    % compute keypoints as weighted sum of locations
    for i = 1:length(lp_uniq)
        lp = lp_uniq(i);
        idxsp = find(unLab(idxsc,1) == lp);
        prob = unProb(idxsc(idxsp),lp+1);
        w = prob;
        w = w./sum(w);
        pos = sum(unPos{lp+pidxOffset+1}(idxsc(idxsp),:).*[w w],1);
        keypointsAll{lp+pidxOffset+1,j} = pos;
    end
end
end