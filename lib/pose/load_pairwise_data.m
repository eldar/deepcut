function [ pairwise ] = load_pairwise_data( p )

pairwise = struct();
pairwise.graph = [];
nextreg = p.nextreg;

if nextreg
    load(p.pairwise_relations, 'means', 'std_devs', 'graph');
    std_devs = permute(std_devs, [3 4 1 2]);
    means = permute(means, [3 4 1 2]);
    pairwise.graph = graph;
    pairwise.means = means;
    pairwise.std_devs = std_devs;
end


end

