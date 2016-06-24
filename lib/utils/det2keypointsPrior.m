function keypointsAll = det2keypointsPrior(expidx,parts,annolist_gt)

keypointsAll = [];

p = rcnn_exp_params(expidx);

% [prior,binSize] = part_location_prior(expidx);
[prior,binSize] = part_location_prior(expidx);
X0 = size(prior,1)/2;
Y0 = size(prior,2)/2;

for i = 1:length(p.pidxs)
       
    pidx = p.pidxs(i);
    % part is a joint
    assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
    jidx = parts(pidx+1).pos(1);
    
    fname = [p.evalTest '_cidx_' num2str(pidx)];
    fprintf('load %s\n',fname);
    try
        if (isfield(p,'prior_no_nms') && p.prior_no_nms == true)
            load(fname,'boxes_nonms');
            boxes = boxes_nonms;
        else
            load(fname,'boxes');
        end
    catch
        warning('file not found: %s\n',fname);
        continue;
    end
    
    % init struct
    if (isempty(keypointsAll))
        keypointsAll = repmat(struct('imgname','','det',nan(16,3)), length(boxes), 1);
        for imgidx = 1:length(boxes)
            keypointsAll(imgidx).imgname = annolist_gt(imgidx).image.name;
            keypointsAll(imgidx).det = nan(16,3);
        end
    end
    
    for imgidx = 1:length(boxes)
        [~,name] = fileparts(keypointsAll(imgidx).imgname);
%         assert(strcmp(name,image_ids{imgidx})>0);
%         det = boxes_nonms{imgidx};
        det = boxes{imgidx};
        xx = mean(det(:,[1 3]),2);
        yy = mean(det(:,[2 4]),2);
        scores = det(:,5);
        objpos = annolist_gt(imgidx).annorect.objpos;
        iy = round(Y0 + (yy - objpos.y));
        ix = round(X0 + (xx - objpos.x));
        iy = max(iy,1);
        iy = min(iy,size(prior,1));
        ix = max(ix,1);
        ix = min(ix,size(prior,2));
        iy_hist = ceil(iy/binSize);
        ix_hist = ceil(ix/binSize);
        iy_prior = (iy_hist-1)*binSize+1;
        ix_prior = (ix_hist-1)*binSize+1;
        priorPart = prior(:,:,i);
        idxs = sub2ind(size(priorPart),iy_prior,ix_prior);
%         scores01 = (scores - min(scores))/(max(scores)-min(scores));
        scores01 = 1.0./(1.0+exp(-scores));
%         scores01(priorPart(idxs) < 0.01) = 0;
        scoresNew = scores01 .*priorPart(idxs);
%         scoresNew = scores .* priorPart(idxs);
%         [val,idx] = max(scoresNew);
%         [val,idx] = sort(scoresNew,'descend');
        [val,idx] = max(scoresNew);
%         [val2, idx2] = max(priorPart(idxs(idx(1:10))));
%         idx = idx(idx2);
%         y = yy(idx);
%         x = xx(idx);
        keypointsAll(imgidx).det(jidx+1,:) = [[xx(idx(1)) yy(idx(1))] scores(idx(1))];
    end
end

end