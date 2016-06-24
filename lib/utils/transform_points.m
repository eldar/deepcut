function [pointsT] = transform_points(points,M,sizeImgOrig,sizeImgT)

% translate points to image center
pointsC = points - repmat([sizeImgOrig(2)/2 sizeImgOrig(1)/2],size(points,1),1);

% transform centered points
pointsT = M*[pointsC ones(size(points,1),1)]';
pointsT = pointsT(1:2,:)';

% translate points back
pointsT = pointsT +  repmat([sizeImgT(2)/2 sizeImgT(1)/2],size(points,1),1);

% figure(1); clf;
% subplot(1,2,1);imagesc(img); axis equal; hold on;
% plot(points(:,1),points(:,2),'r+','MarkerSize',5);
% 
% subplot(1,2,2);imagesc(imgT); axis equal; hold on;
% plot(pointsT(:,1),pointsT(:,2),'r+','MarkerSize',5);

end