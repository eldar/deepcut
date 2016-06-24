function annolist = compute_gt_bbox(annolist,pidxs,parts,bbox_offset)

fprintf('compute_gt_bbox\n');

for imgidx = 1:length(annolist)
    fprintf('.');
    img = imread(annolist(imgidx).image.name);
    for ridx = 1:length(annolist(imgidx).annorect) % gt people
        
        rect = annolist(imgidx).annorect(ridx);
        points_gt = rect.annopoints.point;
        
        pointsGTmx = [];
        
        for i = 1:length(pidxs)
            pidx = pidxs(i);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
            pp = util_get_annopoint_by_id(points_gt, jidx);
            if (~isempty(pp))
                pointsGTmx = [pointsGTmx; pp.x pp.y];
            end
        end
        
        bbox = [min(pointsGTmx(:,1)) - bbox_offset min(pointsGTmx(:,2)) - bbox_offset ...
            max(pointsGTmx(:,1)) + bbox_offset max(pointsGTmx(:,2)) + bbox_offset];
        bbox(1) = max(bbox(1),1);
        bbox(2) = max(bbox(2),1);
        bbox(3) = min(bbox(3),size(img,2));
        bbox(4) = min(bbox(4),size(img,1));
        annolist(imgidx).annorect(ridx).bbox = bbox;
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist));
    end
end
fprintf(' done\n');
end