function rotate_data(expidx,firstidx,nImgs)

fprintf('rotate_data()\n');

if (ischar(expidx))
    expidx = str2double(expidx);
end
if (ischar(firstidx))
    firstidx = str2double(firstidx);
end
if (ischar(nImgs))
    nImgs = str2double(nImgs);
end

fprintf('expidx: %d\n',expidx);
fprintf('firstidx: %d\n',firstidx);
fprintf('nImgs: %d\n',nImgs);

p = rcnn_exp_params(expidx);

tic
fprintf('load annotations... ');
annolistName = p.trainGT;
load(annolistName,'annolist');
fprintf('done!\n');
toc
% annolist = annolist(1:10);

lastidx = firstidx + nImgs - 1;

if (lastidx > length(annolist))
    lastidx = length(annolist);
end

if (lastidx < firstidx)
    return;
end

[~,n] = fileparts(annolistName);
annolistNameT = [p.saveImg '/' n '-add-rotated-' padZeros(num2str(firstidx),5) '-' padZeros(num2str(firstidx+nImgs-1),5)];
detNameT = [p.saveDet '/detAll-' padZeros(num2str(firstidx),5) '-' padZeros(num2str(firstidx+nImgs-1),5)];

% check if the files exist
try
    load(annolistNameT,'annolist');
    load(detNameT,'detAll');
    assert(exist('annolist','var')>0);
    assert(exist('detAll','var')>0);
    fprintf('file exist: %s\n',annolistNameT);
    fprintf('file exist: %s\n',detNameT);
    return;
catch
end

saveTo = [p.saveImg '/rotated/'];
if (~exist(saveTo,'dir'))
    mkdir(saveTo);
end

if (~exist(p.saveDet,'dir'))
    mkdir(p.saveDet);
end

tic
fprintf('load proposals... ');
detName = [p.trainDet '/detAll'];
load(detName);
fprintf('done!\n');
toc

assert(length(detAll) == length(annolist));

% rotation angles in degrees
angles = p.dataAugmAngles;
% angles = [-15 15];

bVis = false;

annolistT = annolist(1);
detAllT = detAll(1);
imgidxT = 1;

for imgidx = firstidx:lastidx
    fprintf('.');
    annolistT(imgidxT) = annolist(imgidx);
    assert(strcmp(detAll(imgidx).imgname,annolist(imgidx).image.name)>0);
    detAllT(imgidxT) = detAll(imgidx);
    
    if (isfield(annolist(imgidx),'annorect'))
        rect = annolist(imgidx).annorect;
        assert(length(rect) == 1);
        
        if (isfield(rect ,'annopoints') && isfield(rect.annopoints, 'point'))
        
            img = imread(annolist(imgidx).image.name);
            points = [[rect.annopoints.point.x]',[rect.annopoints.point.y]'];
            nPoints = size(points,1);
            points = [points; [(rect.x1 + rect.x2)/2 (rect.y1 + rect.y2)/2]];
    
            if (isfield(rect,'objpos'))
                points = [points; [rect.objpos.x rect.objpos.y]];
            end
            [~,n] = fileparts(annolist(imgidx).image.name);
    
            for i = 1:length(angles)
                
                imgidxT = imgidxT + 1;
                
                rectT.annopoints.point = rect.annopoints.point;
                ar = angles(i)/180*pi;
                M = [cos(ar) sin(ar) 0; -sin(ar) cos(ar) 0; 0 0 1];
                
                % transform image
                T = maketform('affine',M');
                imgT = imtransform(img,T,'XYScale',1);
                
                % transform points
                pointsT = transform_points(points,M,size(img(:,:,1)),size(imgT(:,:,1)));
                for pp = 1:nPoints
                    rectT.annopoints.point(pp).x = pointsT(pp,1);
                    rectT.annopoints.point(pp).y = pointsT(pp,2);
                end
                
                % transfer rectangle
                rectT.x1 = pointsT(nPoints+1,1) - (points(nPoints+1,1) - rect.x1);
                rectT.x2 = pointsT(nPoints+1,1) + (points(nPoints+1,1) - rect.x1);
                rectT.y1 = pointsT(nPoints+1,2) - (points(nPoints+1,2) - rect.y1);
                rectT.y2 = pointsT(nPoints+1,2) + (points(nPoints+1,2) - rect.y1);
                
                if (bVis)
                    figure(1); clf;
                    subplot(1,2,1);imagesc(img); axis equal; hold on;
                    plot(points(1:nPoints,1),points(1:nPoints,2),'y+','MarkerSize',5);
                    rectangle('Position',[rect.x1 rect.y1 rect.x2-rect.x1 rect.y2-rect.y1],'edgeColor','g','LineWidth',3);
                    
                    subplot(1,2,2);imagesc(imgT); axis equal; hold on;
                    plot(pointsT(1:nPoints,1),pointsT(1:nPoints,2),'y+','MarkerSize',5);
                    rectangle('Position',[rectT.x1 rectT.y1 rectT.x2-rectT.x1 rectT.y2-rectT.y1],'edgeColor','g','LineWidth',3);
                end
                
                % transfer object position
                if (isfield(rect,'objpos'))
                    rectT.objpos.x = pointsT(nPoints+2,1);
                    rectT.objpos.y = pointsT(nPoints+2,2);
                end
                
                % transform proposals
                det = detAll(imgidx).det;
                det(isnan(sum(det,2)),:) = [];
                detT = det;
                bboxC = [mean(det(:,[1 3]),2) mean(det(:,[2 4]),2)];
                bboxCT = transform_points(bboxC,M,size(img(:,:,1)),size(imgT(:,:,1)));

                % transfer proposals
                detT(:,1) = bboxCT(:,1) - (bboxC(:,1) - det(:,1));
                detT(:,3) = bboxCT(:,1) + (bboxC(:,1) - det(:,1));
                detT(:,2) = bboxCT(:,2) - (bboxC(:,2) - det(:,2));
                detT(:,4) = bboxCT(:,2) + (bboxC(:,2) - det(:,2));
                detAllT(imgidxT).det = detT;
                
                detAllT(imgidxT).imgname = detAll(imgidx).imgname;
                
                if (bVis)
                    subplot(1,2,1);
                    for d = 1:10
                        rectangle('Position',[det(d,1) det(d,2) det(d,3)-det(d,1) det(d,4)-det(d,2)],'edgeColor','r','LineWidth',3);
                    end
                    subplot(1,2,2);
                    for d = 1:10
                        rectangle('Position',[detT(d,1) detT(d,2) detT(d,3)-detT(d,1) detT(d,4)-detT(d,2)],'edgeColor','r','LineWidth',3);
                    end
                end
                
                annolistT(imgidxT) = annolist(imgidx);
                annolistT(imgidxT).annorect = rectT;
                
                annolistT(imgidxT).image.name = [saveTo n '_rotidx_' num2str(i) '.png'];
                imwrite(imgT,annolistT(imgidxT).image.name);
            end
            imgidxT = imgidxT + 1;
        end
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist));
    end
end
fprintf(' done\n');


% fprintf('save %s\n',annolistNameT);
% annolist = annolistT;
% save(annolistNameT, 'annolist');
% saveannotations(annolist,[annolistNameT '.al']);
% 
% detAll = detAllT;
% fprintf('save %s\n',detNameT);
% save(detNameT,'detAll');
fprintf('Done\n');
end