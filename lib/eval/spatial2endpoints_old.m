function endpointsAll= spatial2endpoints(expidx,annolist_gt)

fprintf('det2keypointsImg()\n');

p = rcnn_exp_params(expidx);

conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);

predDir = [conf.cache_dir '/pred'];
predPairwiseDir = [conf.cache_dir '/pred-pairwise_old'];
featDir = [p.expDir '/' p.shortName '/feat_cache/v1_finetune_iter_70k/test'];
imdb = exp2imdb(expidx, 'test');

endpointsAll = cell(length(annolist_gt),1);

sticksMap = [10 8 9 11 nan 3 12 6 7 13];
% {[22 17],[22 16],[22 23],[22 4],[22 5],[16 14],[17 19],[4 2],[5 7],[2 0],[7 9],[14 12],[19 21]};
bVis = false;

for imgidx = 1:length(annolist_gt)
    
    fprintf('.');
    
    fname = [predDir '/imgidx_' padZeros(num2str(imgidx-1),5)];
    
    load(fname,'aboxes_nonms');
    boxes = aboxes_nonms;
    
    fname = [predPairwiseDir '/imgidx_' padZeros(num2str(imgidx-1),5)];
    load(fname,'spatial_score_all','box_inds_all');
    
    fname = [featDir '/' imdb.image_ids{imgidx}];
    d = load(fname,'gt');
    
%     endpointsAll(imgidx).imgname = annolist_gt(imgidx).image.name;
    assert(length(p.pidxs) == length(boxes));
    det = nan(10,5);
    for i = 1:length(p.spatidxs)
        idxStick = find(sticksMap == i);
        if (~isempty(idxStick))
            if (~isnan(sticksMap(idxStick)))
                spatidxs = p.spatidxs{sticksMap(idxStick)};
                pidx1 = spatidxs(1);
                pidx2 = spatidxs(2);
                boxes1 = boxes{pidx1 == p.pidxs};
                boxes2 = boxes{pidx2 == p.pidxs};
                [val,idxs] = sort(spatial_score_all{i},'descend');
                
                box_ind = box_inds_all{i}(idxs(1),3:4) - sum(d.gt);
                score = spatial_score_all{i}(idxs(1));
                
%                 x1 = mean(boxes1(box_ind(1),[1 3]));
%                 y1 = mean(boxes1(box_ind(1),[2 4]));
%                 x2 = mean(boxes2(box_ind(2),[1 3]));
%                 y2 = mean(boxes2(box_ind(2),[2 4]));
                if (pidx1 == 22 && pidx2 == 23)
                    x1 = mean(boxes1(box_ind(1),[1 3]));
                    y1 = mean(boxes1(box_ind(1),[2 4]));
                    x2 = mean(boxes2(box_ind(2),[1 3]));
                    y2 = mean(boxes2(box_ind(2),[2 4]));
                else
                    x2 = mean(boxes1(box_ind(1),[1 3]));
                    y2 = mean(boxes1(box_ind(1),[2 4]));
                    x1 = mean(boxes2(box_ind(2),[1 3]));
                    y1 = mean(boxes2(box_ind(2),[2 4]));
                end
            else
                % torso
                x1 = nan;x2 = nan;y1 = nan;y2 = nan;score = nan;
            end
            det(idxStick,:) = [x1 y1 x2 y2 score];
        end
    end
    % debug torso
%     x1y1 = (det(2,1:2) + det(3,1:2))/2;
%     x2y2 = (det(8,1:2) + det(9,1:2))/2;
    x1y1 = (det(2,3:4) + det(3,3:4))/2;
    x2y2 = (det(8,3:4) + det(9,3:4))/2;
    det(5,:) = [x1y1 x2y2 det(3,5)];
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
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(endpointsAll));
    end
end
fprintf(' done\n');

end