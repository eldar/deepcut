function [tp_annolist, fp_annolist, tp_score, fp_score] = matchGT_RP(det_annolist, gt_annolist, bMatchCompidx)

fprintf('matchGT()\n');
thresh_gt = 0.5;
fp_score = [];
tp_score = [];

if (nargin < 3)
    bMatchCompidx = false;
end

for imgidx = 1:length(det_annolist)
    fprintf('.');
%     fprintf('imgidx: %d\n', imgidx);
    
    tp_anno = det_annolist(imgidx);
    tp_anno = rmfield(tp_anno, 'annorect');
    
    fp_anno = det_annolist(imgidx);
    fp_anno = rmfield(fp_anno, 'annorect');
        
    max_score = -10000;
    
    for ridx = 1:length(det_annolist(imgidx).annorect)
        
        match_gt = 0;
                
        for ridx1 = 1:length(gt_annolist(imgidx).annorect)
            is_matching_bbox = is_matching(det_annolist(imgidx).annorect(ridx), gt_annolist(imgidx).annorect(ridx1), thresh_gt);
            
            if (bMatchCompidx)
                compidx_det = det_annolist(imgidx).annorect(ridx).silhouette.id;
                compidx_gt = gt_annolist(imgidx).annorect(ridx1).silhouette.id;
                is_matching_total = is_matching_bbox*(compidx_det == compidx_gt);
            else
                is_matching_total = is_matching_bbox;
            end
            
            if is_matching_total
                match_gt = 1;
                break;
            end
        end
         
        % assume that the detections are sorted by score
        if match_gt == 1
            score = det_annolist(imgidx).annorect(ridx).score;
            if (max_score < score)
                assert(~isfield(tp_anno, 'annorect'))
                max_score = score;
                tp_anno.annorect = det_annolist(imgidx).annorect(ridx);
                tp_score = [tp_score; score];
            else
                if ~isfield(fp_anno, 'annorect')
                    fp_anno.annorect = det_annolist(imgidx).annorect(ridx);
                else
                    fp_anno.annorect(end+1) = det_annolist(imgidx).annorect(ridx);
                end
                fp_score = [fp_score; score];
            end
        else
            if ~isfield(fp_anno, 'annorect')
                fp_anno.annorect = det_annolist(imgidx).annorect(ridx);
            else
                fp_anno.annorect(end+1) = det_annolist(imgidx).annorect(ridx);
            end
            fp_score = [fp_score; det_annolist(imgidx).annorect(ridx).score];
        end
        
    end % rectangles
        
    if ~isfield(tp_anno, 'annorect')
        tp_anno.annorect = [];
    end
    
    if ~isfield(fp_anno, 'annorect')
        fp_anno.annorect = [];
    end
    
    fp_annolist(imgidx) = fp_anno;
    tp_annolist(imgidx) = tp_anno;

    bVis = false;
    
    if bVis
        clf;
        img = imread(tp_anno.image.name);
        imagesc(img); axis equal;
        hold on;
        
        drawRect(gt_annolist(imgidx).annorect, 'b');
        
        tp_det = tp_anno.annorect;
        fp_det = fp_anno.annorect;
        
        if ~isempty(tp_det)
            for ridx = 1:length(fp_det)
                if (fp_det(ridx).score > tp_det.score)
                    drawRect(fp_det(ridx), 'r');
                end
            end
            drawRect(tp_det, 'g');
        else
            for ridx = 1:length(fp_det)
                drawRect(fp_det(ridx), 'r');
            end
        end
        
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(det_annolist));
    end
end

fprintf(' done\n');

    function res = is_matching(annorect1, annorect2, thresh)
        
        w1 = abs(annorect1.x2 - annorect1.x1);
        h1 = abs(annorect1.y2 - annorect1.y1);
        
        w2 = abs(annorect2.x2 - annorect2.x1);
        h2 = abs(annorect2.y2 - annorect2.y1);
        
        int_area = rectint([annorect1.x1, annorect1.y1, w1, h1], [annorect2.x1, annorect2.y1, w2, h2]);
        
        union_area = w1*h1 + w2*h2 - int_area;
       
        if int_area / union_area >= thresh
            res = 1;
        else
            res = 0;
        end

    end

    function drawRect(rect, c)
        
        rectangle('Position',[rect.x1 rect.y1 rect.x2-rect.x1 rect.y2-rect.y1], ...
            'EdgeColor', c, 'LineWidth', 2);
        
        s = sprintf('%1.2f',rect.score);
        text(rect.x1,rect.y1,s,'color','k','backgroundcolor',c,...
            'verticalalignment','top','horizontalalignment','left','fontsize',8);
    end


end
