function keypointsAll= det2keypointsImg(expidx,parts,annolist_gt,nDet,bNMS,bTrain,nms_thresh_det)

fprintf('det2keypointsImg()\n');

if (nargin < 4)
    nDet = 1;
end

if (nargin < 5)
    bNMS = true;
end

if (nargin < 6)
    bTrain = false;
end

if (nargin < 7)
    nms_thresh_det = 0.0;
end

p = rcnn_exp_params(expidx);

if (bTrain)
    conf = rcnn_config('sub_dir', '/cachedir/train', 'exp_dir', [p.expDir '/' p.shortName]);
else
    conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
end

% conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
if (isfield(p,'predDir') && ~bTrain)
    predDir = p.predDir;
else
    predDir = [conf.cache_dir '/pred'];
end

if (nDet == 1)
    keypointsAll = repmat(struct('imgname','','det',nan(16,3)), length(annolist_gt), 1);
else
    for imgidx = 1:length(annolist_gt)
        keypointsAll(imgidx).imgname = '';
        keypointsAll(imgidx).det = cell(16,1);
    end
end

if (isfield(p,'nProposals'))
    nProposals = p.nProposals;
else
    nProposals = inf;
end

if (isfield(p,'min_det_score'))
    min_det_score = p.min_det_score;
else
    min_det_score = -inf;
end

for imgidx = 1:length(annolist_gt)
    
    fprintf('.');
    
    fname = [predDir '/imgidx_' padZeros(num2str(imgidx-1),5)];
    
    if (bNMS)
        load(fname,'aboxes');
        boxes = aboxes;
    else
        load(fname,'aboxes_nonms');
        boxes = aboxes_nonms;
    
        if (nms_thresh_det > 0)
            assert(expidx == 454 || expidx == 464 || expidx == 466 || expidx == 471);
            for i = 1:length(boxes)
                boxes{i}(:,1:4) = rcnn_scale_bbox(boxes{i}(:,1:4),1.0/p.scale,1000,1000);
            end
            idxsNMSall = [];
            for i = 1:length(boxes)
                I = nms_IoMin([boxes{i}(:,1:4) boxes{i}(:,5)], nms_thresh_det);
                idxsNMSall = sort(unique([idxsNMSall; I]));
            end
            for i = 1:length(boxes)
                boxes{i} = boxes{i}(idxsNMSall,:);
            end
        end
        if (isfield(p,'max_detections') && p.max_detections < inf)
            assert(expidx == 464 || expidx == 466 || expidx == 471);
            unProb = zeros(size(boxes{1},1),length(boxes));
            for i = 1:length(boxes)
                unProb(:,i) = boxes{i}(:,5);
            end
            scores = sort(reshape(unProb, size(unProb,1)*size(unProb,2),1));
            unProbThresh = unProb;
            j = 1;
            while (length(find(sum(unProbThresh,2) > 0)) > p.max_detections && j <= length(scores))
                unProbThresh = unProb;
                for cidx = 1:length(boxes)
                    unProbThresh(unProb(:,cidx) < scores(j),cidx) = 0;
                end
                j = j + 1;
                %                     length(find(sum(unProbThresh,2) > 0))
            end
            min_det_score_found = scores(j);
            idxs = find(sum(unProbThresh,2) > 0);
            for i = 1:length(boxes)
                boxes{i} = boxes{i}(idxs,:);
            end
        end
    end
    
    keypointsAll(imgidx).imgname = annolist_gt(imgidx).image.name;
    assert(length(p.pidxs) == length(boxes));
    
    for i = 1:length(p.pidxs)
        
        pidx = p.pidxs(i);
        % part is a joint
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);
        
        det = boxes{i};
        
        if (nDet == 1)
            if (nProposals == 1)
%                 assume 143 proposals per part
                assert(size(det,1) == 2002);
                idx = (i-1)*143 + 1;
                val = det(idx,5);
            else
                assert(nProposals == inf);
                maxtop = min(size(det,1),nProposals);
                [val,idx] = max(det(1:maxtop,5));
            end
            
            x = mean(det(idx,[1 3]));
            y = mean(det(idx,[2 4]));
            
            if (val < min_det_score)
                x = inf;
                y = inf;
            end
%             maxtop = min(size(det,1),100);
%             [~,idxs] = sort(det(:,5),'descend');
%             det = det(idxs(1:maxtop),:);
%             x = mean(det(:,[1 3]),2);
%             y = mean(det(:,[2 4]),2);
%             keep = nms_dist([x,y,det(1:maxtop,end)],0.1,50);
%             det = det(keep,:);
%             [val,idx] = max(det(:,5));
%             x = mean(det(idx,[1 3]));
%             y = mean(det(idx,[2 4]));

            keypointsAll(imgidx).det(jidx+1,:) = [[x y] val];
        else
            score = det(:,5);
            [val,idxs] = sort(score,'descend');
            idxs = idxs(1:min(nDet,length(idxs)));
            % use score threshold
            idxs2 = find(score(idxs) >= min_det_score);
            idxs = idxs(idxs2);
            if (~isempty(idxs))
                x = mean(det(idxs,[1 3]),2);
                y = mean(det(idxs,[2 4]),2);
                keypointsAll(imgidx).det{jidx+1,:} = [[x y] det(idxs,5)];
            else
                keypointsAll(imgidx).det{jidx+1,:} = [[inf inf] min_det_score];
            end
        end
        
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
    end
end
fprintf(' done\n');

end