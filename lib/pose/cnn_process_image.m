function [feat_prob, locreg_pred, next_pred, rpn_prob, rpn_bbox] = cnn_process_image(input, net, sigmoid)

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
    
    prob_idx = find_string(net.outputs, 'prob');
    locref_idx = find_string(net.outputs, 'loc_pred');
    next_idx = find_string(net.outputs, 'next_pred');
    rpn_prob_idx = find_string(net.outputs, 'rpn_prob');
    rpn_bbox_idx = find_string(net.outputs, 'rpn_bbox_pred');

    
    % fc6_data = net.blobs('fc6-conv').get_data();

    locreg_pred = [];
    next_pred = [];
    rpn_prob = [];
    rpn_bbox = [];
    
    if prob_idx ~= -1
        feat_prob = zs{prob_idx};
        feat_prob = permute(feat_prob, [2 1 3]);
        if ~sigmoid
            % remove background class
            feat_prob = feat_prob(:,:,2:end);
        end
    end
    
    if locref_idx ~= -1
        fmap = zs{locref_idx};
        sz = size(fmap);
        fmap = reshape(fmap, sz(1), sz(2), 2, []);
        fmap = permute(fmap, [2 1 4 3]);
        locreg_pred = fmap;
    end
    
    if next_idx ~= -1
        fmap = zs{next_idx};
        sz = size(fmap);
        fmap = reshape(fmap, sz(1), sz(2), 2, []);
        fmap = permute(fmap, [2 1 4 3]);
        next_pred = fmap;
    end

    if rpn_prob_idx ~= -1
        fmap = zs{rpn_prob_idx};
        fmap = permute(fmap, [2 1 3]);
        rpn_prob = fmap;
    end
    
    if rpn_bbox_idx ~= -1
        fmap = zs{rpn_bbox_idx};
        sz = size(fmap);
        fmap = reshape(fmap, sz(1), sz(2), 4, []);
        fmap = permute(fmap, [2 1 4 3]);
        rpn_bbox = fmap;
    end
end

function idx = find_string(list, str)
    for k = 1:length(list)
        cand = list{k};
        if ~isempty(strfind(cand, str))
            idx = k;
            return;
        end
    end
    idx = -1;
end
