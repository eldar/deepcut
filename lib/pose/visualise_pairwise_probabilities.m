function pw_prob = visualise_pairwise_probabilities(expidx,firstidx,nImgs, cidx1, cidx2, bVis)

if (ischar(expidx))
    expidx = str2num(expidx);
end

if (nargin < 2)
    firstidx = 1;
end

if (ischar(firstidx))
    firstidx = str2num(firstidx);
end

if (nargin < 3)
    nImgs = 1;
elseif ischar(nImgs)
    nImgs = str2num(nImgs);
end

if (nargin < 6)
    bVis = true;
end

fprintf('cidxs: %d,%d\n', cidx1, cidx2);

image_set = 'test';
p = exp_params(expidx);
exp_dir = fullfile(p.expDir, p.shortName);
load(p.testGT,'annolist');

pidxs = p.pidxs;
num_joints = length(pidxs);
[~,parts] = util_get_parts24();

multicutDir = p.multicutDir;
mkdir_if_missing(multicutDir);
fprintf('multicutDir: %s\n',multicutDir);
visDir = fullfile(multicutDir, 'vis');
mkdir_if_missing(visDir);

num_images = size(annolist, 2);

lastidx = firstidx + nImgs - 1;
if (lastidx > num_images)
    lastidx = num_images;
end

if (firstidx > lastidx)
    return;
end

% computation parameters
pairwiseDir = p.pairwiseDir;
rotOffset = 0.5*pi;
if isfield(p, 'cidxs')
    cidxs = p.cidxs;
else
    cidxs = p.cidxs_full;
end
pad_orig = p.([image_set 'Pad']);
stride = 8;
scale_mul = sqrt(53);
scale_factor = p.scale_factor;
inv_scale_factor = 1/p.scale_factor;
locref = p.locref;

pwIdxsAllrel1 = cell(0);
n = 0;
for img_idx = 1:length(cidxs)-1
  for j = img_idx+1:length(cidxs)
    n = n + 1;
    pwIdxsAllrel1{n} = [cidxs(img_idx) cidxs(j)];
  end
end

fprintf('Loading spatial model from %s\n', pairwiseDir);
for sidx1 = 1:length(pwIdxsAllrel1)
    modelName  = [pairwiseDir '/spatial_model_cidx_' num2str(pwIdxsAllrel1{sidx1}(1)) '_' num2str(pwIdxsAllrel1{sidx1}(2))];
    %fprintf('%d %s\n', sidx1, modelName);
    try
        m = load(modelName,'spatial_model');
        spatial_model.diff(sidx1).log_reg = m.spatial_model.log_reg;
        spatial_model.diff(sidx1).training_opts = m.spatial_model.training_opts;
    catch
    end
end

nextreg = isfield(p, 'nextreg') && p.nextreg;
bidirect = isfield(p, 'bidirect') && p.bidirect;
neighbour_locref = isfield(p, 'neighbor_locref') && p.neighbor_locref;
allpairs = isfield(p, 'allpairs') && p.allpairs;

load(p.pairwise_relations, 'means', 'std_devs', 'graph');

pw_prob = [];

