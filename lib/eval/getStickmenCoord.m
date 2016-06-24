function coor = getStickmenCoord(keypointsAll)

coor = nan(4,6);

cidx = 6; pidx = [14 13];
if (~isempty(keypointsAll{pidx(1)}) && ~isempty(keypointsAll{pidx(2)}))
    coor(1:2,cidx) = keypointsAll{pidx(1)};
    coor(3:4,cidx) = keypointsAll{pidx(2)};
end

% no torso prediction
coor(1:4,cidx) = nan;

cidx = 2; pidx = [9 8];
if (~isempty(keypointsAll{pidx(1)}) && (~isempty(keypointsAll{pidx(2)})))
    coor(1:2,cidx) = keypointsAll{pidx(1)};
    coor(3:4,cidx) = keypointsAll{pidx(2)};
end

cidx = 4; pidx = [8 7];
if (~isempty(keypointsAll{pidx(1)}) && (~isempty(keypointsAll{pidx(2)})))
    coor(1:2,cidx) = keypointsAll{pidx(1)};
    coor(3:4,cidx) = keypointsAll{pidx(2)};
end

cidx = 3; pidx = [10 11];
if (~isempty(keypointsAll{pidx(1)}) && (~isempty(keypointsAll{pidx(2)})))
    coor(1:2,cidx) = keypointsAll{pidx(1)};
    coor(3:4,cidx) = keypointsAll{pidx(2)};
end

cidx = 5; pidx = [11 12];
if (~isempty(keypointsAll{pidx(1)}) &&  (~isempty(keypointsAll{pidx(2)})))
    coor(1:2,cidx) = keypointsAll{pidx(1)};
    coor(3:4,cidx) = keypointsAll{pidx(2)};
end

end