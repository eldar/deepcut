function dist = getNormGTJointDistBackproject(keypointsAll,gt_annolist,jidx,bUseHeadSize,rectidxs_gt,bHeadSizeFromRect)

if (nargin < 6)
    bHeadSizeFromRect = true;
end

lastidx = 0;
dist = nan(sum(cellfun(@length,rectidxs_gt)),1);
for imgidx = 1:length(gt_annolist)
    refDistAll = nan(length(rectidxs_gt{imgidx}),1);
    point_gt = nan(length(rectidxs_gt{imgidx}),2);
    objpos_gt = nan(length(rectidxs_gt{imgidx}),2);
    if (~isempty(rectidxs_gt{imgidx}))
        for r = 1:length(rectidxs_gt{imgidx})
            rect = gt_annolist(imgidx).annorect(rectidxs_gt{imgidx}(r));
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
                p = util_get_annopoint_by_id(rect.annopoints.point, jidx);
                if (~isempty(p))
                    refDistAll(r) = refDist;
                    point_gt(r,:) = [p.x,p.y];
                    objpos_gt(r,:) = [rect.objpos.x rect.objpos.y];
                end
            end
        end
        
        idxs = find(~isnan(refDistAll));
        [~,idxsPoints] = sort(keypointsAll(imgidx).det{jidx+1}(:,3),'descend');
%         for r = 1:length(idxs)
%             x = keypointsAll(imgidx).det{jidx+1}(idxsPoints,1);
%             y = keypointsAll(imgidx).det{jidx+1}(idxsPoints,2);
%             d = sqrt(sum((repmat(point(idxs(r),:), length(idxsPoints),1) - [x y]).^2,2))./refDistAll(idxs(r));
%             [val,idx] = min(d);
%             dist(lastidx+1) = val;
%             lastidx = lastidx + 1;
%         end
        point_det = keypointsAll(imgidx).det{jidx+1}(idxsPoints,1:2);
        for r = 1:length(idxs)
            d = sqrt(sum((repmat(objpos_gt(idxs(r),:), length(idxsPoints),1) - point_det).^2,2))./refDistAll(idxs(r));
            [~,idx] = min(d);
            dist(lastidx+1) = norm(point_gt(idxs(r),:)-point_det(idx,:));
            lastidx = lastidx + 1;
        end

    end
end