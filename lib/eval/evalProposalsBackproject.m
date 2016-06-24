function evalProposalsBackproject(expidxs,bUseHeadSize,bSave,bHeadSizeFromRect)

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
%     annolist_gt = annolist_gt(1:79);
    
    mkdir_if_missing(p.latexDir);
    mkdir_if_missing(p.plotsDir);
    
    assert(length(p.pidxs) == nJoints);
    
    % load keypoints
    assert(exist([p.evalTest '.mat'],'file')>0);
    fprintf('load %s\n',p.evalTest);
    load([p.evalTest '.mat']);
    
    distAllJoints = cell(length(annolist_gt),16);
    scoreAllJoints = cell(length(annolist_gt),16);
    
    distAll = nan(length(annolist_gt),nJoints);
    accAll = zeros(length(range),nJoints+2);
    
    fprintf('compute tp/fp\n');
    for i = 1:length(p.pidxs)
        pidx = p.pidxs(i);
        fprintf('pidx %d\n',pidx);
        % part is a joint
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);
        
        % compute distance to the ground truth jidx
        if (isfield(p, 'evalIoU') && p.evalIoU == 1)
            [dist,score,points] = getOverlapGT(bboxAll,annolist_gt,jidx,p.scale);
        else
            [dist,score,points] = getNormGTJointDistRP(keypointsAll,annolist_gt,jidx,bUseHeadSize,bHeadSizeFromRect);
        end
        distAllJoints(:,jidx+1) = dist;
        scoreAllJoints(:,jidx+1) = score;
    end
    
    for i = 1:length(p.pidxs)
        pidx = p.pidxs(i);
        fprintf('pidx %d\n',pidx);
        % part is a joint
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);
        
        for imgidx = 1:length(annolist_gt)
            
            if (isempty(scoreAllJoints{imgidx}{jidx+1}))
                continue;
            end
            distAllJoints = inf(length(keypointsAll(imgidx).det),1);
            jidxs2 = find(~cellfun(@isempty,keypointsAll(imgidx).det));
            
            for jidx2 = jidxs2'
                xy = keypointsAll(imgidx).det{jidx2};
                xy = reshape(xy,length(xy)/2,2);
                d = sqrt(sum((repmat([p.x p.y],size(xy,1),1) - xy).^2,2));
                [val,idx] = min(dist);
                distAll(jidx2+1) = norm([p.x p.y] - xy(idx,:))/refDist;
            end
            dist(imgidx) = min(distAll);%norm([p.x p.y] - xy(idx,:))/refDist;
        end
    end
        
    
    
    
        
        bFixPart = false;
        if (isfield(p,'fix_proposals_part'))
            bFixPart = p.fix_proposals_part;
        end
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
            
            % compute distance to the ground truth jidx
            distAll(:,i) = getNormGTJointDistOracle(keypointsAll,annolist_gt,jidx,bUseHeadSize,bFixPart);
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
    
%         pidxs = p.pidxs;
%         save(fnameDist,'tp_score_all','fp_score_all','totalPos_all','pidxs','tp_points_all','fp_points_all','tp_idxs_all','fp_idxs_all');
    
    groups = {22, 21, 12, 19, 14, 17, 16, 9, 0, 7, 2, 5, 4, 23, [0 9], [2 7], [4 5], [12 21], [14 19], [16 17], [22 23]};
    labels = {'neck','lwrist','rwrist','lelbow','relbow','lshoulder','rshoulder','lankle','rankle','lknee','rknee','lhip','rhip','tophead','ankle','knee','hip','wrist','elbow','shoulder','head'};
    
    for i = 1:length(groups)
        figure(100); clf;
        if (length(groups{i}) == 2)
            tp_score = [tp_score_all{p.pidxs == groups{i}(1)};tp_score_all{p.pidxs == groups{i}(2)}];
            fp_score = [fp_score_all{p.pidxs == groups{i}(1)};fp_score_all{p.pidxs == groups{i}(2)}];
            totalPos = totalPos_all{p.pidxs == groups{i}(1)} + totalPos_all{p.pidxs == groups{i}(2)};
        else
            tp_score = tp_score_all{p.pidxs == groups{i}(1)};
            fp_score = fp_score_all{p.pidxs == groups{i}(1)};
            totalPos = totalPos_all{p.pidxs == groups{i}(1)};
        end
        
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
        
        if (length(groups{i}) == 1)
            fp_idxs_sort = sortidx(sorted_labels == 0) - length(tp_score);
            first_idxs = fp_idxs_all{p.pidxs == groups{i}(1)}(fp_idxs_sort);
            first_scores = fp_score_all{p.pidxs == groups{i}(1)}(fp_idxs_sort);
            first_points = fp_points_all{p.pidxs == groups{i}(1)}(fp_idxs_sort,:);
            first_dist = fp_dist_all{p.pidxs == groups{i}(1)}(fp_idxs_sort);
            %         tp_idxs_sort = sortidx(sorted_labels == 1);
            %         first_idxs = tp_idxs_all{p.pidxs == groups{i}(1)}(tp_idxs_sort);
            %         first_scores = tp_score_all{p.pidxs == groups{i}(1)}(tp_idxs_sort);
            %         first_points = tp_points_all{p.pidxs == groups{i}(1)}(tp_idxs_sort,:);
            
            visTFP(first_idxs(1:50),first_points,first_dist,first_scores,annolist_gt,parts(groups{i}(1)+1).pos(1),[fileparts(p.evalTest) '/vis/fp/pidx_' num2str(groups{i}(1))]);
        end
    end
end



end