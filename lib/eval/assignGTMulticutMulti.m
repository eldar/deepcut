function [scoresAll, labelsAll, nGTall] = assignGTMulticutMulti(keypointsAll,annolist,pidxsAll,parts,thresh_gt)

if (nargin < 5)
    thresh_gt = 0.5;
end

scoresAll = cell(length(pidxsAll),1);
labelsAll = cell(length(pidxsAll),1);
nGTall = zeros(length(pidxsAll),length(annolist));

for i = 1:length(pidxsAll)
    scoresAll{i} = cell(length(annolist),1);
    labelsAll{i} = cell(length(annolist),1);
end

bVis = false;

for imgidx = 1:length(annolist)
    
    fprintf('.');
    
    dist = inf(length(keypointsAll(imgidx).det),length(annolist(imgidx).annorect),length(pidxsAll));
    score = nan(length(keypointsAll(imgidx).det),length(annolist(imgidx).annorect),length(pidxsAll));
    hasDet = false(length(keypointsAll(imgidx).det),length(annolist(imgidx).annorect),length(pidxsAll));
    hasGT = false(length(keypointsAll(imgidx).det),length(annolist(imgidx).annorect),length(pidxsAll));
    
    for j = 1:length(keypointsAll(imgidx).det) % clusters

        for ridx = 1:length(annolist(imgidx).annorect) % gt people
            
            rect = annolist(imgidx).annorect(ridx);
            refDist = util_get_head_size(rect);
            points_gt = rect.annopoints.point;
            
            for i = 1:length(pidxsAll)
                pidx = pidxsAll(i);
                % part is a joint
                assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
                jidx = parts(pidx+1).pos(1);
                
                det = keypointsAll(imgidx).det{j}{jidx+1};
                if (~isempty(det))
                    point_det = det(1:2);
                    score(j,ridx,i) = det(3);
                    hasDet(j,ridx,i) = true;
                end
                pp = util_get_annopoint_by_id(points_gt, jidx);
                if (~isempty(pp))
                    hasGT(j,ridx,i) = true;
                end
                if (hasDet(j,ridx,i) && hasGT(j,ridx,i))
                    dist(j,ridx,i) = norm([pp.x pp.y] - point_det)/refDist;
                end
            end
        end
    end
    
    match = dist <= thresh_gt;
    pck = sum(match,3)./sum(hasGT,3);
    [val,idx] = max(pck,[],2);
    for j = 1:length(idx)
        pck(j,setdiff(1:size(pck,2),idx(j))) = 0;
    end
    [val,clusToGT] = max(pck,[],1);
    clusToGT(val == 0) = 0;
    
    for j = 1:length(keypointsAll(imgidx).det)
        if (ismember(j,clusToGT)) % match to GT
            ridx = find(clusToGT == j);
            
            if (bVis)
                rect = annolist(imgidx).annorect(ridx);
                points_gt = rect.annopoints.point;
                gt = cell(16,1);
                for i = 1:length(pidxsAll)
                    pidx = pidxsAll(i);
                    % part is a joint
                    assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
                    jidx = parts(pidx+1).pos(1);
                    pp = util_get_annopoint_by_id(points_gt, jidx);
                    if (~isempty(pp))
                        gt{jidx+1} = [pp.x pp.y -1];
                    end
                end
                
                img = imread(annolist(imgidx).image.name);
                figure(100); clf; subplot(1,2,1); imagesc(img); axis equal; hold on;
                vis_multicut2(keypointsAll(imgidx).det{j},pidxsAll,parts);
                subplot(1,2,2); imagesc(img); axis equal; hold on;
                vis_multicut2(gt,pidxsAll,parts);
            end
            
            s = squeeze(score(j,ridx,:));
            m = squeeze(match(j,ridx,:));
            hd = squeeze(hasDet(j,ridx,:));
            
            idxs = find(hd);
            for i = 1:length(idxs)
                scoresAll{idxs(i)}{imgidx} = [scoresAll{idxs(i)}{imgidx};s(idxs(i))];
                labelsAll{idxs(i)}{imgidx} = [labelsAll{idxs(i)}{imgidx};m(idxs(i))];
            end
            
        else % no matching to GT
            s = squeeze(score(j,1,:));
            m = false(size(match,3),1);
            hd = squeeze(hasDet(j,ridx,:));
            idxs = find(hd);
            for i = 1:length(idxs)
                scoresAll{idxs(i)}{imgidx} = [scoresAll{idxs(i)}{imgidx};s(idxs(i))];
                labelsAll{idxs(i)}{imgidx} = [labelsAll{idxs(i)}{imgidx};m(idxs(i))];
            end
        end
    end
    
    for ridx = 1:length(annolist(imgidx).annorect)
        hg = squeeze(hasGT(1,ridx,:));
%         idxs = find(hg);
%         for i = 1:length(idxs)
%             nGTall(idxs(i),imgidx) = nGTall(idxs(i),imgidx) + hg(idxs(i));
%         end
        nGTall(:,imgidx) = nGTall(:,imgidx) + hg;
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
    end
end
fprintf(' done\n');
end