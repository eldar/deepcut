function [ crop ] = get_detection_crop_2( p, annorect, im_size, pad_orig)

if p.detcrop_image
    [~, rect_orig] = get_detection_crop( p, annorect, im_size);
    crop_left = rect_orig(1);
    crop_top = rect_orig(2);
    crop_right = rect_orig(3);
    crop_bottom = rect_orig(4);
else
    crop_left = pad_orig+1;
    crop_top = pad_orig+1;
    crop_right = im_size(2) - pad_orig;
    crop_bottom = im_size(1) - pad_orig;
end

crop = [crop_left crop_top crop_right crop_bottom];

end

