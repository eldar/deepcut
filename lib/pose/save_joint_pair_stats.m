function save_joint_pair_stats( expidx )

p = exp_params(expidx);

pwIdxsAllrel = build_joint_pairs(p);

num_relations = length(pwIdxsAllrel);

graph = zeros(num_relations, 2);

for k = 1:num_relations
    graph(k, :) = pwIdxsAllrel{k};
end

graph = [graph; graph(:,2), graph(:,1)];

save_dir = fullfile(p.exp_dir, 'data');
load(fullfile(save_dir, 'all_pairs_stats'), 'means', 'std_devs');

means = [means; -means];
std_devs = [std_devs; std_devs];

input_file = fullfile(save_dir, 'all_stats.txt');

fid = fopen(input_file, 'wt');
write_text_matrix(fid, graph, 'graph');
write_text_matrix(fid, means, 'means');
write_text_matrix(fid, std_devs, 'std_devs');
fclose(fid);

save(fullfile(save_dir, 'all_pairs_stats_all'), 'means', 'std_devs', 'graph');

end
