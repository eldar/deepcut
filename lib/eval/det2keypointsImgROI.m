function keypointsAll= det2keypointsImgROI(expidx,parts,annolist_gt,nDet,bNMS,bTrain)

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

p = rcnn_exp_params(expidx);

if (bTrain)
    conf = rcnn_config('sub_dir', '/cachedir/train', 'exp_dir', [p.expDir '/' p.shortName]);
else
    conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
end

% conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
if (isfield(p,'predDir'))
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

for imgidx = 1:length(annolist_gt)
    
    fprintf('.');
    
    fname = [predDir '/imgidx_' padZeros(num2str(imgidx-1),5)];
    if (bNMS)
        load(fname,'aboxes');
        boxes = aboxes;
    else
        load(fname,'aboxes_nonms');
        boxes = aboxes_nonms;
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
            
            maxtop = min(size(det,1),nProposals);
            [val,idx] = max(det(1:maxtop,5));
            x = mean(det(idx,[1 3]));
            y = mean(det(idx,[2 4]));

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
            [~,idxs] = sort(score,'descend');
            idxs = idxs(1:min(nDet,length(idxs)));
            x = mean(det(idxs,[1 3]),2);
            y = mean(det(idxs,[2 4]),2);
            keypointsAll(imgidx).det{jidx+1,:} = [[x y] det(idxs,5)];
        end
        
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
    end
end
fprintf(' done\n');

end