function boxes = scale_bbox(boxes,sc,X,Y)
% change scale
boxesC = [mean(boxes(:,[1 3]),2) mean(boxes(:,[2 4]),2)];
boxesW = boxes(:,3) - boxes(:,1);
boxesH = boxes(:,4) - boxes(:,2);
boxes = round([boxesC(:,1) - sc*boxesW/2 boxesC(:,2) - sc*boxesH/2 boxesC(:,1) + sc*boxesW/2 boxesC(:,2) + sc*boxesH/2]);

boxes(:,1) = max(ones(size(boxes,1),1),boxes(:,1));
boxes(:,2) = max(ones(size(boxes,1),1),boxes(:,2));
boxes(:,3) = min(ones(size(boxes,1),1)*X,boxes(:,3));
boxes(:,4) = min(ones(size(boxes,1),1)*Y,boxes(:,4));
end