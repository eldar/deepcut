function [idx, C ] = spectralclustering( input_data, num_cluster )
%D = compute_pairwise_distance( input_data, input_data );
D = squareform(pdist(input_data));

v = 1;
W = exp(-D/v);
D = diag(sum(W));
L = D - W;
[U, V] = eig(L);
[~, I] = sort(diag(V));
[idx, C] = kmeans(U(:, I(1:num_cluster)), num_cluster);
end