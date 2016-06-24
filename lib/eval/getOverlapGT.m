function [dist,score,points] = getOverlapGT(bboxAll,annolist_gt,jidx,scale)

dist = cell(length(annolist_gt),1);
score = cell(length(annolist_gt),1);
points = cell(length(annolist_gt),1);

for imgidx = 1:length(annolist_gt)
    assert(strcmp(bboxAll(imgidx).imgname,annolist_gt(imgidx).image.name) > 0);
    dist{imgidx} = inf(length(bboxAll(imgidx).det{jidx+1,1}),length(annolist_gt(imgidx).annorect));
end

for imgidx = 1:length(annolist_gt)
    for ridx = 1:length(annolist_gt(imgidx).annorect)
        rect = annolist_gt(imgidx).annorect(ridx);
        minPartSize = 30*scale*rect.scale;
        det = bboxAll(imgidx).det{jidx+1,1};
        score{imgidx} = det(:,5);
        points{imgidx} = [mean(det(:,[1 3]),2) mean(det(:,[2 4]),2)];
        if (isfield(rect, 'annopoints') && isfield(rect.annopoints, 'point'))
            p = util_get_annopoint_by_id(rect.annopoints.point, jidx);
            if (~isempty(p))
                rectNew = rcnn_compute_bbox(rect,[jidx jidx],minPartSize,inf,inf,-inf,-inf);
                dist{imgidx}(:,ridx) = 1 - boxoverlap(det(:,1:4), [rectNew.x1 rectNew.y1 rectNew.x2 rectNew.y2]);
%                 idxs = find(dist{imgidx}(:,ridx) <= 0.5);
%                 if (~isempty(idxs))
%                     figure(1); clf; imagesc(imread(annolist_gt(imgidx).image.name)); axis equal;hold on;
%                     rectangle('Pos',[rectNew.x1 rectNew.y1 rectNew.x2 - rectNew.x1 rectNew.y2 - rectNew.y1],'edgeColor','y','lineWidth',2);
%                     plot((rectNew.x1+rectNew.x2)/2,(rectNew.y1+rectNew.y2)/2,'yo','markerSize',5,'MarkerFaceColor','y','MarkerEdgeColor','k');
%                     for idx = idxs'
%                         rectangle('Pos',[det(idx,1) det(idx,2) det(idx,3)-det(idx,1) det(idx,4)-det(idx,2)],'edgeColor','r','lineWidth',2);
%                         plot((det(idx,1)+det(idx,3))/2,(det(idx,2)+det(idx,4))/2,'ro','markerSize',5,'MarkerFaceColor','r','MarkerEdgeColor','k');
%                     end
%                     print(gcf, '-dpng', ['/BS/leonid-projects/work/experiments-rcnn/parts14-joint-train-19000-rwrist-test-correct-gt-scale4-140k-step-80k-lr-0002-pad-pad-500-test-multi-person-20000-nms-09/cachedir/test/vis' '/imgidx_' padZeros(num2str(imgidx),5) '_ridx_' num2str(ridx) '.png']);
%                     dist{imgidx}(idxs,ridx)
%                     fprintf('%d\n',length(idxs));
%                 end
            end
        end
    end
end

end