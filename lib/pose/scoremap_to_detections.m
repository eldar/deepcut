function [ locations ] = scoremap_to_detections( sm )

height = size(sm, 1);
width  = size(sm, 2);

locations = zeros(height*width, 3);

for j = 1:height
    for i = 1:width
        locations(sub2ind(size(sm), j, i), :) = [i j sm(j,i)];
    end
end

end

