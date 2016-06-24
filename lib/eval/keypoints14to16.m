function keypointsAll = keypoints14to16(keypointsAllcell)

keypointsAll = repmat(struct('det',nan(16,3),'imgname',''),size(keypointsAllcell,1),1);

for imgidx = 1:length(keypointsAll)
    det = keypointsAllcell{imgidx};
    keypointsAll(imgidx).det(1:6,1:2) = det(1:6,1:2);
    %keypointsAll(imgidx).det(9,1:2) = det(13,1:2);
    %keypointsAll(imgidx).det(10,1:2) = det(14,1:2);
    keypointsAll(imgidx).det(9:16,1:2) = det(7:14,1:2);
end

end