function [scoremaps, locreg_pred, nextreg_pred] = cnn_process_image_tiled(input, net, sigmoid, im_bg_width, im_bg_height, stride)

    max_size = 1000;
    rf = 224; %receptive field
    cut_off = rf/stride;

    num_tiles_x = get_num_tiles(im_bg_width, max_size);
    num_tiles_y = get_num_tiles(im_bg_height, max_size);

    scoremaps = [];
    locreg_pred = [];
    nextreg_pred = [];

    for j = 1:num_tiles_y
        if j == 1
            start_y = 1;
        else
            start_y = (j-1)*(max_size-2*rf)+1;
        end
        if j == num_tiles_y
            end_y = im_bg_height;
        else
            end_y = start_y+max_size-1;
        end
        
        scoremaps_line = [];
        locreg_pred_line = [];
        nextreg_pred_line = [];
        
        for i = 1:num_tiles_x
            if i == 1
                start_x = 1;
            else
                start_x = (i-1)*(max_size-2*rf)+1;
            end
            if i == num_tiles_x
                end_x = im_bg_width;
            else
                end_x = start_x+max_size-1;
            end
            
            input_tile = input(start_y:end_y, start_x:end_x, :);

            [scoremaps_tile, locreg_pred_tile, nextreg_pred_tile] = cnn_process_image(input_tile, net, sigmoid);
            
            scoremaps_tile = cutoff_tile(scoremaps_tile, num_tiles_x, i, cut_off, true);
            locreg_pred_tile = cutoff_tile(locreg_pred_tile, num_tiles_x, i, cut_off, true);
            nextreg_pred_tile = cutoff_tile(nextreg_pred_tile, num_tiles_x, i, cut_off, true);
            
            scoremaps_line = cat(2, scoremaps_line, scoremaps_tile);
            locreg_pred_line = cat(2, locreg_pred_line, locreg_pred_tile);
            nextreg_pred_line = cat(2, nextreg_pred_line, nextreg_pred_tile);
        end
        
        scoremaps_line = cutoff_tile(scoremaps_line, num_tiles_y, j, cut_off, false);
        locreg_pred_line = cutoff_tile(locreg_pred_line, num_tiles_y, j, cut_off, false);
        nextreg_pred_line = cutoff_tile(nextreg_pred_line, num_tiles_y, j, cut_off, false);
            
        scoremaps = cat(1, scoremaps, scoremaps_line);
        locreg_pred = cat(1, locreg_pred, locreg_pred_line);
        nextreg_pred = cat(1, nextreg_pred, nextreg_pred_line);
    end

end

function [feat_prob, locreg_pred, next_pred] = cnn_process_image_tile(input, net, sigmoid)

    % switch width and height for Caffe
    input = permute(input, [2 1 3]);

    blob_size = [size(input), 1];
    net.blobs('data').reshape(blob_size);
    
    blob_size = [size(input), 1];

    batch = zeros(blob_size, 'single');
    batch(:,:,:,1) = input;
    batches = cell(1,1);
    batches{1} = batch;
    zs = net.forward(batches);
    
    % fc6_data = net.blobs('fc6-conv').get_data();

    locreg_pred = [];
    next_pred = [];
    
    for k = 1:length(zs);
        fmap = zs{k};
        if size(fmap, 3) == 14
            feat_prob = fmap;
            feat_prob = permute(feat_prob, [2 1 3]);
            continue;
        end
        fmap = zs{k};
        sz = size(fmap);
        fmap = reshape(fmap, sz(1), sz(2), 2, []);
        fmap = permute(fmap, [2 1 4 3]);
        if size(fmap, 3) == 14
            locreg_pred = fmap;
        else
            next_pred = fmap;
        end
    end
    
    if ~sigmoid
        % remove background class
        feat_prob = feat_prob(:,:,2:end);
    end
end

function num = get_num_tiles(sz, max_size)

rf = 224; %receptive field

if sz <= max_size
    num = 1;
    return;
end

k = 0;
while true
    % first and last tiles + middle tiles
    new_size = (max_size-rf)*2 + (max_size-2*rf)*k;
    if new_size >= sz
        break;
    end
    k = k + 1;
end

num = 2 + k;
end

function sm = cutoff_tile(sm, num_tiles, idx, cut_off, is_x)
    new_sz = [2 1 3 4];
    if is_x
        sm = permute(sm, new_sz);
    end
    
    if num_tiles == 1
    elseif idx == 1
        sm = sm(1:end-cut_off-1, :, :, :);
    elseif idx == num_tiles
        sm = sm(cut_off+1:end, :, :, :);
    else
        sm = sm(cut_off+1:end-cut_off-1, :, :, :);
    end
    
    if is_x
        sm = permute(sm, new_sz);
    end
end