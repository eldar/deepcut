function [ rect, rect_orig ] = get_detection_crop( p, annorect, im_size, scmap_size)

if (nargin < 4)
    scmap_size = [];
end

do_crop = isfield(p, 'detcrop') && ~isempty(p.detcrop);
rect_orig = zeros(1, 4, 'int32');
rect = [];

if do_crop
    objpos = annorect.objpos;
    detcrop = p.detcrop;

    objpos = int32([objpos.x objpos.y]);
    rect_orig(1) = objpos(1) + detcrop(1); %left
    rect_orig(2) = objpos(2) + detcrop(2); %top
    rect_orig(3) = objpos(1) + detcrop(3); %right
    rect_orig(4) = objpos(2) + detcrop(4); %bottom

    rect_copy = double(rect_orig);
    
    rect_orig(1) = max(1, rect_orig(1));
    rect_orig(2) = max(1, rect_orig(2));
    rect_orig(3) = min(im_size(2), rect_orig(3));
    rect_orig(4) = min(im_size(1), rect_orig(4));

    if ~isempty(scmap_size)
        rect = int32(round(rect_copy*p.scale_factor/p.stride)+1);

        rect(1) = max(1, rect(1));
        rect(2) = max(1, rect(2));
        rect(3) = min(scmap_size(2), rect(3));
        rect(4) = min(scmap_size(1), rect(4));
    end
else
    rect_orig(1) = 1;
    rect_orig(2) = 1;
    rect_orig(3) = im_size(2);
    rect_orig(4) = im_size(1);
    
    if ~isempty(scmap_size)
        rect = zeros(1, 4, 'int32');
        rect(1:2) = 1;
        rect(3:4) = scmap_size([2, 1]);
    end
end

end
