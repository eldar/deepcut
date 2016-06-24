function cnn_cache_features( expidx, image_set, firstidx, nImgs)

p = exp_params(expidx);

if (nargin < 3)
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

if (nargin < 4)
    nImgs = num_images;
elseif ischar(nImgs)
    nImgs = str2num(nImgs);
end

lastidx = firstidx + nImgs - 1;
if (lastidx > num_images)
    lastidx = num_images;
end

% params
overwrite = true;

mirror_map = [6 5 4 3 2 1 12 11 10 9 8 7 13 14];

nextreg = isfield(p, 'nextreg') && p.nextreg;

models_dir = [p.code_dir '/models/'];
net_def_file = [models_dir p.net_def_file];

net_dir = p.net_dir;
net_bin_file = get_net_filename(net_dir);
if isfield(p, 'net_bin_file')
    net_bin_file = [net_dir '/' p.net_bin_file];
end

caffe.reset_all();
caffe.set_mode_gpu();
net = caffe.Net(net_def_file, net_bin_file, 'test');

cache_dir = fullfile(p.scoremaps, image_set);
mkdir_if_missing(cache_dir);

fprintf('save dir %s\n', cache_dir);
fprintf('testing from net file %s\n', net_bin_file);

pairwise = load_pairwise_data(p);

for im_idx = firstidx:lastidx

    fprintf('%s: test (%s) %d/%d\n', procid(), p.name, im_idx, num_images);
    im_fn = annolist(im_idx).image.name;
    [~,im_name,~] = fileparts(im_fn);
    save_file_name = fullfile(cache_dir, im_name);
    
    if (exist([save_file_name '.mat'], 'file') == 2) && ~overwrite
        continue
    end

    im = imread(im_fn);

    pad_orig = p.([image_set 'Pad']);
    
    [scoremaps, locreg_pred, nextreg_pred] = extract_features(im, net, p, annolist(im_idx).annorect, pad_orig, pairwise);
    
    save(save_file_name, 'scoremaps');
    if ~isempty(locreg_pred)
        save(fullfile(cache_dir, [im_name '_locreg']), 'locreg_pred');
    end
    if nextreg && ~isempty(nextreg_pred)
        save(fullfile(cache_dir, [im_name '_nextreg']), 'nextreg_pred');
    end
end

caffe.reset_all();

end