for img_idx = firstidx:lastidx
    fprintf('imgidx: %d\n',img_idx);
    
    tic
    fprintf('loading features... ');
    im_fn = annolist(img_idx).image.name;
    [~,im_name,~] = fileparts(im_fn);
    fprintf('displaying image %s\n', im_name);
    load(fullfile(p.pairwise_scoremap_dir, im_name), 'scoremaps');
    load(fullfile(p.pairwise_scoremap_dir, [im_name '_locreg']), 'locreg_pred');
    if nextreg
        load(fullfile(p.pairwise_scoremap_dir, [im_name '_nextreg']), 'nextreg_pred');
        nextreg_pred = nextreg_pred/scale_factor;
    end
    fprintf('done!\n');
    
    one_sm = squeeze(scoremaps(:,:,1));
    height = size(one_sm, 1);
    width  = size(one_sm, 2);

    num_proposals = height*width;
    idxsAll = 1:num_proposals;
    unPos = zeros(num_proposals, 2);
    if locref
        locationRefine = zeros(num_proposals, num_joints, 2);
    else
        locationRefine = 0;
    end
    num_scores = size(scoremaps, 3);
    unProb = zeros(num_proposals, num_scores);
    if nextreg
        nextReg = zeros(num_proposals, size(nextreg_pred, 3), size(nextreg_pred, 4));
    end
    for k = 1:num_proposals
        idx = idxsAll(k);
        [row, col] = ind2sub(size(one_sm), idx);
        % transform heatmap to image coordinates
        im_y = (row-1)*stride;
        im_x = (col-1)*stride;
        unPos(k, :) = [pad_orig, pad_orig] + [im_x, im_y]*inv_scale_factor;
        unProb(k, :) = scoremaps(row,col,:);
        if nextreg
            nextReg(k, :, :) = squeeze(nextreg_pred(row, col, :, :));
        end
        if locref
            locationRefine(k, :, :) = squeeze(locreg_pred(row, col, :, :))*scale_mul*inv_scale_factor;
        end
    end

    [is_neighbor, forward_edge, backward_edge] = search_in_graph(graph, cidx1, cidx2);
    
    person_id = 2;
    rect = annolist(img_idx).annorect(person_id);
    joints = get_anno_joints( rect, pidxs, parts);

    origin_joint = cidx1;
    gt_joint = joints(origin_joint, :);
    if isnan(gt_joint(1,1))
        continue;
    end
    
    sm_size = size(one_sm);
    gt_sm_coord = image2scoremap_coord(gt_joint, pad_orig, scale_factor, stride);
    
    if (gt_sm_coord(1) > sm_size(2)) || (gt_sm_coord(1) < 1)
        continue;
    end
    if (gt_sm_coord(2) > sm_size(1)) || (gt_sm_coord(2) < 1)
        continue;
    end
    
    gt_loc = sub2ind(sm_size, gt_sm_coord(2), gt_sm_coord(1));

    
    [q1,q2] = meshgrid(gt_loc,1:num_proposals);
    idxsAll = [q1(:) q2(:)];
    if origin_joint == cidx2
        idxsAll = [idxsAll(:,2) idxsAll(:,1)];
    end

    for sidx1 = 1:length(pwIdxsAllrel1)
        if (pwIdxsAllrel1{sidx1}(1)== cidx1 && pwIdxsAllrel1{sidx1}(2)== cidx2)
            break;
        end
    end
    assert(sidx1 <= length(pwIdxsAllrel1));

    adhoc_features = false;
    
    if ~is_neighbor
        [featDiff,~,cb1Diff,cb2Diff] = get_spatial_features_diff_img_dx_dy_dense(unPos,idxsAll,rotOffset,unProb);
        featDiff = get_augm_spatial_features_diff_dx_dy(featDiff,spatial_model.diff(sidx1).training_opts.X_pos_mean, p);
        feat_norm = getFeatNorm(featDiff,spatial_model.diff(sidx1).training_opts.X_min,spatial_model.diff(sidx1).training_opts.X_max);
    elseif adhoc_features
        featDiff = get_spatial_features_neighbour_img(unPos,idxsAll,squeeze(nextReg(:,[forward_edge backward_edge],:)));
        featDiff = get_augm_spatial_features_diff_neighbour(featDiff);
        dists = featDiff(:, 1);
        prob = 1./(1+exp(0.2*dists-7.5));
        dists = featDiff(:, 3);
        prob2 = 1./(1+exp(0.2*dists-7.5));
        prob = prob .* prob2;
    else
        if neighbour_locref
            
            featDiff = get_spatial_features_neighbour_locref(unPos,idxsAll, ...
                                                             squeeze(nextReg(:,[forward_edge backward_edge],:)), ...
                                                             squeeze(locationRefine(:,[cidx1 cidx2],:)));
            featDiff = get_augm_spatial_features_diff_neighbour_locref(featDiff);
            feat_norm = getFeatNorm(featDiff,spatial_model.diff(sidx1).training_opts.X_min,spatial_model.diff(sidx1).training_opts.X_max);
            
            ex = sparse(double(feat_norm));
            model = spatial_model.diff(sidx1).log_reg;
            [~,acc,prob] = predict(zeros(size(ex,1),1), ex, model, '-b 1');
            prob = prob(:, 1);

            %{
            feat_norm1 = feat_norm;
            feat_norm1(:,[1 2 5 6]) = 0;
            ex = sparse(double(feat_norm1));
            model = spatial_model.diff(sidx1).log_reg;
            [~,acc,prob] = predict(zeros(size(ex,1),1), ex, model, '-b 1');
            prob1 = prob(:, 1);

            feat_norm2 = feat_norm;
            feat_norm2(:,[3 4 7 8]) = 0;
            ex = sparse(double(feat_norm2));
            model = spatial_model.diff(sidx1).log_reg;
            [~,acc,prob] = predict(zeros(size(ex,1),1), ex, model, '-b 1');
            prob2 = prob(:, 1);

            prob = prob1 .* prob2;
            %}
            
            
        else
            featDiff = get_spatial_features_neighbour_img(unPos,idxsAll,squeeze(nextReg(:,[forward_edge backward_edge],:)));
            featDiff = get_augm_spatial_features_diff_neighbour(featDiff, p);
            feat_norm = getFeatNorm(featDiff,spatial_model.diff(sidx1).training_opts.X_min,spatial_model.diff(sidx1).training_opts.X_max);
        end
    end


    if adhoc_features || neighbour_locref
    else
        ex = sparse(double(feat_norm));
        model = spatial_model.diff(sidx1).log_reg;
        [~,acc,prob] = predict(zeros(size(ex,1),1), ex, model, '-b 1');
        prob = prob(:, 1);
    end
    
    %histogram(prob);
    im = imread(im_fn);
    im = im(pad_orig+1:end-pad_orig, pad_orig+1:end-pad_orig, :);
    
    %figure(1);
    %clf;
    %imagesc(im);
    
    pw_prob = reshape(prob, height, width);

    enhance_contrast = false;
    if enhance_contrast
        zr = zeros(size(pw_prob));
        thr = 0.65;
        pw_prob = max((pw_prob-thr)/(1-thr), zr);
    end
    
    %imagesc(pw_prob);
    scmap = visualise_scoremap( pw_prob, 1 );
    
   
    scmap = imresize(scmap, [size(im, 1), size(im, 2)], 'bicubic');
    pw_prob_img = imresize(pw_prob, [size(im, 1), size(im, 2)], 'bicubic');
    
    
    %figure(100);
    %imshow(scmap);
    
    %hold on;
    %figure(2);
    %imagesc(pw_prob_img);
    %colorbar;
    
    color1 = [1 0 1];
    colors = [1 0 1; 1 1 0; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1];
    c = reshape(colors(cidx1, :), 1, 1, 3);
    color_rep = repmat(c, size(im, 1), size(im, 2), 1);
    color_rep = color_rep*255;
    
    pw_prob_img = repmat(pw_prob_img, 1, 1, 3);
    %figure(4);
    %imagesc(pw_prob_img);
    
    %scmap = uint8(scmap*255);
    %limm = uint8(ones(size(im))*255);
    %im_sc = min(im+scmap, limm);
    
    if bVis
        figure(3);
        final_img = (pw_prob_img) .* double(color_rep) + (1-pw_prob_img) .* double(im);
        final_img = uint8(final_img);
        imshow(final_img);

        axis off;
        set(gca, 'LooseInset', get(gca, 'TightInset'));
        %fname = fullfile('/BS/eldar/work/pose/misc/pairwise-scoremaps/lsp-test', [num2str(img_idx) '_cidxs_' num2str(cidx1) '_' num2str(cidx2) '.png']);
        %print(gcf,'-dpng', fname);
    end
    
    if img_idx ~= lastidx
        pause;
    end
    continue;
    %{
    for row = 1:2:height
        for col = 1:2:width
            % transform heatmap to image coordinates
            im_y = (row-1)*stride;
            im_x = (col-1)*stride;
            s = [im_x, im_y]*inv_scale_factor;
            e = s + squeeze(nextreg_pred(row, col, forward_edge, :))';
            line([s(1) e(1)], [s(2) e(2)], 'Color', 'r');
        end
    end
    %}
    
    gt_joint1 = joints(cidx1, :);
    gt_sm_coord1 = image2scoremap_coord(gt_joint1, pad_orig, scale_factor, stride);
    gt_loc1 = sub2ind(sm_size, gt_sm_coord1(2), gt_sm_coord1(1));
    
    gt_joint2 = joints(cidx2, :);
    gt_sm_coord2 = image2scoremap_coord(gt_joint2, pad_orig, scale_factor, stride);
    gt_loc2 = sub2ind(sm_size, gt_sm_coord2(2), gt_sm_coord2(1));
    
    s = gt_joint1 - [pad_orig, pad_orig];
    e = s + squeeze(nextreg_pred(gt_sm_coord1(2), gt_sm_coord1(1), forward_edge, :))';
    line([s(1) e(1)], [s(2) e(2)], 'Color', 'r');
    plot(s(1), s(2), 'go', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'MarkerSize', 5);

    s = gt_joint2 - [pad_orig, pad_orig];
    e = s + squeeze(nextreg_pred(gt_sm_coord2(2), gt_sm_coord2(1), backward_edge, :))';
    line([s(1) e(1)], [s(2) e(2)], 'Color', 'b');
    plot(s(1), s(2), 'go', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'MarkerSize', 5);
    
    if origin_joint == cidx1
        val_at_gt = prob(gt_loc2);
    else
        val_at_gt = prob(gt_loc1);
    end
    fprintf('pairwise probability is %f\n', val_at_gt);
    
    pause;
end

fprintf('done\n');

if (isdeployed)
    close all;
end

end

function coord = image2scoremap_coord(joint, pad_orig, scale_factor, stride)
coord = round((joint - [pad_orig, pad_orig])*scale_factor/stride + [1, 1]);
end
