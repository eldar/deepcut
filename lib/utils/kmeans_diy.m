function [ cur_group ] = kmeans_diy( input_data, k )
n = size(input_data, 1);
d = size(input_data, 2);
% initialise means from random samples
means = input_data(randsample(n, k), :);
% main loop
newmeans = zeros(k,d);
scores = zeros(n, k);
change = Inf;
while change > eps
    % assign labels to data points according to distances to the means
    for j = 1:k
        diff = bsxfun(@minus, input_data, means(j,:));
        scores(:,j) = sqrt(sum(diff.^2,2));
    end
    [~,cur_group] = min(scores, [], 2);
    % recompute means based on obtained labelings
    for j = 1:k
        newmeans(j,:) = mean(input_data(cur_group == j,:));
    end
    % stopping criteria
    change = sqrt(sum(sum((newmeans-means).^2, 1), 2))/k;
    means = newmeans;
end
end