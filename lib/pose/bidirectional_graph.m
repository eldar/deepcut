function [ graph ] = bidirectional_graph()

ends = neighbour_joint_list();
starts = 1:length(ends);

graph = [starts, ends; ...
         ends,   starts];
graph = graph';
end

