function vis_bp(expidx,firstidx,nImgs)

fprintf('vis_bp()\n');

fprintf('expidx: %d\n',expidx);

p = rcnn_exp_params(expidx);
exp_dir = [p.expDir '/' p.shortName];
fprintf('exp_dir: %s\n',exp_dir);
load(p.testGT,'annolist');

lastidx = firstidx + nImgs - 1;
if (lastidx > length(annolist))
    lastidx = length(annolist);
end

if (firstidx > lastidx)
    return;
end

nParts = length(p.pidxs);
conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
infDir = [conf.cache_dir '/inference'];
visDir = [infDir '/vis'];
if (~exist(visDir,'dir'))
    mkdir(visDir);
end

figure(300); 
for imgidx = firstidx:lastidx
    fprintf('.');
    fnameVis = [visDir '/imgidx_' padZeros(num2str(imgidx),5) '.png'];
    fnameInf = [infDir '/imgidx_' padZeros(num2str(imgidx-1),5) '.mat'];
    
    if (~exist(fnameVis,'file')>0 && exist(fnameInf,'file')>0);
        clf;
        imagesc(imread(annolist(imgidx).image.name)); hold on; axis equal;
        
        load(fnameInf,'predAll');
        topPredAll = predAll;
        nTop = size(topPredAll{1},1);
        for m = 1:nParts
            c = repmat([1 0 0],nTop,1);
            scatter(topPredAll{m}(:,1),topPredAll{m}(:,2),15,c(:,:),'filled');
        end
            
        for m = 1:nParts
            c = repmat([1 0 0],nTop,1);
            [val,idxs1] = max(topPredAll{m}(:,4));
            c(idxs1,:) = repmat([0 1 0],length(idxs1),1);
            scatter(topPredAll{m}(idxs1,1),topPredAll{m}(idxs1,2),15,c(idxs1,:),'filled');
            lab = cell(length(idxs1),1);
            for i=1:length(lab)
                lab{i} = num2str(m);
            end
            text(double(topPredAll{m}(idxs1,1)),double(topPredAll{m}(idxs1,2))+10,lab,'BackgroundColor','w','verticalalignment','top','horizontalalignment','left','fontSize',6);
        end
        print(gcf, '-dpng', fnameVis);
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist));
    end
end
fprintf('done\n');
end