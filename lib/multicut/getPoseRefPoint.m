function poseRefPoint = getPoseRefPoint(keypointsAll,pidxsHead)

poseRefPoint = zeros(size(keypointsAll,2),2);
for clusidx = 1:size(keypointsAll,2)
    pp = [];
    % reference point is head center
%     pidxHC = 8; % head center
%     pidxN = 15; % neck
%     pidxHT = 16; % head top
    for pidx = pidxsHead
        pp = [pp; keypointsAll{pidx,clusidx}];
    end
    if (isempty(pp))
        pp = [-inf -inf];
    end
    poseRefPoint(clusidx,:) = mean(pp,1);
end

end