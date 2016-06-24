function endpointsAll = keypoints2endpoints(keypointsAll)

% endpoints = repmat(struct('imgname','','det',nan(10,4)),length(keypointsAll),1);
endpointsAll = cell(length(keypointsAll),1);

for imgidx = 1:length(keypointsAll)
    endpoints = nan(10,4);
    det = keypointsAll(imgidx).det;
    endpoints(1,:) = [det(1,1:2) det(2,1:2)];
    endpoints(2,:) = [det(2,1:2) det(3,1:2)];
    endpoints(3,:) = [det(5,1:2) det(4,1:2)];
    endpoints(4,:) = [det(6,1:2) det(5,1:2)];
    endpoints(5,:) = [mean([det(3,1:2); det(4,1:2)]) mean([det(13,1:2); det(14,1:2)])];
    endpoints(6,:) = [det(9,1:2) det(10,1:2)];
    endpoints(7,:) = [det(11,1:2) det(12,1:2)];
    endpoints(8,:) = [det(12,1:2) det(13,1:2)];
    endpoints(9,:) = [det(15,1:2) det(14,1:2)];
    endpoints(10,:) = [det(16,1:2) det(15,1:2)];
    endpointsAll{imgidx} = endpoints;
end

end