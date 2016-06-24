function stickmen = getImprovedTorsoHead(stickmen,unProb,unPosAll,pidxOffset,img)

% min detection score
detScoreThresh = 0.1;
% how much can deviate from the top head
topHeadMult = 0.1;
% how much can deviate from the neck
topNeckMult = 0.7;
% ignore torso prediction for boxes significantly overlapping with other boxes
% and located significantly higher than other boxes
% addresses cases when torso is mistakenly predicted for occluded people 
% standing in the second row
% least overlap and difference in y required to ignore the torso prediction
ovThresh = 0.2;
hThresh = 0.1;

topHeadIdx = 7;
neckIdx = 6;
% figure(101); clf; imagesc(img); axis equal; axis off;

for ridx = 1:length(stickmen)
    headStick = stickmen(ridx).coor(:,6);
    headSize = norm(headStick(1:2)-headStick(3:4));
    
    % select detections with reasonable head score
    idxs = find(unProb(:,topHeadIdx+1) >= detScoreThresh);
    headPos = unPosAll{topHeadIdx+pidxOffset+1}(idxs,:);
    % compute distance to top head stick
    d = sqrt(sum((headPos - repmat(headStick(1:2)',size(headPos,1),1)).^2,2));
    [val,idxTopHead] = min(d);
    % if detection is in vicinity, use detection
    if (val <= topHeadMult*headSize)
        headStick(1:2) = headPos(idxTopHead,:);
    end
    
    % select detections with reasonable neck score
    idxs = find(unProb(:,neckIdx+1) >= detScoreThresh);
    neckPos = unPosAll{neckIdx+pidxOffset+1}(idxs,:);
    % compute distance to bottom head stick
    d = sqrt(sum((neckPos - repmat(headStick(3:4)',size(neckPos,1),1)).^2,2));
    [val,idxNeck] = min(d);
    % if detection is in vicinity, use detection
    if (val <= topNeckMult*headSize)
        headStick(3:4) = neckPos(idxNeck,:);
    end
    
    % update stick
    stickmen(ridx).coor(:,6) = headStick;
    
%     DrawStickman(stickmen(ridx).coor,[]); hold on;
%     plot(headPos(idxTopHead,1),headPos(idxTopHead,2),'r+');
%     plot(neckPos(idxNeck,1),neckPos(idxNeck,2),'b+');
end

% compute bounding box overlap
boxes = zeros(length(stickmen),4);
ov = zeros(length(stickmen),length(stickmen));
for ridx = 1:length(stickmen)
    boxes(ridx,:) = stickmen(ridx).det;
end
for ridx = 1:length(stickmen)
    ov(ridx,:) = boxoverlap(boxes, boxes(ridx,:));
end
ov(ov == 1) = 0;

% remove torso, if box overlap with other boxes >= thresh and box is significantly higher
for ridx = 1:length(stickmen)
    % all boxes with which the box overlaps >= thresh
    idxs = find(ov(ridx,:) >= ovThresh);
    % box height
    h = boxes(ridx,4) - boxes(ridx,2);
    for i = 1:length(idxs)
        % if box is significantly higher, remove torso
        if (boxes(idxs(i),2) - boxes(ridx,2) >= hThresh*h)
            stickmen(ridx).coor(:,1) = nan;
            break;
        end
    end
end