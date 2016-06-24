function pose2keypoints(expidx)

p = rcnn_exp_params(expidx);
% load ground truth
load(p.testGT);
if (~exist('annolist','var'))
    annolist = single_person_annolist;
end

sc = 1.0;

if (isfield(p,'pidxs_ps_map'))
    pidxs_ps_map = p.pidxs_ps_map;
else
    pidxs_ps_map = [1:6 9:16];
end
% poseEstDir = [p.expDir '/' p.shortName '/part_marginals_samples_post/'];
poseEstDir = [p.expDir '/' p.shortName '/part_marginals/'];
% endpointsFiles = dir([poseEstDir '/pose_est_imgidx*.mat']);
% assert(length(endpointsFiles) == length(annolist));

keypointsAll = repmat(struct('imgname','','det',nan(16,3)),length(annolist),1);

nmissing = 0;

for imgidx = 1:length(annolist)
    fprintf('.');
    fname = [poseEstDir '/pose_est_imgidx' padZeros(num2str(imgidx-1),4)];
    try
        val = load(fname);
        keypoints = val.best_conf(:,[5 6]);
        keypointsAll(imgidx).imgname = annolist(imgidx).image.name;
        keypointsAll(imgidx).det(pidxs_ps_map,1:2) = keypoints*sc;
    catch
        nmissing = nmissing + 1;
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(annolist));
    end
end
fprintf('done\n');
fprintf('nmissing: %d\n',nmissing);

% save([keypointsDir '/keypointsAll_refHeight_400'],'keypointsAll');
save(p.evalTest,'keypointsAll');
end