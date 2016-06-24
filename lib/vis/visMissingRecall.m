function visMissingRecall(first_idxs,annolist_gt,jidx,saveTo)

if (~exist(saveTo,'dir'))
    mkdir(saveTo);
end

for j = 1:length(first_idxs)
    figure(101); clf;
    img = imread(annolist_gt(j).image.name);
    imagesc(img); axis equal; hold on;
    rects = annolist_gt(j).annorect(first_idxs{j});
    
    points = [];
    for ridx = 1:length(rects)
        point = util_get_annopoint_by_id(rects(ridx).annopoints.point,jidx);
        points = [points; [point.x point.y]];
%         if (isfield(rects(ridx), 'annopoints') && ~isempty(rects(ridx).annopoints) && ...
%             isfield(rects(ridx).annopoints, 'point') && ~isempty(rects(ridx).annopoints.point))
%             point = util_get_annopoint_by_id(rects(ridx).annopoints.point,jidx);
%             if (~isempty(point))
%                 points = [points; [point.x point.y]];
%             end
%         end
    end
    plot(points(:,1),points(:,2),'ro','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',5);
%     lname = sprintf('detection, score: %1.2f, dist: %1.2f\n',first_scores(j),first_dist(j));
%     legend({lname,'GT'},'fontSize',12);
    axis off;
%     fprintf('imgidx: %d\n',first_idxs(j));
    print(gcf, '-dpng', [saveTo '/imgidx_' padZeros(num2str(j),5) '.png']);
end

end