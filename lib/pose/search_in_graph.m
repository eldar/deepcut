function [is_neighbor, forward_edge, backward_edge] = search_in_graph(graph, cidx1, cidx2)
    [~,forward_edge]  = ismember([cidx1 cidx2], graph, 'rows');
    [~,backward_edge] = ismember([cidx2 cidx1], graph, 'rows');

    is_neighbor = forward_edge ~= 0 && backward_edge ~= 0;
end