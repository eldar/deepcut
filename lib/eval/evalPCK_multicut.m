function [pck, auc] = evalPCK_multicut(expidxs,bUseHeadSize,bSave,legendloc,bHeadSizeFromRect,bTrain)

fprintf('evalPCK_multicut()\n');

if (nargin < 2)
    bUseHeadSize = true;
end

if (nargin < 3)
    bSave = true;
end

if (nargin < 4)
    legendloc = 'NorthWest';
end

if (nargin < 5)
    bHeadSizeFromRect = true;
end

if (nargin < 6)
    bTrain = false;
end

if (bUseHeadSize)
    prefix = 'pck-head-';
%     range = 0:0.05:0.5;
    range = 0:0.01:0.5;
%     range = 0:0.05:1.0;
else
    prefix = 'pck-torso-';
    range = 0:0.02:0.2;
end

if (bTrain)
    prefix = [prefix 'train-'];
end

fontSize = 18;
figure(100); clf; hold on;
legendName = cell(0);
set(0,'DefaultAxesFontSize', fontSize)
set(0,'DefaultTextFontSize', fontSize)

%[~,parts] = util_get_parts24();
parts = get_parts();
jidxsUpperBody = 7:12;

symmJidxs = {5,4,3,2,1,0,6,7,8,9,15,14,13,12,11,10};

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
    
    nJoints = length(p.cidxs);
    
    if (~exist('annolist','var'))
        annolist = single_person_annolist;
    end
    annolist_gt = annolist;
    
    if (~bTrain)   
        path = fileparts(p.evalTest);
    else
        path = fileparts(p.evalTrain);
    end
    if (isfield(p,'predDir'))
        path = fileparts(p.predDir);
    end
    
    fnameDist = [fileparts(p.evalTest) '/distAll'];
    
    clear boxes boxes_nonms image_ids keypointsAll;
    
    mkdir_if_missing(p.latexDir);
    mkdir_if_missing(p.plotsDir);
    mkdir_if_missing(fileparts(p.evalTest));
    
    try
        assert(false); % no load
        load(fnameDist,'distAll','accAll','pidxs','keypointsAll'); 
        assert(exist('keypointsAll','var') && length(pidxs) == length(p.pidxs) && ...
               sum(pidxs ~= p.pidxs) == 0 && size(accAll,2) == nJoints+2);
    catch
        assert(length(p.pidxs) == nJoints);
        % try to load keypoints
        if (exist([p.evalTest '.mat'],'file')>0)
            fprintf('load %s\n',p.evalTest);
            load([p.evalTest '.mat']);
            if (iscell(keypointsAll) && size(keypointsAll{1},1) == 14)
                keypointsAll = keypoints14to16(keypointsAll);
            end
        end
        
        imgidxs_missing = [];
        % convert detections into keypoints
        if (~exist('keypointsAll','var'))
            if (isfield(p,'multicut') && p.multicut == true)
                [keypointsAll, imgidxs_missing]= det2keypointsImgMulticut(expidx,parts,annolist_gt);
            elseif (isfield(p,'multicutUnaries') && p.multicutUnaries == true)
                [keypointsAll, imgidxs_missing]= det2keypointsImgMulticutUnaries(expidx,parts,annolist_gt);
            elseif (isfield(p,'usePartLocPrior') && p.usePartLocPrior)
                keypointsAll = det2keypointsPrior(expidx,parts,annolist_gt);
%             elseif (isfield(p,'dpmUnaries') && p.dpmUnaries == true)
%                 keypointsAll = det2keypointsImg(expidx,parts,annolist_gt,nDet,bNMS,bTrain,nms_thresh_det);
            elseif (exist([path '/pred'],'dir'))
                if (isfield(p,'top_det'))
                    nDet = p.top_det;
                else
                    nDet = 1;
                end
                if (isfield(p,'nms_thresh_det'))
                    bNMS = p.nms_thresh_det == 0.5;
                else
                    bNMS = true;
                end
                if (isfield(p,'nms_iomin') && p.nms_iomin)
                    nms_thresh_det = p.nms_thresh_det;
                else
                    nms_thresh_det = 0;
                end
                keypointsAll = det2keypointsImg(expidx,parts,annolist_gt,nDet,bNMS,bTrain,nms_thresh_det);
            else
                keypointsAll = det2keypoints(expidx,parts,annolist_gt);
            end
        end
