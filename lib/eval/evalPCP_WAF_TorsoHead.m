function evalPCP_WAF_TorsoHead(expidx,firstidx,nImgs,bVisSticks,bDeriveTorsoHeadDet,bUnaryOnly)
%fprintf('evalPCP_WAF_TorsoHead()\n');
if (nargin < 4)
    bVisSticks = false;
end
if (nargin < 5)
    bDeriveTorsoHeadDet = true;
end
if (nargin < 6)
    bUnaryOnly = false;
end

suff = '';

p = exp_params(expidx);
multicutDir = p.multicutDir;
visDir = [multicutDir '/vis-sticks/'];

if (bUnaryOnly)
    suff = [suff '-unary'];
end

if (~exist(visDir,'dir')),mkdir(visDir);end

load(p.testGTnopad,'annolist');
    
lastidx = firstidx + nImgs - 1;

if (isfield(p,'cidxs'))
    cidxs = p.cidxs;
elseif p.stagewise
    cidxs = 7:14;
else
    cidxs = 1:14;
end

% assume if number of parts = 16, the model has torso and head center parts
bModelTorsoHead = length(p.pidxs) == 16;

if (bModelTorsoHead)
    getStickmenCoordFunc = @getStickmenCoordTorsoHead;
    pidxsHead = [8 15 16];
else
    getStickmenCoordFunc = @getStickmenCoord;
    pidxsHead = [13 14];
end

warning('off','all');

minClusSize = 1;

load('/BS/leonid-people-3d/work/data/WeAreFamily_Stickmen_v1.02/eccv10_WeAreFamily_TestsetResults.mat','eccv10_fullMPS_testset');
eichnerAll = eccv10_fullMPS_testset;

rootDir = '/BS/leonid-people-3d/work/data/WeAreFamily_Stickmen_v1.02';
addpath([rootDir '/eval_chen']);
addpath([rootDir '/eval_chen/utils']);

% addpath([rootDir '/code']);
% addpath([rootDir '/code/utils']);

GTWAF = ReadStickmenAnnotationTxtMulti('/BS/leonid-people-3d/work/data/WeAreFamily_Stickmen_v1.02//data/waf_sticks_all.txt');
GTWAF_testset = GTWAF(351:end);

if (isfield(p,'unaryRegDir') && exist(p.unaryRegDir,'dir'))
    bReg = true;
else
    bReg = false;
end

predAll = [];
bExist = false(length(annolist),1);
for imgidx = firstidx:lastidx
    if p.stagewise
        fname = [multicutDir '/imgidx_' padZeros(num2str(imgidx),4) '_stage_' num2str(p.num_stages) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end)) '.mat'];
    else
        fname = [multicutDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
    end
    clear unLab; clear unPos; clear unProb;
    try
        load(fname,'unLab','unPos','unProb', 'locationRefine');
    catch
    end
    
    if (exist('unLab','var') && exist('unPos','var') && exist('unProb','var'))
        bExist(imgidx) = true;
        imgname = annolist(imgidx).image.name;
        points.imgname = imgname;
        unPosAll = cell(length(p.pidxs),1);
        pidxOffset = cidxs(1)-1;
        if (isfield(p,'bidxs'))
            bidxs = p.bidxs;
        else
            bidxs = 1:length(p.pidxs)+1;
        end
        
        % project detections
        if (bReg)
            load([p.unaryRegDir '/imgidx_' padZeros(num2str(imgidx),5)],'boxes');
            boxesAll = boxes(bidxs);
            for i = 1:length(cidxs)
                boxes = boxesAll{cidxs(i)+1};
                points.det = [mean(boxes(box_inds,[1 3]),2) mean(boxes(box_inds,[2 4]),2)];
                points = projectKeypoints(points,fileparts(p.testGTnopad),fileparts(p.testGT),annolist);
                unPosAll{pidxOffset+i} = points.det;
            end
        else
            % no position regression - project and copy one set of points
            %points.det = unPos;
            %points = projectKeypoints(points,fileparts(p.testGTnopad),fileparts(p.testGT),annolist);
            %for i = 1:length(cidxs)
            %    unPosAll{pidxOffset+i} = points.det;
            %end
            
            for i = 1:length(cidxs)
                points.det = unPos;
                if p.locref
                    points.det = points.det + squeeze(locationRefine(:, i, :));
                end
                points = projectKeypoints(points,fileparts(p.testGTnopad),fileparts(p.testGT),annolist);
                unPosAll{pidxOffset+i} = points.det;
            end
        end
        
        % remove small clusters with number of points below threshold
        [unLab,unPosAll] = removeSmallClusters(unLab,minClusSize,unPosAll,pidxOffset,cidxs);
        
        % convert multicut predictions to points
        if (bUnaryOnly)
            % extend upper body detection box
            boxesAll = extendBBoxStickmen(eichnerAll(imgidx).stickmen);
            % use extended box to filter unaries
            keypointsAll = multicut2keypointsBBox(unProb,unPosAll,pidxOffset,boxesAll);
            % assignment is in the order of boxes
            clusidxs = 1:size(boxesAll,1);
        else
            keypointsAll = multicut2keypoints(unLab,unProb,unPosAll,pidxOffset);
            clusidxs = [];
        end
        
        % compute reference point of multicut pose
        % required for later matching to upper body detections
        poseRefPoint = getPoseRefPoint(keypointsAll,pidxsHead);

        % prepare stickmen structure
        stickmen = prepareStickmen(eichnerAll(imgidx).stickmen,keypointsAll,poseRefPoint,bDeriveTorsoHeadDet,getStickmenCoordFunc);
        img = [];
        stickmen = getImprovedTorsoHead(stickmen,unProb,unPosAll,pidxOffset,img);
        
        predAll(imgidx).stickmen = stickmen;
        predAll(imgidx).filename = eichnerAll(imgidx).filename;
    end
end

[detrate, PCP, PCPdetail, AOP, AOPdetail, evalidx, scores, scoredetail] = BatchEval(@detBBFromStickmanWAF,@EvalStickmenMulti,predAll(bExist),GTWAF_testset(bExist));

if (bVisSticks)
    i = 0;
    for imgidx = firstidx:lastidx
        if (bExist(imgidx))
            i = i + 1;
            fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_sticks'];
            img = imread(annolist(imgidx).image.name);
            vis_sticks_waf(img,predAll(imgidx).stickmen,GTWAF_testset(imgidx).stickmen,evalidx{i},scoredetail{i},fname);
        end
    end
end

%fprintf('done & expidx& &head & ru arm & lu arm & rl arm & ll arm & torso & total & AOP %s\n','\\');
row = sprintf('%d/%d & %d& %s & %1.1f & %1.1f & %1.1f & %1.1f & %1.1f & %1.1f & %1.1f & %1.1f %s\n',sum(bExist),length(annolist),expidx,p.name,PCPdetail([6 2 3 4 5 1])*100,PCP*100,AOP*100,'\\');
% fprintf('%d/%d & %d& %s & %1.1f & %1.1f & %1.1f & %1.1f & %1.1f & %1.1f & %1.1f %s\n',sum(bExist),length(annolist),expidx,p.name,AOPdetail([6 2 3 4 5 1])*100,AOP*100,'\\');
tableFilename = [p.latexDir '/pcp' suff '-expidx' num2str(expidx) '.tex'];
fid = fopen(tableFilename,'wt');assert(fid ~= -1);
fprintf(fid,'%s',row);fclose(fid);
fprintf('%s',row);
end