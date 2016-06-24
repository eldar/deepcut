function evalRP_multicut_waf(expidxs,bSave)

fprintf('evalRP_multicut()\n');

if (nargin < 2)
    bSave = true;
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

rootDir = '/BS/leonid-people-3d/work/data/WeAreFamily_Stickmen_v1.02';
addpath([rootDir '/code']);
addpath([rootDir '/code/utils']);

GTWAF = ReadStickmenAnnotationTxtMulti('/BS/leonid-people-3d/work/data/WeAreFamily_Stickmen_v1.02//data/waf_sticks_all.txt');
annolistWAF_gt = GTWAF(351:end);

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = rcnn_exp_params(expidx);
    
    if (isfield(p,'nms_thresh_det'))
        nms_thresh_det = p.nms_thresh_det;
    else
        nms_thresh_det = 0.5;
    end
    
    load(p.testGT);
    annolist_gt = annolist%(1:300);
    
    mkdir_if_missing(p.latexDir);
    mkdir_if_missing(p.plotsDir);
    
    assert(length(p.pidxs) == nJoints);
    
    if (isfield(p,'clusSizeThresh'))
        clusSizeThresh = p.clusSizeThresh;
    else
        clusSizeThresh = 1;
    end
    
    % load keypoints
    if (isfield(p,'multicut') && p.multicut == true)
        [keypointsAll,imgidxs_missing] = det2keypointsImgMulticutMulti(expidx,parts,annolist_gt,clusSizeThresh);
        annolistWAF_det = backproject_waf(expidx,keypointsAll,annolistWAF_gt);
    end

    annolist_gt(imgidxs_missing) = [];
    keypointsAll(imgidxs_missing) = [];
    
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