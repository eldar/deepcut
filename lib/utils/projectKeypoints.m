function keypointsAll = projectKeypoints(keypointsAll,nopadDir,padDir)

% fprintf('projectKeypoints()\n');

for imgidx = 1:length(keypointsAll)
%     fprintf('.');
    [path,name] = fileparts(keypointsAll(imgidx).imgname);
    load([padDir '/T_' name(3:end)],'T');
%     load([path '/T_' name(1:end)],'T');
    T1 = T;
    try
        load([nopadDir '/T_' name(3:end)],'T');
    catch
        T = eye(3);
    end
    T2 = T;
    det = keypointsAll(imgidx).det;
    if (iscell(det))
        for jidx = [1:6 9:length(det)]
            assert(sum(det{jidx}(:,1) < 0)==0);
            assert(sum(det{jidx}(:,2) < 0)==0);
            detNew = ([det{jidx}(:,1:2) ones(size(det{jidx},1),1)]*T1'-repmat(T2(:,3)',size(det{jidx},1),1))./T2(1,1);
            det{jidx}(:,1:2) = detNew(:,1:2);
%             figure(101); clf; imagesc(imread(keypointsAll(imgidx).imgname)); axis equal; hold on;
%             plot(det{jidx}(:,1),det{jidx}(:,2),'ro','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',5);
%             set(gca,'Ydir','reverse');
            assert(sum(det{jidx}(:,1) < 0)==0);
            assert(sum(det{jidx}(:,2) < 0)==0);
        end
    else
        detNew = ([det(:,1:2) ones(size(det,1),1)]*T1'-repmat(T2(:,3)',size(det,1),1))./T2(1,1);
        det(:,1:2) = detNew(:,1:2);
    end
%     figure(100); clf; imagesc(imread(annolist_nopad(imgidx).image.name)); axis equal; hold on;
%     plot(det(:,1),det(:,2),'r*','MarkerSize',10);
%     set(gca,'Ydir','reverse');
    keypointsAll(imgidx).det = det;
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
    end
end
% fprintf(' done\n');
end