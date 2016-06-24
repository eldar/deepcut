function cnn_test_dense_unaries( expidx, image_set, bVis, firstidx, nImgs, net_bin_file_param)

p = exp_params(expidx);

if (nargin < 4)
    firstidx = 1;
elseif ischar(firstidx)
    firstidx = str2num(firstidx);
end

if strcmp(image_set, 'test')
    load(p.testGT)
else
    load(p.trainGT)
end

num_images = size(annolist, 2);

if (nargin < 5)
    nImgs = num_images;
elseif ischar(nImgs)
    nImgs = str2num(nImgs);
end

if (nargin < 3)
    bVis = false;
end

lastidx = firstidx + nImgs - 1;
if (lastidx > num_images)
    lastidx = num_images;
end

% params
pad_orig = p.([image_set 'Pad']);
stride = p.stride;
half_stride = stride/2;
scale_factor = p.scale_factor;
scale_mul = sqrt(53);

locreg = p.locref;
nextreg = p.nextreg;
do_crop = isfield(p, 'detcrop') && ~isempty(p.detcrop);

display_regressions = false;
vis_scoremaps = bVis;
vis_crop = false;

code_dir = p.code_dir;
models_dir = [code_dir '/models/'];

net_def_file = [models_dir p.net_def_file];

net_dir = p.net_dir;

net_bin_file = get_net_filename(net_dir);
if isfield(p, 'net_bin_file')
    net_bin_file = [net_dir '/' p.net_bin_file];
end
%net_bin_file = [net_dir '/final_model.caffemodel'];
if nargin >= 6
    net_bin_file = [net_dir '/' net_bin_file_param];
end

net = [];

parts = get_parts();

pairwise = load_pairwise_data(p);
graph = pairwise.graph;

fprintf('testing from net file %s\n', net_bin_file);

num_joints = length(p.cidxs);

joints = zeros(length(firstidx:lastidx), num_joints, 2);

