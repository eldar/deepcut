function [pcp,nseg] = eval_plot_pcp(isMatchAll, pidxs)

nMatchAll = 0;
nSegAll = 0;
pcp = zeros(1,11);
nseg = zeros(1,11);
idxsAll = [];
for pidx = pidxs
    idxs = find(~isnan(isMatchAll(:,pidx)));
    idxsAll = union(idxsAll,idxs);
    nSeg = sum(~isnan(isMatchAll(:,pidx)));
    nMatch = sum(isMatchAll(:,pidx) == 1);
    nMatchAll = nMatchAll + nMatch;
    nSegAll = nSegAll + nSeg;
    pcp(pidx) = nMatch/nSeg*100;
    nseg(pidx) = nSeg;
end

pcp(end) = nMatchAll/nSegAll*100;
nseg(end) = nSegAll;

% pcp = [pcp(5) (pcp(2)+pcp(3))/2 (pcp(1)+pcp(4))/2 (pcp(8)+pcp(9))/2 (pcp(7)+pcp(10))/2 pcp(6) (pcp(5)+pcp(8)+pcp(9)+pcp(7)+pcp(10))/5 pcp(11)];