function test_spatial_app_neighbour(expidx,firstidx,nImgs,bRecompute,bVis)

fprintf('test_spatial_hist()\n');

if (ischar(expidx))
    expidx = str2num(expidx);
end

if (ischar(firstidx))
    firstidx = str2num(firstidx);
end

if (nargin < 2)
    firstidx = 1;
end

if (nargin < 3)
    nImgs = 1;
elseif ischar(nImgs)
    nImgs = str2num(nImgs);
end

if (nargin < 4)
    bRecompute = false;
end

if (nargin < 5)
    bVis = false;
end

fprintf('expidx: %d\n',expidx);
fprintf('firstidx: %d\n',firstidx);
fprintf('nImgs: %d\n',nImgs);

is_release_mode = get_release_mode();

image_set = 'test';
p = exp_params(expidx);
exp_dir = fullfile(p.expDir, p.shortName);
load(p.testGT,'annolist');

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
pad_orig = p.([image_set 'Pad']);
stride = p.stride;
half_stride = stride/2;
locref_scale_mul = p.locref_scale;
inv_scale_factor = 1/p.scale_factor;
scale_factor = p.scale_factor;
locref = p.locref;
nextreg = isfield(p, 'nextreg') && p.nextreg;
unLab_cls = 'uint64';
max_sizet_val = intmax(unLab_cls);


stagewise = isfield(p, 'stagewise') && p.stagewise;
if isfield(p, 'cidxs_full')
    cidxs_full = p.cidxs_full;
else
    cidxs_full = p.cidxs;
end

if stagewise
    num_stages = length(p.cidxs_stages);
else
    num_stages = 1;
end

if isfield(p, 'dets_per_part_per_stage')
    dets_per_part = p.dets_per_part_per_stage;
elseif isfield(p, 'dets_per_part')
    dets_per_part = p.dets_per_part;
    if stagewise
        dets_per_part = repmat(dets_per_part, num_stages);
    end
end

use_graph_subset = isfield(p, 'graph_subset');
if use_graph_subset
    load(p.graph_subset);
end

pairwise = load_pairwise_data(p);
graph = pairwise.graph;

if isfield(p, 'nms_dist')
    nms_dist = p.nms_dist;
else
    nms_dist = 1.5;
end


hist_pairwise = isfield(p, 'histogram_pairwise') && p.histogram_pairwise;

pwIdxsAllrel1 = build_pairwise_pairs(cidxs_full);

spatial_model = cell(1,1);

fprintf('Loading spatial model from %s\n', pairwiseDir);
for sidx1 = 1:length(pwIdxsAllrel1)
    cidx1 = pwIdxsAllrel1{sidx1}(1);
    cidx2 = pwIdxsAllrel1{sidx1}(2);
    modelName  = [pairwiseDir '/spatial_model_cidx_' num2str(cidx1) '_' num2str(cidx2)];
    spatial_model{sidx1} = struct;
    if hist_pairwise
        spatial_model{sidx1}.diff = load(modelName,'edges1','edges2','posHist','negHist','nPos','nNeg');
    else
        m = load(modelName,'spatial_model');
        spatial_model{sidx1}.diff = struct;
        spatial_model{sidx1}.diff.log_reg = m.spatial_model.log_reg;
        spatial_model{sidx1}.diff.training_opts = m.spatial_model.training_opts;
    end
end

fprintf('recompute %d\n', bRecompute);

