function dist = getNormGTJointDistOracle(keypointsAll,gt_annolist,jidx,bUseHeadSize,bFixPart)

dist = nan(length(gt_annolist),1);
for imgidx = 1:length(gt_annolist)
    
    rect = gt_annolist(imgidx).annorect(1);
    assert(length(rect) == 1);
    if (bUseHeadSize)
        refDist = util_get_head_size(rect);
    else
        refDist = util_get_torso_size(rect);
        if (isnan(refDist))
            continue;
        end
    end
    
    if (isfield(rect, 'annopoints'))
        p = util_get_annopoint_by_id(rect.annopoints.point, jidx);
        if (~isempty(p))
            distAll = inf(length(keypointsAll(imgidx).det),1);
            if (bFixPart)
                jidxs2 = jidx+1;
            else
                jidxs2 = find(~cellfun(@isempty,keypointsAll(imgidx).det));
            end
            for jidx2 = jidxs2'
                xy = keypointsAll(imgidx).det{jidx2};
                xy = reshape(xy,length(xy)/2,2);
                d = sqrt(sum((repmat([p.x p.y],size(xy,1),1) - xy).^2,2));
                [val,idx] = min(d);
                distAll(jidx2+1) = norm([p.x p.y] - xy(idx,:))/refDist;
            end
            dist(imgidx) = min(distAll);%norm([p.x p.y] - xy(idx,:))/refDist;
        end
    end
end