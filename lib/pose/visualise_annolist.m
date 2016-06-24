function visualise_annolist( expidx, image_set, firstidx )

if (nargin < 3)
    firstidx = 1;
end

p = exp_params(expidx);

load(p.([image_set 'GT']), 'annolist');

num_images = length(annolist);
parts = get_parts();

for imgidx = firstidx:num_images
    fprintf('img %d/%d\n', imgidx, num_images);
    im = imread(annolist(imgidx).image.name);
    clf;
    imagesc(im); axis equal; hold on;

    annorect = annolist(imgidx).annorect;
    
    for k = 1:length(annorect)
        rect = annorect(k);
        joints = get_anno_joints(rect, p.pidxs, parts);
        figure(1);
        vis_pred(joints);
    end
    
    %{
    [scmap, poly] = get_sticks_segmentation(p, im, joints);
    plot(poly(:,1), poly(:,2));
    
    scmap = visualise_scoremap(scmap , 4);
    figure(2);
    imshow(scmap);
    %}

    
    pause;
end


end

