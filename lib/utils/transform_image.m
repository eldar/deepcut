function [imgT,pointsT] = transform_image(img,points,M)

T = maketform('affine',M');
imgT = imtransform(img,T,'XYScale',1);

% translate points to image center
pointsC = points - repmat([size(img,2)/2 size(img,1)/2],size(points,1),1);

% transform centered points
pointsT = M*[pointsC ones(size(points,1),1)]';
pointsT = pointsT(1:2,:)';

% translate points back
pointsT = pointsT +  repmat([size(imgT,2)/2 size(imgT,1)/2],size(points,1),1);

figure(1); clf;
subplot(1,2,1);imagesc(img); axis equal; hold on;
plot(points(:,1),points(:,2),'r+','MarkerSize',5);

subplot(1,2,2);imagesc(imgT); axis equal; hold on;
plot(pointsT(:,1),pointsT(:,2),'r+','MarkerSize',5);

end