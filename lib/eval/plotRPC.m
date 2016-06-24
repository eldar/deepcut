% function [precision, recall, sorted_scores] = plotRPC(class_margin, true_labels, totalpos, colorVal, lineType, legendName, bPlot)
function [precision, recall] = plotRPC(precision, recall, colorVal, lineType, titleName)

% if (nargin < 7)
%     bPlot = true;
% end
% 
% N = length(true_labels);
% ndet = N;
% 
% npos = 0;
% 
% [sorted_scores, sortidx] = sort(class_margin, 'descend');
% sorted_labels = true_labels(sortidx);
% [sorted_scores, sorted_labels];
% 
% recall = zeros(ndet, 1);
% precision = zeros(ndet, 1);
% 
% for ridx = 1:ndet
%     if sorted_labels(ridx) == 1
%         npos = npos + 1;
%     end
%     
%     precision(ridx) = npos / ridx;
%     recall(ridx) = npos / totalpos;
% end

% if (bPlot)
plot(1 - precision, recall, 'color', colorVal, 'LineStyle', lineType, 'LineWidth', 3);
xlabel('1 - Precision'); ylabel('Recall');
title(titleName);
axis([0, 1, 0, 1]);
end