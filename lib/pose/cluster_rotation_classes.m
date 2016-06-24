function C = cluster_rotation_classes(vecs, k, vis)

styles = get_vis_styles();

[idx, C]= kmeans(vecs,k);

if vis
    figure(1);
    hold on;

    % do PCA to display stuff
    if size(vecs, 2) > 2
        [coeff,score,latent,tsquared,explained,mu] = pca(vecs);
        explained
        vecs = score;
    end

    for i = 1:k
        iset = (idx == i);
        if size(vecs, 2) > 2
            scatter3(vecs(iset, 1), vecs(iset, 2), vecs(iset, 3));
        else
            scatter(vecs(iset, 1), vecs(iset, 2), styles{i});
        end
    end
end