function keypointsAll = projectKeypoints(keypointsAll,nopadDir,padDir,annolist_nopad)

for imgidx = 1:length(keypointsAll)
    [path,name] = fileparts(keypointsAll(imgidx).imgname);
    try
        try
            load([padDir '/T_' name(3:end)],'T');
        catch
            load([padDir '/T_' name],'T');
        end
    catch
        T = eye(3);
    end
    T1 = T;
    
    try
        try
            load([nopadDir '/T_' name(3:end)],'T');
        catch
            load([nopadDir '/T_' name],'T');
        end
    catch
        T = eye(3);
    end
    
    T2 = T;
    det = keypointsAll(imgidx).det;
    
    detNew = ([det(:,1:2) ones(size(det,1),1)]*T1'-repmat(T2(:,3)',size(det,1),1))./T2(1,1);
    det(:,1:2) = detNew(:,1:2);
    
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