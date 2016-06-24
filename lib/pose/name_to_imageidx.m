function [ i ] = name_to_imageidx( expidx, name )

p = exp_params(expidx);
load(p.testGT)
num_images = size(annolist, 2);

for i = 1:num_images
    im_fn = annolist(i).image.name;
    if ~isempty(strfind(im_fn, name))
        return
    end
end

end

