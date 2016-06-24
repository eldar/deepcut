function [ unary_maps, locreg_pred, nextreg_pred, rpn_prob, rpn_bbox ] = extract_features( im, net, p, annorect, pad_orig, pairwise, crop )

sigmoid = true;
mean_pixel = p.mean_pixel;
stride = p.stride;
nextreg = p.nextreg;
pad_size = 64;
scale_factor = p.scale_factor;

if nargin < 7
    crop = get_detection_crop_2( p, annorect, size(im), pad_orig);
end

crop_left = crop(1);
crop_top = crop(2);
crop_right = crop(3);
crop_bottom = crop(4);

im = im(crop_top:crop_bottom, crop_left:crop_right, :);

im_bg_width = ceil(size(im, 2)*scale_factor/stride)*stride;
im_bg_height = ceil(size(im, 1)*scale_factor/stride)*stride;

im_bot_pixels = im(end, :, :);
im_bot = repmat(im_bot_pixels, pad_size, 1, 1);
im = [im; im_bot];
im_right_pixels = im(:,end, :);
im_right = repmat(im_right_pixels, 1, pad_size, 1);
im = [im, im_right];

% permute to BGR for Caffe and to use single precision
im = single(im(:,:,[3 2 1]));

if scale_factor ~= 1
    im = imresize(im, scale_factor, 'bilinear', 'antialiasing', false);
end

im_width = size(im, 2);
im_height = size(im, 1);

% subtract mean pixel
im = bsxfun(@minus, im, reshape(mean_pixel, [1 1 3]));
% create image background
input = zeros(im_bg_height, im_bg_width, 3, 'single');
input(1:min(im_height, im_bg_height), 1:min(im_width, im_bg_width), :) = ...
     im(1:min(im_height, im_bg_height),1:min(im_width, im_bg_width),:);

%[feat_prob, locreg_pred, nextreg_pred] = cnn_process_image_tiled(input, net, sigmoid, im_bg_width, im_bg_height, stride);
[unary_maps, locreg_pred, nextreg_pred, rpn_prob, rpn_bbox] = cnn_process_image(input, net, sigmoid);
if nextreg
    nextreg_pred = bsxfun(@plus, pairwise.means, bsxfun(@times, nextreg_pred, pairwise.std_devs));
end

end

