function [torsoStick, headStick] = getTorsoHeadStickFromBbox(box)

% head and neck points computed from detection bounding box
topHeadDet = [0.5*(box(1)+box(3)) box(2)];
neckDet = [0.5*(box(1)+box(3)) 0.5*(box(2)+box(4))];
headHeight = norm(topHeadDet-neckDet);

topTorsoDet = neckDet;
% torso height = 0.5 * bbox_height + 0.5 * head_height
bottomTorsoDet = topTorsoDet + [0 0.5*(box(4)-box(2))] + [0 0.5*headHeight];
% bottomTorsoDet = [0.5*(box(1)+box(3)), box(4) + 0.5*(box(4)-box(2))];

torsoStick = [topTorsoDet'; bottomTorsoDet'];
headStick = [topHeadDet'; neckDet'];

end
