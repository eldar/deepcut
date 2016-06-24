function e = compute_idpr_entropy( distr )

e1 = 0;
for i = 1:size(distr, 1)
    e1 = e1 + compute_entropy(distr(i,:));
end
e1 = e1/size(distr, 1)

e2 = 0;
for i = 1:size(distr, 2)
    e2 = e2 + compute_entropy(distr(:,i));
end
e2 = e2/size(distr, 2)



e = compute_entropy(distr(:));

end

function e = compute_entropy(prob)
positives = prob>0;
prob = prob(positives)/sum(prob);
e = -sum(prob .* log2(prob));
end