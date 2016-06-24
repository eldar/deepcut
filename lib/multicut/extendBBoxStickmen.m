function boxesAll = extendBBoxStickmen(stickmen)
boxesAll = zeros(length(stickmen),4);
for ridx = 1:length(stickmen)
    box = stickmen(ridx).det;
    h = box(4) - box(2);
    % 2x extension in Y
    box(4) = box(4) + h;
    % pad in from all sides
    delta1 = 0.1*h;
    delta2 = 0.1*h;
    box = box + [-delta1 -delta2 delta1 delta2];
    boxesAll(ridx,:) = box;
end

end