function vis_sticks_waf(img,pred_stickmen, chen_stickmen, gt_stickmen,evalidx, evalidx_chen, scoredetail,fname)

% plot predicted sticks, upper body detections and GT sticks
% predicted and GT sticks are only plotted for upper body detections
% that match the GT upper body bounding boxes

draw_box = false;

%{
clf; imagesc(img); axis equal; axis  off; hold on;
for ridx = 1:length(gt_stickmen)
    if (evalidx(ridx) ~= 0) % upper body detection matches GT bounding box
        % plot detection
        sc = scoredetail;
        if (sc{ridx}(6) == 0) % head prediction is wrong
            c = 'y';
        else
            c = 'r';
        end
        if draw_box
            b = pred_stickmen(evalidx(ridx)).det;
            rectangle('Pos',[b(1) b(2) b(3)-b(1) b(4)-b(2)],'lineWidth',2,'edgeColor',c);
            % plot number of parts estimated correctly / total number of parts
            text(b(1),b(2),sprintf('%d/%d',sum(sc{ridx}),numel(sc{ridx})),'FontSize',10,'color','k','BackgroundColor','g',...
                'verticalalignment','top','horizontalalignment','left');
        end
        
        DrawStickman(pred_stickmen(evalidx(ridx)).coor,[]);
    end
end
%}

%print(gcf,'-dpng',[fname '_unary.png']);
%printpdf([fname '_unary.pdf']);


% draw a subset of GT poses for which evaluation is performed
clf; imagesc(img); axis equal; axis  off; hold on;
for ridx = 1:length(gt_stickmen)
    if (evalidx_chen(ridx) ~= 0) % upper body detection matches GT bounding box
        DrawStickman(chen_stickmen(evalidx_chen(ridx)).coor,[]);
    end
end
%print(gcf,'-dpng',[fname '_gt.png']);
printpdf([fname '_chen.pdf']);


%unix(['montage ' fname '_unary.png' ' ' fname '.png' ' '  fname '_gt.png' ' -geometry +0+0 ' fname '_combo.png']);
end