function  plot_RP_pairwise( expidx )
% Plots RPC for pairwise

joint_names = {'r ankle', 'r knee', 'r hip', 'l hip', 'l knee', 'l ankle', ...
               'r wrist', 'r elbow', 'r shoulder', 'l shoulder', 'l elbow', 'l wrist', ...
               'chin', 'top head'};
               
colours = ['b' 'r' 'g'];

pw_prob_all = cell(length(expidx), 1);
is_pw_gt_all = cell(length(expidx), 1);

names = cell(1);

for k = 1:length(expidx)
    p = exp_params(expidx(k));

    out_dir = fullfile(p.exp_dir, 'tmp');
    filename = fullfile(out_dir, 'pw_prob_gt_allpairs');
    load(filename, 'pw_prob', 'is_pw_gt');
    pw_prob_all{k} = pw_prob;
    is_pw_gt_all{k} = is_pw_gt;
    names{k} = p.name;
end

num_joints = 14;

pw_idx = 1;
for m = 1:num_joints-1
    for n = m+1:num_joints

        clf;
        hold on;
        
        pr = cell(1);
        rc = cell(1);

        for k = 1:length(expidx)
            
            pw_prob = pw_prob_all{k};
            pw_prob = pw_prob(:, pw_idx);
            is_pw_gt = is_pw_gt_all{k};
            is_pw_gt = is_pw_gt(:, pw_idx);

            [~, I] = sort(pw_prob, 'descend');
            is_pw_gt_sorted = is_pw_gt(I);

            num_all_gt = sum(is_pw_gt);

            curr_num_gt = 0;

            bins = false;
            if bins
                num_bins = 200000;
                precision = zeros(num_bins, 1);
                recall = zeros(num_bins, 1);

                num_samples = length(pw_prob);
                prev_idx = 1;
                for i = 1:num_bins
                    curr_idx = round(i/num_bins*num_samples);
                    curr_num_gt = curr_num_gt + sum(is_pw_gt_sorted(prev_idx:curr_idx));
                    precision(i) = curr_num_gt / curr_idx;
                    recall(i) = curr_num_gt / num_all_gt;
                    prev_idx = curr_idx;
                end
            else
                num_bins = length(is_pw_gt_sorted);
                precision = zeros(num_bins, 1);
                recall = zeros(num_bins, 1);

                %cumsum(is_pw_gt_sorted);
                i = 1;
                j = 1;
                curr_recall = 0.0;
                while curr_recall < 0.99
                    is_gt = is_pw_gt_sorted(i);
                    if is_gt
                        curr_num_gt = curr_num_gt + 1;
                        precision(j) = curr_num_gt / i;
                        curr_recall = curr_num_gt / num_all_gt;
                        recall(j) = curr_recall;
                        j = j + 1;
                    end
                    i = i + 1;
                end
                precision(j:end) = [];
                recall(j:end) = [];
            end

            pr{k} = 1-precision;
            rc{k} = recall;
        end

        if length(pr) == 1
            plot(pr{1}, rc{1}, colours(1));
            legend(names{1});
        else
            plot(pr{1}, rc{1}, colours(1), pr{2}, rc{2}, colours(2));
            legend(names{1}, names{2});
        end

        title(sprintf('RPC pairwise (%s)-(%s)', joint_names{m}, joint_names{n}));
        axis([0.0 1.0 0.0 1.0]);
        xlabel('1-Precision');
        ylabel('Recall');
        
        plot_dir = '/BS/eldar/work/pose/misc/pairwise-rpc-plots';
        print(gcf, '-dpng', fullfile(plot_dir, sprintf('pairwise_%d_%d.png', m, n)));
        fprintf('pairwise %d-%d complete\n', m, n);

        %pause;
        pw_idx = pw_idx + 1;
    end
end


end

