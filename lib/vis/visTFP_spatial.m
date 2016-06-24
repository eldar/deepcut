function visTFP_spatial(first_idxs,first_points,first_dist,first_scores,annolist_gt,rectidxs_gt,xaxis,saveTo)

if (~exist(saveTo,'dir'))
    mkdir(saveTo);
end

for j = 1:length(first_idxs)
    clf;
    img = imread(annolist_gt(first_idxs(j)).image.name);
    imagesc(img); axis equal; hold on;
%     plot([first_points(j,1); first_points(j,3)],[first_points(j,2);first_points(j,4)],'ro','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',5);
    plot([first_points(j,1); first_points(j,3)],[first_points(j,2);first_points(j,4)],'r-','lineWidth',3);
    rects = annolist_gt(first_idxs(j)).annorect;
    
    pointsGTeval = [];
    pointsGTrest = [];
    for ridx = 1:length(rects)
        if (isfield(rects(ridx), 'annopoints') && ~isempty(rects(ridx).annopoints) && ...
            isfield(rects(ridx).annopoints, 'point') && ~isempty(rects(ridx).annopoints.point))
            p1 = util_get_annopoint_by_id(rects(ridx).annopoints.point,xaxis(2));
            p2 = util_get_annopoint_by_id(rects(ridx).annopoints.point,xaxis(1));
            if (~isempty(p1) && ~isempty(p2))
                if (ismember(ridx,rectidxs_gt{first_idxs(j)}))
                    pointsGTeval = [pointsGTeval; [p1.x p1.y p2.x p2.y]];
                else
                    pointsGTrest = [pointsGTrest; [p1.x p1.y p2.x p2.y]];
                end
            end
        end
    end
    lname = sprintf('detection, score: %1.2f, dist: (%1.2f,%1.2f)\n',first_scores(j),first_dist(j,1),first_dist(j,2));
%     plot([pointsGTeval(:,1);pointsGTeval(:,3)], [pointsGTeval(:,2); pointsGTeval(:,4)],'ro','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',5);
    for i = 1:size(pointsGTeval,1)
         plot([pointsGTeval(i,1); pointsGTeval(i,3)],[pointsGTeval(i,2);pointsGTeval(i,4)],'y-','lineWidth',3);
    end
    if (~isempty(pointsGTrest))
%         plot([pointsGTrest(:,1); pointsGTrest(:,3)],[pointsGTrest(:,2);pointsGTrest(:,4)],'ro','MarkerFaceColor','g','MarkerEdgeColor','k','MarkerSize',5);
        for i = 1:size(pointsGTrest,1)
            plot([pointsGTrest(i,1); pointsGTrest(i,3)],[pointsGTrest(i,2);pointsGTrest(i,4)],'g-','lineWidth',3);
        end
%         legend({lname,'GT eval','GT rest'},'fontSize',12);
        legend({lname,'GT eval'},'fontSize',12);
    else
        legend({lname,'GT eval'},'fontSize',12);
    end
    axis off;
%     fprintf('imgidx: %d\n',first_idxs(j));
    print(gcf, '-dpng', [saveTo '/imgidx_' padZeros(num2str(j),5) '.png']);
end

end