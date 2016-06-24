function [posterior,posLikelihood] = computePosterior2D(feat,edges1,edges2,posHist,negHist,nPos,nNeg)

assert(size(feat,2) == 2);

posterior = zeros(size(feat,1),1);
posLikelihood = zeros(size(feat,1),1);

[~,ind1] = histc(feat(:,1),edges1);
[~,ind2] = histc(feat(:,2),edges2);

for i=1:length(ind1)
    posterior(i) = posHist(ind1(i),ind2(i))*nPos/(nPos+nNeg)./(posHist(ind1(i),ind2(i))*nPos/(nPos+nNeg) + negHist(ind1(i),ind2(i))*nNeg/(nPos+nNeg));
    posLikelihood(i) = posHist(ind1(i),ind2(i));
end
    
end