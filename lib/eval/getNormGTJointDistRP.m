function [dist,score,points] = getNormGTJointDistRP_group(keypointsAll,gt_annolist,jidx,bUseHeadSize,bHeadSizeFromRect)

if (nargin < 5)
    bHeadSizeFromRect = true;
end

dist = cell(length(gt_annolist),1);
score = cell(length(gt_annolist),1);
points = cell(length(gt_annolist),1);

for imgidx = 1:length(gt_annolist)
    assert(strcmp(keypointsAll(imgidx).imgname,gt_annolist(imgidx).image.name) > 0);
    dist{imgidx} = inf(size(keypointsAll(imgidx).det{jidx+1},1),length(gt_annolist(imgidx).annorect));
end

for imgidx = 1:length(gt_annolist)
    
    for ridx = 1:length(gt_annolist(imgidx).annorect)
        rect = gt_annolist(imgidx).annorect(ridx);
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
        
        if (isfield(rect, 'annopoints') && isfield(rect.annopoints, 'point'))
            det = keypointsAll(imgidx).det{jidx+1,1};
            score{imgidx} = det(:,3);
            points{imgidx} = det(:,1:2);
            p = util_get_annopoint_by_id(rect.annopoints.point, jidx);
            if (~isempty(p))
                dist{imgidx}(:,ridx) = sqrt(sum(((repmat([p.x p.y],size(det,1),1) - det(:,1:2)).^2),2))/refDist;
            end
        end
    end
end