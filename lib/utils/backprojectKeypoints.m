function [keypointsAll,bboxAll] = backprojectKeypoints(expidx)

fprintf('backprojectKeypoints()\n');

% load annolist with full size images
[annolistOrig, imgidxs] = getAnnolist(expidx);
for imgidx = 1:length(annolistOrig)
    annolistOrig(imgidx).annorect = [];
end

p = rcnn_exp_params(expidx);
load(p.testGT);
if (~exist('annolist','var'))
    annolist = single_person_annolist;
end
annolist_crops = annolist;

[~,parts] = util_get_parts24();

% load bboxes
bboxAll = getBBoxAll(expidx,parts,length(annolist_crops));
imgidxs_orig = zeros(length(bboxAll),1);
jidxs = [1:6 9:length(bboxAll(1).det)];

fprintf('backproject bboxes()\n');
for imgidx = 1:length(bboxAll)
    fprintf('.');
    [~,name] = fileparts(annolist_crops(imgidx).image.name);
    load([fileparts(p.testGT) '/T_' name(3:end)],'T');
    imgidxs_orig(imgidx) = str2double(name(3:7));
    
    det = bboxAll(imgidx).det;
    for jidx = jidxs
        detNew1 = ([det{jidx}(:,1:2) ones(size(det{jidx},1),1)]*T');
        detNew2 = ([det{jidx}(:,3:4) ones(size(det{jidx},1),1)]*T');
        det{jidx}(:,1:4) = [detNew1(:,1:2) detNew2(:,1:2)];
        %             figure(101); clf; imagesc(imread(annolist(imgidx_orig).image.name)); axis equal; hold on;
        %             plot(det{jidx}(:,1),det{jidx}(:,2),'ro','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',5);
    end
    
    bboxAll(imgidx).det = det;
    bboxAll(imgidx).imgname = annolistOrig(imgidxs_orig(imgidx)).image.name;
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(bboxAll));
    end
end
fprintf(' done\n');

% merge detections
imgidxs_merged = imgidxs_orig(1);
imgidxs_merged_rel = 1;
for imgidx = 2:length(bboxAll)
    if (imgidxs_orig(imgidx) == imgidxs_merged(end))
        for jidx = jidxs
            bboxAll(imgidxs_merged_rel(end)).det{jidx} = [bboxAll(imgidxs_merged_rel(end)).det{jidx}; bboxAll(imgidx).det{jidx}];
        end
    else
        imgidxs_merged = [imgidxs_merged; imgidxs_orig(imgidx)];
        imgidxs_merged_rel = [imgidxs_merged_rel; imgidx];
    end
end
bboxAll = bboxAll(imgidxs_merged_rel);

fprintf('nms()\n');
for imgidx = 1:length(bboxAll)
    fprintf('.');
    for jidx = jidxs
        keep = nms(bboxAll(imgidx).det{jidx}, 0.5);
        bboxAll(imgidx).det{jidx} = bboxAll(imgidx).det{jidx}(keep, :);
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(bboxAll));
    end
end
fprintf(' done\n');

for imgidx = 1:length(bboxAll)
    keypointsAll(imgidx).imgname = bboxAll(imgidx).imgname;
    keypointsAll(imgidx).det = cell(16,1);
end

% convert to keypoints
for imgidx = 1:length(bboxAll)
    points = nan(16,2);
    for jidx = jidxs
        det = bboxAll(imgidx).det{jidx};
        x = mean(det(:,[1 3]),2);
        y = mean(det(:,[2 4]),2);
        keypointsAll(imgidx).det{jidx,:} = [[x y] det(:,5)];
        [val,idx] = max(det(:,5));
        points(jidx,:) = [x(idx) y(idx)];
    end
%     figure(101); clf; imagesc(imread(keypointsAll(imgidx).imgname)); axis equal; hold on;
%     plot(points(:,1),points(:,2),'ro','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',5);
%     set(gca,'Ydir','reverse');
end

path = fileparts(p.evalTest);
fnameKeypoints = [path '/keypointsAll'];
save(fnameKeypoints, 'keypointsAll');

fnameBBox = [path '/bboxAll'];
save(fnameBBox, 'bboxAll');
end