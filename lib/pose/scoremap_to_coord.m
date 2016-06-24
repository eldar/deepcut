function [ pos ] = scoremap_to_coord( p, locations, crop, locref )

if nargin < 4
    locref = [];
end

scale_factor = p.scale_factor;
stride = p.stride;
half_stride = stride/2;
locref_scale = p.locref_scale;

crd = (locations-1)*stride;
if p.res_net
    crd = crd + half_stride;
end
if ~isempty(locref)
    crd = crd + squeeze(locref)*locref_scale;
end
pos = bsxfun(@plus, crd/scale_factor, double(crop(1:2)-1));

end

