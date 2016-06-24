function featAugm = get_augm_spatial_features_diff_neighbour_locref(feat)

% relative coord of 2 detections
delta = feat(:, 1:2);
a = compute_angle(delta(:,1), delta(:,2));

delta_forward = feat(:, 5:6);
a_forward = compute_angle(delta_forward(:,1), delta_forward(:,2));

delta1 = delta - delta_forward;
dist1 = sqrt(delta1(:,1).^2 + delta1(:,2).^2);
a1 = wrap_angle(a - a_forward);
abs_a1 = abs(a1);
%abs_a1(:) = 0;

% now the same for backward
delta = feat(:, 3:4);
a = compute_angle(-delta(:,1), -delta(:,2));

delta_backward = feat(:, 7:8);
a_backward = compute_angle(delta_backward(:,1), delta_backward(:,2));

delta2 = delta - delta_backward;
dist2 = sqrt(delta2(:,1).^2 + delta2(:,2).^2);
a2 = wrap_angle(a - a_backward);
abs_a2 = abs(a2);

%featAugm = cat(2, dist, exp(-dist), dx, dy, abs(dx), abs(dy), dxdy, dx.^2, dy.^2, abs_a, a.^2, exp(-abs_a));

featAugm = cat(2, dist1, abs_a1, dist2, abs_a2);
featAugm = cat(2, featAugm, exp(-featAugm));

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