%         load('./imgidxs_missing','imgidxs_missing');
%         save('./imgidxs_missing','imgidxs_missing');
        annolist_gt(imgidxs_missing) = [];
        keypointsAll(imgidxs_missing) = [];
        
        distAll = nan(length(annolist_gt),nJoints);
        accAll = zeros(length(range),nJoints+2);
        
        if (isfield(p,'evalOC') && p.evalOC)
            keypointsAll = swapKeypoints(keypointsAll);
        end
        
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
            
            % compute distance to the ground truth jidx
            distAll(:,i) = getNormGTJointDist(keypointsAll,annolist_gt,jidx,bUseHeadSize,bHeadSizeFromRect);
            if (isfield(p,'symmParts') && p.symmParts == true)
                d = getNormGTJointDist(keypointsAll,annolist_gt,jidx,bUseHeadSize,bHeadSizeFromRect,symmJidxs{jidx+1});
                distAll(:,i) = min([distAll(:,i) d],[],2);
            end
        end

        matchPCK = double(distAll <= range(end));

        if (isfield(p,'singlePerson') && p.singlePerson)
            issingle = getSinglePersonImages(annolist_gt);
            distAll(issingle==0,:) = nan;
        end
        matchPCK(isnan(distAll)) = nan;
        
        totalPCK = zeros(size(matchPCK,1),1);
        nCorrect = zeros(size(matchPCK,1),1);
        for imgidx = 1:length(totalPCK)
            idxs = ~isnan(matchPCK(imgidx,:));
            totalPCK(imgidx) = sum(matchPCK(imgidx,idxs))/length(idxs);
            nCorrect(imgidx) = sum(matchPCK(imgidx,idxs));
        end
        [val,idx] = sort(totalPCK,'ascend');
        nCorrectSort = nCorrect(idx);
        
        for i = 1:length(p.pidxs)
            dist = distAll(:,i);
%             dist = distAll(1001:2000,i);
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
        pck = accAll(k,end);
        try
            save(fnameDist,'distAll','accAll','pidxs','keypointsAll','matchPCK', 'imgidxs_missing');
%             save(fnameDist,'accAll');
        catch
            warning('Unable to save %s\n',fnameDist);
        end
    end
      
    if (bSave)
        tableFilename = [p.latexDir '/' prefix 'expidx' num2str(expidx) '.tex'];
        [row, header] = genTable(accAll(end,:),p.name);
        fid = fopen(tableFilename,'wt');assert(fid ~= -1);
        fprintf(fid,'%s\n',row{1});fclose(fid);
        fid = fopen([p.latexDir '/' prefix 'header.tex'],'wt');assert(fid ~= -1);
        fprintf(fid,'%s\n',header);fclose(fid);
    end
    auc = area_under_curve(scale01(range),accAll(:,end));
    plot(range,accAll(:,end),'color',p.colorName,'LineStyle','-','LineWidth',3);
    legendName{end+1} = sprintf('%s, AUC: %1.1f%%', p.name, auc);
    
    fprintf('%s\n',legendName{end});
end

legend(legendName,'Location',legendloc);
set(gca,'YLim',[0 100]);

xlabel('Normalized distance');
ylabel('Detection rate, %');

if (bSave)
    print(gcf, '-dpng', [p.plotsDir '/' prefix 'expidx' num2str(expidx) '.png']);
    printpdf([p.plotsDir '/' prefix 'expidx' num2str(expidx) '.pdf']);
end

%gvv_auc_curve(accAll, range);


end