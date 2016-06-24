function [prior,binSize] = part_location_prior_pairwise(expidx)

p = rcnn_exp_params(expidx);
exp_dir = [p.expDir '/' p.shortName];

conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', exp_dir);
saveTo = [conf.cache_dir '/pairwise_prior/'];
if (~exist(saveTo,'dir'))
    mkdir(saveTo);
end

% sc = p.refHeight/200;
sc = 2;
binSize = 10*sc;%;p.prior_bin_size*sc;
delta = 300*sc;
nBins = round(2*delta/binSize);
spatidxsAll = p.spatidxs;

fname = [saveTo '/prior'];
try
    assert(false);
    load(fname, 'prior');
catch
    load(p.trainGT);
    
    [~,parts] = util_get_parts24();

    nParts = length(p.pidxs);
    prior = zeros(2*delta,2*delta,length(spatidxsAll));
    histLoc = zeros(nBins,nBins,nParts);
    nEx = zeros(nParts,1);
    X0 = size(prior,1)/2;
    Y0 = size(prior,2)/2;
    
    distAll = nan(length(annolist),length(spatidxsAll));
    
    for imgidx = 1:length(annolist)
        fprintf('.');
        rect = annolist(imgidx).annorect;
        
        for ridx = 1:length(rect)
            points = rect(ridx).annopoints.point;
            
            for sidx = 1:length(spatidxsAll)
                spatidxs = spatidxsAll{sidx};
                pidx1 = spatidxs(1)+1;
                pidx2 = spatidxs(2)+1;
                assert(parts(pidx1).pos(1) == parts(pidx1).pos(2));
                assert(parts(pidx2).pos(1) == parts(pidx2).pos(2));
                p1 = util_get_annopoint_by_id(points,parts(pidx1).pos(1));
                p2 = util_get_annopoint_by_id(points,parts(pidx2).pos(1));
                if (~isempty(p1)&&~isempty(p2))
                    distAll(imgidx,sidx) = norm([p1.x p1.y]-[p2.x p2.y]);
                    iy = round(Y0 + sc*(p1.y - p2.y));
                    ix = round(X0 + sc*(p2.x - p1.x));
                    if (iy >= 1 && iy <= 2*delta && ix >= 1 && ix <= 2*delta)
                        iy = max(iy,1);
                        iy = min(iy,2*delta);
                        ix = max(ix,1);
                        ix = min(ix,2*delta);
                        iy_hist = ceil(iy/binSize);
                        ix_hist = ceil(ix/binSize);
                        histLoc(iy_hist,ix_hist,sidx) = histLoc(iy_hist,ix_hist,sidx) + 1;
                        iy_prior = (iy_hist-1)*binSize+1:iy_hist*binSize;
                        ix_prior = (ix_hist-1)*binSize+1:ix_hist*binSize;
                        prior(iy_prior,ix_prior,sidx) = prior(iy_prior,ix_prior,sidx) + ones(binSize,binSize);
                        nEx(sidx) = nEx(sidx) + 1;
                    end
                end
                
            end
        end
        if (~mod(imgidx, 100))
            fprintf(' %d/%d\n',imgidx,length(annolist));
        end
    end
    fprintf(' done\n');
    if (isfield(p,'sigma_gauss'))
        sigma_gauss = p.sigma_gauss;
    else
        sigma_gauss = binSize*2;
    end
    for sidx = 1:length(spatidxsAll)
        prior(:,:,sidx) = prior(:,:,sidx)/max(max(prior(:,:,sidx)));
        pr = prior(:,:,sidx);
%         pr(pr > 0) = 1;
%         se = strel('disk',2*binSize);
%         pr = imclose(pr,se);
%         prior(:,:,sidx) = pr;
        filterMask = gausswin(2*sigma_gauss+1)*gausswin(2*sigma_gauss+1)';
        prior(:,:,sidx) = filter2(filterMask, pr);%/nEx(pidx);
        prior(:,:,sidx) = prior(:,:,sidx)/max(max(prior(:,:,sidx)));
    end
    nBinsHist = 20;
    priorHist = zeros(nBinsHist+1,length(spatidxsAll));
    binRanges = zeros(nBinsHist+1,length(spatidxsAll));
    for sidx = 1:length(spatidxsAll)
        idxs = ~isnan(distAll(:,sidx));
        m = mean(distAll(idxs,sidx));
        s = std(distAll(idxs,sidx));
        maxD = m + 4*s;
        minD = max(m - 4*s,0);
        binS = (maxD - minD)/nBinsHist;
        edges = minD:binS:maxD;
        N = histc(distAll(idxs,sidx),edges);
        figure(100); clf;
        bar(N/sum(N));
        priorHist(:,sidx) = N/sum(N);
        binRanges(:,sidx) = edges;
    end
    
    save(fname, 'prior', 'priorHist', 'binRanges');
end

labels = {'l-shoulder','r-shoulder','head','r-hip','l-hip','ru-arm','lu-arm','ru-leg','lu-leg','rl-leg','ll-leg','rl-arm','ll-arm'};
tics = [1 size(prior,1)/6:size(prior,1)/6:size(prior,1)];
for sidx = 1:length(spatidxsAll)
    figure(101);clf;%colormap gray;
    pr = prior(:,:,sidx);
%     imagesc(log(log(pr+1))); hold on; axis equal;
    imagesc(pr); hold on; axis equal;
    plot([size(prior,2)/2; size(prior,2)/2], [1; size(prior,1)]', 'k-', 'lineWidth', 2);
    plot([1; size(prior,2)], [size(prior,1)/2; size(prior,1)/2]', 'k-', 'lineWidth', 2);
    title([labels{sidx}]);
    set(gca,'XTick',tics,'YTick',tics);
    set(gca,'YDir','normal');
    fImgName = [saveTo '/partDetHist_' labels{sidx}];
    print(gcf, '-dpng', [fImgName '.png']);
end
end