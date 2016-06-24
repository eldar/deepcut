function [ res ] = belief_prop( p, im, unary_maps, locreg_pred, nextreg_pred, graph )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
    stride = p.stride;
    half_stride = stride/2;
    scale_factor = p.scale_factor;

    % perform nms for all parts
    root_cidx = 13;
    nms_thresh = 4.5;
    sm = unary_maps(:,:,root_cidx);
    I = nms_distance_IoMin(sm, nms_thresh);
    
    sm_height = size(sm, 1);
    sm_width = size(sm, 2);

    if true
        figure(19);
        imshow(im);
        
        figure(20);
        imagesc(sm);
        colorbar;

        mask = zeros(size(sm));
        mask(I) = 1;
        figure(21);
        imagesc(mask);
    end


    for k = 1:length(I)
        idx = I(k);
        [row, col] = ind2sub(size(sm), idx);
        fprintf('row col (%d %d) - %f\n', row, col, sm(row, col));
    end
    
    cand_idx = 2;
    idx = I(cand_idx);
    [row, col] = ind2sub(size(sm), idx);
    
    num_joints = 14;
    nodes = cell(num_joints, 1);
    for k = 1:num_joints
        node = struct();
        node.is_root = k == root_cidx;
        sm = unary_maps(:,:,k);
        if node.is_root
            node.loc = [col row];
            % now fix up the scoremap
            new_sm = zeros(sm_height, sm_width);
            for j = 1:sm_height
                for i = 1:sm_width
                    dx = i-col;
                    dy = j-row;
                    dist = sqrt(dx.^2 + dy.^2);
                    if dist <= nms_thresh
                        new_sm(j, i) = sm(j, i);
                    end
                end
            end
            sm = new_sm;
            
            figure(22);
            imagesc(new_sm);
            colorbar;
        end
        node.msg = double(log(sm));
        %node.msg = sm;
        
        nodes{k} = node;
    end
    
    if true % define messaging schedule
        flood = cell(1, 1);
    
        edges = cell(1, 1);
        edges{1} = struct('start', 13, 'end', 14);
        edges{2} = struct('start', 13, 'end', 9);
        edges{3} = struct('start', 13, 'end', 10);
        flood{1} = edges;

        edges = cell(1, 1);
        edges{1} = struct('start', 9, 'end', 10);
        edges{2} = struct('start', 10, 'end', 9);

        edges{3} = struct('start', 9, 'end', 3);
        edges{4} = struct('start', 10, 'end', 4);
        
        edges{5} = struct('start', 9, 'end', 8);
        edges{6} = struct('start', 10, 'end', 11);
        %edges{9} = struct('start', 9, 'end', 7);
        %edges{7} = struct('start', 10, 'end', 4);

        edges{7} = struct('start', 14, 'end', 13);
        edges{8} = struct('start', 9, 'end', 13);
        edges{9} = struct('start', 10, 'end', 13);

        flood{2} = edges;

        edges = cell(1, 1);
        edges{1} = struct('start', 3, 'end', 4);
        edges{2} = struct('start', 4, 'end', 3);
        edges{3} = struct('start', 3, 'end', 9);
        edges{4} = struct('start', 4, 'end', 10);
        edges{5} = struct('start', 8, 'end', 7);
        edges{6} = struct('start', 3, 'end', 2);
        edges{7} = struct('start', 4, 'end', 5);
        edges{8} = struct('start', 11, 'end', 12);
        
        flood{3} = edges;
        
        edges = cell(1, 1);
        edges{1} = struct('start', 2, 'end', 1);
        edges{2} = struct('start', 5, 'end', 6);
        edges{3} = struct('start', 2, 'end', 5);
        edges{4} = struct('start', 5, 'end', 2);
        
        flood{4} = edges;

        %edges = cell(1, 1);
        %edges{1} = struct('start', 1, 'end', 6);
        %edges{2} = struct('start', 6, 'end', 1);
        
        %flood{5} = edges;


    end
    
    kernel = fspecial('gaussian', 7, 2)*4;
    scale_mul = sqrt(53);

    locref = @(row, col, joint) squeeze(locreg_pred(row, col, joint, :))*scale_mul;
    locref_grid = @(row, col, joint) int32(round(squeeze(locreg_pred(row, col, joint, :))*scale_mul/stride));
    
    for stage = 1:length(flood)
        edges = flood{stage};
        
        for i = 1:length(edges)
            edge = edges{i};
            [~, edge_idx, ~] = search_in_graph(graph, edge.start, edge.end);

            msg = nodes{edge.start}.msg;
            
            [~,I] = max(msg(:));
            [row, col] = ind2sub(size(msg),I);
            
            dcrd = locref_grid(row, col, edge.start);
            col = col + dcrd(1);
            row = row + dcrd(2);

            next_crd = squeeze(nextreg_pred(row, col, edge_idx, :));
            shift = round(next_crd/stride);
            %msg_tr = imtranslate(msg, shift);
            
            new_row = row + int32(shift(2));
            new_col = col + int32(shift(1));
            dcrd_new = locref_grid(new_row, new_col, edge.end);

            shift = shift + single(dcrd_new);
            
            msg_tr = shiftimg(msg, shift, -Inf);
            
            msg_conv = log(conv2(exp(msg_tr), kernel, 'same'));

            start_ = edge.start;
            end_ = edge.end;
            %{
            if end_ == 1
                fprintf('start %d\n', start_);
                figure(24);
                imagesc(exp(nodes{end_}.msg));
                colorbar;
                figure(25);
                imagesc(exp(msg_tr));
                colorbar;
                figure(26);
                imagesc(exp(nodes{end_}.msg+msg_conv));
                colorbar;
                pause;
            end
            %}

            nodes{edge.end}.msg = nodes{edge.end}.msg + msg_conv;
        end
        
        fprintf('stage %d completed \n', stage);

        figure(30);
        imagesc(exp(nodes{13}.msg));
        colorbar;
        pause;
        %{

        figure(31);
        imagesc(exp(nodes{1}.msg));
        colorbar;
        pause;
        %}
    end
    
    upd = [1 2 3 4 5 6 7 8 9 10 13 14];
    res = zeros(length(upd), 2);
    for k = 1:length(upd)
        joint = upd(k);
        msg = nodes{joint}.msg;
        [~,I] = max(msg(:));
        [row, col] = ind2sub(size(msg),I);
        dcrd = locref(row, col, joint);
        crd = [col-1, row-1]*stride;
        if p.res_net
            crd = crd + half_stride;
        end
        crd = single(crd);
        crd = crd + dcrd';
        crd = crd/scale_factor;
        res(k,:) = crd;
    end
end