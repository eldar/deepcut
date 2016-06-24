function vis_proposals(detAll,nDet,detDir)

visDir = [detDir '/vis'];
if (~exist(visDir,'dir'))
    mkdir(visDir);
end

figure(100);
for imgidx = 1:length(detAll)
    clf;
    if (ischar(detAll(imgidx).imgname))
        imagesc(imread(detAll(imgidx).imgname));axis equal;hold on;
        [~,idxs] = sort(detAll(imgidx).det(:,6));
        vis_bbox(detAll(imgidx).det(idxs(1:nDet),1:4),'r');
        [~,name] = fileparts(detAll(imgidx).imgname);
        axis off;
        print(gcf,'-dpng',[visDir '/' name '_det.png']);
    end
end
close(100);

end