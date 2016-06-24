function annolist = compute_det_bbox(expidx,annolist,nms_thresh,det_thresh,bbox_offset)

fprintf('compute_det_bbox()\n');

p = exp_params(expidx);
predDir = p.multicutDir;

nmissing = 0;
bVis = false;
imgidxs_missing = [];
pidx = 13; % neck
headSize = p.refHeight/8;

n = 0;

for imgidx = 1:length(annolist)
    
    fprintf('.');
    keypointsAll(imgidx).imgname = annolist(imgidx).image.name;
    fname = [predDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_1_14'];
    img = imread(annolist(imgidx).image.name);
    try
        load(fname,'unLab','unPos','unProb');
    catch
        annolist(imgidx).annorect(1).bbox = [];
        annolist(imgidx).annorect(2:end) = [];
        imgidxs_missing = [imgidxs_missing; imgidx];
        nmissing = nmissing + 1;
        continue;
    end
    
    bbox = [unPos(:,1) - 1.5*headSize unPos(:,2) - headSize,...
                 unPos(:,1) + 1.5*headSize unPos(:,2) + 7*headSize];
    
    bbox(:,1) = bbox(:,1) - bbox_offset;         
    bbox(:,2) = bbox(:,2) - bbox_offset;
    bbox(:,3) = bbox(:,3) + bbox_offset;         
    bbox(:,4) = bbox(:,4) + bbox_offset;
    
    bbox = [bbox unProb(:,pidx)];
    bbox(bbox(:,5) < det_thresh,:) = [];
    
    if (isempty(bbox))
        annolist(imgidx).annorect(1).bbox = [];
        annolist(imgidx).annorect(2:end) = [];
        continue;
    end
    
    I = nms(bbox,nms_thresh);
    bbox = bbox(I,:);
    bbox(:,1) = max(bbox(:,1),1);
    bbox(:,2) = max(bbox(:,2),1);
    bbox(3) = min(bbox(3),size(img,2));
    bbox(4) = min(bbox(4),size(img,1));
    
    n = n + size(bbox,1);
    for ridx = 1:size(bbox)
        annolist(imgidx).annorect(ridx).bbox = bbox(ridx,1:4);
    end
    
    if (size(bbox,1) < length(annolist(imgidx).annorect))
        annolist(imgidx).annorect(size(bbox,1)+1:end) = [];
    end
    if (bVis)
        colors = {'r','g','b','c','m','y'};
        markers = {'+','o','s'}; %,'x','.','-','s','d'
        img = imread(annolist(imgidx).image.name);
        figure(100); clf; imagesc(img); axis equal; hold on;
        for ridx = 1:size(bbox,1)
            bb = annolist(imgidx).annorect(ridx).bbox;
            rectangle('Pos',[bb(:,1) bb(:,2) bb(:,3)-bb(:,1) bb(:,4)-bb(:,2)],'edgeColor',colors{mod(ridx,6)+1},'LineWidth',5);
            axis off;
        end
    end
    
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist));
    end
end
fprintf(' done\n');
fprintf('# bbox: %d\n',n);
fprintf('nmissing: %d\n',nmissing);

end