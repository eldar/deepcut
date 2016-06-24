function [dist,score,points] = getStickDistRP(endpointsAll,gt_annolist,xaxis,pidx)

dist = cell(length(gt_annolist),2);
score = cell(length(gt_annolist),1);
points = cell(length(gt_annolist),1);

for imgidx = 1:length(gt_annolist)
    assert(strcmp(endpointsAll(imgidx).imgname,gt_annolist(imgidx).image.name) > 0);
    dist{imgidx,1} = inf(size(endpointsAll(imgidx).det{pidx},1),length(gt_annolist(imgidx).annorect));
    dist{imgidx,2} = inf(size(endpointsAll(imgidx).det{pidx},1),length(gt_annolist(imgidx).annorect));
end

for imgidx = 1:length(gt_annolist)
    for ridx = 1:length(gt_annolist(imgidx).annorect)
        rect = gt_annolist(imgidx).annorect(ridx);
        assert(length(rect) == 1);

        if (isfield(rect, 'annopoints') && isfield(rect.annopoints, 'point'))
            
            p1 = util_get_annopoint_by_id(rect.annopoints.point,xaxis(2));
            p2 = util_get_annopoint_by_id(rect.annopoints.point,xaxis(1));
            det = endpointsAll(imgidx).det{pidx};
            if ~isempty(det)
                score{imgidx} = det(:,5);
                points{imgidx} = det(:,1:4);
            end
            if (~isempty(p1) && ~isempty(p2))
                refDist = norm([p1.x p1.y] - [p2.x p2.y]);
                dist{imgidx,1}(:,ridx) = sqrt(sum(((repmat([p1.x p1.y],size(det,1),1) - det(:,1:2)).^2),2))/refDist;
                dist{imgidx,2}(:,ridx) = sqrt(sum(((repmat([p2.x p2.y],size(det,1),1) - det(:,3:4)).^2),2))/refDist;
            end
        end
    end
end