function vis_sticks_waf(img,pred_stickmen,gt_stickmen,evalidx,scoredetail,fname)

% plot predicted sticks, upper body detections and GT sticks
% predicted and GT sticks are only plotted for upper body detections
% that match the GT upper body bounding boxes

clf; imagesc(img); axis equal; axis  off; hold on;
for ridx = 1:length(gt_stickmen)
    if (evalidx(ridx) ~= 0) % upper body detection matches GT bounding box
        % plot detection
        sc = scoredetail;
%         if (sc{ridx}(6) == 0) % head prediction is wrong
        if (sc{ridx}(1) == 0) % torso prediction is wrong
            c = 'y';
        else
            c = 'r';
        end
        b = pred_stickmen(evalidx(ridx)).det;
        rectangle('Pos',[b(1) b(2) b(3)-b(1) b(4)-b(2)],'lineWidth',2,'edgeColor',c);
        
        % plot number of parts estimated correctly / total number of parts
        text(b(1),b(2),sprintf('%d/%d',sum(sc{ridx}),numel(sc{ridx})),'FontSize',10,'color','k','BackgroundColor','g',...
            'verticalalignment','top','horizontalalignment','left');
        DrawStickman(pred_stickmen(evalidx(ridx)).coor,[]);
    end
end
print(gcf,'-dpng',[fname '.png']);
% draw a subset of GT poses for which evaluation is performed
clf; imagesc(img); axis equal; axis  off; hold on;
for ridx = 1:length(gt_stickmen)
    if (evalidx(ridx) ~= 0) % upper body detection matches GT bounding box
        DrawStickman(gt_stickmen(ridx).coor,[]);
    end
end
print(gcf,'-dpng',[fname '_gt.png']);
unix(['montage ' fname '.png' ' ' fname '_gt.png' ' -geometry +0+0 ' fname '_combo.png']);
end