function keypointsAll= inf2keypointsImgBPcellMulti(expidx,parts,annolist_gt,imgidxs_gt)

fprintf('inf2keypointsImg()\n');

p = rcnn_exp_params(expidx);
conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
if (isfield(p,'infDir'))
    infDir = p.infDir;
else
    infDir = [conf.cache_dir '/inference'];    
end

keypointsAll = struct();
nTrials = 12;

for imgidx = 1:length(annolist_gt)
    
    keypointsAll(imgidx).det = cell(nTrials/2,1);
    fprintf('.');
    for trialidx = 1:nTrials/2
        fnameInf = [infDir '/imgidx_' padZeros(num2str(imgidxs_gt(imgidx)-1),5) '_' num2str(trialidx) '.mat'];
        %     if (~exist(fnameInf,'file'))
        %         continue;
        %     end
        try
            load(fnameInf,'predAll');
            keypointsAll(imgidx).det{trialidx} = cell(16,1);
            
            keypointsAll(imgidx).imgname = annolist_gt(imgidx).image.name;
            assert(length(p.pidxs) == length(predAll));
            
            for i = 1:length(p.pidxs)
                pidx = p.pidxs(i);
                % part is a joint
                assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
                jidx = parts(pidx+1).pos(1);
                
                det = predAll{i};
                if (~isempty(det))
                    %         [val,id] = max(det(:,4)); % for not swapped minus factor graph (expidx 326)
                    [val,id] = max(det(:,5));
                    
                    %                 keypointsAll(imgidx).det(jidx+1,:) = [[x y] val];
                    keypointsAll(imgidx).det{trialidx}{jidx+1} = [keypointsAll(imgidx).det{trialidx}{jidx+1}; det(id,:)];
                    
                    [val,id] = max(det(:,6));
                    
                    keypointsAll(imgidx).det{trialidx}{jidx+1} = [keypointsAll(imgidx).det{trialidx}{jidx+1}; det(id,:)];
                else
                    keypointsAll(imgidx).det{trialidx}{jidx+1} = [keypointsAll(imgidx).det{trialidx}{jidx+1}; nan(1,6)];
                    keypointsAll(imgidx).det{trialidx}{jidx+1} = [keypointsAll(imgidx).det{trialidx}{jidx+1}; nan(1,6)];
                end
            end
        catch
            fnameInfNext = [infDir '/imgidx_' padZeros(num2str(imgidx-1),5) '_' num2str(trialidx+1) '.mat'];
            assert(~exist(fnameInfNext,'file'));
            assert(trialidx > 1);
        end
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist_gt));
    end
end
fprintf(' done\n');

end