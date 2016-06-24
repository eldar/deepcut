function keypointsAll= inf2keypointsImgBPcell(expidx,parts,annolist_gt,imgidxs_gt)

if (nargin < 4)
    imgidxs_gt = 1:length(annolist_gt);
end
fprintf('inf2keypointsImg()\n');

p = rcnn_exp_params(expidx);
conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
if (isfield(p,'infDir'))
    infDir = p.infDir;
else
    infDir = [conf.cache_dir '/inference'];    
end

keypointsAll = struct();

for imgidx = 1:length(imgidxs_gt)
    
    fprintf('.');
    
    fnameInf = [infDir '/imgidx_' padZeros(num2str(imgidxs_gt(imgidx)-1),5) '.mat'];
%     if (~exist(fnameInf,'file'))
%         continue;
%     end
    load(fnameInf,'predAll');
    
    keypointsAll(imgidx).imgname = annolist_gt(imgidxs_gt(imgidx)).image.name;
    assert(length(p.pidxs) == length(predAll));
    
    for i = 1:length(p.pidxs)
        pidx = p.pidxs(i);
        % part is a joint
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);
        
        det = predAll{i};
%         [val,id] = max(det(:,4)); % for not swapped minus factor graph (expidx 326)
%         [val,id] = max(det(:,5));
        
%         x = det(id,1);
%         y = det(id,2);
%         keypointsAll(imgidx).det(jidx+1,:) = [[x y] val];
        keypointsAll(imgidx).det{jidx+1} = det;
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(imgidxs_gt));
    end
end
fprintf(' done\n');

end