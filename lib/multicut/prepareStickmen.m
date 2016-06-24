function stickmen = prepareStickmen(stickmen,keypointsAll,poseRefPoint,bDeriveTorsoHeadDet,getStickmenCoordFunc)

for ridx = 1:length(stickmen)
    % erase all coor values
    stickmen(ridx).coor = nan(4,6);
    % use upper body detection bounding box from Eichner&Ferrari
    box = stickmen(ridx).det;
    % compute torso and head sticks from the box
    [torsoStick, headStick] = getTorsoHeadStickFromBbox(box);
    % compute reference point of box as head center
    boxRefPoint = [mean(headStick([1 3])) mean(headStick([2 4]))];
    d = sqrt(sum((poseRefPoint - repmat(boxRefPoint,size(poseRefPoint,1),1)).^2,2));
    % find closest multicut pose
    [dist,clusidx] = min(d);
    % compute head size
    headSize = norm(headStick(1:2)-headStick(3:4));
    % if multicut head center matches det bbox head center
    if (dist <= 1.0*headSize)
        stickmen(ridx).coor = getStickmenCoordFunc(keypointsAll(:,clusidx));
    end
    % fill in torso and head sticks computed from box
    if (bDeriveTorsoHeadDet)
        % compute torso/head sticks from detection box
        stickmen(ridx).coor(:,1) = torsoStick;
        stickmen(ridx).coor(:,6) = headStick;
    end
end