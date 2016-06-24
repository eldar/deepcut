function [ output_args ] = rcnn_assign_soft_cluster_score(expidx)

p = rcnn_exp_params(expidx);

fn = [p.expDir '/' p.shortName '/imdb/cache/clusters.mat'];
load(fn);

joint_no = 13;

vecs_j = vecs{joint_no};
vecs_j = vecs_j(:, 1:end-1);

C = clusters{joint_no};
k = size(C, 1);
num_all = size(vecs_j, 1);

%[idx, C] = spectralclustering(vecs_j, k);
%load('~/spectral_clustering', 'C', 'idx');

idx = zeros(num_all, 1);
for j = 1:num_all
    vec = vecs_j(j, :);
    diff = bsxfun(@minus, C, vec);
    [~, min_dist] = min(sum(diff.^2, 2));
    idx(j) = min_dist;
end


%assign soft scores
D = pdist(C);
min_dist = min(D);
sigma = min_dist/1.5;

figure(1);
hold on;

is_3d = size(vecs_j, 2) > 2;

% do PCA to display stuff
if is_3d
    [coeff,score,latent,tsquared,explained,mu] = pca(vecs_j);
    vecs_j = score;
end

for i = 1:k
    iset = (idx == i);
    if is_3d
        scatter3(vecs_j(iset, 1), vecs_j(iset, 2), vecs_j(iset, 3), 5, 'filled');
    else
        scatter(vecs_j(iset, 1), vecs_j(iset, 2), 5, 'filled');
    end
end

for i = 1:num_all
    idx = unidrnd(num_all);
    vec = vecs_j(idx, :);
    dists = pdist2(C,vec);
    scores = exp(-dists.^2/(sigma^2));
    scores = scores/sum(scores);
    if is_3d
        scatter3(vec(1), vec(2), vec(3), 20, [0 0 0], 'filled');
    else
        scatter(vec(1), vec(2), 20, [0 0 0], 'filled');
    end
    find(scores' > 0.1)
    pause;
end

end

