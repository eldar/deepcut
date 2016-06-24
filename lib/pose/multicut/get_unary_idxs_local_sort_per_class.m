function idxs = get_unary_idxs_local_sort_per_class(unProb,nDetClass)
            
idxs = [];
for j = 1:size(unProb,2)
    scores = unProb(:,j);
    [val,idx] = sort(scores,'descend');
    idxs = union(idxs,idx(1:min(nDetClass, length(idx))));
end

end