function keypointsAll = multicut2keypointsBBox(unProb,unPosAll,pidxOffset,boxesAll)

keypointsAll = cell(size(unPosAll,1),size(boxesAll,1));
bDisjoint = true;

for ridx = 1:size(boxesAll,1)
    bbox = boxesAll(ridx,:);
    for j = 1:size(unPosAll,1)-pidxOffset
        unPos = unPosAll{j+pidxOffset};
        idxs = find((unPos(:,1) >= bbox(1) & unPos(:,2) >= bbox(2) & ...
            unPos(:,1) <= bbox(3) & unPos(:,2) <= bbox(4)));
        
        [val,idx] = max(unProb(idxs,j));
        keypointsAll{j+pidxOffset,ridx} = unPos(idxs(idx),:);
        if (bDisjoint)
            unProb(idxs(idx),:) = -inf;
        end
    end
end
end