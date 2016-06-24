function cnn_compute_image_sizes( expidx, image_set )

p = exp_params(expidx);

% load annolist
if strcmp(image_set, 'test')
    load(p.testGT)
else
    load(p.trainGT)
end

num_images = length(annolist);

sizes = zeros(num_images, 2);
for i = 1:num_images
    tic_toc_print('imdb: %d/%d\n', i, num_images);
    info = imfinfo(annolist(i).image.name);
    sizes(i, :) = [info.Height info.Width];
end

max(sizes, [], 1)

data_dir = fullfile(p.expDir, p.shortName, 'data');
mkdir_if_missing(data_dir);
save(fullfile(data_dir, ['sizes_' image_set]), 'sizes');

end

