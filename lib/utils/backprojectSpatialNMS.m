function endpointsAll = backprojectSpatialNMS(expidx,firstidx,nImgs,bSave)

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
predDir = [conf.cache_dir '/pred'];

for imgidx = firstidx:lastidx
    endpointsAll(imgidx).imgname = annolistOrig(imgidxs(imgidx)).image.name;
    endpointsAll(imgidx).det = cell(length(p.spatidxs)+1,1);
end

sticksMap = [0 2; 2 4; 7 5; 9 7; nan nan; 22 23; 12 14; 14 16; 19 17; 21 19; 16 22; 17 22; 4 22; 5 22];

bVis = false;

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

%         fname = [predPairwiseDir '/imgidx_' padZeros(num2str(ii-1),5) '_nms'];
%         load(fname,'det_nms_union_05_all','idxs_nms_union_05_all');
%         det_spatial = det_nms_union_05_all;
%         idxs_spatial = idxs_nms_union_05_all;

%         load(fname,'det_nms_inters_03_all','idxs_nms_inters_03_all');
%         det_spatial = det_nms_inters_03_all;
%         idxs_spatial = idxs_nms_inters_03_all;
        
%         load(fname,'det_nms_inters_05_all','idxs_nms_inters_05_all');
%         det_spatial = det_nms_inters_05_all;
%         idxs_spatial = idxs_nms_inters_05_all;
        
        fname = [predDir '/imgidx_' padZeros(num2str(ii-1),5)];
        load(fname,'aboxes_nonms');
        boxes = aboxes_nonms;

        fname = [predPairwiseDir '/imgidx_' padZeros(num2str(ii-1),5)];
        load(fname,'spatial_score_all','box_inds_all');

        % transformation matrix
        load([fileparts(p.testGT) '/T_' name(3:end)],'T');
        for j = 1:length(p.spatidxs)
            
            spatidxs = p.spatidxs{j};
            
            idxStick = find(sum(abs(repmat(spatidxs,length(sticksMap),1)-sticksMap),2) == 0 | ...
                        sum(abs(repmat(spatidxs([2 1]),length(sticksMap),1)-sticksMap),2)==0);
            
            pidx1 = sticksMap(idxStick,1);
            pidx2 = sticksMap(idxStick,2);
            
            class_ids(1) = find(pidx1 == p.pidxs);
            class_ids(2) = find(pidx2 == p.pidxs);
            
            boxes1 = boxes{class_ids(1)};
            boxes2 = boxes{class_ids(2)};
            
            score = spatial_score_all{j};
            
            idx1 = find(box_inds_all{j}(1,1:2) == class_ids(1));
            idx2 = find(box_inds_all{j}(1,1:2) == class_ids(2));
            if (idx1 == 2 && idx2 == 1)
                box_ind(:,1) = box_inds_all{j}(:,4);
                box_ind(:,2) = box_inds_all{j}(:,3);
            else
                box_ind(:,1) = box_inds_all{j}(:,3);
                box_ind(:,2) = box_inds_all{j}(:,4);
            end
            
            x1 = mean(boxes1(box_ind(:,1),[1 3]),2);
            y1 = mean(boxes1(box_ind(:,1),[2 4]),2);
            x2 = mean(boxes2(box_ind(:,2),[1 3]),2);
            y2 = mean(boxes2(box_ind(:,2),[2 4]),2);

            % backproject det
            det = [x1 y1 x2 y2 score];
            detNew1 = ([det(:,1:2) ones(size(det,1),1)]*T');
            detNew2 = ([det(:,3:4) ones(size(det,1),1)]*T');
            det(:,1:4) = [detNew1(:,1:2) detNew2(:,1:2)];
            
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
    
    % nms
    for j = 1:length(endpointsAll(i).det)
        det = endpointsAll(i).det{j};
        if (~isempty(det))
            [val,idxs] = sort(det(:,5),'descend');
            det = det(idxs,:);
            idx_curr = 1;
            while (idx_curr + 1 <= size(det,1))
                top = det(idx_curr,:);
                refDist = norm((top(1:2) - top(3:4)));
                dist1 = sqrt(sum((det(idx_curr+1:end,1:2) - repmat(top(1:2),size(det(idx_curr+1:end,:),1),1)).^2,2));
                dist2 = sqrt(sum((det(idx_curr+1:end,3:4) - repmat(top(3:4),size(det(idx_curr+1:end,:),1),1)).^2,2));
                idx = find(dist1./refDist <= nms_thresh_det & dist2./refDist <= nms_thresh_det);
                det(idx_curr+idx,:) = [];
                idx_curr = idx_curr + 1;
            end
        end
        endpointsAll(i).det{j} = det;
    end
    
    if (bVis)
        clf; imagesc(imread(endpointsAll(i).imgname));axis equal;hold on;
        for j = 1:length(endpointsAll(i).det)
            det = endpointsAll(i).det{j};
            nVis = min(100,size(det,1));
            if (~isempty(det))
                [val,idx] = sort(det(:,end),'descend');
                for n = 1:nVis
                    plot(det(idx(n),[1 3]),det(idx(n),[2 4]),'r-','lineWidth',3);
                end
%                 text(double(det(idx(1),1)) + 30,double(det(idx(1),2)),sprintf('%1.1f',det(idx(1),end)),'BackgroundColor','w','verticalalignment','top','horizontalalignment','left','fontSize',14);
                
                plot(det(idx(1:nVis),1),det(idx(1:nVis),2),'bo','MarkerSize',10,'MarkerFaceColor','b','MarkerEdgeColor','k');
                plot(det(idx(1:nVis),3),det(idx(1:nVis),4),'go','MarkerSize',10,'MarkerFaceColor','g','MarkerEdgeColor','k');
            end
        end
    end
    
    if (bSave)
        fname = [saveTo '/keypoints_' padZeros(num2str(imgidxs(i)),5)];
        keypoints = endpointsAll(i);
        save(fname,'keypoints');
    end
        
    if (~mod(i, 100))
        fprintf(' %d/%d\n',i,length(imgidxs));
    end
end

fprintf(' done\n');

if (~exist('endpointsAll','var'))
    endpointsAll = [];
end
% path = fileparts(p.evalTest);
% fnameKeypoints = [path '/keypointsAll'];
% save(fnameKeypoints, 'keypointsAll');
% 
% fnameBBox = [path '/bboxAll'];
% save(fnameBBox, 'bboxAll');
end