tic
for i = firstidx:lastidx

    fprintf('%s: test (%s) %d/%d\n', procid(), p.name, i, nImgs);
    im_fn = annolist(i).image.name;
    [~,im_name,~] = fileparts(im_fn);
    im = imread(im_fn);
    im_orig = im;
    
    crop = get_detection_crop_2( p, annolist(i).annorect, size(im), pad_orig);

    
    if isfield(p, 'det_crop_rpn') && p.det_crop_rpn
        load(fullfile(p.rpn_scoremap_dir, [im_name '_rpn']), 'rpn_prob', 'rpn_bbox');

        objpos = annolist(i).annorect.objpos;
        objpos = single([objpos.x objpos.y]);
        
        pos = int32((objpos*scale_factor - half_stride)/stride) + 1;
        row = pos(2);
        col = pos(1);
        
        anchors = squeeze(rpn_prob(row, col, :));
        [~,anch] = max(anchors);
        
        t = squeeze(rpn_bbox(row, col, anch, :));
        
        anchor_types = single([ 1, 130; 1, 211; 2, 153; 3, 125; 4, 97]);
        w_a = anchor_types(anch, 2);
        h_a = w_a * anchor_types(anch, 1);
        x_a = objpos(1);
        y_a = objpos(2);
        
        x = x_a + w_a*t(1);
        y = y_a + h_a*t(2);
        w = w_a * exp(t(3));
        h = h_a * exp(t(4));

        %extra_margin = 80;
        w = w + 120;
        h = h + 180;

        x_r = x - w/2;
        y_r = y - h/2 + 10;
        
        rect_orig = single([x_r y_r x_r+w y_r+h]);
        rect = int32((rect_orig*scale_factor - half_stride)/stride) + 1;
        sm_height = size(rpn_prob, 1);
        sm_width = size(rpn_prob, 2);
        rect(1) = max(rect(1), 1);
        rect(2) = max(rect(2), 1);
        rect(3) = min(rect(3), sm_width);
        rect(4) = min(rect(4), sm_height);

        crop(1) = max(rect_orig(1), 1);
        crop(2) = max(rect_orig(2), 1);
        crop(3) = min(rect_orig(3), size(im_orig, 2));
        crop(4) = min(rect_orig(4), size(im_orig, 1));

        if bVis
            scmap = visualise_scoremap( rpn_prob );
            figure(3);
            imshow(scmap);

            figure(4);
            imagesc(im_orig);
            rectangle('Position', [x_r y_r w h]);
            
            figure(5);
            imagesc(im_orig(crop(2):crop(4),crop(1):crop(3), : ));
            %pause;
        end
      
        %crop = [rect(1), rect(2), rect(1) + rect(3), rect(2) + rect(4)];
    end
    
    crop_left = crop(1);
    crop_top = crop(2);

    if isfield(p, 'unary_scoremap_dir')
        scmap_name = fullfile(p.unary_scoremap_dir, [im_name '.mat']);
    end
    
    if isfield(p, 'unary_scoremap_dir') && exist(scmap_name, 'file') == 2
        load(scmap_name, 'scoremaps');
        unary_maps = scoremaps;
        load(fullfile(p.unary_scoremap_dir, [im_name '_locreg']), 'locreg_pred');
        if nextreg
            load(fullfile(p.unary_scoremap_dir, [im_name '_nextreg']), 'nextreg_pred');
        end
    else
        if isempty(net)
            caffe.reset_all();
            caffe.set_mode_gpu();
            net = caffe.Net(net_def_file, net_bin_file, 'test');
            fprintf('testing from net file %s\n', net_bin_file);
        end
        
        [unary_maps, locreg_pred, nextreg_pred, rpn_prob, rpn_bbox] = extract_features(im, net, p, annolist(i).annorect, pad_orig, pairwise, crop);
        mirror = false;
        if mirror
            wdth = size(im, 2);
            im2 = im(:, wdth:-1:1, :);
            [unary_maps2, locreg_pred2, nextreg_pred2] = extract_features(im2, net, p, annolist(i).annorect, pad_orig, pairwise);
            mirror_map = [6 5 4 3 2 1 12 11 10 9 8 7 13 14];
            scmap_width = size(unary_maps2, 2);
            unary_maps2 = unary_maps2(:, scmap_width:-1:1, mirror_map);
            unary_maps = (unary_maps + unary_maps2) * 0.5;
        end
    end

    pts = zeros(num_joints, 2);

    [rect, rect_orig] = get_detection_crop(p, annolist(i).annorect, size(unary_maps));
   
    segmentation = false;
    if segmentation
        prob_segm = net.blobs('segm_pred').get_data();
        prob_segm = permute(prob_segm, [2 1 3]);
    end
    
    for k = 1:num_joints
        part_map = unary_maps(:,:,k);
        %part_map = part_map(rect(2):rect(4), rect(1):rect(3));
        [~,I] = max(part_map(:));
        [row, col] = ind2sub(size(part_map),I);
        % transform heatmap to image coordinates
        crd = [col-1, row-1]*stride;
        if p.res_net
            crd = crd + half_stride;
        end
        crd = single(crd);
        if locreg
            dcrd = squeeze(locreg_pred(row, col, k, :))*scale_mul;
            crd = crd + dcrd';
        end
        pts(k, :) = double([crop_left, crop_top]-1) + crd/scale_factor;
    end
    
    do_belief_prop = false;
    if do_belief_prop
        new_joints = belief_prop(p, im_orig, unary_maps, locreg_pred, nextreg_pred, graph);
        upd = [1 2 3 4 5 6 7 8 9 10 13 14];
        for k = 1:length(upd)
            jnt = upd(k);
            pts(jnt, :) = [crop_left, crop_top] + new_joints(k, :);
        end
    end
    
    if p.detcrop_recall
        %[~, rect_orig] = get_detection_crop(p, annolist(i).annorect, size(scoremaps));
        %fprintf('crop rectangle (x, y, width, height): (%d %d %d %d)\n', ...
        %        rect_orig(1), rect_orig(2), (rect_orig(3) - rect_orig(1)), (rect_orig(4) - rect_orig(2)));
        parts = get_parts();
        joint_list = get_anno_joints(annolist(i).annorect(1), p.pidxs, parts);
        idxs = point_in_rect(joint_list, rect_orig);
        pts(:, :) = -100;
        pts(idxs,:) = joint_list(idxs, :);
    end
    
    if false
        gt_joints = get_anno_joints(annolist(i).annorect, p.pidxs, parts);
    end

    if nextreg
        next_joint = zeros(13, 2);
        for k = 1:size(nextreg_pred, 3)
            joint_id = graph(k, 1);
            
            if false
                part_map = unary_maps(:,:,joint_id);
                [~,I] = max(part_map(:));
                [row, col] = ind2sub(size(part_map),I);
            else
                loc = coord_to_scoremap(p, gt_joints(joint_id, :), crop );
                col = loc(1);
                row = loc(2);
            end

            next_crd = squeeze(nextreg_pred(row, col, k, :));
            next_joint(k,:) = next_crd/scale_factor;
        end
        %-----------------------------
        
        if display_regressions
            joint_to_display = 11;

            num_graph = size(graph, 1);
            pts_no_pad = bsxfun(@minus, pts, [crop_left, crop_top]);
            figure(100);
            imagesc(im_orig);
            part_map = unary_maps(:,:,1);
            height = size(unary_maps, 1);
            width = size(unary_maps, 2);
    %        for row = 1:2:height
    %            for col = 1:2:width
            for row = 10:2:(height-7)
                for col = 10:2:(width-7)
                    % transform heatmap to image coordinates
                    im_y = (row-1)*stride;
                    im_x = (col-1)*stride;
                    s = [im_x, im_y]/scale_factor;
                    closest = closest_point(pts, s);

                    for k = 1:num_graph
                        if graph(k, 1) == closest && graph(k, 2) == joint_to_display
                            break;
                        end
                    end

                    e = s + squeeze(nextreg_pred(row, col, k, :))'/scale_factor;
                    line([s(1) e(1)], [s(2) e(2)], 'Color', 'b');
                end
            end
        end
        %-----------------------------
        
    else
        next_joint = [];
    end
    
    joints(i-firstidx+1, :, :) = pts;

    if bVis
        figure(1);
        clf;
        imagesc(im_orig); axis equal; hold on;
        vis_pred(pts, next_joint, graph);

        %{
        joint_no = 12;
        
        score_map = unary_maps(:,:,joint_no);
        score_map = score_map';
        figure(2);
        imagesc(im_orig);
        figure(3);
        imagesc(score_map);
        %}
        %pause;
    end
    
    bVisRegressions = false;
    if bVisRegressions
        figure(1);
        clf;
        %axes('position', [0 0 1 1])
        %axis off;
        
        axis equal;
        %axis equal; axis off;
        
        imagesc(im(crop(2):crop(4), crop(1):crop(3), :)); axis equal; hold on;
        pts = bsxfun(@minus, gt_joints, crop(1:2));
        vis_next_pred(pts, next_joint, graph);
        axis off;
        set(gca, 'LooseInset', get(gca, 'TightInset'));
        fname = fullfile('/BS/eldar/work/pose/misc/pairwise-regr-vis/lsp-test', [num2str(i) '.png']);
        print(gcf,'-dpng', fname);
    end
    
    if vis_crop && do_crop
        figure(2);
        imagesc(im_orig);
        rectangle('Position', [rect.x1 rect.y1 (rect.x2 - rect.x1) (rect.y2 - rect.y1)]);
        pause;
    end
    
    if vis_scoremaps
        scmap = visualise_scoremap( unary_maps );
        figure(2);
        imshow(scmap);

        if exist('prob_res3b3')
            scmap = visualise_scoremap( prob_res3b3 );
            figure(3);
            imshow(scmap);
        end

        if segmentation
            %[1 2 4 7 8 9]
            scmap = visualise_scoremap( prob_segm(:, :, :), 8 );
            figure(4);
            imshow(scmap);
        end
        
        %sc_dir = fullfile(p.expDir, p.shortName, 'scoremap_imgs');
        %mkdir_if_missing(sc_dir);
        %imwrite(scmap, fullfile(sc_dir, [im_name '_scmap.png']));
        %figure(3);
        %imshow(im_orig);
    end
    
    if bVis
        pause;
    end
end

secs = toc;

joints2keypointsAll(expidx, image_set, joints);

caffe.reset_all();

fprintf('time, fps: %f %f\n', secs, nImgs/secs);
end

function idx = closest_point(pts, pt)
pts = bsxfun(@minus, pts, pt);
ls = sqrt(sum(pts.^2, 2));
[~, idx] = min(ls);
end
