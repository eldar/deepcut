function res = displayKeypoints(imidx, keypointsAll, stuff)

    im = imread(keypointsAll(imidx).imgname);

    joints_orig = keypoints2joints(stuff.keypointsAll(imidx).det);
    joints_tomp = keypoints2joints(keypointsAll(imidx).det);

    figure(1);
    vis_pred(im, joints_orig);
    figure(2);
    vis_pred(im, joints_tomp);

end

function keypts = keypoints2joints(keypointsAll)
    keypts = keypointsAll;
    keypts = keypts(:,1:2);
    keypts = [keypts(1:6,:); keypts(9:16,:)];
end