for i = firstidx:lastidx
    fprintf('imgidx: %d\n',i);

    cidxs_prev = [];
    for stage=1:num_stages
       
        if stagewise
            if stage > 1
                cidxs_prev = cidxs;
            end
            cidxs = sort(p.cidxs_stages{stage});
            %cidxs = p.cidxs_stages{stage};
            if p.correction_stages(stage) == 1
                cidxs_new = cidxs;
            else
                cidxs_new = sort(setdiff(cidxs, cidxs_prev));
                %cidxs_new = setdiff(cidxs, cidxs_prev);
            end
        else
            cidxs = cidxs_full;
            cidxs_new = cidxs_full;
        end

        if stagewise
            fname = [multicutDir '/imgidx_' padZeros(num2str(i),4) '_stage_' num2str(stage) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
            fname_final = [multicutDir '/imgidx_' padZeros(num2str(i),4) '_stage_' num2str(num_stages) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
            if exist(fname_final, 'file') == 2
                return;
            end
        else
            fname = [multicutDir '/imgidx_' padZeros(num2str(i),4) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
        end
        
        if stagewise
            delete([multicutDir '/imgidx_' padZeros(num2str(i),4) '_*']);
        end
        
        try
            assert(bRecompute == false);
            load(fname,'unLab','unPos','unProb', 'locationRefine');
        catch
            fprintf('loading features... ');
            im_fn = annolist(i).image.name;
            [~,im_name,~] = fileparts(im_fn);
            load(fullfile(p.unary_scoremap_dir, im_name), 'scoremaps');
            if locref
                load(fullfile(p.unary_scoremap_dir, [im_name '_locreg']), 'locreg_pred');
            end
            if nextreg
                if isfield(p, 'pairwise_scoremap_dir')
                    pairwise_scoremap_dir = p.pairwise_scoremap_dir;
                else
                    pairwise_scoremap_dir = p.unary_scoremap_dir;
                end
                load(fullfile(pairwise_scoremap_dir, [im_name '_nextreg']), 'nextreg_pred');
                nextreg_pred = nextreg_pred/p.scale_factor;
            end
            fprintf('done!\n');
            fprintf('im_name %s\n', im_name);

            im = imread(im_fn);
            im_orig = im;

            crop = get_detection_crop_2( p, annolist(i).annorect, size(im), pad_orig);
            crop_left = crop(1);
            crop_top = crop(2);
            crop_right = crop(3);
            crop_bottom = crop(4);

            im = im(crop_top:crop_bottom, crop_left:crop_right, :);

            if bVis && stage == 1
                %figure(11);
                %imagesc(im);
                figure(12);
                scmap_vis = visualise_scoremap(scoremaps);
                imshow(scmap_vis);
            end

            % perform nms for all parts
            idxsNMSall = [];
            for cidx = cidxs_new
                sm = scoremaps(:,:,cidx);
                %I = nms_grid(sm, 1);
                I = nms_distance(scoremap_to_detections(sm), nms_dist);
                idxsNMSall = sort(unique([idxsNMSall; I]));

                if cidx == 1 && false
                    figure(1);
                    imagesc(sm);
                    colorbar;

                    mask = zeros(size(sm));
                    mask(I) = 1;
                    figure(2);
                    imagesc(mask);
                    pause;
                end
            end

            num_proposals = length(idxsNMSall);
            unPos = zeros(num_proposals, 2);
            unPos_sm = zeros(num_proposals, 2);
            num_joints = length(p.pidxs);
            if locref
                locationRefine = zeros(num_proposals, num_joints, 2);
            else
                locationRefine = [];
            end
            unProb = zeros(num_proposals, num_joints);
            if nextreg
                nextReg = zeros(num_proposals, size(nextreg_pred, 3), size(nextreg_pred, 4));
            else
                nextReg = [];
            end
            for k = 1:num_proposals
                idx = idxsNMSall(k);
                [row, col] = ind2sub(size(sm), idx);
                % transform heatmap to image coordinates
                %fprintf('row, col: %d %d\n', row, col);
                crd = [col-1, row-1]*stride;
                if p.res_net
                    crd = crd + half_stride;
                end
                unPos(k, :) = double([crop_left, crop_top]-1) + crd/scale_factor;
                unPos_sm(k, :) = [col, row];
                unProb(k, :) = scoremaps(row,col,:);
                if locref
                    locationRefine(k, :, :) = squeeze(locreg_pred(row, col, :, :))*locref_scale_mul*inv_scale_factor;
                end
                if nextreg
                    nextReg(k, :, :) = squeeze(nextreg_pred(row, col, :, :));
                end
            end
            dets = Detections.make(unPos, unPos_sm, unProb, locationRefine, nextReg);
            %dets.unProb = dets.unProb(:, cidxs);
            %dets.locationRefine = dets.locationRefine(:, cidxs_new, :);

            clearvars unPos unPos_sm unProb locationRefine nextReg;

            if p.nms_locref
                idxsNMSall = [];
                for k = 1:length(cidxs_full)
                    locRefJoint = squeeze(dets.locationRefine(:, k, :));
                    refinedCoord = dets.unPos + locRefJoint;
                    locations = coord_to_scoremap(p, refinedCoord, [crop_left crop_right]);
                    locations = [locations dets.unProb(:, k)];
                    I = nms_distance(locations, p.nms_locref_dist);
                    idxsNMSall = sort(unique([idxsNMSall; I]));
                end

                fprintf('number of detections before %d after %d\n', size(dets.unProb, 1), length(idxsNMSall));

                dets = Detections.slice(dets, idxsNMSall);
            end

            min_det_score = p.min_det_score;

            % truncate based on crop:
            if true
                [~, rect_orig] = get_detection_crop(p, annolist(i).annorect, size(im));
                rect_orig = rect_orig + pad_orig;

                fprintf('crop rectangle (x, y, width, height): (%d %d %d %d)\n', ...
                        rect_orig(1), rect_orig(2), (rect_orig(3) - rect_orig(1)), (rect_orig(4) - rect_orig(2)));
                idxs = point_in_rect(dets.unPos, rect_orig);
                dets = Detections.slice(dets, idxs);
            end
            
            if isfield(p, 'split_threshold')
                dets = split_detections_by_probabilities(dets, p, cidxs_new);
            end

            if (isfield(p,'ignore_low_scores') && p.ignore_low_scores)
                if stagewise
                    idxs = get_unary_idxs_local_sort_per_class(dets.unProb(:,cidxs_new), dets_per_part(stage));
                else
                    if (isfield(p,'high_scores_per_class') && p.high_scores_per_class)
                        idxs = get_unary_idxs_local_sort(dets.unProb(:,cidxs_new), p.max_detections);
                    else
                        idxs = get_unary_idxs_global_sort(dets.unProb(:,cidxs_new), p.max_detections);
                    end
                end

                fprintf('preserve %d/%d detections\n',length(idxs),length(dets.unProb));
                dets = Detections.slice(dets, idxs);
            end
            dets.unProbNoThresh = dets.unProb;
            dets.unProb(dets.unProb < min_det_score) = 0;
            
            dets.unLab = zeros(size(dets.unPos, 1), 2, unLab_cls);
            dets.unLab(:,:) = max_sizet_val;
            
            dets_fullcidxs = copy_detections(dets);
    
            dets = slice_detections_cidxs(dets, cidxs);
            
            if stagewise && stage > 1
                
                dets_fullcidxs = Detections.merge(prev_dets, dets_fullcidxs);

                prev_dets = slice_detections_cidxs(prev_dets, cidxs);
                unLab_p = prev_dets.unLab;
                for k = 1:length(cidxs)
                    cidx = cidxs(k);
                    unLab_p( unLab_p(:,1) == cidx, 1 ) = k-1;
                end
                prev_dets.unLab = unLab_p;
                
                num_prev = size(prev_dets.unPos, 1);
                num_new = size(dets.unPos, 1);
                fprintf('stage: %d, previous dets: %d, new dets %d\n', stage, num_prev, num_new);
                dets = Detections.merge(prev_dets, dets);
            end


            if (bVis)
                figure(100);clf;
                imagesc(imread(im_fn)); axis equal; hold on;
                %[val,idx] = sort(dets.unProb(:,j),'descend');
                cb = dets.unPos;
                plot(cb(:,1),cb(:,2),'b+');
                if false
                    for j = 1:size(dets.unPos, 1)
                        text(cb(j,1),cb(j,2), num2str(j), 'Color', 'g', 'FontSize', 10);
                    end
                end

                rectangle('Position',[rect_orig(1) rect_orig(2) (rect_orig(3) - rect_orig(1)) (rect_orig(4) - rect_orig(2))]);
                if ~is_release_mode
                    pause;
                end

                %{
                figure(103);clf;
                imagesc(imread(im_fn)); axis equal; hold on;
                for j = 1:length(cidxs)
                    cb1 = unPos;
                    cb2 = unPos + squeeze(locationRefine(:, 8, :));
                    plot(cb1(:,1),cb1(:,2),'b+');
                    for k = 1:size(cb1, 1)
                       line([cb1(k,1); cb2(k,1)], [cb1(k,2); cb2(k,2)], 'Color', 'r', 'LineWidth', 1);
                    end
                end

                rectangle('Position',[rect_orig(1) rect_orig(2) (rect_orig(3) - rect_orig(1)) (rect_orig(4) - rect_orig(2))]);
                pause;
                %}
            end

            pwProb = compute_pairwise_probabilities( p, dets, cidxs, pwIdxsAllrel1, graph, ...
                                                     hist_pairwise, nextreg, spatial_model, ...
                                                     use_graph_subset);

            problemFname = [multicutDir '/problem-' padZeros(num2str(i),4) '.h5'];

            fprintf('save problem\n');
            % write problem
            solutionFname = [multicutDir '/solution-' padZeros(num2str(i),4) '.h5'];
            dataName = 'part-class-probabilities';
            write_mode = 'overwrite';
            marray_save(problemFname, dataName, dets.unProb, write_mode);

            write_mode = 'append';
            dataName =  'join-probabilities';
            marray_save(problemFname, dataName, pwProb, write_mode);

            dataName = 'coordinates-vertices';
            marray_save(problemFname, dataName, dets.unPos, write_mode);

            % solve
            singMultSwitch = 'm';
            if (isfield(p,'single_people_solver') && p.single_people_solver)
                singMultSwitch = 's';
            end

            time_limit = p.time_limit;

            solver = p.solver;

            cmd = [solver ' ' problemFname  '  ' solutionFname '  ' singMultSwitch ' ' num2str(time_limit)];

            if stagewise && stage > 1
                initSolutionFname = fullfile(multicutDir, ['init-solution-' padZeros(num2str(i),4) '-stage1' '.h5']);
                dataName = 'detection-parts-and-clusters';
                min_cl = min(dets.unLab(:, 2));
                %for k = 1:size(dets.unLab, 1)
                %    cl = dets.unLab(k, 2);
                %    if cl ~= max_val
                %         dets.unLab(k, 2) = cl - min_cl;
                %    end
                %end
		        %dets.unProb(1:20, :)
	            %dets.unLab(1:20, :)
                marray_save(initSolutionFname, dataName, dets.unLab, 'overwrite');
                cmd = [cmd ' ' initSolutionFname];
            end

            fprintf('calling solver: %s\n', cmd);

            [~,hostname] = unix('echo $HOSTNAME');
            
            fprintf('hostname: %s',hostname);
            pre_cmd = ['export GRB_LICENSE_FILE=' p.gurobi_license_file ' '];

            tic
            setenv('LD_LIBRARY_PATH', '');
            s = unix([pre_cmd cmd]);
            toc
            if (s > 0)
                error('solver error');
            end
            assert(s == 0);

            % clean up
            unix(['rm ' problemFname]);

            % load solution
            dataName = 'detection-parts-and-clusters';
            unLab = marray_load(solutionFname, dataName);

            out_dets = copy_detections(dets);
            if stagewise
                [unLab_out, unLab, idxs] = pruneDetections(unLab, dets.unProb, cidxs);
                out_dets = Detections.slice(out_dets, idxs);
                out_dets.unLab = unLab;
                prev_dets = Detections.slice(dets_fullcidxs, idxs);
                prev_dets.unLab = unLab_out;
            end
            
            if p.complete_clusters && stage == num_stages
                out_dets = complete_people_clusters(p, out_dets, unLab, cidxs, crop, ...
                                                    scoremaps, locreg_pred, nextreg_pred, ...
                                                    spatial_model);
                unLab = out_dets.unLab;
            end
            
            Detections.save(out_dets, unLab, fname);
            
            if stage == num_stages
                out_dets.unLab = unLab;
                people = compute_final_multiperson_prediction(out_dets);
                save([multicutDir '/prediction_' padZeros(num2str(i),4)], 'people');
            end
        end % catch

        if p.single_people_solver && stage == num_stages
            [detAll, pts] = compute_final_prediction_single_person(p, annolist, i, crop, out_dets, scoremaps, locreg_pred);
            finalname = [multicutDir '/prediction_' padZeros(num2str(i),4)];
            save(finalname, 'detAll');

            if bVis
                figure(7);
                clf;
                imagesc(im_orig); axis equal; hold on;
                vis_pred(pts, [], graph);
            end
        end

        if (~isdeployed && bVis)
            vis_multicut(expidx, true, i, 1, cidxs);
            if ~is_release_mode
                pause;
            end
        end
    end
    
end

fprintf('done\n');

if (isdeployed)
    close all;
end

end

function [unLab_out, unLab_new, idxs] = pruneDetections(unLab, unProb, cidxs)
    max_val = intmax(class(unLab));
    
    clusters = unique(unLab(:, 2));
    clusters(clusters == max_val) = [];
    
    idxs = [];
    
    for j = 1:length(clusters)
        cl = clusters(j);
        detections = unLab(:, 2) == cl;
        for k = 1:length(cidxs)
            cidx = cidxs(k);
            label = k-1;
            bundle = find(detections & unLab(:,1) == label);
            if isempty(bundle)
                continue;
            end
            probs = unProb(bundle, k);
            [~, I] = max(probs);
            idxs = [idxs; bundle(I)];
        end
    end
    
    unLab_new = unLab(idxs, :);
    unLab_out = unLab;
    for k = 1:length(cidxs)
        cidx = cidxs(k);
        label = k - 1;
        I = unLab(:,1) == label;
        unLab_out(I,1) = cidx;
    end
    unLab_out = unLab_out(idxs, :);

    %idxs
end

function [unPos, unPos_sm, unProb, locationRefine, nextReg, unProbNoThresh] = extract_detections(dets)
    unPos = dets.unPos;
    unPos_sm = dets.unPos_sm;
    unProb = dets.unProb;
    locationRefine = dets.locationRefine;
    nextReg = dets.nextReg;
    unProbNoThresh = dets.unProbNoThresh;
end

function dets = slice_detections_cidxs(dets, cidxs)
    dets = copy_detections(dets);
    dets.unProb = dets.unProb(:, cidxs);
    dets.locationRefine = dets.locationRefine(:, cidxs, :);
    dets.unProbNoThresh = dets.unProbNoThresh(:, cidxs);
end

function dets = copy_detections(dets_src)
    dets = struct();
    dets.unPos = dets_src.unPos;
    dets.unPos_sm = dets_src.unPos_sm;
    dets.unProb = dets_src.unProb;
    dets.locationRefine = dets_src.locationRefine;
    dets.nextReg = dets_src.nextReg;
    dets.unProbNoThresh = dets_src.unProbNoThresh;
    if isfield(dets_src, 'unLab')
        dets.unLab = dets_src.unLab;
    end
end

