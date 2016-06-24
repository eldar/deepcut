function featAugm = get_augm_spatial_features_same_regr(feat)

% relative coord of 2 detections
deltaX = feat(:, 1);
deltaY = feat(:, 2);

dist_sq = deltaX.^2 +deltaY.^2;
dist = sqrt(dist_sq);

featAugm = cat(2, dist, dist_sq);
end

function angle = compute_angle(deltaX, deltaY)
angle = atan2(deltaY,deltaX);
angle = wrapMinusPiPifast(angle);
assert(all(angle <= pi) && all(angle >= -pi));
end

function a = wrap_angle(a)
larger = a > pi;
smaller = a < -pi;
a(larger)  = a(larger) - 2*pi;
a(smaller) = a(smaller)+ 2*pi;
end