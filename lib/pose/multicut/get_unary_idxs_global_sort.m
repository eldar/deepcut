function idxs = get_unary_idxs_global_sort(unProb,max_detections)
            
unProbThresh = unProb;
scores = sort(reshape(unProb, size(unProb,1)*size(unProb,2),1));
j = 1;
while (length(find(sum(unProbThresh,2) > 0)) > max_detections && j <= length(scores))
    unProbThresh = unProb;
    for m = 1:size(unProb,2)
        unProbThresh(unProb(:,m) < scores(j),m) = 0;
    end
    j = j + 1;
end
            
min_det_score_found = scores(j);
fprintf('found min_det_score: %1.2f\n',min_det_score_found);

idxs = find(sum(unProbThresh,2) > 0);
end