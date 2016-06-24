function endpointsAll= spatial2endpoints(expidx,annolist_gt,nPartsEval)

fprintf('spatial2endpoints()\n');

if (nargin < 3)
    bAddParts = 10;
end

p = rcnn_exp_params(expidx);

conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);

predDir = [conf.cache_dir '/pred'];
predPairwiseDir = [conf.cache_dir '/pred-pairwise'];

endpointsAll = cell(length(annolist_gt),1);

% spatial to stick map
sticksMap = [0 2; 2 4; 7 5; 9 7; nan nan; 22 23; 12 14; 14 16; 19 17; 21 19; 16 22; 17 22; 4 22; 5 22];
% sticksMap = [0 2; 2 4; 7 5; 9 7; nan nan; 22 23; 12 14; 14 16; 19 17; 21 19; 22 17; 22 16; 22 4; 22 5];
% {[22 17],[22 16],[22 23],[22 4],[22 5],[16 14],[17 19],[4 2],[5 7],[2 0],[7 9],[14 12],[19 21]};
bVis = false;

for imgidx = 1:length(annolist_gt)
    
    fprintf('.');
    
    fname = [predDir '/imgidx_' padZeros(num2str(imgidx-1),5)];
    load(fname,'aboxes_nonms');
    boxes = aboxes_nonms;
    
    fname = [predPairwiseDir '/imgidx_' padZeros(num2str(imgidx-1),5)];
    load(fname,'spatial_score_top','box_inds_top');
    
    assert(length(p.pidxs) == length(boxes));
    
    det = nan(10,5);
    
    for i = 1:length(p.spatidxs)
        spatidxs = p.spatidxs{i};
        idxStick = find(sum(abs(repmat(spatidxs,length(sticksMap),1)-sticksMap),2) == 0 | ...
                        sum(abs(repmat(spatidxs([2 1]),length(sticksMap),1)-sticksMap),2)==0);
                    
        if (~isempty(idxStick))
            
            pidx1 = sticksMap(idxStick,1);
            pidx2 = sticksMap(idxStick,2);
            
            class_ids(1) = find(pidx1 == p.pidxs);
            class_ids(2) = find(pidx2 == p.pidxs);
            
            boxes1 = boxes{class_ids(1)};
            boxes2 = boxes{class_ids(2)};
            
            score = spatial_score_top{i};
            
            box_ind(1) = box_inds_top{i}(find(box_inds_top{i}(1:2) == class_ids(1))+2);
            box_ind(2) = box_inds_top{i}(find(box_inds_top{i}(1:2) == class_ids(2))+2);
            
            x1 = mean(boxes1(box_ind(1),[1 3]));
            y1 = mean(boxes1(box_ind(1),[2 4]));
            x2 = mean(boxes2(box_ind(2),[1 3]));
            y2 = mean(boxes2(box_ind(2),[2 4]));

            det(idxStick,:) = [x1 y1 x2 y2 score];
        end
    end
    
    % debug torso
%     x1y1 = (det(2,3:4) + det(3,3:4))/2;
%     x2y2 = (det(8,3:4) + det(9,3:4))/2;
%     det(5,:) = [x1y1 x2y2 det(3,5)];
%     x2y2 = (det(11,3:4) + det(12,3:4))/2;
%     x1y1 = (det(13,3:4) + det(14,3:4))/2;
    x2y2 = (det(11,1:2) + det(12,1:2))/2;
    x1y1 = (det(13,1:2) + det(14,1:2))/2;
    det(5,:) = [x1y1 x2y2 det(11,5)];
    det(nPartsEval+1:end,:) = [];
    
    endpointsAll{imgidx} = det;
    
    if (bVis)
        endpoints = endpointsAll{imgidx};
        figure(100);clf;imagesc(imread(annolist_gt(imgidx).image.name));axis equal; hold on;
        
        for i = 1:(size(endpoints, 1))
            c = 'r';
            plot([endpoints(i, 1); endpoints(i, 3)], ...
                [endpoints(i, 2); endpoints(i, 4)], ...
                [c '-'], 'linewidth', 10);
            hold on;
            plot([endpoints(i, 1); endpoints(i, 3)], ...
                [endpoints(i, 2); endpoints(i, 4)], ...
                [c 'o'], 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k', 'MarkerSize', 15);
            hold on;
        end
        fname = ['/BS/leonid-projects/work/experiments-rcnn/parts14-joint-train-19000-rwrist-test-correct-gt-scale4-140k-step-80k-lr-0002-pad-pad-500-test-train-pairwise-nImgs-1000-ovr-01-eval-comb-torso/cachedir/test/vis/imgidx_' num2str(imgidx)];
        print(gcf, '-dpng', [fname '.png']);
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(endpointsAll));
    end
end
fprintf(' done\n');

end