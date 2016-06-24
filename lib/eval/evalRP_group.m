function evalRP_group(expidxs,bUseHeadSize,bSave,bHeadSizeFromRect)

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

[~,parts] = util_get_parts24();
nJoints = 14;
jidxsUpperBody = 7:12;

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = rcnn_exp_params(expidx);
    
    if (isfield(p,'nms_thresh_det'))
        nms_thresh_det = p.nms_thresh_det;
    else
        nms_thresh_det = 0.5;
    end
%     % load ground truth
%     [annolist, imgidxs_gt, rectidxs_gt, rect_ignore, ~, keypointsidxs] = getAnnolist(expidx);
%     annolist_gt = annolist(imgidxs_gt);
    
    fname = '/home/andriluk/IMAGES/human_pose_dataset/dataset/dataset_release_candidate1/test/multPerson/h400/annolist-2-people';
    try
        load(fname,'annolist','imgidxs_gt','rectidxs_gt','rect_ignore','keypointsidxs');
        annolist_gt = annolist(imgidxs_gt);
    catch
        [annolist, imgidxs_gt, rectidxs_gt, rect_ignore, ~, keypointsidxs] = getAnnolist(expidx);
        annolist_gt = annolist(imgidxs_gt);
        save(fname,'annolist','imgidxs_gt','rectidxs_gt','rect_ignore','keypointsidxs')
    end
      
    mkdir_if_missing(p.latexDir);
    mkdir_if_missing(p.plotsDir);
    
    assert(length(p.pidxs) == nJoints);
    
    % load keypoints
    if (exist([p.evalTest '.mat'],'file')>0)
        fprintf('load %s\n',p.evalTest);
        load([p.evalTest '.mat']);
    else
        warning('file not found: %s\n',[p.evalTest '.mat']);
        keypointsAll = backprojectKeypointsImg(expidx,1,length(annolist_gt),false);
    end
    
    if (isfield(p,'bp'))
        bp = p.bp;
    else
        bp = false;
    end
    
    if (~bp)
        keypointsAll = keypointsAll(keypointsidxs);
    end
    assert(length(annolist_gt) == length(keypointsAll));
    
    if (isfield(p,'img_2_people_only'))
        nrects = cellfun(@length, rectidxs_gt(imgidxs_gt));
        annolist_gt = annolist_gt(nrects == 2);
        imgidxs_gt = imgidxs_gt(nrects == 2);
        keypointsidxs = keypointsidxs(nrects == 2);
        keypointsAll = keypointsAll(nrects == 2);
    end
    
    % get detections from neck detector
    if (isfield(p,'neckDetFilename'))
        fnameNeck = p.neckDetFilename;
    else
        fnameNeck = [fileparts(p.evalTest) '/boxesNeck'];
    end
    
    if (isfield(p,'oracle_det'))
        oracle_det = p.oracle_det;
    else
        oracle_det = false;
    end
    
    if (~bp)
        if (oracle_det)
            boxesNeck = struct();
            for imgidx = 1:length(annolist_gt)
                rect = annolist_gt(imgidx).annorect;
                boxes = [];
                for ridx = 1:length(rect)
                    if (isfield(rect(ridx), 'annopoints') && isfield(rect(ridx).annopoints, 'point'))
                        points = rect(ridx).annopoints.point;
                        x = [points.x];
                        y = [points.y];
                        x1 = min(x);
                        x2 = max(x);
                        y1 = min(y);
                        y2 = max(y);
                        boxes = [boxes; x1 y1 x2 y2];
                    end
                end
                boxesNeck(imgidx).det = boxes;
            end
        else
            try
                %         assert(false);
                load(fnameNeck,'boxesNeck');
            catch
                fboxes = [fileparts(p.evalTest) '/bboxAll'];
                load(fboxes,'bboxAll');
                refHeadSizeAll = zeros(length(keypointsAll),1);
                nNecks = zeros(length(keypointsAll),1);
                for imgidx = 1:length(keypointsAll)
                    keypointsNeck(imgidx).imgname = keypointsAll(imgidx).imgname;
                    rect = annolist_gt(imgidx).annorect;
                    headSize = [];
                    for ridx = 1:length(rect)
                        headSize = [headSize; util_get_head_size(rect(ridx))];
                    end
                    refDist = mean(headSize);
                    keep = nms_dist(keypointsAll(imgidx).det{9},nms_thresh_det,refDist);
                    keypointsNeck(imgidx).det = {keypointsAll(imgidx).det{9}(keep,:)};
                    refHeadSizeAll(imgidx) = refDist;
                    nNecks(imgidx) = size(keypointsNeck(imgidx).det{1},1);
                    %         keypointsAll(imgidx).det(9) = keypointsNeck(imgidx).det;
                end
                
                boxesNeck = struct();
                for imgidx = 1:length(keypointsAll)
                    fprintf('.');
                    img = imread(keypointsNeck(imgidx).imgname);
                    [Y,X,~] = size(img);
                    boxesNeck(imgidx).imgname = keypointsNeck(imgidx).imgname;
                    %         [val,idxs] = sort(keypointsNeck(imgidx).det{1}(:,end),'descend');
                    points = keypointsNeck(imgidx).det{1};
                    boxes = [points(:,1)-2*refHeadSizeAll(imgidx) points(:,2)-1.5*refHeadSizeAll(imgidx) ...
                        points(:,1)+2*refHeadSizeAll(imgidx) points(:,2)+7*refHeadSizeAll(imgidx)];
                    boxes(:,1) = max(1,boxes(:,1));
                    boxes(:,2) = max(1,boxes(:,2));
                    boxes(:,3) = min(X,boxes(:,3));
                    boxes(:,4) = min(Y,boxes(:,4));
                    boxesNeck(imgidx).det = boxes;
                    figure(200); clf; imagesc(imread(annolist_gt(imgidx).image.name));
                    hold on; axis equal;
                    for i=1:size(boxes,1)
                        plot(points(i,1),points(i,2),'r+');
                        rectangle('Pos',[boxes(i,1) boxes(i,2) boxes(i,3) - boxes(i,1) boxes(i,4) - boxes(i,2)],'lineWidth',5,'edgeColor','g');
                    end
                    if (~mod(imgidx, 100))
                        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
                    end
                end
                save(fnameNeck,'boxesNeck');
            end
        end
    end
    
    if (isfield(p,'img_2_people_only'))
        for imgidx = 1:length(boxesNeck)
        end
    end
    
    tp_score_all = cell(length(p.pidxs),1);
    fp_score_all = cell(length(p.pidxs),1);
    totalPos_all = cell(length(p.pidxs),1);
    tp_points_all = cell(length(p.pidxs),1);
    fp_points_all = cell(length(p.pidxs),1);
    tp_idxs_all = cell(length(p.pidxs),1);
    fp_idxs_all = cell(length(p.pidxs),1);
    fp_dist_all = cell(length(p.pidxs),1);
    missing_recall_all = cell(length(p.pidxs),1);
    
    fprintf('compute tp/fp\n');
    if (bp)
        if (isfield(p,'marg_scores'))
            marg_scores = p.marg_scores;
        else
            marg_scores = false;
        end
        
        [distAll,scoresAll,pointsAll] = assignGTinference(keypointsAll,annolist_gt,p.pidxs,parts,0.5,marg_scores);
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            fprintf('pidx %d\n',pidx);
            [tp_score_all{i},fp_score_all{i},totalPos_all{i},tp_points_all{i},fp_points_all{i},tp_idxs_all{i},fp_idxs_all{i},fp_dist_all{i},missing_recall_all{i}] = ...
                computeTFP(distAll{i},scoresAll{i},pointsAll{i},rectidxs_gt(imgidxs_gt),rect_ignore(imgidxs_gt));
        end
    else
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            fprintf('pidx %d\n',pidx);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
            
            for imgidx = 1:length(keypointsAll)
                [val,idxs] = sort(keypointsAll(imgidx).det{jidx+1}(:,end),'descend');
                keypointsAll(imgidx).det{jidx+1} = keypointsAll(imgidx).det{jidx+1}(idxs(1:p.top_det),:);
            end
            
            [dist,score,points] = getNormGTJointDistRP_group(keypointsAll,annolist_gt,jidx,boxesNeck);
            
            [tp_score_all{i},fp_score_all{i},totalPos_all{i},tp_points_all{i},fp_points_all{i},tp_idxs_all{i},fp_idxs_all{i},fp_dist_all{i},missing_recall_all{i}] = ...
                computeTFP(dist,score,points,rectidxs_gt(imgidxs_gt),rect_ignore(imgidxs_gt));%,rect_ignore(imgidxs_gt));
        end
    end    
