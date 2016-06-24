function rcnn_scoremaps_save(config, rcnn_model_file)
  root_dir = config.dataset_root_dir;
  imdb_test = config.imdb_func(root_dir, 'test', config);
  roidb = imdb_test.roidb_func(imdb_test);
  
  fprintf('loading model\n');
  rcnn_model = rcnn_load_model(rcnn_model_file, true);
  
  scoremaps = []; cnt = 1;
  for i = 1:numel(roidb.rois), image = imdb_test.image_at(i);
    fprintf('%d/%d: %s\n', i, numel(roidb.rois), image);
    im = imread(image);
    is_gt = roidb.rois(i).gt;
    boxes = roidb.rois(i).boxes(is_gt,:);
    
    for j = 1:size(boxes,1)
%       [t_boxes,X,Y] = wiggle(boxes(j,:));
      n = 5;
      [t_boxes,X,Y, heights] = wiggle_pos_scale(boxes(j,:), 4, n);
    
      feat = rcnn_features(im, t_boxes, rcnn_model);
      feat = rcnn_scale_features(feat, rcnn_model.training_opts.feat_norm_mean);
      
      scores = bsxfun(@plus, feat*rcnn_model.detectors.W, rcnn_model.detectors.B);

      m = n*2+1;
      score_map = reshape(scores,[m m m]);
      scoremaps(cnt).img_idx = i;
      scoremaps(cnt).img_id = imdb_test.image_ids{i};
      scoremaps(cnt).gt_box = boxes(j,:);
      scoremaps(cnt).boxes = cat(2, t_boxes, scores);
      scoremaps(cnt).xs = X;
      scoremaps(cnt).ys = Y;
      scoremaps(cnt).heights = heights;
      scoremaps(cnt).score_map = score_map;
      cnt = cnt + 1;
    end
  end
  
  save('scoremaps-3d.mat', 'scoremaps');
end

function [new_boxes, xs, ys, hs] = wiggle_pos_scale(box, normalized_stride, n)
  h = box(4) - box(2) + 1;
  w = box(3) - box(1) + 1;
  cx = box(1)+w/2;
  cy = box(2)+h/2;
  ar = w/h;

  heights = unique(round(h*(normalized_stride/96+1).^(-n:n)));
  new_boxes = cell(numel(heights), 1);
  xs = cell(numel(heights), 1);
  ys = cell(numel(heights), 1);
  hs = cell(numel(heights), 1);
  for i = 1:numel(heights), new_h = heights(i);
    new_w = new_h * ar;
    t_box = [cx - new_w/2 - 0.5, cy - new_h/2 - 0.5, cx + new_w/2 + 0.5, cy + new_h/2 + 0.5];
    [new_boxes{i}, xs{i}, ys{i}] = wiggle(t_box, normalized_stride, n);
    hs{i} = ones(size(xs)) * new_h;
  end
  new_boxes = cat(1, new_boxes{:});
  xs = cat(1, xs{:});
  ys = cat(1, ys{:});
  hs = cat(1, hs{:});
end

function [new_boxes, xs, ys] = wiggle(box, normalized_stride, n)
  [X,Y] = meshgrid(-n:n, -n:n);
  X = X(:); Y = Y(:);
  n = numel(X);
  
  assert(size(box,1) == 1);
  w = box(1,3) - box(1,1) + 1;
  h = box(1,4) - box(1,2) + 1;
  s = h/96;
  stride = s * normalized_stride;
  x_offsets = X * stride;
  y_offsets = Y * stride;
      
      
  new_xs = repmat(box(1), [n 1]) + x_offsets;
  new_ys = repmat(box(2), [n 1]) + y_offsets;
  new_boxes = [new_xs, new_ys, new_xs+w-1, new_ys+h-1];
  
  xs = box(1) + w/2 + [-8:8] * stride;
  ys = box(2) + h/2 + [-8:8] * stride;
end
