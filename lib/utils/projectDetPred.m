function projectDetPred(expidx,firstidx,nImgs)

fprintf('projectDetPred()\n');

if (ischar(expidx))
    expidx = str2double(expidx);
end

if (ischar(firstidx))
    firstidx = str2double(firstidx);
end

if (ischar(nImgs))
    nImgs = str2double(nImgs);
end

fprintf('expidx: %d\n',expidx);
fprintf('firstidx: %d\n',firstidx);
fprintf('nImgs: %d\n',nImgs);

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

lastidx = firstidx + nImgs - 1;
if (lastidx > length(annolistHR))
    lastidx = length(annolistHR);
end

assert(length(annolistLR) == length(annolistHR));
saveto = [conf.cache_dir 'h200'];
if (~exist(saveto,'dir'))
    mkdir(saveto);
end

for imgidx = firstidx:lastidx
    
    fprintf('.');
    
    clear aboxes_nonms;
    fname = [conf.cache_dir 'pred/imgidx_' padZeros(num2str(imgidx-1),5)];
    load(fname,'aboxes_nonms');
    assert(length(aboxes_nonms) == length(p.pidxs));
    [path,name] = fileparts(annolistHR(imgidx).image.name);
    load([path '/T_' name(3:end)],'T');
    T1 = T;
    [path,name] = fileparts(annolistLR(imgidx).image.name);
    load([path '/T_' name(3:end)],'T');
    T2 = T;
        
    for pidx = 1:length(p.pidxs)
        det = aboxes_nonms{pidx};
        [val,idxs] = sort(det(:,5),'descend');
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
        filenameSave = [saveto '/boxes_test_bbox_reg_imgidx_' num2str(imgidx-1) '_cidx_' num2str(p.pidxs(pidx))];
        save(filenameSave,'boxes','idxs');
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolistLR));
    end
end
fprintf(' done\n');
end