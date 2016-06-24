function [ unary_scores ] = cnn_to_unary_scores( p, cnn_score )
% transforms CNN output to unary scores, converting from IDPR when needed

num_joints = 14;

if isfield(p, 'idpr') && p.idpr
    unary_scores = zeros(size(cnn_score, 1), num_joints);
    s_j = 1;
    for j = 1 : num_joints
        num_cl = p.idpr_num_clusters(j);
        unary_scores(:, j) = sum(cnn_score(:, s_j:s_j+num_cl-1), 2);
        s_j = s_j + num_cl;
    end
else
    unary_scores = cnn_score;
end

end

