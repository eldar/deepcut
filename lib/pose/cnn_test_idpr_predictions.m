function [ correct_samples, total_samples, correct_un_samples, total_un_samples ] = rcnn_test_idpr_predictions( expidx, image_set, firstidx, nImgs, bVis )

fprintf('rcnn_test_idpr_predictions()\n');

if (ischar(expidx))
    expidx = str2num(expidx);
end

if (nargin < 3)
    firstidx = 1;
elseif ischar(firstidx)
    firstidx = str2num(firstidx);
end

imdb = exp2imdb(expidx, image_set);

if (nargin < 4)
    nImgs = length(imdb.image_ids);
elseif ischar(nImgs)
    nImgs = str2num(nImgs);
end

if (nargin < 5)
    bVis = false;
end

fprintf('expidx: %d\n',expidx);
fprintf('firstidx: %d\n',firstidx);
fprintf('nImgs: %d\n',nImgs);

p = exp_params(expidx);
exp_dir = [p.expDir '/' p.shortName];
fprintf('exp_dir: %s\n',exp_dir);

if (isfield(p, 'featExpDir'))
    feat_exp_dir = p.featExpDir;
else
    feat_exp_dir = exp_dir;
end

cache_name   = 'v1_finetune_iter_70k';

if (isfield(p,'pwModelExpDir'))
    model_exp_dir = p.pwModelExpDir;
else
    model_exp_dir = exp_dir;
end

conf = rcnn_config('sub_dir', '/cachedir/train', 'exp_dir', model_exp_dir);
net_file = rcnn_get_net_filename(p.netsDir);
assert(~isempty(net_file));

lastidx = firstidx + nImgs - 1;
if (lastidx > length(imdb.image_ids))
    lastidx = length(imdb.image_ids);
end

if (firstidx > lastidx)
    return;
end

conf = rcnn_config('sub_dir', ['/cachedir/' imdb.image_set], 'exp_dir', exp_dir);

joints = zeros(length(firstidx:lastidx), length(p.pidxs), 2);

num_classes = sum(p.idpr_num_clusters)+1;
skip_class = num_classes;

top_k = 2;

total_samples = zeros(num_classes, 1);
correct_samples = zeros(num_classes, 1);
correct_topk_samples = zeros(num_classes, 1);

num_joints = 14;
total_un_samples = zeros(num_joints+1, 1);
correct_un_samples = zeros(num_joints+1, 1);

cumul_num_clusters = zeros(1, length(p.idpr_num_clusters));
for i = 1:length(p.idpr_num_clusters)
    cumul_num_clusters(i) = sum(p.idpr_num_clusters(1:i));
end


for i = firstidx:lastidx
    
    tic
    fprintf('%s: test (%s) %d/%d\n', procid(), imdb.name, i, length(imdb.image_ids));
    file = sprintf('%s/feat_cache/%s/%s/%s', feat_exp_dir, cache_name, imdb.image_set, imdb.image_ids{i});
    d = rcnn_load_cached_pool5_features(file);
    
    assert(~isempty(d.feat));
    %if isempty(d.feat)
    %    continue;
    %end
    
    feat_len = size(d.feat, 2);
    if feat_len == 9216
        featFC8 = rcnn_pool5_to_fcX(d.feat, 8, rcnn_model);
        featFC8 = rcnn_softmax(featFC8);
    else
        featFC8 = d.feat;
    end
    featFC8_score = featFC8(:,2:end);

    overlap = d.overlap;
    
    boxes = d.boxes;

    num_boxes = size(boxes, 1);
    for j = 1:num_boxes
        [ov, gt_label] = max(overlap(j,:));
        % zero overlap => label = 0 (background)
        if gt_label == skip_class
            continue;
        end
        if ov < 0.5
          gt_label = 0;
        end
        [~, pred_label] = max(featFC8(j,:));
        pred_label = pred_label-1;

        if gt_label == 0
            gt_un_label = 0;
        else        
            gt_un_label =  find(cumul_num_clusters >= gt_label, 1);
        end
        if pred_label == 0
            pred_un_label = 0;
        else
            pred_un_label =  find(cumul_num_clusters >= pred_label, 1);
        end
        
        total_un_samples(gt_un_label+1) = total_un_samples(gt_un_label+1) + 1;
        total_samples(gt_label+1) = total_samples(gt_label+1) + 1;

        if pred_label == gt_label
            correct_samples(gt_label+1) = correct_samples(gt_label+1) + 1;
        end
        if pred_un_label == gt_un_label
            correct_un_samples(gt_un_label+1) = correct_un_samples(gt_un_label+1) + 1;
        end
        
        [~, max_labels] = sort(featFC8(j,:), 'descend');
        for k = 1:top_k
            pred_k_label = max_labels(k)-1;
            if pred_k_label == gt_label
                correct_topk_samples(gt_label+1) = correct_topk_samples(gt_label+1) + 1;
                break;
            end
        end
        
    end
end

toc

fprintf('accuracy for positives idpr %f\n', sum(correct_samples(2:end))/sum(total_samples(2:end)));
fprintf('accuracy for positives top k idpr %f\n', sum(correct_topk_samples(2:end))/sum(total_samples(2:end)));
fprintf('accuracy for positives unary %f\n', sum(correct_un_samples(2:end))/sum(total_un_samples(2:end)));

fprintf('done\n');

if (isdeployed)
    close all;
end

end

