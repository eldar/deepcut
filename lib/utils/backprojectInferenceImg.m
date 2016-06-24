function [keypointsAll,bboxAll] = backprojectInferenceImg(expidx,firstidx,nImgs,bSave)

fprintf('backprojectInferenceImg()\n');

if (ischar(expidx))
    expidx = str2double(expidx);
end

if (ischar(firstidx))
    firstidx = str2double(firstidx);
end

if (ischar(nImgs))
    nImgs = str2double(nImgs);
end

if (nargin < 4)
    bSave = true;
elseif (ischar(bSave))
    bSave = str2double(bSave);
end

% load annolist with full size images
fname = '/home/andriluk/IMAGES/human_pose_dataset/dataset/dataset_release_candidate1/test/multPerson/h400/annolist-2-people';
try
%     assert(false);
    load(fname,'annolist','imgidxs_gt');
    annolistOrig = annolist;
    imgidxs = imgidxs_gt;
catch
    [annolistOrig, imgidxs] = getAnnolist(expidx);
end

for imgidx = 1:length(annolistOrig)
    annolistOrig(imgidx).annorect = [];
end

lastidx = firstidx + nImgs - 1;
if (lastidx > length(imgidxs))
    lastidx = length(imgidxs);
end

p = rcnn_exp_params(expidx);

if (isfield(p,'nms_thresh_det'))
    nms_thresh_det = p.nms_thresh_det;
else
    nms_thresh_det = 0.5;
end

if (isfield(p,'scale'))
    scale = p.scale;
else
    assert(false);
end

fprintf('expidx: %d\n',expidx);
fprintf('firstidx: %d\n',firstidx);
fprintf('nImgs: %d\n',nImgs);
fprintf('nms_thresh: %1.1f\n',nms_thresh_det);

load(p.testGT);
if (~exist('annolist','var'))
    annolist = single_person_annolist;
end
annolist_crops = annolist;

[~,parts] = util_get_parts24();

saveTo = [fileparts(p.evalTest) '/inference_backproj'];
if (~exist(saveTo,'dir'))
    mkdir(saveTo);
end

conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);

% if (isfield(p,'predDir'))
%     predDir = p.predDir;
% else
predDir = [conf.cache_dir '/inference'];
% end

for imgidx = firstidx:lastidx
    bboxAll(imgidx).imgname = annolistOrig(imgidxs(imgidx)).image.name;
    bboxAll(imgidx).det = cell(16,1);
    keypointsAll(imgidx).imgname = annolistOrig(imgidxs(imgidx)).image.name;
    keypointsAll(imgidx).det = cell(16,1);
end

imdb = exp2imdb(expidx, 'test');

if (isfield(p,'top_det'))
    top_det = p.top_det;
else
    top_det = 1000000;
end

ii = 1;
for i = firstidx:lastidx
    fprintf('.');
    
    fnameKeypoints = [saveTo '/keypoints_' padZeros(num2str(imgidxs(i)),5)];
    
    try 
        assert(false);
        load(fnameKeypoints,'keypoints');
        keypointsAll(imgidx) = keypoints;
    catch
        
        [~,name] = fileparts(annolist_crops(ii).image.name);
        imgidx_crop = str2double(name(3:7));
        while (imgidx_crop ~= imgidxs(i))
            ii = ii + 1;
            [~,name] = fileparts(annolist_crops(ii).image.name);
            imgidx_crop = str2double(name(3:7));
        end
        
        % load bboxes
        while (imgidx_crop == imgidxs(i))
            fname = [predDir '/imgidx_' padZeros(num2str(ii-1),5)];
            load(fname,'predAll');
            assert(length(p.pidxs) == length(predAll));
            
            % transformation matrix
            load([fileparts(p.testGT) '/T_' name(3:end)],'T');
            for j = 1:length(p.pidxs)
                pidx = p.pidxs(j);
                % part is a joint
                assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
                jidx = parts(pidx+1).pos(1);
                
                % backproject boxes
                det = predAll{j};
                detNew1 = ([det(:,1:2) ones(size(det,1),1)]*T');
                det(:,1:2) = detNew1(:,1:2);
                
                % add to detections
                bboxAll(i).det{jidx+1} = [bboxAll(i).det{jidx+1,:}; det];
            end
            ii = ii + 1;
            if (ii > length(annolist_crops))
                break;
            end
            [~,name] = fileparts(annolist_crops(ii).image.name);
            imgidx_crop = str2double(name(3:7));
        end
        
        % nms
        %     tic
        
        for j = 1:length(p.pidxs)
            jidx = parts(p.pidxs(j)+1).pos(1);
            if (top_det < size(bboxAll(i).det{jidx+1},1))
                [val,idxs] = sort(bboxAll(i).det{jidx+1}(:,end),'descend');
                keep = idxs(1:min(top_det,top_det));
                bboxAll(i).det{jidx+1} = bboxAll(i).det{jidx+1}(keep, :);
            end
        end
        
%         if (nms_thresh_det >= 0 && nms_thresh_det < 1)
%             for j = 1:length(p.pidxs)
%                 jidx = parts(p.pidxs(j)+1).pos(1);
%                 %             boxes = rcnn_scale_bbox(bboxAll(i).det{jidx+1},1/scale,imdb.sizes(i,2),imdb.sizes(i,1));
%                 %             keep = nms(boxes, nms_thresh_det);
%                 keep = nms(bboxAll(i).det{jidx+1}, nms_thresh_det);
%                 bboxAll(i).det{jidx+1} = bboxAll(i).det{jidx+1}(keep, :);
%             end
%         end
        
        %     toc
        % convert to keypoints
%         figure(101); clf; imagesc(imread(keypointsAll(i).imgname)); axis equal; hold on;
        for j = 1:length(p.pidxs)
            jidx = parts(p.pidxs(j)+1).pos(1);
            det = bboxAll(i).det{jidx+1};
            keypointsAll(i).det{jidx+1} = bboxAll(i).det{jidx+1};
            x = det(:,1);
            y = det(:,2);
%             plot(x,y,'ro','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',5);
        end
        
        if (bSave)
            keypoints = keypointsAll(i);
            save(fnameKeypoints,'keypoints');
            
%             fname = [saveTo '/bboxes_' padZeros(num2str(imgidxs(i)),5)];
%             bboxes = bboxAll(i);
%             save(fname,'bboxes');
        end
    end
    if (~mod(i, 100))
        fprintf(' %d/%d\n',i,length(imgidxs));
    end
end

fprintf(' done\n');

if (~exist('keypointsAll','var'))
    keypointsAll = [];
    bboxAll = [];
end
% path = fileparts(p.evalTest);
% fnameKeypoints = [path '/keypointsAll'];
% save(fnameKeypoints, 'keypointsAll');
% 
% fnameBBox = [path '/bboxAll'];
% save(fnameBBox, 'bboxAll');
end