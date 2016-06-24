function keypointsAll = scoremaps2keypoints(expidx, image_set)

p = exp_params(expidx);

pad_orig = p.([image_set 'Pad']);
stride = p.stride;
inv_scale_factor = 1/p.scale_factor;
locref = p.locref;
scale_mul = sqrt(53);


pidxs = p.pidxs;
[~,parts] = util_get_parts24();

load(p.testGT,'annolist');

keypointsAll = [];

min_det_score = 1e-03;

save_dir = fullfile(p.exp_dir, image_set);

for imgidx = 1:length(annolist)
    fprintf('imgidx: %d/%d\n', imgidx, length(annolist));
    im_fn = annolist(imgidx).image.name;
    [~,im_name,~] = fileparts(im_fn);
    load(fullfile(p.unary_scoremap_dir, im_name), 'scoremaps');
    if locref
        load(fullfile(p.unary_scoremap_dir, [im_name '_locreg']), 'locreg_pred');
    end
    
    size2d = size(scoremaps(:,:,1));
    num_proposals = size(scoremaps, 1) * size(scoremaps, 2);
    num_channels = size(scoremaps, 3);
    unPosAll = zeros(num_proposals, 2);
    unProbAll = zeros(num_proposals, num_channels);
    if locref
        locationRefine = zeros(num_proposals, num_channels, 2);
    end

    for k = 1:num_proposals
        idx = k;
        [row, col] = ind2sub(size2d, idx);
        % transform heatmap to image coordinates
        im_y = (row-1)*stride;
        im_x = (col-1)*stride;
        unPosAll(k, :) = [pad_orig, pad_orig] + [im_x, im_y]*inv_scale_factor;
        unProbAll(k,:) = scoremaps(row,col,:);
        if locref
            locationRefine(k, :, :) = squeeze(locreg_pred(row, col, :, :))*scale_mul*inv_scale_factor;
        end
    end
        
    for i = 1:length(pidxs)
        pidx = pidxs(i);
        % part is a joint
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);

        unPos = unPosAll;
        if locref
            unPos = unPos + squeeze(locationRefine(:,i,:));
        end
        unProb = unProbAll(:,i);
        
        I = unProb >= min_det_score;
        unProb = unProb(I,:);
        unPos = unPos(I,:);
        [unProb,I] = sort(unProb, 'descend');
        unPos = unPos(I,:);
        
        keypointsAll(imgidx).det{jidx+1} = [unPos unProb];
    end
end

mkdir_if_missing(save_dir);
save(fullfile(save_dir, 'keypointsAll'), 'keypointsAll');