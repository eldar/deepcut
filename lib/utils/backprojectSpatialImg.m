function [endpointsAll,bboxAll] = backprojectSpatialImg(expidx,firstidx,nImgs,bSave)

fprintf('backprojectSpatialImg()\n');

if (ischar(expidx))
    expidx = str2double(expidx);
end

if (ischar(firstidx))
    firstidx = str2double(firstidx);
end

if (ischar(nImgs))
    nImgs = str2double(nImgs);
end

if (nargin < 4)
    bSave = true;
elseif (ischar(bSave))
    bSave = str2double(bSave);
end

% load annolist with full size images
[annolistOrig, imgidxs] = getAnnolist(expidx);
for imgidx = 1:length(annolistOrig)
    annolistOrig(imgidx).annorect = [];
end

lastidx = firstidx + nImgs - 1;
if (lastidx > length(imgidxs))
    lastidx = length(imgidxs);
end

p = rcnn_exp_params(expidx);

if (isfield(p,'nms_thresh_det'))
    nms_thresh_det = p.nms_thresh_det;
else
    nms_thresh_det = 0.5;
end

fprintf('expidx: %d\n',expidx);
fprintf('firstidx: %d\n',firstidx);
fprintf('nImgs: %d\n',nImgs);
fprintf('nms_thresh: %1.1f\n',nms_thresh_det);

load(p.testGT);
if (~exist('annolist','var'))
    annolist = single_person_annolist;
end
annolist_crops = annolist;

[~,parts] = util_get_parts24();

saveTo = [fileparts(p.evalTest) '/pred_pairwise_backproj'];
if (~exist(saveTo,'dir'))
    mkdir(saveTo);
end

conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
predPairwiseDir = [conf.cache_dir '/pred-pairwise'];

for imgidx = firstidx:lastidx
    endpointsAll(imgidx).imgname = annolistOrig(imgidxs(imgidx)).image.name;
    endpointsAll(imgidx).det = cell(length(p.spatidxs)+1,1);
end

sticksMap = [0 2; 2 4; 7 5; 9 7; nan nan; 22 23; 12 14; 14 16; 19 17; 21 19; 16 22; 17 22; 4 22; 5 22];

bVis = true;

ii = 1;
for i = firstidx:lastidx
    fprintf('.');
    
    [~,name] = fileparts(annolist_crops(ii).image.name);
    imgidx_crop = str2double(name(3:7));
    while (imgidx_crop ~= imgidxs(i))
        ii = ii + 1;
        [~,name] = fileparts(annolist_crops(ii).image.name);
        imgidx_crop = str2double(name(3:7));
    end
        
    % load bboxes
    while (imgidx_crop == imgidxs(i))

        fname = [predPairwiseDir '/imgidx_' padZeros(num2str(ii-1),5) '_nms'];
        load(fname,'det_nms_union_07_all','idxs_nms_union_07_all');
        det_spatial = det_nms_union_07_all;
        idxs_spatial = idxs_nms_union_07_all;

%         load(fname,'det_nms_inters_03_all','idxs_nms_inters_03_all');
%         det_spatial = det_nms_inters_03_all;
%         idxs_spatial = idxs_nms_inters_03_all;
        
%         load(fname,'det_nms_inters_05_all','idxs_nms_inters_05_all');
%         det_spatial = det_nms_inters_05_all;
%         idxs_spatial = idxs_nms_inters_05_all;
        
        % transformation matrix
        load([fileparts(p.testGT) '/T_' name(3:end)],'T');
        for j = 1:length(p.spatidxs)
            
            spatidxs = p.spatidxs{j};
            
            % backproject det
            det = det_spatial{j}(:,1:5);
            detNew1 = ([det(:,1:2) ones(size(det,1),1)]*T');
            detNew2 = ([det(:,3:4) ones(size(det,1),1)]*T');
            det(:,1:4) = [detNew1(:,1:2) detNew2(:,1:2)];
            
            idxStick = find(sum(abs(repmat(spatidxs,length(sticksMap),1)-sticksMap),2) == 0 | ...
                        sum(abs(repmat(spatidxs([2 1]),length(sticksMap),1)-sticksMap),2)==0);
            
            pidx1 = sticksMap(idxStick,1);
            pidx2 = sticksMap(idxStick,2);
            
            class_ids(1) = find(pidx1 == p.pidxs);
            class_ids(2) = find(pidx2 == p.pidxs);
            
            idx1 = find(idxs_spatial{j}(1,1:2) == class_ids(1));
            idx2 = find(idxs_spatial{j}(1,1:2) == class_ids(2));
            if (idx1 == 2 && idx2 == 1)
                det(:,1:4) = det(:,[3:4 1:2]);
            end
            
            % add to detections
            endpointsAll(i).det{idxStick} = [endpointsAll(i).det{idxStick}; det];
        end
%         x2y2 = (endpointsAll(i).det{11}(:,1:2) + endpointsAll(i).det{12}(:,1:2))/2;
%         x1y1 = (endpointsAll(i).det{13}(:,1:2) + endpointsAll(i).det{14}(:,1:2))/2;
%         endpointsAll(i).det{5} = [x1y1 x2y2 endpointsAll(i).det{11}(:,5)];
        ii = ii + 1;
        if (ii > length(annolist_crops))
            break;
        end
        [~,name] = fileparts(annolist_crops(ii).image.name);
        imgidx_crop = str2double(name(3:7));
    end
    
    if (bVis)
        clf; imagesc(imread(endpointsAll(i).imgname));axis equal;hold on;
        for j = 1:length(endpointsAll(i).det)
            det = endpointsAll(i).det{j};
            if (~isempty(det))
                [val,idx] = sort(det(:,end),'descend');
                plot(det(idx(1),[1 3]),det(idx(1),[2 4]),'r-','lineWidth',3);
%                 text(double(det(idx(1),1)) + 30,double(det(idx(1),2)),sprintf('%1.1f',det(idx(1),end)),'BackgroundColor','w','verticalalignment','top','horizontalalignment','left','fontSize',14);
                
                plot(det(idx(1),1),det(idx(1),2),'bo','MarkerSize',10,'MarkerFaceColor','b','MarkerEdgeColor','k');
                plot(det(idx(1),3),det(idx(1),4),'go','MarkerSize',10,'MarkerFaceColor','g','MarkerEdgeColor','k');
            end
        end
    end
    
    if (bSave)
        fname = [saveTo '/keypoints_' padZeros(num2str(imgidxs(i)),5)];
        keypoints = endpointsAll(i);
        save(fname,'keypoints');
        
        fname = [saveTo '/bboxes_' padZeros(num2str(imgidxs(i)),5)];
        bboxes = bboxAll(i);
        save(fname,'bboxes');
    end
        
    if (~mod(i, 100))
        fprintf(' %d/%d\n',i,length(imgidxs));
    end
end

fprintf(' done\n');

if (~exist('endpointsAll','var'))
    endpointsAll = [];
    bboxAll = [];
end
% path = fileparts(p.evalTest);
% fnameKeypoints = [path '/keypointsAll'];
% save(fnameKeypoints, 'keypointsAll');
% 
% fnameBBox = [path '/bboxAll'];
% save(fnameBBox, 'bboxAll');
end