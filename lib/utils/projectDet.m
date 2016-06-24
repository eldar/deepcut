function projectDet(expidx)

fprintf('projectDet()\n');

p = rcnn_exp_params(expidx);
exp_dir = [p.expDir '/' p.shortName];

conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', exp_dir);

load(p.testGT);
annolistHR = annolist;

load(p.testGTdpm);
if (exist('single_person_annolist','var'))
    annolistLR = single_person_annolist;
else
    annolistLR = annolist;
end

assert(length(annolistLR) == length(annolistHR));
saveto = [conf.cache_dir 'h200'];
if (~exist(saveto,'dir'))
    mkdir(saveto);
end

for pidx = p.pidxs
% for pidx = [0 16]  
% for pidx = [9 7 5 4 23 22 21 2 19 17 14 12 0 16]  
    fprintf('pidx: %d\n',pidx);
    clear boxes_nonms;
    filename = [conf.cache_dir 'boxes_test_bbox_reg_cidx_' num2str(pidx)];
    load(filename,'boxes_nonms');
    assert(length(boxes_nonms) == length(annolistHR));
    for imgidx = 1:length(annolistLR)
        fprintf('.');
        [path,name] = fileparts(annolistHR(imgidx).image.name);
        load([path '/T_' name(3:end)],'T');
%         load([path '/T_' name(1:end)],'T');
        T1 = T;
        [path,name] = fileparts(annolistLR(imgidx).image.name);
        try
            load([path '/T_' name(3:end)],'T');
        catch
            T = eye(3,3);
        end
        T2 = T;
        [val,idxs] = sort(boxes_nonms{imgidx}(:,5),'descend');
        det = boxes_nonms{imgidx};
        detNew12 = ([det(:,1:2) ones(size(det,1),1)]*T1'-repmat(T2(:,3)',size(det,1),1))./T2(1,1);
        detNew34 = ([det(:,3:4) ones(size(det,1),1)]*T1'-repmat(T2(:,3)',size(det,1),1))./T2(1,1);
        det(:,1:4) = [detNew12(:,1:2) detNew34(:,1:2)];
%         figure(100); clf; imagesc(imread(annolistLR(imgidx).image.name)); axis equal; hold on;
%         p1 = (det(1,1) + det(1,3))/2;
%         p2 = (det(1,2) + det(1,4))/2;
%         plot(p1,p2,'r*','MarkerSize',10);
%         set(gca,'Ydir','reverse');
        det = det(idxs,:);
        boxes = {det};
        idxs = {idxs};
        filenameSave = [saveto '/boxes_test_bbox_reg_imgidx_' num2str(imgidx-1) '_cidx_' num2str(pidx)];
        save(filenameSave,'boxes','idxs');
        if (~mod(imgidx, 100))
            fprintf(' %d/%d\n',imgidx,length(annolistLR));
        end
    end
    fprintf(' done\n');
end
end