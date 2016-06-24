function [keypointsAll, imgidxs_missing] = det2keypointsImgMulticutUnaries(expidx,parts,annolist_gt)

fprintf('det2keypointsImgMulticut()\n');

if (nargin < 4)
    nDet = 1;
end

assert(nDet == 1);

p = rcnn_exp_params(expidx);
if (isfield(p,'predDir'))
    predDir = [p.predDir '/multicut/'];
else
    conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
    predDir = [conf.cache_dir '/multicut/'];
end

if (isfield(p,'min_det_score'))
    min_det_score = p.min_det_score;
else
    min_det_score = -inf;
end

if (isfield(p,'top_det'))
    nDet = p.top_det;
else
    nDet = 1;
end

if (nDet == 1)
    keypointsAll = repmat(struct('imgname','','det',nan(16,3)), length(annolist_gt), 1);
else
    for imgidx = 1:length(annolist_gt)
        keypointsAll(imgidx).imgname = '';
        keypointsAll(imgidx).det = cell(16,1);
    end
end

nmissing = 0;
imgidxs_missing = [];
for imgidx = 1:length(annolist_gt)
    
    fprintf('.');
        
    keypointsAll(imgidx).imgname = annolist_gt(imgidx).image.name;
    
    fname = [predDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_1_14'];
    try
        load(fname,'unLab','unPos','unProb');
    catch
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            jidx = parts(pidx+1).pos(1);
            keypointsAll(imgidx).det(jidx+1,:) = [inf inf -1];
        end
        nmissing = nmissing + 1;
        imgidxs_missing = [imgidxs_missing; imgidx];
        continue;
    end
    
    for i = 1:length(p.pidxs)
        
        pidx = p.pidxs(i);
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);
        
        if (nDet == 1)
            
            [val,idx] = max(unProb(:,i));
            det = [unPos(idx,:),val];
            if (val < min_det_score)
                det = [inf inf -1];
            end
            % part is a joint
            
            keypointsAll(imgidx).det(jidx+1,:) = det;
        else
%             assert(nDet == size(unProb,1));
            [val,idxs] = sort(unProb(:,i),'descend');
            idxs = idxs(1:min(nDet,length(idxs)));
            % use score threshold
            idxs2 = find(unProb(idxs,i) >= min_det_score);
            idxs = idxs(idxs2);
            if (~isempty(idxs))
                keypointsAll(imgidx).det{jidx+1,:} = [unPos(idxs,:) unProb(idxs,i)];
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
fprintf('nmissing: %d\n',nmissing);

end