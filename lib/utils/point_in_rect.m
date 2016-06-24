function [ res ] = point_in_rect( pt, rect )
% Tests if the point pt is within rectangle rect
%  rect is [left_x top_y right_x bottom_y]

res = (pt(:,1) >= rect(1)) & (pt(:,2) >= rect(2)) & (pt(:,1) <= rect(3)) & (pt(:,2) <= rect(4));

end

