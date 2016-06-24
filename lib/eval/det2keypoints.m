function keypointsAll = det2keypoints(expidx,parts,annolist_gt,bMaxOnly)

if (nargin < 4)
    bMaxOnly = true;
end

keypointsAll = [];

p = rcnn_exp_params(expidx);

for i = 1:length(p.pidxs)
       
    pidx = p.pidxs(i);
    % part is a joint
    assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
    jidx = parts(pidx+1).pos(1);
    
    fname = [p.evalTest '_cidx_' num2str(pidx)];
    fprintf('load %s\n',fname);
    try
        load(fname,'boxes','boxes_nonms','image_ids');
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
        det = boxes{imgidx};
        
        if (bMaxOnly)
            [val,idx] = max(det(:,5));
            x = mean(det(idx,[1 3]));
            y = mean(det(idx,[2 4]));
            keypointsAll(imgidx).det(jidx+1,:) = [[x y] val];
        else
            x = mean(det(:,[1 3]),2);
            y = mean(det(:,[2 4]),2);
            keypointsAll(imgidx).det(jidx+1,:) = [[x y] det(:,5)];
        end
        
    end
end

end