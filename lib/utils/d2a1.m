function [D]=d2a1(A,B)
%D2A1 Pairwise squared L2 distance along 1st axis.
% D = D2A1(A,B) Computes squared L2 (Euclidean) distance
% between all pairs of d-dimensional points in A and B.
%
% Inputs:
% A - d-by-m matrix of m d-dimensional points;
% B - d-by-n matrix of n d-dimensional points.
%
% Outputs:
% D - m-by-n matrix of pairwise distances.
%
% See also D2A2.

if nargin < 2
    D = full(A'*A);
    d = diag(D);
    D = bsxfun(@minus, d, 2*D);
    D = bsxfun(@plus, d', D);
    D = max(D, 0);
else
    D = full(A'*B);
    D = bsxfun(@minus, sum(B.^2,1), 2*D);
    D = bsxfun(@plus, sum(A.^2,1)', D);
    D = max(D, 0);
end