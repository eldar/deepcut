function [ pwIdxsAllrel1 ] = build_pairwise_pairs( cidxs )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

pwIdxsAllrel1 = cell(0);
n = 0;
for i = 1:length(cidxs)-1
  for j = i+1:length(cidxs)
    n = n + 1;
    pwIdxsAllrel1{n} = [cidxs(i) cidxs(j)];
  end
end

end

