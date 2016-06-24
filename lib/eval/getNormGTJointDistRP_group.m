function [dist,score,points] = getNormGTJointDistRP_group(keypointsAll,gt_annolist,jidx,boxesNeck)

dist = cell(length(gt_annolist),1);
score = cell(length(gt_annolist),1);
points = cell(length(gt_annolist),1);

for imgidx = 1:length(gt_annolist)
    assert(strcmp(keypointsAll(imgidx).imgname,gt_annolist(imgidx).image.name) > 0);
    dist{imgidx} = inf(0,length(gt_annolist(imgidx).annorect));
end

for imgidx = 1:length(gt_annolist)
%     figure(200); clf; imagesc(imread(gt_annolist(imgidx).image.name));
%     hold on; axis equal;
    for detidx = 1:size(boxesNeck(imgidx).det,1)
        sc = nan;
        pp = [nan nan];
        d = inf(1,length(gt_annolist(imgidx).annorect));
        
        det = keypointsAll(imgidx).det{jidx+1,1};
        if (~isempty(det))
            x1 = boxesNeck(imgidx).det(detidx,1);
            y1 = boxesNeck(imgidx).det(detidx,2);
            x2 = boxesNeck(imgidx).det(detidx,3);
            y2 = boxesNeck(imgidx).det(detidx,4);
            keep = (det(:,1)>=x1 & det(:,1)<= x2 & det(:,2) >= y1 & det(:,2) <= y2);
            
            det = det(keep,:);
%                     rectangle('Pos',[x1 y1 x2 - x1 y2 - y1],'lineWidth',5,'edgeColor','g');
            if (~isempty(det))
                [val,idx] = max(det(:,end));
                sc = det(idx,3);
                pp = det(idx,1:2);
%                             plot(pp(1,1),pp(1,2),'r*','Markersize',15);
                for ridx = 1:length(gt_annolist(imgidx).annorect)
                    rect = gt_annolist(imgidx).annorect(ridx);
                    assert(length(rect) == 1);
                    refDist = util_get_head_size(rect);
                    if (isfield(rect, 'annopoints') && isfield(rect.annopoints, 'point'))
                        p = util_get_annopoint_by_id(rect.annopoints.point, jidx);
                        if (~isempty(p))
                            if (p.x>=x1 && p.x<= x2 && p.y >= y1 && p.y <= y2)
                                d(1,ridx) = norm([p.x p.y] - pp)/refDist;
                            end
%                                                     plot(p.x,p.y,'y+','Markersize',15);
                        else
                            d(1,ridx) = nan;
                        end
                    end
                end
            end
        end
        for ridx = 1:length(gt_annolist(imgidx).annorect)
            rect = gt_annolist(imgidx).annorect(ridx);
            if (isfield(rect, 'annopoints') && isfield(rect.annopoints, 'point'))
                p = util_get_annopoint_by_id(rect.annopoints.point, jidx);
                if (isempty(p))
                    d(1,ridx) = nan;
                end
            end
        end
%         score{imgidx} = [score{imgidx};sc];
%         points{imgidx} = [points{imgidx};pp];
%         dist{imgidx} = [dist{imgidx};d];
        score{imgidx} = [score{imgidx};sc];
        points{imgidx} = [points{imgidx};pp];
        dist{imgidx} = [dist{imgidx};d];
    end
end