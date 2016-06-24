function visTFP(first_idxs,first_points,first_dist,first_scores,annolist_gt,rectidxs_gt,jidx,saveTo)

if (~exist(saveTo,'dir'))
    mkdir(saveTo);
end

for j = 1:length(first_idxs)
    figure(101); clf;
    img = imread(annolist_gt(first_idxs(j)).image.name);
    imagesc(img); axis equal; hold on;
    plot(first_points(j,1),first_points(j,2),'ro','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',5);
    rects = annolist_gt(first_idxs(j)).annorect;
    
    pointsGTeval = [];
    pointsGTrest = [];
    for ridx = 1:length(rects)
        if (isfield(rects(ridx), 'annopoints') && ~isempty(rects(ridx).annopoints) && ...
            isfield(rects(ridx).annopoints, 'point') && ~isempty(rects(ridx).annopoints.point))
            point = util_get_annopoint_by_id(rects(ridx).annopoints.point,jidx);
            if (~isempty(point))
                if (ismember(ridx,rectidxs_gt{first_idxs(j)}))
                    pointsGTeval = [pointsGTeval; [point.x point.y]];
                else
                    pointsGTrest = [pointsGTrest; [point.x point.y]];
                end
            end
        end
    end
    lname = sprintf('detection, score: %1.2f, dist: %1.2f\n',first_scores(j),first_dist(j));
    plot(pointsGTeval(:,1),pointsGTeval(:,2),'ro','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',5);
    if (~isempty(pointsGTrest))
        plot(pointsGTrest(:,1),pointsGTrest(:,2),'ro','MarkerFaceColor','g','MarkerEdgeColor','k','MarkerSize',5);
        legend({lname,'GT eval','GT rest'},'fontSize',12);
    else
        legend({lname,'GT eval'},'fontSize',12);
    end
    axis off;
%     fprintf('imgidx: %d\n',first_idxs(j));
    print(gcf, '-dpng', [saveTo '/imgidx_' padZeros(num2str(j),5) '.png']);
end

end