function vis_combined_scoremap(expidx, img_idx, ends)

p = exp_params(expidx);
load(p.testGT)

im_fn = annolist(img_idx).image.name;
[~,im_name,~] = fileparts(im_fn);
im = imread(im_fn);

scmap_name = fullfile(p.unary_scoremap_dir, [im_name '.mat']);
load(scmap_name, 'scoremaps');

colors = [1 0 1; 1 1 0; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1];

pw_map_img = im;
un_map_img = im;

for end_ = ends

    if true
        scmap = [];

        for start = 1:14
            if start ~= end_
                current = visualise_pairwise_probabilities(expidx, img_idx, 1, start, end_, false);
                if isempty(current)
                    continue;
                end
                if isempty(scmap)
                    scmap = current;
                else
                    scmap = scmap .* current;
                end
            end
        end
        %save('~/pw_scmap.mat', 'scmap');
    else
        %load('~/pw_scmap.mat', 'scmap');
    end


    %figure(1);
    %imagesc(scmap);
    %colorbar;

    scmap_rescaled = scmap/max(scmap(:));
    pw_map_img = vis_scoremap_on_img(pw_map_img, scmap_rescaled, colors(end_,:));

    unary_map = scoremaps(:, :, end_);
    un_map_img = vis_scoremap_on_img(un_map_img, unary_map, colors(end_,:));
end

out_dir = '/tmp/';

figure(1);
fname = fullfile(out_dir, [num2str(img_idx) '_cidxs_all.png']);
showsaveimg(pw_map_img, fname);

figure(2);
fname = fullfile(out_dir, [num2str(img_idx) '_unary.png']);
showsaveimg(un_map_img, fname);

end

function showsaveimg(im, fname)
imshow(im);
axis off;
set(gca, 'LooseInset', get(gca, 'TightInset'));
print(gcf,'-dpng', fname);
end



function final_img = vis_scoremap_on_img(im, scoremap, color1)
scoremap_img = imresize(scoremap, [size(im, 1), size(im, 2)], 'bicubic');

c = reshape(color1, 1, 1, 3);
color_rep = repmat(c, size(im, 1), size(im, 2), 1);
color_rep = color_rep*255;

scoremap_img = repmat(scoremap_img, 1, 1, 3);
%figure(4);
%imagesc(pw_prob_img);

final_img = (scoremap_img) .* double(color_rep) + (1-scoremap_img) .* double(im);
final_img = uint8(final_img);

end
