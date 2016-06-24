function evalPCKbackproject(expidxs,bUseHeadSize,bSave,bHeadSizeFromRect)

fprintf('evalPCK()\n');

if (nargin < 2)
    bUseHeadSize = true;
end

if (nargin < 3)
    bSave = true;
end

if (nargin < 4)
    bHeadSizeFromRect = true;
end

if (bUseHeadSize)
    prefix = 'pck-head-';
    range = 0:0.05:0.5;
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

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = rcnn_exp_params(expidx);
    % load ground truth
    [annolist, imgidxs_gt, rectidxs_gt, rect_ignore] = getAnnolist(expidx);
    annolist_gt = annolist(imgidxs_gt);
    
    fnameDist = [fileparts(p.evalTest) '/distAll'];
    
    mkdir_if_missing(p.latexDir);
    mkdir_if_missing(p.plotsDir);
    
    try
        assert(false); % no load
        load(fnameDist,'distAll','accAll','pidxs','keypointsAll'); 
        assert(exist('keypointsAll','var') && length(pidxs) == length(p.pidxs) && ...
               sum(pidxs ~= p.pidxs) == 0 && size(accAll,2) == nJoints+2);
    catch
        assert(length(p.pidxs) == nJoints);
        % load keypoints
        if (exist([p.evalTest '.mat'],'file')>0)
            fprintf('load %s\n',p.evalTest);
            load([p.evalTest '.mat']);
            assert(exist('keypointsAll','var')>0||exist('bboxAll','var')>0)
        else
            warning('file not found: %s\n',[p.evalTest '.mat']);
            keypointsAll = backprojectKeypointsImg(expidx,1,length(annolist_gt),false);
        end
                
        distAll = nan(sum(cellfun(@length,rectidxs_gt(imgidxs_gt))),nJoints);
        accAll = zeros(length(range),nJoints+2);
        
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
            
            % compute distance to the ground truth jidx
            distAll(:,i) = getNormGTJointDistBackproject(keypointsAll,annolist_gt,jidx,bUseHeadSize,rectidxs_gt(imgidxs_gt),bHeadSizeFromRect);
        end

        matchPCK = double(distAll <= range(end));

%         if (isfield(p,'singlePerson') && p.singlePerson)
%             issingle = getSinglePersonImages(annolist_gt);
%             distAll(issingle==0,:) = nan;
%         end
        matchPCK(isnan(distAll)) = nan;

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
        try
            save(fnameDist,'distAll','accAll','pidxs','keypointsAll','matchPCK');
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

legend(legendName,'Location','NorthWest');
set(gca,'YLim',[0 100]);

xlabel('Normalized distance');
ylabel('Detection rate, %');

if (bSave)
    print(gcf, '-dpng', [p.plotsDir '/' prefix 'expidx' num2str(expidx) '.png']);
    printpdf([p.plotsDir '/' prefix 'expidx' num2str(expidx) '.pdf']);
end

end