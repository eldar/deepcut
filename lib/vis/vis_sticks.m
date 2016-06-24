function vis_sticks(expidxs,nImgs,bSort,bTrain)

fprintf('vis_sticks()\n');

if (nargin < 3)
    bSort = false;
end

if (nargin < 4)
    bTrain = false;
end

nJoints = 14;

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = exp_params(expidx);
    % load ground truth
    if (bTrain)
        load(p.trainGT);
        path = fileparts(p.evalTrain);
    else
        load(p.testGT);
        path = fileparts(p.evalTest);
    end
    if (~exist('annolist','var'))
        annolist = single_person_annolist;
    end
    annolist = set_full_path(annolist,p.imgDir);
    fnameDist = [path '/distAll'];
    
    try
%         assert(false);
        load(fnameDist,'pidxs','keypointsAll','matchPCK');
        assert(exist('keypointsAll','var') && length(pidxs) == length(p.pidxs) && ...
               sum(pidxs ~= p.pidxs) == 0 && size(matchPCK,2) == nJoints);
    catch
        warning('keypoints are not found, running evalPCK...');
        evalPCK(expidx);
        load(fnameDist,'pidxs','keypointsAll','matchPCK');
        assert(exist('keypointsAll','var') && length(pidxs) == length(p.pidxs) && ...
               sum(pidxs ~= p.pidxs) == 0 && size(matchPCK,2) == nJoints);
    end

    nImgs = min(length(keypointsAll),nImgs);
    keypointsAll = keypointsAll(1:nImgs);
    if (isfield(p, 'testGTnopad'))
        load(p.testGTnopad,'annolist');
        keypointsAll = projectKeypoints(keypointsAll,fileparts(p.testGTnopad),fileparts(p.testGT));%,annolist
        endpointsAllGT = gt2endpoints(p.testGTnopad);
    else
        endpointsAllGT = gt2endpoints(p.testGT);
    end
    endpointsAll = keypoints2endpoints(keypointsAll);
    matchPCP = eval_match_parts_gt(endpointsAll, annolist(1:min(length(annolist),length(endpointsAll))), 1.0, 1);
    pcp = eval_plot_pcp(matchPCP,1:10);
    
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
    plot_sticks(p, endpointsAll, annolist, visDir, matchPCP, keypointsAll, matchPCK, p.pidxs, endpointsAllGT, bSort);
end

end