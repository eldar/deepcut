function vis_logreg(pred,acc,idxPos,idxNeg)

p1_pos =  pred(idxPos,1);
p1_neg =  pred(idxNeg,1);
cost_pos = log((1-p1_pos)./p1_pos);
cost_neg = log((1-p1_neg)./p1_neg);

% vis_violate_pairwise(cost_positive, cost_negative);

% visualize training examples VS pairwise cost
thr_cost = 5;
x_range_cost = -thr_cost:0.1:thr_cost;
x_range_prob =  0:0.01:1;

% positive
subplot(2,3,1); 
[hist_cost_pos,x] = hist(cost_pos, x_range_cost);
bar(x,hist_cost_pos);  
xlim([x_range_cost(1), x_range_cost(end)]);
title(['Accuracy: ' num2str(acc(1))]);

hist_cost_pos = hist_cost_pos./sum(hist_cost_pos);
subplot(2,3,2); 
plot(x_range_cost,hist_cost_pos,'Linewidth',2); 
title('norm cost');

subplot(2,3,3); 
plot(x_range_cost,cumsum(hist_cost_pos) ,'Linewidth',2); 
title('cum norm cost');ylim([0, 1]); % plot cumulative normalized histogram

% negative
subplot(2,3,1);hold on; 
[hist_cost_neg,x] =  hist(cost_neg, x_range_cost);
bar(x,hist_cost_neg, 'r');
xlim([x_range_cost(1), x_range_cost(end)]); 
title('cost');
legend('pos ex costs', 'neg ex costs');
hist_cost_neg = hist_cost_neg./sum(hist_cost_neg);

subplot(2,3,2); hold on;  
plot(x_range_cost,hist_cost_neg, 'Color','r'); 
title('norm cost');
legend('pos ex costs', 'neg ex costs');
subplot(2,3,3); hold on; 
plot(x_range_cost,cumsum(hist_cost_neg), 'Color','r', 'Linewidth',2); 
title('cum norm cost');ylim([0, 1]); % plot cumulative normalized histogram
legend('pos ex costs', 'neg ex costs');

% visualize training example VS pairwise probability
% positive
subplot(2,3,4);[g1_pos,x] =  hist(p1_pos,x_range_prob);
bar(x,g1_pos); 
xlim([x_range_prob(1), x_range_prob(end)]); 
title('hist of probability');  % plot histogram of distance

g1_pos = g1_pos./sum(g1_pos);
subplot(2,3,5); plot(x_range_prob, g1_pos); title('norm prob'); % plot normalized histogram

subplot(2,3,6); 
plot(x_range_prob,cumsum(g1_pos), 'Linewidth',2);
title('cum norm prob'); ylim([0, 1]); % plot cumulative normalized histogram

% negative
subplot(2,3,4); hold on; 
[g1_neg,x] = hist(p1_neg,x_range_prob); 
bar(x,g1_neg,  'r'); xlim([x_range_prob(1), x_range_prob(end)]); 
title('prob');% plot histogram of distance
legend('p(i) = 1 pos ', 'p(i) = 1 neg');

g1_neg = g1_neg./sum(g1_neg);
subplot(2,3,5);hold on;
plot(x_range_prob,g1_neg,'Color','r'); 
title('norm prob'); % plot normalized histogram
legend('p(i) = 1 pos ', 'p(i) = 1 neg');

subplot(2,3,6); hold on; 
plot(x_range_prob, cumsum(g1_neg), 'Color','r','Linewidth',2); 
title('cum norm prob');ylim([0, 1]);% plot cumulative normalized histogram
legend('p(i) = 1 pos ', 'p(i) = 1 neg');
end