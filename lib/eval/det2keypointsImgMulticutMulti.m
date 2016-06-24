function [keypointsAll, imgidxs_missing]= det2keypointsImgMulticutMulti(expidx,parts,annolist,clusSizeThresh)

fprintf('det2keypointsImgMulticutMulti()\n');

if (nargin < 4)
    clusSizeThresh = 0;
end

p = exp_params(expidx);
multicutDir = p.multicutDir;

if ~p.stagewise
    cidxs = p.cidxs;
else
    num_stages = length(p.cidxs_stages);
    cidxs = sort(p.cidxs_stages{num_stages});
end

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

nmissing = 0;
bVis = false;
imgidxs_missing = [];

for imgidx = 1:length(annolist)
    
    fprintf('.');
    keypointsAll(imgidx).imgname = annolist(imgidx).image.name;
    if ~p.stagewise
        fname = [multicutDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
    else
        %files = dir([predDir '/imgidx_' padZeros(num2str(imgidx),4) '*']);
        %fname = '';
        %if ~isempty(files)
        %    fname = fullfile(predDir, files(length(files)).name);
        %end
        fname = [multicutDir '/imgidx_' padZeros(num2str(imgidx),4) '_stage_' num2str(num_stages) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end)) '.mat'];
    end
    
    try
        assert(length(annolist(imgidx).annorect) >= nPeopleMin && ...
            length(annolist(imgidx).annorect) <= nPeopleMax);
        load(fname,'unLab','unPos','unProb', 'locationRefine');
        if isempty(unLab)
            assert(false);
        end
    catch
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            jidx = parts(pidx+1).pos(1);
            keypointsAll(imgidx).det{1}{jidx+1} = [];
        end
        imgidxs_missing = [imgidxs_missing; imgidx];
        nmissing = nmissing + 1;
        if (~mod(imgidx, 100))
            fprintf(' %d/%d\n',imgidx,length(annolist));
        end
        continue;
    end
    
    if isfield(p, 'res_net_correct') && p.res_net_correct
        half_stride = p.stride/2;
        unPos = unPos + half_stride/p.scale_factor;
    end

    clusidxs = unLab(unLab(:,1)<1000,2);
    clusidxsUniq = unique(clusidxs);
    num_clusters = length(clusidxsUniq);
    %{
    if num_clusters > 10
        imgidxs_missing = [imgidxs_missing; imgidx];
        nmissing = nmissing + 1;
        continue;
    end
    %}

    nPointClus = zeros(length(clusidxsUniq),1);
    nPartClus = zeros(length(clusidxsUniq),1);
    for j = 1:length(clusidxsUniq)
        nPointClus(j) = sum((unLab(:,2) == clusidxsUniq(j)));
        for i = 1:length(p.pidxs)
            % part is a joint
            pidx = p.pidxs(i);
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
%             detidxs = (unLab(:,1) == i-1 & unLab(:,2) == clusidxsUniq(j));
            det = [];
            id = find(cidxs == i);
            if (~isempty(id))
                detidxs = (unLab(:,1) == id-1 & unLab(:,2) == clusidxsUniq(j));
                if (sum(detidxs)>0)
                    w = unProb(detidxs,id);
                    w = w./sum(w);
                    loc_refine = squeeze(locationRefine(detidxs, id, :));
                    if size(loc_refine, 2) == 1
                        loc_refine = loc_refine';
                    end
                    pos = (unPos(detidxs,:)' + loc_refine')*w;
                    %pos = unPos(detidxs,:)'*w;
                    det = [pos' max(unProb(detidxs,id))];
                    nPartClus(j) = nPartClus(j) + 1;
                end
            end
            keypointsAll(imgidx).det{j}{jidx+1} = det;
        end
    end
    
    keypointsAll(imgidx).det(nPointClus < clusSizeThresh) = [];
    if (isempty(keypointsAll(imgidx).det))
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            jidx = parts(pidx+1).pos(1);
            keypointsAll(imgidx).det{1}{jidx+1} = [];
        end
    end
    
    if (bVis)
        colors = {'r','g','b','c','m','y'};
        markers = {'+','o','s'}; %,'x','.','-','s','d'
        img = imread(annolist(imgidx).image.name);
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
            lp = clusidxsUniq(j);
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
        fprintf(' %d/%d\n',imgidx,length(annolist));
    end
end
fprintf(' done\n');
fprintf('nmissing: %d\n',nmissing);

end