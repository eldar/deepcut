function vis_sticks_multicut(expidxs,bSort)

fprintf('vis_sticks()\n');

if (nargin < 2)
    bSort = false;
end

nJoints = 14;

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = exp_params(expidx);
    % load ground truth
    load(p.testGT, 'annolist');

    fnameDist = [fileparts(p.evalTest) '/distAll'];
    load(fnameDist,'distAll','accAll','pidxs','keypointsAll','matchPCK', 'imgidxs_missing');
    annolist(imgidxs_missing) = [];

    nImgs = length(keypointsAll);
    %nImgs = 100;
    endpointsAllGT = gt2endpoints(annolist(1:nImgs));
    endpointsAll = keypoints2endpoints(keypointsAll(1:nImgs));
    matchPCP = eval_match_parts_gt(endpointsAll, annolist(1:min(length(annolist),length(endpointsAll))), 1.0, 1);
    %pcp = eval_plot_pcp(matchPCP,1:10);
    
    %{
    if (bSort)
        visDir = [p.expDir '/' p.shortName '/cachedir/test/vis/sort'];
        pckImg = zeros(nImgs,1);
        nanImg = zeros(nImgs,1);
        for imgidx = 1:nImgs
            pckImg(imgidx) = sum(matchPCK(imgidx,~isnan(matchPCK(imgidx,:))));
            allNaNImg(imgidx) = sum(~isnan(matchPCK(imgidx,:))) == 0;
        end
        pckImg(allNaNImg) = nan;
        [~,idxs] = sort(pckImg);
        endpointsAll = endpointsAll(idxs,:);
        keypointsAll = keypointsAll(idxs,:);
        matchPCP = matchPCP(idxs,:);
        matchPCK = matchPCK(idxs,:);
        annolist = annolist(idxs);
        endpointsAllGT = endpointsAllGT(idxs);
    else
        visDir = [p.expDir '/' p.shortName '/cachedir/test/vis/'];
    end
    %}
    visDir = fullfile(p.multicutDir, 'visPred');
    mkdir_if_missing(visDir);
    plot_sticks(p, endpointsAll, annolist, visDir, matchPCP, keypointsAll, matchPCK, p.pidxs, endpointsAllGT, bSort);
end

end