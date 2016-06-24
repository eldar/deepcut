function meanPartLength = eval_compute_mean_part_length(annolist,parts)

fprintf('eval_compute_mean_part_length()\n');

meanPartLength = zeros(length(parts),1);
numGTseg = zeros(length(parts),1);

for pidx = 1:length(parts)
    
    for imgidx = 1:length(annolist)
        points = annolist(imgidx).annorect(1).annopoints.point;
        p1 = util_get_annopoint_by_id(points,parts(pidx).xaxis(2));
        p2 = util_get_annopoint_by_id(points,parts(pidx).xaxis(1));
        if (~isempty(p1) && ~isempty(p2))
            gtBottom = [p1.x p1.y];
            gtTop    = [p2.x p2.y];
            meanPartLength(pidx) = meanPartLength(pidx) + norm(gtBottom - gtTop);
            numGTseg(pidx) = numGTseg(pidx) + 1;
        end
    end
    
end
meanPartLength = meanPartLength./numGTseg;

end