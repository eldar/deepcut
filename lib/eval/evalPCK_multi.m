function evalPCK_multi(expidxs,bUseHeadSize,bHeadSizeFromRect,bTrain)

fprintf('evalPCK()\n');

if (nargin < 2)
    bUseHeadSize = true;
end

if (nargin < 3)
    bHeadSizeFromRect = false;
end

if (nargin < 4)
    bTrain = false;
end

if (bUseHeadSize)
    prefix = 'pck-head-';
    range = 0:0.01:0.5;
else
    prefix = 'pck-torso-';
    range = 0:0.01:0.2;
end

if (bTrain)
    prefix = [prefix 'train-'];
end

if bTrain
    image_set = 'train';
else
    image_set = 'test';
end

legendName = cell(0);

[~,parts] = util_get_parts24();
jidxsUpperBody = 7:12;
nJoints = 14;
% nJoints = length(p.cidxs);
for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = exp_params(expidx);
    
    % load ground truth
    if (~bTrain)
        load(p.testGT);
    else
        load(p.trainGT);
        annolist = annolist(1:17000);
    end
    
    if (~exist('annolist','var'))
        annolist = single_person_annolist;
    end
    annolist_gt = annolist;%(1:100)
    
    if (~exist(p.outputDir,'dir')), mkdir(p.outputDir); end
    fnameEvalRes = [fileparts(p.outputDir) '/evalAll'];
    
    clear boxes boxes_nonms image_ids keypointsAll;
    
    if (~exist(p.latexDir,'dir')), mkdir(p.latexDir); end
    if (~exist(p.plotsDir,'dir')), mkdir(p.plotsDir); end
    
%     assert(length(p.pidxs) == nJoints);
%     assert(length(p.cidxs) == nJoints);
    
    if (~isfield(p,'bidxs'))
        bidxs = 1:length(p.pidxs)+1;
    else
        bidxs = p.bidxs;
    end

    % Load keypoints
    fn = fullfile(p.exp_dir, image_set, 'keypointsAll.mat');
    if exist(fn, 'file') ~= 2
        scoremaps2keypoints(expidx, image_set);
    end
    fprintf('loading %s\n', fn);
    load(fn, 'keypointsAll');
    
%     visBoxes(annolist_gt,keypointsAll,p.pidxs,parts);
    nrects = 0;
    for imgidx = 1:length(annolist_gt)
        nrects = nrects + length(annolist_gt(imgidx).annorect);
    end
    
    distAll = nan(nrects,nJoints);
    accAll = zeros(length(range),nJoints+2);
        
    for i = 1:length(p.pidxs)
      pidx = p.pidxs(i);
      % part is a joint
      assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
      jidx = parts(pidx+1).pos(1);
            
      % compute distance to the ground truth jidx
      distAll(:,i) = getNormGTJointDistMulti(keypointsAll,annolist_gt,jidx,bUseHeadSize,bHeadSizeFromRect,jidx,nrects);
    end
    matchPCK = double(distAll <= range(end));
        
    totalPCK = zeros(size(matchPCK,1),1);
    nCorrect = zeros(size(matchPCK,1),1);
    for imgidx = 1:length(totalPCK)
      idxs = ~isnan(distAll(imgidx,:));
%       idxs = ~isnan(matchPCK(imgidx,:));
      totalPCK(imgidx) = sum(matchPCK(imgidx,idxs))/sum(idxs);
%       totalPCK(imgidx) = sum(matchPCK(imgidx,idxs))/length(idxs);
      nCorrect(imgidx) = sum(matchPCK(imgidx,idxs));
    end
        
    for i = 1:length(p.pidxs)
      dist = distAll(:,i);
      % remove the cases without the ground truth
      dist(isnan(dist)) = [];
      % compute accuracy for each threshold
      for k = 1:numel(range)
        accAll(k,i) = 100*mean(dist<=range(k));
      end
    end
                
    % compute avg PCKh upper body
    dist = reshape(distAll(:,jidxsUpperBody),size(distAll,1)*length(jidxsUpperBody),1);
    dist(isnan(dist)) = [];
    for k = 1:numel(range)
      accAll(k,end-1) = 100*mean(dist<=range(k));
    end
    
    % compute avg PCKh full body
    dist = reshape(distAll,size(distAll,1)*size(distAll,2),1);
    dist(isnan(dist)) = [];
    for k = 1:numel(range)
      accAll(k,end) = 100*mean(dist<=range(k));
    end
    
    pidxs = p.pidxs;
%     save(fnameEvalRes,'distAll','accAll','pidxs','keypointsAll','matchPCK');
    
    auc = area_under_curve(scale01(range),accAll(:,end));
    legendName{end+1} = sprintf('%s, AUC: %1.1f%%', p.name, auc);
    
    tableFilename = [p.latexDir '/' prefix 'expidx' num2str(expidx) '.tex'];
    [row, header] = genTableNew(accAll(end,:),auc,p.name);
    row = strrep(row,'NaN','-');
    fid = fopen(tableFilename,'wt');assert(fid ~= -1);
    fprintf(fid,'%s\n',row{1});fclose(fid);
    fid = fopen([p.latexDir '/' prefix 'header.tex'],'wt');assert(fid ~= -1);
    fprintf(fid,'%s\n',header);fclose(fid);
    
%     fprintf('%s\n',legendName{end});
end

end