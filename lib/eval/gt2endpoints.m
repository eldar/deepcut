function endpointsAll = gt2endpoints(annolistFilename)

if isstruct(annolistFilename)
    annolist = annolistFilename;
else
    load(annolistFilename);
end
%if (~exist('annolist','var'))
%    annolist = single_person_annolist;
%end
endpointsAll = cell(length(annolist),1);

skel = [0 1; 1 2; 3 4; 4 5; 6 7; 8 9; 10 11; 11 12; 13 14; 14 15];

for imgidx = 1:length(annolist)
    endpoints = nan(10,4);
    points = annolist(imgidx).annorect.annopoints.point;
    for sidx = 1:size(skel,1)
        p1 = util_get_annopoint_by_id(points,skel(sidx,1));
        p2 = util_get_annopoint_by_id(points,skel(sidx,2));
        if (~isempty(p1) && ~isempty(p2))
            endpoints(sidx,:) = [p1.x p1.y p2.x p2.y];
        end
    end
    endpointsAll{imgidx} = endpoints;
end

end