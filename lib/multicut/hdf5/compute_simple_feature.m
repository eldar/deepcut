function feature = compute_simple_feature(det,frame_rate_norm)
% compute spatial-temporal feature between two detections 
% needs to be normalized by frame rate
det1 = det(1,:);
det2 = det(2,:);

[h1,xCenter1,yCenter1, t1] = get_detail(det1);
[h2,xCenter2,yCenter2, t2] = get_detail(det2);
h_cmp = (h1+h2)/2;

offset_t = abs(t2-t1)*frame_rate_norm; % t'-t
x1 = abs((xCenter2 - xCenter1)./h_cmp); %(x' - x)/ave_h
y1 = abs((yCenter2 - yCenter1)./h_cmp); %(y' - y)/ave_h
offset_h = abs((h2-h1)./h_cmp); %(h' - h)/ave_h

if offset_t==0 % same frame
    x1_norm = 0;
    y1_norm = 0;
    offset_h_norm = 0;
else
    x1_norm = x1/offset_t;
    y1_norm = y1/offset_t;
    offset_h_norm = offset_h/offset_t;
end
feature_linear = [offset_t;x1;y1;offset_h;x1_norm;y1_norm;offset_h_norm];
% feature_quadratic = feature_linear.^2;
% feature_exponential = exp(-feature_linear);
% feature = [feature_linear;feature_quadratic;feature_exponential];
feature = feature_linear;
end

function [h,xCenter,yCenter, frameIdx] = get_detail(det)
h = det(4) - det(2);
xCenter = (det(1) + det(3))/2;
yCenter = (det(2) + det(4))/2;
frameIdx = det(7);
end