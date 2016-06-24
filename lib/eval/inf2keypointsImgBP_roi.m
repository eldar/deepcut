function keypointsAll= inf2keypointsImgBP_roi(expidx,parts,annolist_gt,boxesNeck,imgidxs_gt,marg_scores)

fprintf('inf2keypointsImgBP_roi()\n');

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
    keypointsAll(imgidx).imgname = annolist_gt(imgidxs_gt(imgidx)).image.name;
    keypointsAll(imgidx).det = cell(16,1);
    for detidx = 1:size(boxesNeck(imgidx).det,1)
        fnameInf = [infDir '/imgidx_' padZeros(num2str(imgidxs_gt(imgidx)-1),5) '_' num2str(detidx) '.mat'];
        
        load(fnameInf,'predAll');
        assert(length(p.pidxs) == length(predAll));
        
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
            
            det = predAll{i};
            %         [val,id] = max(det(:,4)); % for not swapped minus factor graph (expidx 326)
            if (~isempty(det))
                [val,id] = max(det(:,5));
                x = det(id,1);
                y = det(id,2);
                if (marg_scores)
                    val = det(id,5);
                else
                    val = det(id,3);
                end
                keypointsAll(imgidx).det{jidx+1} = [keypointsAll(imgidx).det{jidx+1,:};[[x y] val]];
            end
        end
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(imgidxs_gt));
    end
end
fprintf(' done\n');

end