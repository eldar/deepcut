function [ res ] = extract_pair_distribution( p, distr, j1, j2 )
num_c = p.idpr_num_clusters;

res = distr(idpr_joint_range(j1, num_c), idpr_joint_range(j2, num_c));

end

function res = idpr_joint_range(joint_no, num_clusters)
  s = sum(num_clusters(1:joint_no-1));
  res = s+1:s+num_clusters(joint_no);
end