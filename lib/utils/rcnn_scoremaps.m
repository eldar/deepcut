function rcnn_scoremaps(config, rcnn_model_file)
  root_dir = config.dataset_root_dir;
  imdb_test = config.imdb_func(root_dir, 'test', config);
  roidb = imdb_test.roidb_func(imdb_test);
  
  rcnn_model = rcnn_load_model(rcnn_model_file, true);
  
  fh = figure;
  for i = 1:numel(roidb.rois), image = imdb_test.image_at(i);
    im = imread(image);
    is_gt = roidb.rois(i).gt;
    boxes = roidb.rois(i).boxes(is_gt,:);
    
    for j = 1:size(boxes,1)
      [t_boxes,X,Y] = wiggle(boxes(j,:));
    
      feat = rcnn_features(im, t_boxes, rcnn_model);
      feat = rcnn_scale_features(feat, rcnn_model.training_opts.feat_norm_mean);
      
      scores = bsxfun(@plus, feat*rcnn_model.detectors.W, rcnn_model.detectors.B);

      figure(fh); hold off;
      imshow(im);
      hold on;
      score_map = reshape(scores,[17,17]);
      fmin = min(scores); fmax = max(scores);
      score_map = (score_map - fmin) / (fmax - fmin) * 255;
      [c,h] = contourf(X,Y,score_map);
      colorbar;
      title(sprintf('max score: %f, min score: %f', fmin, fmax));
      
%       colorbar;
%       colormap(hot);
%        clabel(c,h), colorbar
%       ch = get(h,'child'); alpha(ch,0.4);
      
      pause;
    end
  end
end


function [new_boxes, xs, ys] = wiggle(box)
  [X,Y] = meshgrid([-8:8], [-8:8]);
  X = X(:); Y = Y(:);
  n = numel(X);
  
  assert(size(box,1) == 1);
  w = box(1,3) - box(1,1) + 1;
  h = box(1,4) - box(1,2) + 1;
  s = h/96;
  stride = s * 4;
  x_offsets = X * stride;
  y_offsets = Y * stride;
      
      
  new_xs = repmat(box(1), [n 1]) + x_offsets;
  new_ys = repmat(box(2), [n 1]) + y_offsets;
  new_boxes = [new_xs, new_ys, new_xs+w-1, new_ys+h-1];
  
  xs = box(1) + w/2 + [-8:8] * stride;
  ys = box(2) + h/2 + [-8:8] * stride;
end