%         pidxs = p.pidxs;
%         save(fnameDist,'tp_score_all','fp_score_all','totalPos_all','pidxs','tp_points_all','fp_points_all','tp_idxs_all','fp_idxs_all');
    
%     groups = {22, 21, 12, 19, 14, 17, 16, 9, 0, 7, 2, 5, 4, 23};%, [0 9], [2 7], [4 5], [12 21], [14 19], [16 17], [22 23]
    groups = {0,2,4,5,7,9,12,14,16,17,19,21,22,23};
%     labels = {'neck','lwrist','rwrist','lelbow','relbow','lshoulder','rshoulder','lankle','rankle','lknee','rknee','lhip','rhip','tophead'}; 
%     labels = {'neck','lwrist','rwrist','lelbow','relbow','lshoulder','rshoulder','lankle','rankle','lknee','rknee','lhip','rhip','tophead'}; 
    labels = {'rankle','rknee','rhip','lhip','lknee','lankle','rwrist','relbow','rshoulder','lshoulder','lelbow','lwrist','neck','tophead'};
    apAll = zeros(length(groups),1);
    figure(100);
    for i = 1:length(groups)
        clf;
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
        apAll(i) = ap;
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
            
%             visTFP(first_idxs(1:50),first_points,first_dist,first_scores,annolist_gt,rectidxs_gt(imgidxs_gt),parts(groups{i}(1)+1).pos(1),[fileparts(p.evalTest) '/vis/fp/pidx_' num2str(groups{i}(1))]);
            missing_recall = missing_recall_all{p.pidxs == groups{i}(1)};
            idxs = find(cellfun(@isempty,missing_recall) == 0);
            
            fprintf('missing recall: %1.2f%%\n',sum(cellfun(@length,missing_recall))/totalPos_all{p.pidxs == groups{i}(1)}*100);
%             visMissingRecall(missing_recall(idxs(1:50)),annolist_gt(idxs(1:50)),parts(groups{i}(1)+1).pos(1),[fileparts(p.evalTest) '/vis/mr/pidx_' num2str(groups{i}(1))]);
        end
    end
    if (bSave)
        tableFilename = [p.latexDir '/ap-expidx' num2str(expidx) '.tex'];
        apAll(15,:) = mean(apAll(7:14));
        apAll(16,:) = mean(apAll);
        [row, header] = genTable(apAll,p.name);
        fid = fopen(tableFilename,'wt');assert(fid ~= -1);
        fprintf(fid,'%s\n',row{1});fclose(fid);
        fid = fopen([p.latexDir '/ap-header.tex'],'wt');assert(fid ~= -1);
        fprintf(fid,'%s\n',header);fclose(fid);
    end
end



end