function [keypointsAll, imgidxs_missing]= det2keypointsImgMulticutBBoxMulti(expidx,parts,annolist_bbox,bDisjoint)

fprintf('det2keypointsImgMulticutBBoxMulti()\n');

if (nargin < 4)
    bDisjoint = false;
end

p = exp_params(expidx);

multicutDir = p.multicutDir;
cidxs = p.cidxs;
keypointsAll = [];

if (isfield(p,'nPeopleMax'))
    nPeopleMax = p.nPeopleMax;
else
    nPeopleMax = inf;
end

if (isfield(p,'nPeopleMin'))
    nPeopleMin = p.nPeopleMin;
else
    nPeopleMin = 0;
end

load(p.testGT,'annolist');

assert(length(annolist) == length(annolist_bbox));

nmissing = 0;
bVis = false;
imgidxs_missing = [];

for imgidx = 1:length(annolist_bbox)
    
    fprintf('.');
    fname = [multicutDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
    
    try
        assert(length(annolist(imgidx).annorect) >= nPeopleMin && ...
            length(annolist(imgidx).annorect) <= nPeopleMax);
        load(fname,'unLab','unPos','unProb');
    catch
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            jidx = parts(pidx+1).pos(1);
            keypointsAll(imgidx).det{1}{jidx+1} = [];
        end
        imgidxs_missing = [imgidxs_missing; imgidx];
        nmissing = nmissing + 1;
        if (~mod(imgidx,100))
            fprintf(' %d/%d\n',imgidx,length(annolist_bbox));
        end
        continue;
    end
    
    for ridx = 1:length(annolist_bbox(imgidx).annorect) 
        
        bbox = annolist_bbox(imgidx).annorect(ridx).bbox;
        if (~isempty(bbox))
            idxs = find((unPos(:,1) >= bbox(1) & unPos(:,2) >= bbox(2) & ...
                unPos(:,1) <= bbox(3) & unPos(:,2) <= bbox(4)));
            
            for i = 1:length(p.pidxs)
                pidx = p.pidxs(i);
                assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
                jidx = parts(pidx+1).pos(1);
                det = [];
                id = find(cidxs == i);
                if (~isempty(id))
                    [val,idx] = max(unProb(idxs,id));
                    det = [unPos(idxs(idx),:) val];
                    if (bDisjoint)
                        unProb(idxs(idx),:) = -inf;
                    end
                end
                keypointsAll(imgidx).det{ridx}{jidx+1} = det;
            end
        else
            for i = 1:length(p.pidxs)
                pidx = p.pidxs(i);
                assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
                jidx = parts(pidx+1).pos(1);
                keypointsAll(imgidx).det{ridx}{jidx+1} = [];
            end
        end
    end
    
    if (bVis)
        colors = {'r','g','b','c','m','y'};
        markers = {'+','o','s'}; %,'x','.','-','s','d'
        img = imread(annolist_bbox(imgidx).image.name);
        figure(100); clf; imagesc(img); axis equal; hold on;
        for j = 1:length(keypointsAll(imgidx).det)
            labels = cell(0);
            n = 0;
            points = zeros(1,2);
            for i = 1:length(p.pidxs)
                pidx = p.pidxs(i);
                jidx = parts(pidx+1).pos(1);
                pp = keypointsAll(imgidx).det{j}{jidx+1};
                if (~isempty(pp))
                    n = n  + 1;
                    labels{n} = num2str(i);
%                     labels{n} = sprintf('%1.2f',pp(3));
                    points(n,:) = pp(1:2);
                end
            end
            lp = j;
            if (lp <= 5)
                m = markers{1};
            elseif (lp > 5 && lp <= 11)
                m = markers{2};
            else
                m = markers{3};
            end
            plot(points(:,1),points(:,2),[colors{mod(lp,6)+1} m],'MarkerSize',5);
            text(points(:,1)+10,points(:,2),labels,'FontSize',6,'BackgroundColor','w');
            axis off;
        end
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist_bbox));
    end
end
fprintf(' done\n');
fprintf('nmissing: %d\n',nmissing);

end