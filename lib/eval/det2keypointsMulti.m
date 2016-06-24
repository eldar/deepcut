function keypointsAll = det2keypointsMulti(boxesAll,pidxs,parts)

keypointsAll = [];

for imgidx = 1:length(boxesAll)
  for i = 1:length(pidxs)
    pidx = pidxs(i);
    % part is a joint
    assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
    jidx = parts(pidx+1).pos(1);
    det = boxesAll{i+1,imgidx};
    det = det(det(:,3) > det(:,1) & det(:,4) > det(:,2),:);
    x = mean(det(:,[1 3]),2);
    y = mean(det(:,[2 4]),2);
    keypointsAll(imgidx).det{jidx+1} = [x y det(:,5)];
  end
end