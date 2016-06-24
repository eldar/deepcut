function [keypointsAll, annolistOrig] = projectKeypointsOrig(keypointsAll,padDir)

fprintf('projectKeypointsOrig()\n');

load('/home/andriluk/IMAGES/human_pose_dataset/dataset/dataset_release_candidate1/dataset_info_v12.mat','DATASET');
load(DATASET.conf.source_annolist_filename, 'annolist');

for imgidx = 1:length(DATASET.single_person)
    DATASET.mult_person{imgidx} = [DATASET.mult_person{imgidx} DATASET.borderline_person{imgidx}'];
end
rectidxs = DATASET.mult_person;

imgidxs1 = find(cellfun(@isempty,rectidxs) == 0);
imgidxs2 = find(DATASET.img_train == 0);
imgidxs = intersect(imgidxs1,imgidxs2);

for imgidx = 1:length(annolist)
    ridxs = DATASET.single_person{imgidx};
    for i = 1:length(ridxs)
        annolist(imgidx).annorect(ridxs(i)).annopoints.point = [];
    end
end

annolistOrig = annolist(imgidxs);
imgidxs_orig = zeros(length(keypointsAll),1);

for imgidx = 1:length(keypointsAll)
    fprintf('.');
    [~,name] = fileparts(keypointsAll(imgidx).imgname);
    load([padDir '/T_' name(3:end)],'T');
    T1 = T;
    imgidx_orig = str2double(name(3:7));
    imgidxs_orig(imgidx) = imgidx_orig;
    
    det = keypointsAll(imgidx).det;
    if (iscell(det))
        for jidx = [1:6 9:length(det)]
            assert(sum(det{jidx}(:,1) < 0)==0);
            assert(sum(det{jidx}(:,2) < 0)==0);
            detNew = ([det{jidx}(:,1:2) ones(size(det{jidx},1),1)]*T1');
%             detNew = ([det{jidx}(:,1:2) ones(size(det{jidx},1),1)]*T1'-repmat(T2(:,3)',size(det{jidx},1),1))./T2(1,1);
%             figure(100); clf; imagesc(imread([padDir '/' name '.png'])); axis equal; hold on;
%             plot(det{jidx}(:,1),det{jidx}(:,2),'ro','MarkerFaceColor','g','MarkerEdgeColor','k','MarkerSize',5);
            det{jidx}(:,1:2) = detNew(:,1:2);
%             figure(101); clf; imagesc(imread(annolist(imgidx_orig).image.name)); axis equal; hold on;
%             plot(det{jidx}(:,1),det{jidx}(:,2),'ro','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',5);
%             set(gca,'Ydir','reverse');
            assert(sum(det{jidx}(:,1) < 0)==0);
            assert(sum(det{jidx}(:,2) < 0)==0);
        end
    else
        detNew = ([det(:,1:2) ones(size(det,1),1)]*T1');
        det(:,1:2) = detNew(:,1:2);
    end
    keypointsAll(imgidx).det = det;
    keypointsAll(imgidx).imgname = annolist(imgidx_orig).image.name;
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
    end
end
fprintf(' done\n');

% merge detections
imgidxs_merged = imgidxs_orig(1);
imgidxs_merged_rel = 1;
for imgidx = 2:length(keypointsAll)
    if (imgidxs_orig(imgidx) == imgidxs_merged(end))
        for jidx = [1:6 9:length(keypointsAll(imgidx).det)]
            keypointsAll(imgidxs_merged_rel(end)).det{jidx} = [keypointsAll(imgidxs_merged_rel(end)).det{jidx}; keypointsAll(imgidx).det{jidx}];
        end
    else
        imgidxs_merged = [imgidxs_merged; imgidxs_orig(imgidx)];
        imgidxs_merged_rel = [imgidxs_merged_rel; imgidx];
    end
end
keypointsAll = keypointsAll(imgidxs_merged_rel);
annolistOrig = annolistOrig(1:length(keypointsAll));

end