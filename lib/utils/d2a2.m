function [D]=d2a2(A,B)
%D2A2 Pairwise squared L2 distance along 2nd axis.
% D = D2A2(A,B) Computes squared L2 (Euclidean) distance
% between all pairs of d-dimensional points in A and B.
%
% Inputs:
% A - m-by-d matrix of m d-dimensional points;
% B - n-by-d matrix of n d-dimensional points.
%
% Outputs:
% D - m-by-n matrix of pairwise distances.
%
% See also D2A1.
if nargin < 2
D = full(A*A');
d = diag(D);
D = bsxfun(@minus, d, 2*D);
D = bsxfun(@plus, d', D);
D = max(D, 0);
else
D = full(A*B');
D = bsxfun(@minus, sum(B.^2,2)', 2*D);
D = bsxfun(@plus, sum(A.^2,2), D);
D = max(D, 0);
end