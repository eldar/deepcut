function compute_rotation_classes(expidx, image_set)

fprintf('rcnn_compute_rotation_classes()\n');

p = exp_params(expidx);

pidxs = p.pidxs;

[~,parts] = util_get_parts24();

num_joints = length(pidxs);

spatidxs = {[22 17],[22 16],[22 23],[22 4],[22 5],[16 14],[17 19],[4 2],[5 7],[2 0],[7 9],[14 12],[19 21]};
% convert spatidxs to 0-14 format
n = 1;
for pidx = pidxs
    for i = 1:length(spatidxs)
        if spatidxs{i}(1) == pidx
            spatidxs{i}(1) = n;
        end
        if spatidxs{i}(2) == pidx
            spatidxs{i}(2) = n;
        end
    end
    n = n + 1;
end
% build incidence map
% adjacent joints
adjc = cell(num_joints, 1);
for n = 1:length(spatidxs)
    edge = spatidxs{n};
    v1 = edge(1);
    v2 = edge(2);
    adjc{v1} = unique([adjc{v1} v2]);
    adjc{v2} = unique([adjc{v2} v1]);
end

GT = p.([image_set 'GT']);
load(GT, 'annolist');

if isfield(p, 'idpr_cache_dir')
    clusters_cache_dir = p.idpr_cache_dir;
else
    clusters_cache_dir = [p.expDir '/' p.shortName '/data'];
end

try
    load([clusters_cache_dir '/clusters'],'clusters');
catch
    % compute clusters
    vecs = cell(num_joints, 1);
    for i = 1:num_joints
        vecs{i} = zeros(length(annolist), length(adjc{i})*2+1);
    end

    sz = zeros(num_joints, 1);

    for imgidx = 1:length(annolist)
    %    if imgidx == 12220 % outlier
    %        continue;
    %    end

        fprintf('.');

        assert(length(annolist(imgidx).annorect) == 1);
        %for ridx = 1:length(annolist(imgidx).annorect)
        ridx = 1;

        rect = annolist(imgidx).annorect(ridx);
        joints = get_joints(rect, pidxs, parts);

        for idx = 1:num_joints
            [vec, no_points] = compute_pairwise_vec(joints, adjc, idx);
            if ~no_points
                sz(idx) = sz(idx) + 1;
                vecs{idx}(sz(idx), :) = [vec', imgidx];
            end
        end

        %img = imread(annolist(imgidx).image.name);
        %vis_pred(img, joints(:,:));
        %pause;
        if (~mod(imgidx, 100))
            fprintf(' %d/%d\n',imgidx,length(annolist));
        end
    end

    clusters = cell(num_joints, 1);
    for idx = 1:num_joints
        vecs{idx} = vecs{idx}(1:sz, :);
    end

    for idx = 1:num_joints
        num_clasters = p.idpr_num_clusters(idx);
        clusters{idx} = cluster_rotation_classes(vecs{idx}(:,1:end-1), num_clasters, false);
    end
    
    mkdir_if_missing(clusters_cache_dir);
    save([clusters_cache_dir '/clusters'], 'clusters', 'vecs', '-v7.3');
end

pairwise_classes = cell(length(annolist), 1);
skip_class = sum(p.idpr_num_clusters) + 1;

% now compute pairwise class for all images 
for imgidx = 1:length(annolist)
    fprintf('.');

    ridx = 1;
        
    rect = annolist(imgidx).annorect(ridx);
    joints = get_joints(rect, pidxs, parts);

    pairwise_class = ones(num_joints, 3) * 1e6;
    for idx = 1:num_joints
        [vec, no_points] = compute_pairwise_vec(joints, adjc, idx);
        pj = joints(idx, :);
        pairwise_class(idx, 1:2) = pj;
        if ~no_points
            diff = bsxfun(@minus, clusters{idx}, vec');
            [~, min_dist] = min(sum(diff.^2, 2));
            pairwise_class(idx, 3) = compute_idpr_class(idx, min_dist, p.idpr_num_clusters);
        elseif ~isnan(pj(1))
            pairwise_class(idx, 3) = skip_class;
        end
    end
    pairwise_classes{imgidx} = pairwise_class;

    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist));
    end
end

cache_dir = [p.expDir '/' p.shortName '/data'];
mkdir_if_missing(cache_dir);
save([cache_dir '/pairwise_classes'],'pairwise_classes', '-v7.3');


function [vec, no_points] = compute_pairwise_vec(joints, adjc, idx)
    pj = joints(idx, :);
    no_points = isnan(pj(1));
    vec = zeros(length(adjc{idx})*2, 1);
    n = 0;
    for adj = adjc{idx}
        pa = joints(adj, :);
        vec(n*2+1:n*2+2) = pa - pj;
        no_points = no_points | isnan(pa(1)) | (abs(vec(1)) > 300) | (abs(vec(2)) > 300);
        n = n + 1;
    end

function joints = get_joints(rect, pidxs, parts)
    points = rect.annopoints.point;
    joints = NaN(14, 2);
    n = 1;
    for pidx = pidxs
        annopoint_idxs = parts(pidx+1).pos;
        assert(annopoint_idxs(1) == annopoint_idxs(2));
        pt = util_get_annopoint_by_id(points, annopoint_idxs(1));
        if (~isempty(pt))
            joints(n, :) = [pt.x pt.y];
        end
        n = n + 1;
    end

function res = compute_idpr_class(joint_no, joint_class, num_clusters)
res = sum(num_clusters(1:joint_no-1))+joint_class;

