function [keypointsAll, imgidxs_missing]= det2keypointsImgMulticutBBoxMultiPoses(expidx,parts,nImgs)

fprintf('det2keypointsImgMulticutBBoxMultiPoses()\n');

p = rcnn_exp_params(expidx);
load([p.detDir '/annolist_poses'],'annolist_poses');

load(p.testGT,'annolist');

assert(length(annolist) == length(annolist_poses));

nmissing = 0;
bVis = false;
imgidxs_missing = [];

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

nTotalBBox = 0;
nTotalBBoxDet = 0;
nTotalImgs = 0;
nTotalImgsNotDet = 0;
idxmap = [8 7 6 12 13 14 -1 -1 2 1 5 4 3 9 10 11];
for imgidx = 1:nImgs
    
    fprintf('.');
    keypointsAll(imgidx).imgname = annolist_poses(imgidx).image.name;
    
    ndet = 0; clusidx = 0;
    bNeedNumberOfPeople = false;
    if (length(annolist(imgidx).annorect) <= nPeopleMax && ...
        length(annolist(imgidx).annorect) >= nPeopleMin)
        nTotalImgs = nTotalImgs + 1;
        bNeedNumberOfPeople = true;
        for ridx = 1:length(annolist_poses(imgidx).annorect)
            nTotalBBox = nTotalBBox + 1;
            rect = annolist_poses(imgidx).annorect(ridx);
            if (isfield(rect,'joints') && ~isempty(rect.joints))
                nTotalBBoxDet = nTotalBBoxDet + 1;
                clusidx = clusidx + 1;
                joints = rect.joints;
                %             img = imread(annolist_poses(imgidx).image.name);
                %             figure(100); clf; imagesc(img); axis equal; hold on;
                %             labels = cell(0);
                %             for i = 1:14
                %                 labels{i} = i;
                %             end
                %             joints = double(joints);
                %             plot(joints(:,1),joints(:,2),'r+','MarkerSize',5);
                %             text(joints(:,1)+10,joints(:,2),labels,'FontSize',6,'BackgroundColor','w');
                for i = 1:length(p.pidxs)
                    pidx = p.pidxs(i);
                    assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
                    jidx = parts(pidx+1).pos(1);
                    ndet = ndet + 1;
                    keypointsAll(imgidx).det{clusidx}{jidx+1} = joints(idxmap(jidx+1),:);
                end
            end
        end
        if (ndet == 0)
            nTotalImgsNotDet = nTotalImgsNotDet + 1;
        end
    end
    if (ndet == 0)
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            jidx = parts(pidx+1).pos(1);
            keypointsAll(imgidx).det{1}{jidx+1} = [];
        end
        if (~bNeedNumberOfPeople)
            imgidxs_missing = [imgidxs_missing; imgidx];
            nmissing = nmissing + 1;
        end
        if (~mod(imgidx, 100))
            fprintf(' %d/%d\n',imgidx,length(annolist_poses));
        end
        continue;
    end
    
    if (bVis)
        colors = {'r','g','b','c','m','y'};
        markers = {'+','o','s'}; %,'x','.','-','s','d'
        img = imread(annolist_poses(imgidx).image.name);
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
        fprintf(' %d/%d\n',imgidx,length(annolist_poses));
    end
end
fprintf(' done\n');
fprintf('nmissing: %d\n',nmissing);
fprintf('nTotal: %d\n',nTotalBBox);
fprintf('nTotalDet: %d\n',nTotalBBoxDet);
fprintf('nTotalImgs: %d\n',nTotalImgs);
fprintf('nTotalImgsNotDet: %d\n',nTotalImgsNotDet);
nTotalImgsNotDet/nTotalImgs
end