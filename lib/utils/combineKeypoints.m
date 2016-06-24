function combineKeypoints(expidx)

fprintf('combineKeypoints()\n');

if (ischar(expidx))
    expidx = str2double(expidx);
end

% load annolist with full size images
[~,imgidxs] = getAnnolist(expidx);

p = rcnn_exp_params(expidx);
saveTo = [fileparts(p.evalTest) '/pred_backproj'];

fname = [saveTo '/keypoints_' padZeros(num2str(imgidxs(1)),5)];
load(fname,'keypoints');
keypointsAll = keypoints;

fname = [saveTo '/bboxes_' padZeros(num2str(imgidxs(1)),5)];
load(fname,'bboxes');
bboxAll = bboxes;

for i = 1:length(imgidxs)
    fprintf('.');
    
    fname = [saveTo '/keypoints_' padZeros(num2str(imgidxs(i)),5)];
    load(fname,'keypoints');
    keypointsAll(i) = keypoints;
    
    fname = [saveTo '/bboxes_' padZeros(num2str(imgidxs(i)),5)];
    load(fname,'bboxes');
    bboxAll(i) = bboxes;

    if (~mod(i, 100))
        fprintf(' %d/%d\n',i,length(imgidxs));
    end
end
fprintf(' done\n');

fnameKeypoints = [fileparts(p.evalTest) '/keypointsAll'];
save(fnameKeypoints, 'keypointsAll');

fnameBBox = [fileparts(p.evalTest) '/bboxAll'];
save(fnameBBox, 'bboxAll');
end