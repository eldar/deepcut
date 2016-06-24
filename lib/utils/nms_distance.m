function pick = nms_distance_IoMin(locations, dist_threshold)
% top = nms(boxes, overlap)
% Non-maximum suppression. (FAST VERSION)
% Greedily select high-scoring detections and skip detections
% that are significantly covered by a previously selected
% detection.
%
% NOTE: This is adapted from Pedro Felzenszwalb's version (nms.m),
% but an inner loop has been eliminated to significantly speed it
% up in the case of a large number of boxes

% Copyright (C) 2011-12 by Tomasz Malisiewicz
% All rights reserved.
% 
% This file is part of the Exemplar-SVM library and is made
% available under the terms of the MIT license (see COPYING file).
% Project homepage: https://github.com/quantombone/exemplarsvm

if isempty(locations)
  pick = [];
  return;
end

x1 = locations(:,1);
y1 = locations(:,2);
s = locations(:,end);

[vals, I] = sort(s);

pick = s*0;
counter = 1;
while ~isempty(I)
  last = length(I);
  i = I(last);
  if s(i) < 1e-3
      break;
  end
  pick(counter) = i;
  counter = counter + 1;
  
  dx = x1(I(1:last-1)) - x1(i);
  dy = y1(I(1:last-1)) - y1(i);
  dist = sqrt(dx.^2 + dy.^2);
 
  I = I(find(dist>dist_threshold));
end

pick = pick(1:(counter-1));
