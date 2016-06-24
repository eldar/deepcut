function dist = getNormGTJointDistMulti(keypointsAll,gt_annolist,jidx,bUseHeadSize,bHeadSizeFromRect,jidxGT,nrects)

if (nargin < 5)
    bHeadSizeFromRect = true;
end

if (nargin < 6)
    jidxGT = jidx;
end

scCorr = 1.33;% WAF scale correction factor when using head annopoints

dist = nan(nrects,1);
n = 0;
for imgidx = 1:length(gt_annolist)
    
    rect = gt_annolist(imgidx).annorect;
    for ridx = 1:length(rect)
        n = n + 1;
        if (bUseHeadSize)
            if (bHeadSizeFromRect)
                refDist = util_get_head_size(rect(ridx));
            else
                if (isfield(rect(ridx), 'annopoints'))
                    points = rect(ridx).annopoints.point;
                    p1 = util_get_annopoint_by_id(points,8);
                    p2 = util_get_annopoint_by_id(points,9);
                    refDist = scCorr*norm([p1.x p1.y] - [p2.x, p2.y]);
                else
                    assert(false);
                end
            end
        else
            refDist = util_get_torso_size(rect(ridx));
            if (isnan(refDist))
                continue;
            end
        end
        
        if (isfield(rect(ridx), 'annopoints'))
            points = rect(ridx).annopoints.point;
            pointsAll = [];
            for ppidx = 1:length(points)
                pointsAll = [pointsAll; points(ppidx).x points(ppidx).y];
            end
            bbox = [min(pointsAll(:,1)) min(pointsAll(:,2)) max(pointsAll(:,1)) max(pointsAll(:,2))];
            d = refDist*0.1;
            bbox = bbox + [-d -d d d];
            p = util_get_annopoint_by_id(rect(ridx).annopoints.point, jidxGT);
            if (~isempty(p))
                det = keypointsAll(imgidx).det{jidx+1};
                idxs = det(:,1) >= bbox(1) & det(:,2) >= bbox(2) & det(:,1) <= bbox(3) & det(:,2) <= bbox(4);
                detRect = det(idxs,:);
                if (~isempty(detRect))
                    [val,id] = max(detRect(:,3));
                    points_det = detRect(id,1:2);
                else
                    points_det = [inf inf];
                end
                dist(n) = norm([p.x p.y] - points_det)/refDist;
                bVis = false;
                if (bVis)
                    figure(100); clf; imagesc(imread(gt_annolist(imgidx).image.name)); axis equal; hold on;
                    vis_bbox(bbox,'g');
                    plot(points_det(:,1),points_det(:,2),'ro','MarkerSize',6,'MarkerFaceColor','r');
                    plot(p.x,p.y,'go','MarkerSize',6,'MarkerFaceColor','g');
                    text(bbox(1),bbox(2),sprintf('%1.2f',dist(n)),'FontSize',10,'color','k','BackgroundColor','g',...
                        'verticalalignment','top','horizontalalignment','left');
                end
            end
        end
    end
end