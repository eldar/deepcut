function [tp_score,fp_score,totalPos,tp_points,fp_points,tp_idxs,fp_idxs,fp_dist,missing_recall] = computeTFPmulticut(dist,score,points,rectidxs_gt,rect_ignore,thresh_gt)

if (nargin < 5)
    rect_ignore = cell(length(dist),1);
end

if (nargin < 6)
    thresh_gt = 0.5;
end

assert(length(rectidxs_gt) == length(dist));

N = sum(cellfun('length',score));
fp_score = nan(N,1);
tp_score = nan(N,1);

fp_points = nan(N,2);
tp_points = nan(N,2);

fp_idxs = nan(N,1);
tp_idxs = nan(N,1);

fp_dist = nan(N,1);
missing_recall = cell(length(dist),1);

last_fpidx = 0;
last_tpidx = 0;
totalPos = 0;
nskipped = 0;

for imgidx = 1:length(dist)
        
%     if (imgidx == 212)
%         fprintf('blabla\n');
%     end
    assert(size(dist{imgidx},1) == size(score{imgidx},1));
    
    [minDist,minIdx] = min(dist{imgidx},[],2);
    match_gt = minDist <= thresh_gt;
    
    tp_img = nan(1,size(dist{imgidx},2));
    tp_score_img = -inf(1,size(dist{imgidx},2));
    
    fp_img = find(match_gt == 0);
    
    % exclude fp on not annotated people
    idxs_ignore = false(length(fp_img),1);
    if (~isempty(rect_ignore{imgidx}))
        for i=1:size(rect_ignore{imgidx},1)
            r = rect_ignore{imgidx}(i,:);
            condX1 = points{imgidx}(fp_img,1) >= repmat(r(1),length(fp_img),1);
            condX2 = points{imgidx}(fp_img,1) <= repmat(r(3),length(fp_img),1);
            condY1 = points{imgidx}(fp_img,2) >= repmat(r(2),length(fp_img),1);
            condY2 = points{imgidx}(fp_img,2) <= repmat(r(4),length(fp_img),1);
            s = condX1 + condX2 + condY1 + condY2;
            idxs_ignore(s == 4) = true;
        end
    end
    fp_img(idxs_ignore) = [];
    
    fp_score_img = score{imgidx}(fp_img);
    
    matchidx = find(match_gt == 1);
    
    nskipped_img = 0;
    for ridx = matchidx'
        
        % ignore tp w.r.t other rectangles
        if (ismember(minIdx(ridx),rectidxs_gt{imgidx}))
        
            if (isinf(tp_score_img(minIdx(ridx))))
                tp_img(minIdx(ridx)) = ridx;
                tp_score_img(minIdx(ridx)) = score{imgidx}(ridx);
            elseif (tp_score_img(minIdx(ridx)) < score{imgidx}(ridx))
                fp_img = [fp_img; tp_img(minIdx(ridx))];
                fp_score_img = [fp_score_img; tp_score_img(minIdx(ridx))];
                tp_img(minIdx(ridx)) = ridx;
                tp_score_img(minIdx(ridx)) = score{imgidx}(ridx);
            else
                fp_img = [fp_img; ridx];
                fp_score_img = [fp_score_img; score{imgidx}(ridx)];
            end
        else
            nskipped_img = nskipped_img + 1;
%             fprintf('not a member!\n');
        end
    end % rectangles
    
    % rectangles with the part which is not present in the image
    idxs_absent = find(sum(isnan(dist{imgidx}),1) == size(dist{imgidx},1));
    
    % relevant rectangles with present body part
    idxs_present = setdiff(rectidxs_gt{imgidx},idxs_absent);
%     idxs_present = rectidxs_gt{imgidx};
    totalPos = totalPos + length(idxs_present);
    
    idxs = find(isinf(tp_score_img));
    tp_score_img(idxs) = [];
    tp_img(idxs) = [];
    
    % relevant not found rectangles
    missing_recall{imgidx} = intersect(idxs,idxs_present);
    
    assert(length(tp_img) + length(fp_img) + nskipped_img + sum(idxs_ignore) == length(match_gt));
    
    idxsNaN = find(isnan(fp_score_img));
    if (~isempty(idxsNaN))
        fp_img(idxsNaN) = [];
        fp_score_img(idxsNaN) = [];
    end
    tp_score(last_tpidx+1:last_tpidx+length(tp_img)) = tp_score_img;
    fp_score(last_fpidx+1:last_fpidx+length(fp_img)) = fp_score_img;
    tp_points(last_tpidx+1:last_tpidx+length(tp_img),:) = points{imgidx}(tp_img,:);
    fp_points(last_fpidx+1:last_fpidx+length(fp_img),:) = points{imgidx}(fp_img,:);
    tp_idxs(last_tpidx+1:last_tpidx+length(tp_img)) = imgidx;
    fp_idxs(last_fpidx+1:last_fpidx+length(fp_img)) = imgidx;
    fp_dist(last_fpidx+1:last_fpidx+length(fp_img)) = minDist(fp_img);
    
    last_tpidx = last_tpidx+length(tp_img);
    last_fpidx = last_fpidx+length(fp_img);
    
    nskipped = nskipped + nskipped_img;
end

idxs = find(isnan(tp_score));
tp_score(idxs) = [];
tp_points(idxs,:) = [];
tp_idxs(idxs) = [];

idxs = find(isnan(fp_score));
fp_score(idxs) = [];
fp_points(idxs,:) = [];
fp_idxs(idxs) = [];
fp_dist(idxs) = [];

% assert(length(tp_score) + length(fp_score) + nskipped == N);

end
