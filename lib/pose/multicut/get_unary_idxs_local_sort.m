function idxs = get_unary_idxs_local_sort(unProb,max_detections)
            
nDetClass = ceil(max_detections/size(unProb,2));

idxs = [];
for j = 1:size(unProb,2)
    scores = unProb(:,j);
    [val,idx] = sort(scores,'descend');
    idxs = union(idxs,idx(1:nDetClass));
end
end