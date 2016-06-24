function evalRP_spatial(expidxs,bUseHeadSize,bSave)

fprintf('evalRP()\n');

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
    prefix = 'pck-head-rpc-';
    range = 0:0.05:0.5;
else
    prefix = 'pck-torso-rpc-';
    range = 0:0.02:0.2;
end

fontSize = 18;
figure(100); clf; hold on;
legendName = cell(0);
set(0,'DefaultAxesFontSize', fontSize)
set(0,'DefaultTextFontSize', fontSize)

[~,parts] = util_get_parts_spatial();
nJoints = 14;
jidxsUpperBody = 7:12;

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = rcnn_exp_params(expidx);
    
    % load ground truth
    [annolist, imgidxs_gt, rectidxs_gt, rect_ignore, ~, keypointsidxs] = getAnnolist(expidx);
    annolist_gt = annolist(imgidxs_gt);
        
    mkdir_if_missing(p.latexDir);
    mkdir_if_missing(p.plotsDir);
    
    assert(length(p.pidxs) == nJoints);
    
    % load keypoints
    if (exist([p.evalTest '.mat'],'file')>0 && true)
        fprintf('load %s\n',p.evalTest);
        load([p.evalTest '.mat']);
    else
        warning('file not found: %s\n',[p.evalTest '.mat']);
        endpointsAll = backprojectSpatialNMS(expidx,1,length(annolist_gt),false);
        save([p.evalTest '.mat'],'endpointsAll');
    end
    
    endpointsAll = endpointsAll(keypointsidxs);
    assert(length(annolist_gt) == length(endpointsAll));
    
    tp_score_all = cell(length(endpointsAll(1).det),1);
    fp_score_all = cell(length(endpointsAll(1).det),1);
    totalPos_all = cell(length(endpointsAll(1).det),1);
    tp_points_all = cell(length(endpointsAll(1).det),1);
    fp_points_all = cell(length(endpointsAll(1).det),1);
    tp_idxs_all = cell(length(endpointsAll(1).det),1);
    fp_idxs_all = cell(length(endpointsAll(1).det),1);
    fp_dist_all = cell(length(endpointsAll(1).det),1);
    missing_recall_all = cell(length(endpointsAll(1).det),1);
    
    fprintf('compute tp/fp\n');
    for i = [1:4 6:length(parts)]
        fprintf('pidx %d\n',i);

        % compute distance to the ground truth jidx
        [dist,score,points] = getStickDistRP(endpointsAll,annolist_gt,parts(i).xaxis,i);
        
        [tp_score_all{i},fp_score_all{i},totalPos_all{i},tp_points_all{i},fp_points_all{i},tp_idxs_all{i},fp_idxs_all{i},fp_dist_all{i},missing_recall_all{i}] = ...
            computeTFP_spatial(dist,score,points,rectidxs_gt(imgidxs_gt),rect_ignore(imgidxs_gt));%,rect_ignore(imgidxs_gt));
    end

    labels = {'rl-leg','ru-leg','lu-leg','ll-leg','torso','head','rl-arm','ru-arm','lu-arm','ll-arm','r-shoulder','l-shoulder','r-hip','l-hip'}; 
    
    nVis = 0;
    
    for i = [1:4 6:length(parts)]
        figure(100); clf;
        
        tp_score = tp_score_all{i};
        fp_score = fp_score_all{i};
        totalPos = totalPos_all{i};
        
        [precision,recall,sorted_scores,sortidx,sorted_labels] = getRPC([tp_score; fp_score], [ones(length(tp_score),1);zeros(length(fp_score),1)],totalPos);
        plotRPC(precision,recall,p.colorName,'-',labels{i});
        ap = VOCap(recall,precision)*100;
        legendName = sprintf('%s, AP: %1.1f%%', p.name, ap);
        legend(legendName,'Location','NorthWest');
        fprintf('%s\n',legendName);
        
        if (bSave)
            print(gcf, '-dpng', [p.plotsDir '/' prefix labels{i} '-' 'expidx' num2str(expidx) '.png']);
            printpdf([p.plotsDir '/' prefix labels{i} '-' 'expidx' num2str(expidx) '.pdf']);
        end
        
        if (nVis > 0)
            figure(101); clf;
            fp_idxs_sort = sortidx(sorted_labels == 0) - length(tp_score);
            first_idxs = fp_idxs_all{i}(fp_idxs_sort);
            first_scores = fp_score_all{i}(fp_idxs_sort);
            first_points = fp_points_all{i}(fp_idxs_sort,:);
            first_dist = fp_dist_all{i}(fp_idxs_sort,:);
            %         tp_idxs_sort = sortidx(sorted_labels == 1);
            %         first_idxs = tp_idxs_all{p.pidxs == groups{i}(1)}(tp_idxs_sort);
            %         first_scores = tp_score_all{p.pidxs == groups{i}(1)}(tp_idxs_sort);
            %         first_points = tp_points_all{p.pidxs == groups{i}(1)}(tp_idxs_sort,:);

            visTFP_spatial(first_idxs(1:nVis),first_points,first_dist,first_scores,annolist_gt,rectidxs_gt(imgidxs_gt),parts(i).xaxis,[fileparts(p.evalTest) '/vis/fp/pidx_' num2str(i)]);
            missing_recall = missing_recall_all{i};
            idxs = find(cellfun(@isempty,missing_recall) == 0);
            
            fprintf('missing recall: %1.2f%%\n',sum(cellfun(@length,missing_recall))/totalPos_all{i}*100);
            visMissingRecall_spatial(missing_recall(idxs(1:nVis)),annolist_gt(idxs(1:nVis)),parts(i).xaxis,[fileparts(p.evalTest) '/vis/mr/pidx_' num2str(i)]);
        end
    end
end



end