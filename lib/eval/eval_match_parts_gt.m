function isMatchAll = eval_match_parts_gt(endpointsAll, annolist, sc, evlType, factor, nPartsEval)

fprintf('eval_match_parts_gt()\n');

if ischar(annolist)
    annolist = loadannotations(annolist);
end

if (nargin < 5)
    factor = 0.5;
end

if (nargin < 4)
    evlType = 1;
end

if (nargin < 5)
    nPartsEval = 10;
end

if (nPartsEval > 10)
    [~, parts] = util_get_parts_spatial();
else
    [~, parts] = util_get_parts();
end

if (evlType == 2)
    mean_part_length = eval_compute_mean_part_length(annolist,parts);
end

isMatchAll = nan(length(annolist),length(parts));

for imgidx = 1:length(annolist)
    fprintf('.');
    rect = annolist(imgidx).annorect(1);
    points = rect.annopoints.point;
    endpoints = endpointsAll{imgidx};
   
    if (isempty(endpoints))
        for pidx = 1:length(parts)
            p1 = util_get_annopoint_by_id(points,parts(pidx).xaxis(2));
            p2 = util_get_annopoint_by_id(points,parts(pidx).xaxis(1));
            if (~isempty(p1) && ~isempty(p2))
                isMatchAll(imgidx,pidx) = 0;
            end
        end
    else
        for pidx = 1:length(parts)
            p1 = util_get_annopoint_by_id(points,parts(pidx).xaxis(2));
            p2 = util_get_annopoint_by_id(points,parts(pidx).xaxis(1));
            
            detBottom = [endpoints(pidx,1) endpoints(pidx,2)];
            detTop    = [endpoints(pidx,3) endpoints(pidx,4)];
            
            if (~isempty(p1) && ~isempty(p2)) 
                gtBottom = sc*[p1.x p1.y];
                gtTop    = sc*[p2.x p2.y];
                
                distBottom = norm(detBottom - gtBottom);
                distTop    = norm(detTop   - gtTop);
                
                if (evlType == 1) % standard pcp
                    % use part size
                    gtScale = norm(gtBottom - gtTop);
                elseif (evlType == 2) % pcp with fixed thresh
                    % use mean part length
                    gtScale = sc*mean_part_length(pidx);
                end
                
                bIsGTmatch = is_gt_match_pcp(distBottom, distTop, factor, gtScale);
                isMatchAll(imgidx,pidx) = bIsGTmatch;
            end
        end
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist));
    end
end
fprintf('\ndone\n');

    function res = is_gt_match_pcp(distBottom, distTop, factor, gtLen)
        res = distBottom <= gtLen*factor && distTop <= gtLen*factor;
    end

end