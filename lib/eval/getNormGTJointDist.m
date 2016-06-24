function dist = getNormGTJointDist(keypointsAll,gt_annolist,jidx,bUseHeadSize,bHeadSizeFromRect,jidxGT)

if (nargin < 5)
    bHeadSizeFromRect = true;
end

if (nargin < 6)
    jidxGT = jidx;
end

dist = nan(length(gt_annolist),1);
for imgidx = 1:length(gt_annolist)
    
    rect = gt_annolist(imgidx).annorect(1);
    assert(length(rect) == 1);
    if (bUseHeadSize)
        if (bHeadSizeFromRect)
            refDist = util_get_head_size(rect);
        else
            if (isfield(rect, 'annopoints'))
                points = rect.annopoints.point;
                p1 = util_get_annopoint_by_id(points,8);
                p2 = util_get_annopoint_by_id(points,9);
                refDist = norm([p1.x p1.y] - [p2.x, p2.y]);
            else
                assert(false);
            end
        end
    else
        refDist = util_get_torso_size(rect);
        if (isnan(refDist))
            continue;
        end
    end
    
    if (isfield(rect, 'annopoints'))
        p = util_get_annopoint_by_id(rect.annopoints.point, jidxGT);
        if (~isempty(p))
            det = keypointsAll(imgidx).det;
            if ~iscell(det)
                points_det = keypointsAll(imgidx).det(jidx+1,1:2);
                dist(imgidx) = norm([p.x p.y] - points_det)/refDist;
            else
                points_det = keypointsAll(imgidx).det{jidx+1}(:,1:2);
                d = sqrt(sum((repmat([p.x p.y],size(points_det,1),1) - points_det).^2,2))./refDist;
                dist(imgidx) = min(d);
            end
        end
    end
end