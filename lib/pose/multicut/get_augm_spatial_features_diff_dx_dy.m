function featAugm = get_augm_spatial_features_diff_neighbour(feat, featMean, p)

dx = feat(:,1) - featMean(:,1);
dy = feat(:,2) - featMean(:,2);
dist = sqrt(dx.^2 + dy.^2);
dxdy = dx.*dy;
abs_dx = abs(dx);
abs_dy = abs(dy);
a = feat(:,3) - featMean(:,3);
abs_a = abs(a);
featAugm = cat(2, dx, dy, dxdy, dx.^2, dy.^2, dxdy.^2, a, a.^2, abs_a, exp(-abs_a), dist, dist.^2, exp(-dist));
%featAugm = cat(2, dx, dy, dxdy, dx.^2, dy.^2, a, a.^2, abs_a, dist, dist.^2);
%featAugm = cat(2, a, abs_a, dx, dy, dist);

if ~(isfield(p,'geom_only') && p.geom_only)
    featAugm = cat(2, featAugm, feat(:,4:end));
end

end
