function vis_gt(annolist,detDir,scale)

if (nargin < 3)
    scale = 1;
end

visDir = [detDir '/vis'];
if (~exist(visDir,'dir'))
    mkdir(visDir);
end

figure(100);
for imgidx = 1:length(annolist)
    clf;
    img = imread(annolist(imgidx).image.name);
    [Y,X] = size(img);
    imagesc(img);axis equal;hold on;
    labels = cell(length(annolist(imgidx).annorect),1);
    points = nan(length(annolist(imgidx).annorect),4);
    for ridx = 1:length(annolist(imgidx).annorect)
        rect = annolist(imgidx).annorect(ridx);
        vis_bbox([rect.x1 rect.y1 rect.x2 rect.y2],'g');
        labels{ridx} = rect.silhouette.id;
        bbox = [rect.x1 rect.y1 rect.x2 rect.y2];
        if (scale ~= 1)
            bbox = rcnn_scale_bbox(bbox,scale,X,Y);
        end
        points(ridx,:) = [rect.x1 rect.y1 (rect.x1 + rect.x2)/2 (rect.y1 + rect.y2)/2];
    end
    plot(points(:,3),points(:,4),'yo','MarkerSize',6,'MarkerFaceColor','y');
    text(points(:,1),points(:,2),labels,'FontSize',10,'color','k','BackgroundColor','g',...
        'verticalalignment','top','horizontalalignment','left');
    [~,name] = fileparts(annolist(imgidx).image.name);
    axis off;
    print(gcf,'-dpng',[visDir '/' name '_gt.png']);
end
close(100);

end