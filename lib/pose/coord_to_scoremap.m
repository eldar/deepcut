function [ loc ] = coord_to_scoremap( p, locations, crop )

scale_factor = p.scale_factor;
stride = p.stride;
half_stride = stride/2;

loc = bsxfun(@minus, locations, double(crop(1:2) - 1));
loc = loc*scale_factor;
if p.res_net
    loc = loc - half_stride;
end
loc = loc / stride;
loc = loc + 1;
loc = round(loc);

end

