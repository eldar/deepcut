function p = exp_params(expidx)

is_release = get_release_mode();

if ~is_release
    p = exp_params_dev(expidx);
    return;
end

p = [];
p.code_dir = pwd();
p.expDir = [p.code_dir '/data/'];
p.imgDir = [p.code_dir '/data/images/'];
p.latexDir = [p.code_dir '/output/latex/'];
p.plotsDir = [p.code_dir '/output/plots/'];

p.solver = [p.code_dir '/external/solver/solver-callback'];
p.gurobi_license_file = [p.expDir '/gurobi/gurobi.lic;'];

p.datasetInfo = '/home/andriluk/IMAGES/human_pose_dataset/dataset/dataset_release_candidate1/dataset_info_v12.mat';

p.pairwise_relations = [p.expDir '/pairwise/all_pairs_stats_all.mat'];

p.liblinear_predict = true;

switch expidx
    case 1
        p.name = 'MPII multiperson test';
        p.shortName = 'mpii-multiperson';
        p.testGT = fullfile(p.expDir, p.shortName, 'images/test/annolist');
        p.testPad = 0;

        p.evalTest = fullfile(p.expDir, p.shortName, 'test', 'predictions');

        p.outputDir = [p.expDir '/' p.shortName '/output/'];
        p.multicutDir = [p.expDir '/' p.shortName '/multicut/'];

        p.pairwiseDir = fullfile(p.expDir, 'pairwise');

        p.net_def_file = 'ResNet-101-FCN_out_14_sigmoid_locreg_allpairs_test.prototxt';
        p.net_dir = fullfile(p.expDir, 'caffe-models');
        p.net_bin_file = 'ResNet-101-mpii-multiperson.caffemodel';

        p.unary_scoremap_dir = fullfile(p.expDir, p.shortName, 'scoremaps', 'test');
        p.pairwise_scoremap_dir = fullfile(p.expDir, p.shortName, 'scoremaps', 'test');
        p.scoremaps = fullfile(p.expDir, p.shortName, 'scoremaps');

        p.stride = 8;
        p.scale_factor = 224/265;
        p.locref = true;
        p.nextreg = true;
        p.allpairs = true;

	    p.res_net = true;

        p.nms_dist = 3.0;
        p.nms_locref = true;
        p.nms_locref_dist = 3.0;

        p.pidxs = [0 2 4 5 7 9 12 14 16 17 19 21 22 23];
        p.cidxs_full = 1:14;

        p.stagewise = true;
        p.split_threshold = 0.4;
        p.cidxs_stages = {[9 10 13 14], [9 10 13 14 7 8 11 12], [9 10 13 14 7 8 11 12 1 2 3 4 5 6]};
        p.correction_stages = [0 0 0];

        p.all_parts_on = false;
        p.nFeatSample = 10^2;

        p.dets_per_part = 20;

        p.ignore_low_scores = true;
        p.min_det_score = 0.2;
        p.single_people_solver = false;
        p.high_scores_per_class = true;
        p.all_parts_on = false;
        p.multi_people = true;
        p.time_limit = 86400;
        
        p.scale = 4;
        p.colorIdxs = [5 1];
        p.refHeight = 400;

        p.multicut = true;
end


if (isfield(p,'colorIdxs') && ~isempty(p.colorIdxs))
    p.colorName = eval_get_color_new(p.colorIdxs);
    p.colorName = p.colorName ./ 255;
end

p.exp_dir = fullfile(p.expDir, p.shortName);
p.res_net = isfield(p, 'res_net') && p.res_net;
p.rpn_detect = isfield(p, 'rpn_detect') && p.rpn_detect;
p.detcrop_recall = isfield(p, 'detcrop_recall') && p.detcrop_recall;
p.detcrop_image = isfield(p, 'detcrop_image') && p.detcrop_image;
p.histogram_pairwise = isfield(p, 'histogram_pairwise') && p.histogram_pairwise;
p.nms_locref = isfield(p, 'nms_locref') && p.nms_locref;
p.stagewise = isfield(p, 'stagewise') && p.stagewise;
if p.stagewise
    p.num_stages = length(p.cidxs_stages);
end
p.person_part = isfield(p, 'person_part') && p.person_part;
p.complete_clusters = isfield(p, 'complete_clusters') && p.complete_clusters;

p.locref_scale = sqrt(53);

p.mean_pixel = [104, 117, 123];

if ~isfield(p, 'stride')
    p.stride = 8;
end

end
