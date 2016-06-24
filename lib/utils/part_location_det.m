function [prior,binSize] = part_location_det(expidx)

p = rcnn_exp_params(expidx);
exp_dir = [p.expDir '/' p.shortName];

conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', exp_dir);
% saveTo = [conf.cache_dir '/gtHist/'];
saveTo = [conf.cache_dir '/detHist/'];
if (~exist(saveTo,'dir'))
    mkdir(saveTo);
end

% sc = p.refHeight/200;
sc = 2;
binSize = p.prior_bin_size*sc;
delta = 300*sc;
nBins = round(2*delta/binSize);

try
    assert(false);
%     load(fname, 'prior');
catch
%     load(p.testGT);
    load(p.trainGT);
%     if (exist('single_person_annolist','var'))
%         annolist = single_person_annolist;
%     end
    
    fnameDist = [fileparts(p.evalTest) '/distAll'];
    load(fnameDist, 'keypointsAll');
    assert(length(keypointsAll) == length(annolist));
    
    [~,parts] = util_get_parts24();
    nParts = length(p.pidxs);
    prior = zeros(2*delta,2*delta,nParts);
    histLoc = zeros(nBins,nBins,nParts);
    nEx = zeros(nParts,1);
    X0 = size(prior,1)/2;
    Y0 = size(prior,2)/2;
    
    for imgidx = 1:length(annolist)
        fprintf('.');
        rect = annolist(imgidx).annorect;
        for ridx = 1:length(rect)
            objpos = rect(ridx).objpos;
            points = rect(ridx).annopoints.point;
            for pidx = 1:length(parts)
                pidxLin = find(p.pidxs == parts(pidx).id);
                if (~isempty(pidxLin))
                    assert(parts(pidx).pos(1) == parts(pidx).pos(2));
%                     pp = util_get_annopoint_by_id(points,parts(pidx).pos(1));
                    pp = keypointsAll(imgidx).det(parts(pidx).pos(1)+1,1:2);
                    if (~isempty(pp))
                        iy = round(Y0 + sc*(pp(:,2) - objpos.y));
                        ix = round(X0 + sc*(pp(:,1) - objpos.x));
%                         iy = round(Y0 + sc*(pp.y - objpos.y));
%                         ix = round(X0 + sc*(pp.x - objpos.x));
                        iy = max(iy,1);
                        iy = min(iy,2*delta);
                        ix = max(ix,1);
                        ix = min(ix,2*delta);
                        iy_hist = ceil(iy/binSize);
                        ix_hist = ceil(ix/binSize);
                        histLoc(iy_hist,ix_hist,pidxLin) = histLoc(iy_hist,ix_hist,pidxLin) + 1;
                        iy_prior = (iy_hist-1)*binSize+1:iy_hist*binSize;
                        ix_prior = (ix_hist-1)*binSize+1:ix_hist*binSize;
                        prior(iy_prior,ix_prior,pidxLin) = prior(iy_prior,ix_prior,pidxLin) + ones(binSize,binSize);
                        nEx(pidxLin) = nEx(pidxLin) + 1;
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
        sigma_gauss = binSize;
    end
    for pidx = 1:nParts
%         prior(:,:,pidx) = prior(:,:,pidx)/nEx(pidx);
        prior(:,:,pidx) = prior(:,:,pidx)/max(max(prior(:,:,pidx)));
%         pr = prior(:,:,pidx);
%         pr(pr > 0) = 1;
%         filterMask = gausswin(2*sigma_gauss+1)*gausswin(2*sigma_gauss+1)';
%         prior(:,:,pidx) = filter2(filterMask, pr);%/nEx(pidx);
%         prior(:,:,pidx) = prior(:,:,pidx)/max(max(prior(:,:,pidx)));
    end
%     save(fname, 'prior');
end

labels = {'rankle','rknee','rhip','lhip','lknee','lankle','rwrist','relbow','rshoulder','lshoulder','lelbow','lwrist','neck','tophead'};
tics = [1 size(prior,1)/6:size(prior,1)/6:size(prior,1)];
for pidx = 1:length(parts)
    figure(101);clf;%colormap gray;
    pidxLin = find(p.pidxs == parts(pidx).id);
    if (~isempty(pidxLin))
        pr = prior(:,:,pidxLin);
        imagesc(log(log(pr+1))); hold on; axis equal;
        plot([size(prior,2)/2; size(prior,2)/2], [1; size(prior,1)]', 'k-', 'lineWidth', 2);
        plot([1; size(prior,2)], [size(prior,1)/2; size(prior,1)/2]', 'k-', 'lineWidth', 2);
        title([labels{pidxLin}]);
        set(gca,'XTick',tics,'YTick',tics);
        fImgName = [saveTo '/partDetHist_' labels{pidxLin}];
        print(gcf, '-dpng', [fImgName '.png']);
    end
end
end