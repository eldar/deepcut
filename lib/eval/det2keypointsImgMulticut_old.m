function [keypointsAll, imgidxs_missing] = det2keypointsImgMulticut(expidx,parts,annolist_gt,bAllPartsOn)

fprintf('det2keypointsImgMulticut()\n');

if (nargin < 4)
    bAllPartsOn = false;
end

p = rcnn_exp_params(expidx);

predDir = p.multicutDir;
%{
if (isfield(p,'predDir'))
    predDir = [p.predDir '/multicut/'];
else
    conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
    predDir = [conf.cache_dir '/multicut/'];
end
%}
keypointsAll = repmat(struct('imgname','','det',nan(16,3)), length(annolist_gt), 1);

if (isfield(p,'oracleClusEval'))
    oracleClusEval = p.oracleClusEval;
else
    oracleClusEval = false;
end

if (isfield(p,'oracleEval'))
    oracleEval = p.oracleEval;
else
    oracleEval = false;
end

if (isfield(p,'oracleSymmEval'))
    oracleSymmEval = p.oracleSymmEval;
else
    oracleSymmEval = false;
end

sim_class_id = [
    6
    5
    4
    3
    2
    1
    12
    11
    10
    9
    8
    7
    13
    14
];

cidxs = p.cidxs;

nmissing = 0;
imgidxs_missing = [];
for imgidx = 1:length(annolist_gt)
    
    fprintf('.');
        
    keypointsAll(imgidx).imgname = annolist_gt(imgidx).image.name;
    
    fname = [predDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
    try
        load(fname,'unLab','unPos','unProb');
    catch
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            jidx = parts(pidx+1).pos(1);
            keypointsAll(imgidx).det(jidx+1,:) = [inf inf -1];
        end
        nmissing = nmissing + 1;
        imgidxs_missing = [imgidxs_missing; imgidx];
        continue;
    end
    

    img = imread(annolist_gt(imgidx).image.name);
    [Y,X,~] = size(img);
    Y = 0.5*Y; X = 0.5*X;

%     X = annolist_gt(imgidx).annorect.objpos.x;
%     Y = annolist_gt(imgidx).annorect.objpos.y;
    
    rect = annolist_gt(imgidx).annorect;
    refDist = util_get_torso_size(rect);
    for i = 1:length(p.pidxs)
        if (~ismember(i,cidxs))
            continue;
        end
        pidx = p.pidxs(i);
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);
                
%         detidxs = find(unLab(:,1) == i-1);
        detidxs = find(unLab(:,1) == find(cidxs == i)-1);
        if (isempty(detidxs))
            if (bAllPartsOn)
%                 [val,idx] = max(unProb(:,i));
                [val,idx] = max(unProb(:,find(cidxs == i)));
                det = unPos(idx,:);
            else
                det = [inf inf];
            end
        else
            clusidxs = unLab(detidxs,2);
            clusidxsUniq = unique(clusidxs);
            nExClus = zeros(length(clusidxsUniq),1);
            clusMean = zeros(length(clusidxsUniq),2);
            for j = 1:length(clusidxsUniq)
                nExClus(j) = length(find(unLab(:,2) == clusidxsUniq(j)));
                clusMean(j,:) = mean(unPos(unLab(:,2) == clusidxsUniq(j),:),1);
            end
            d = sqrt(sum((clusMean - repmat([X Y],size(clusMean,1),1)).^2,2));
            [val,id] = sort(d,'ascend');
%             detidxs = find(unLab(:,1) == i-1 & unLab(:,2) == clusidxsUniq(id(1)));
            detidxs = find(unLab(:,1) == find(cidxs == i)-1 & unLab(:,2) == clusidxsUniq(id(1)));
            
%             mean between the two closest
%             d = inf(length(detidxs),length(detidxs));
%             for j = 1:length(detidxs)
%                 d(j,:) = sqrt(sum((repmat(unPos(detidxs(j),:),length(detidxs),1) - unPos(detidxs,:)).^2,2));
%             end
%             for j = 1:length(detidxs)
%                 d(j,j) = inf;
%             end
%             idx = find(d==min(min(d)));
%             [rx,cx] = ind2sub(size(d),idx);
%             det = mean(unPos(detidxs([rx(1) cx(1)]),:),1);
             
%             weighted sum excluding outliers
%             if (length(detidxs) > 2)
%                 d = inf(length(detidxs),length(detidxs));
%                 for j = 1:length(detidxs)
%                     d(j,:) = sqrt(sum((repmat(unPos(detidxs(j),:),length(detidxs),1) - unPos(detidxs,:)).^2,2));
%                 end
%                 dd = sum(d,2);
%                 [val,id2] = sort(dd,'descend');
%                 detidxs = detidxs(2:end);
%             end
%             w = unProb(detidxs,i);
%             w = w./sum(w);
%             det = sum(unPos(detidxs,:).*[w w],1);

%             medoid
%             m = mean(unPos(detidxs,:),1);
%             d = sqrt(sum((repmat(m,length(detidxs),1) - unPos(detidxs,:)).^2,2));
%             [val,id2] = min(d);
%             det = unPos(detidxs(id2),:);

%             maximum    
%             [val,idx] = max(unProb(detidxs));
%             det = unPos(detidxs(idx),:);

%             weighted sum
%             w = unProb(detidxs,i);
            w = unProb(detidxs,find(cidxs == i));
            w = w./sum(w);
            det = sum(unPos(detidxs,:).*[w w],1);
            
            if (oracleEval || oracleClusEval || oracleSymmEval)
                if (oracleEval)
                    detidxs = 1:size(unPos,1);
                elseif (oracleSymmEval)
%                     detidxs = [detidxs; find(unLab(:,1) == sim_class_id(i)-1)];
                    detidxs = [detidxs; find(unLab(:,1) == sim_class_id(find(cidxs == i))-1)];
                end
                pp = util_get_annopoint_by_id(rect.annopoints.point, jidx);
                d = sqrt(sum((repmat([pp.x pp.y],size(unPos(detidxs,:),1),1) - unPos(detidxs,:)).^2,2))./refDist;
                [val,id] = min(d);
                det = unPos(detidxs(id),:);
            end
            
            % DEBUG
%             [val,id] = max(unProb(detidxs,i));
%             det = unPos(detidxs(id),:);
%             figure(100); clf; imagesc(img); axis equal; hold on;
%             detidxsAll = unLab(:,2) == clusidxsUniq(id(1));
%             plot(unPos(detidxsAll,1),unPos(detidxsAll,2),'r+','Markersize',10);
%             plot(unPos(detidxs,1),unPos(detidxs,2),'b+','Markersize',10);
%             plot(det(:,1),det(:,2),'y+','Markersize',10);
        end
        
        % part is a joint
        keypointsAll(imgidx).det(jidx+1,:) = [det,-1];
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
    end
end
fprintf(' done\n');
fprintf('nmissing: %d\n',nmissing);

end