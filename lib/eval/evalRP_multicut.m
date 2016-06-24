function apAll = evalRP_multicut(expidxs, bSave, subset)

fprintf('evalRP_multicut()\n');

if (nargin < 2)
    bSave = true;
end

if (nargin < 3)
    subset = [];
end

fontSize = 18;
% figure(100); clf; hold on;
legendName = cell(0);
set(0,'DefaultAxesFontSize', fontSize)
set(0,'DefaultTextFontSize', fontSize)

prefix = 'pck-head-rpc-';
[~,parts] = util_get_parts24();
nJoints = 14;
pck_thresh = 0.5;

% clusSizeThresh = 15;

num_exps = length(expidxs);
imgidxs_missing_all = cell(num_exps, 1);
keypointsAll_all = cell(num_exps, 1);
annolist_gt_all = cell(num_exps, 1);
annolist_bbox_all = cell(num_exps, 1);

for ii = 1:num_exps
    fprintf('**********************************************************************************\n');
    expidx = expidxs(ii);
    
    % load experiment parameters
    p = exp_params(expidx);
    
    load(p.testGT);
    annolist_gt = annolist;%(1:300);
    
    mkdir_if_missing(p.latexDir);
    mkdir_if_missing(p.plotsDir);
    
    assert(length(p.pidxs) == nJoints);
    
    if (isfield(p,'clusSizeThresh'))
        clusSizeThresh = p.clusSizeThresh;
    else
        clusSizeThresh = 1;
    end
    
    if (isfield(p,'disjointGTassignment'))
        disjointGTassignment = p.disjointGTassignment;
    else
        disjointGTassignment = false;
    end
    
    % load keypoints
    if (isfield(p,'multicut') && p.multicut == true)
        [keypointsAll,imgidxs_missing] = det2keypointsImgMulticutMulti(expidx,parts,annolist_gt,clusSizeThresh);
    elseif (isfield(p,'oracleDetBBox') && p.oracleDetBBox == true && ~isfield(p,'poseClusters'))
        annolist_bbox = compute_gt_bbox(annolist_gt,p.pidxs,parts,p.bbox_offset);
        [keypointsAll,imgidxs_missing] = det2keypointsImgMulticutBBoxMulti(expidx,parts,annolist_bbox,disjointGTassignment);
    elseif (isfield(p,'neckDetBBox') && p.neckDetBBox == true && ~isfield(p,'poseClusters'))
        try
            assert(false);
            load([p.outputDir '/annolist_bbox'],'annolist_bbox');
        catch
            annolist_bbox = compute_det_bbox(expidx,annolist_gt,p.neck_nms_thresh,p.neck_det_thresh,p.bbox_offset);
            if (~exist(p.outputDir,'dir')),mkdir(p.outputDir);end
            save([p.outputDir '/annolist_bbox'],'annolist_bbox');
        end
        [keypointsAll,imgidxs_missing] = det2keypointsImgMulticutBBoxMulti(expidx,parts,annolist_bbox,disjointGTassignment);
    elseif (isfield(p,'poseClusters') && p.poseClusters == true)
        load(p.testGTnopad);
        annolist_gt = annolist(1:length(annolist_gt));
        [keypointsAll,imgidxs_missing] = det2keypointsImgMulticutBBoxMultiPoses(expidx,parts,length(annolist_gt));
    end
    
    imgidxs_missing_all{ii} = imgidxs_missing;
    keypointsAll_all{ii} = keypointsAll;
    annolist_gt_all{ii} = annolist_gt;
    %annolist_bbox_all{ii} = annolist_bbox;
end

imgidxs_missing = [];

for ii = 1:num_exps
    imgidxs_missing = [imgidxs_missing; imgidxs_missing_all{ii}];
end

imgidxs_missing = unique(imgidxs_missing);

%im_idx = 7;
%imgidxs_missing = [1:(im_idx-1) (im_idx+1):1758];

fprintf('final images missing %d\n', length(imgidxs_missing));

for ii = 1:num_exps
    expidx = expidxs(ii);
    p = exp_params(expidx);

    keypointsAll = keypointsAll_all{ii};
    annolist_gt = annolist_gt_all{ii};
    %annolist_bbox = annolist_bbox_all{ii};

    keypointsAll16 = keypointsAll;
    if isempty(subset)
        subset = true(length(annolist_gt), 1);
        subset(imgidxs_missing) = 0;
    end
    annolist_gt = annolist_gt(subset);
    keypointsAll = keypointsAll(subset);
    
    assert(length(annolist_gt) == length(keypointsAll));
    [scoresAll, labelsAll, nGTall] = assignGTMulticutMulti(keypointsAll,annolist_gt,p.pidxs,parts,pck_thresh);
    
%     groups = {0,2,4,5,7,9,12,14,16,17,19,21,22,23};
    partLabels = {'rankle','rknee','rhip','lhip','lknee','lankle','rwrist','relbow','rshoulder','lshoulder','lelbow','lwrist','neck','tophead'};
    
    apAll = zeros(length(p.pidxs),1);
%     figure(100); clf;
    
    for i = 1:length(p.pidxs)
        scores = [];
        labels = [];
        for imgidx = 1:length(annolist_gt)
            scores = [scores; scoresAll{i}{imgidx}];
            labels = [labels; labelsAll{i}{imgidx}];
        end
        [precision,recall,sorted_scores,sortidx,sorted_labels] = getRPC(scores,labels,sum(nGTall(i,:)));
        ap = VOCap(recall,precision)*100;
        apAll(i) = ap;
        legendName = sprintf('%s, AP: %1.1f%%', p.name, ap);
        fprintf('%s\n',legendName);
        
%         plotRPC(precision,recall,p.colorName,'-',partLabels{i});
%         legend(legendName,'Location','NorthWest');        
%         if (bSave)
%             print(gcf, '-dpng', [p.plotsDir '/' prefix partLabels{i} '-' 'expidx' num2str(expidx) '.png']);
%             printpdf([p.plotsDir '/' prefix partLabels{i} '-' 'expidx' num2str(expidx) '.pdf']);
%         end
    end
    
    num_images = length(labelsAll{1});
    num_parts = length(labelsAll);
    simple_scores = zeros(num_images, 1);
    for k = 1:num_images
        num_hits = 0;
        num_all = 0;
        for i = 1:num_parts
            lbl = labelsAll{i}{k};
            num_all = num_all + length(lbl);
            num_hits = num_hits + sum(lbl);
        end

        if num_all ~= 0
            simple_scores(k) = num_hits/num_all;
        end
    end
    
    mkdir_if_missing(fullfile(p.exp_dir, 'data'));
    save(fullfile(p.exp_dir, 'data', 'scores'), 'simple_scores', 'subset', 'keypointsAll16');
    
    if (bSave)
        tableFilename = [p.latexDir '/ap-expidx' num2str(expidx) '.tex'];
        apAll(15,:) = mean(apAll(7:14));
        apAll(16,:) = mean(apAll);
        [row, header] = genTable(apAll,p.name);
        fid = fopen(tableFilename,'wt');assert(fid ~= -1);
        fprintf(fid,'%s\n',row{1});fclose(fid);
        fid = fopen([p.latexDir '/ap-header.tex'],'wt');assert(fid ~= -1);
        fprintf(fid,'%s\n',header);fclose(fid);
        save([p.latexDir '/ap-expidx' num2str(expidx) '.mat'],'apAll');
    end
end
end