function combineSpatial(expidx)

fprintf('combineSpatial()\n');

if (ischar(expidx))
    expidx = str2double(expidx);
end

% load annolist with full size images
[~,imgidxs] = getAnnolist(expidx);

p = rcnn_exp_params(expidx);
saveTo = [fileparts(p.evalTest) '/pred_pairwise_backproj'];

fname = [saveTo '/keypoints_' padZeros(num2str(imgidxs(1)),5)];
load(fname,'keypoints');
endpointsAll = keypoints;

for i = 1:length(imgidxs)
    fprintf('.');
    
    fname = [saveTo '/keypoints_' padZeros(num2str(imgidxs(i)),5)];
    load(fname,'keypoints');
    endpointsAll(i) = keypoints;

    if (~mod(i, 100))
        fprintf(' %d/%d\n',i,length(imgidxs));
    end
end
fprintf(' done\n');

fnameKeypoints = [fileparts(p.evalTest) '/endpointsAll'];
save(fnameKeypoints, 'endpointsAll');

end