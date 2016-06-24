function evalPCK_topScore(expidxs,bUseHeadSize,bSave,legendloc,bHeadSizeFromRect)

fprintf('evalPCK()\n');

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

if (bUseHeadSize)
    prefix = 'pck-head-';
%     range = 0:0.05:0.5;
    range = 0:0.01:0.5;
%     range = 0:0.05:1.0;
else
    prefix = 'pck-torso-';
    range = 0:0.02:0.2;
end

fontSize = 18;
figure(100); clf; hold on;
legendName = cell(0);
set(0,'DefaultAxesFontSize', fontSize)
set(0,'DefaultTextFontSize', fontSize)

[~,parts] = util_get_parts24();
nJoints = 14;
jidxsUpperBody = 7:12;

nTopRange = [1 10:10:1000 2000:1000:10000];

symmJidxs = {5,4,3,2,1,0,6,7,8,9,15,14,13,12,11,10};

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = rcnn_exp_params(expidx);
    % load ground truth
    load(p.testGT);
    if (~exist('annolist','var'))
        annolist = single_person_annolist;
    end
    annolist_gt = annolist;
       
    path = fileparts(p.evalTest);
    fnameDist = [path '/distAll'];
    
    clear boxes boxes_nonms image_ids keypointsAll;
    
    mkdir_if_missing(p.latexDir);
    mkdir_if_missing(p.plotsDir);
    
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
        
        % convert detections into keypoints
        if (~exist('keypointsAll','var'))
            if (isfield(p,'usePartLocPrior') && p.usePartLocPrior)
                keypointsAll = det2keypointsPrior(expidx,parts,annolist_gt);
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
                keypointsAll = det2keypointsImg(expidx,parts,annolist_gt,nDet,bNMS);
            else
                keypointsAll = det2keypoints(expidx,parts,annolist_gt);
            end
        end
                
        distAll = nan(length(annolist_gt),nJoints,length(nTopRange));
        accAll = zeros(length(nTopRange),nJoints+2);
        
        for i = 1:length(p.pidxs)
            tic
            pidx = p.pidxs(i);
            fprintf('pidx: %d\n',pidx);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
            
            % compute distance to the ground truth jidx
            for j = 1:length(nTopRange)
                distAll(:,i,j) = getNormGTJointDist_nTop(keypointsAll,annolist_gt,jidx,bUseHeadSize,bHeadSizeFromRect,jidx,nTopRange(j));
            end
            
            if (isfield(p,'symmParts') && p.symmParts == true)
                d = getNormGTJointDist(keypointsAll,annolist_gt,jidx,bUseHeadSize,bHeadSizeFromRect,symmJidxs{jidx+1});
                distAll(:,i) = min([distAll(:,i) d],[],2);
            end
            toc
        end

%         matchPCK = double(distAll <= range(end));
% 
%         if (isfield(p,'singlePerson') && p.singlePerson)
%             issingle = getSinglePersonImages(annolist_gt);
%             distAll(issingle==0,:) = nan;
%         end
%         matchPCK(isnan(distAll)) = nan;

        for i = 1:length(p.pidxs)
            % compute accuracy for each threshold
            for k = 1:numel(nTopRange)
                dist = squeeze(distAll(:,i,k));
                % remove the cases without the ground truth
                dist(isnan(dist)) = [];
                accAll(k,i) = 100*mean(dist<=range(end));
            end
        end
                
        % compute avg PCKh upper body
        for k = 1:numel(nTopRange)
            dist = reshape(distAll(:,jidxsUpperBody,k),size(distAll,1)*length(jidxsUpperBody),1);
            dist(isnan(dist)) = [];
            accAll(k,end-1) = 100*mean(dist<=range(end));
        end
        
        % compute avg PCKh full body
        for k = 1:numel(nTopRange)
            dist = reshape(distAll(:,:,k),size(distAll,1)*size(distAll,2),1);
            dist(isnan(dist)) = [];
            accAll(k,end) = 100*mean(dist<=range(end));
        end
        
        pidxs = p.pidxs;
        try
            save(fnameDist,'distAll','accAll','pidxs','keypointsAll','matchPCK');
        catch
            warning('Unable to save %s\n',fnameDist);
        end
    end
      
%     if (bSave)
%         tableFilename = [p.latexDir '/' prefix 'expidx' num2str(expidx) '.tex'];
%         [row, header] = genTable(accAll(end,:),p.name);
%         fid = fopen(tableFilename,'wt');assert(fid ~= -1);
%         fprintf(fid,'%s\n',row{1});fclose(fid);
%         fid = fopen([p.latexDir '/' prefix 'header.tex'],'wt');assert(fid ~= -1);
%         fprintf(fid,'%s\n',header);fclose(fid);
%     end
    labels = {'rankle','rknee','rhip','lhip','lknee','lankle','rwrist','relbow','rshoulder','lshoulder','lelbow','lwrist','neck','tophead','upperBody','fullBody'};
    for i = 1:length(p.pidxs) + 2
        figure(100); clf;
        auc = area_under_curve(scale01(nTopRange),accAll(:,i));
        semilogx(nTopRange,accAll(:,i),'color',p.colorName,'LineStyle','-','LineWidth',3);
        legendName = sprintf('%s, AUC: %1.1f%%', [p.name, ', ' labels{i}], auc);
        legend(legendName,'Location','southEast');
        set(gca,'YLim',[0 100],'XTick',[1 10 100 1000 10000]);

        xlabel('Normalized distance');
        ylabel('Detection rate, %');
        
        print(gcf, '-dpng', [p.plotsDir '/pck-head-nTop-expidx' num2str(expidx) '-' labels{i} '.png']);
        printpdf([p.plotsDir '/pck-head-nTop-expidx' num2str(expidx) '-' labels{i} '.pdf']);
        fprintf('%s\n',legendName);
    end
end

end