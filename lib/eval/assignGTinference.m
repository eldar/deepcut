function [distAll, scoresAll, pointsAll] = assignGTinference(keypointsAll,annolist,pidxsAll,parts,thresh_gt,marg_scores,nTrials)

if (nargin < 5)
    thresh_gt = 0.5;
end

scoresAll = cell(length(pidxsAll),1);
pointsAll = cell(length(pidxsAll),1);
distAll = cell(length(pidxsAll),1);

for i = 1:length(pidxsAll)
    scoresAll{i} = cell(length(annolist),1);
    pointsAll{i} = cell(length(annolist),1);
    distAll{i} = cell(length(annolist),1);
end

for imgidx = 1:length(annolist)
    
%     figure(200); clf; imagesc(imread(annolist(imgidx).image.name));
%     hold on; axis equal;
    
    dist = cell(2,1);
    
    det_c = {'g','b'};
    for detidx = 1:nTrials
        
        dist{detidx} = inf(length(pidxsAll),length(annolist(imgidx).annorect));
        for i = 1:length(pidxsAll)
            pidx = pidxsAll(i);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
        
            det = keypointsAll(imgidx).det{jidx+1};
            if (~isempty(det))
                [val,id] = max(det(:,4+detidx));
                pp = det(id,1:2);
            else
                val = -inf;
                pp = [0 0];
            end
            pointsAll{i}{imgidx} = [pointsAll{i}{imgidx}; pp];
            if (marg_scores)
                scoresAll{i}{imgidx} = [scoresAll{i}{imgidx}; val];
            else
                scoresAll{i}{imgidx} = [scoresAll{i}{imgidx}; det(id,3)];
            end
            
            for ridx = 1:length(annolist(imgidx).annorect)
                rect = annolist(imgidx).annorect(ridx);
                refDist = util_get_head_size(rect);
                if (isfield(rect, 'annopoints') && isfield(rect.annopoints, 'point'))
                    p = util_get_annopoint_by_id(rect.annopoints.point, jidx);
                    if (~isempty(p))
                        dist{detidx}(i,ridx) = norm([p.x p.y] - pp)/refDist;
%                         plot(p.x,p.y,'ro','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',10);
                    else
                        dist{detidx}(i,ridx) = nan;
                    end
                end
            end
%             plot(pp(1),pp(2),'ro','MarkerFaceColor',det_c{detidx},'MarkerEdgeColor','k','MarkerSize',10);
        end
    end
    
    for detidx = 1:2
        pckSum = zeros(1,size(dist{detidx},2));
        idxsNotNaN = ~isnan(dist{detidx});
        for i=1:size(dist{detidx},2)
            pckSum(i) = sum(dist{detidx}(idxsNotNaN(:,i),i) <= thresh_gt);
        end
        [val,idx] = max(pckSum);
        idx2 = setdiff(1:size(dist{detidx},2),idx);
        dist{detidx}(idxsNotNaN(:,idx2),idx2) = inf;
        for i = 1:length(pidxsAll)
            distAll{i}{imgidx} = [distAll{i}{imgidx}; dist{detidx}(i,:)];
        end
    end
   
end

end