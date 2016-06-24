function plot_sticks(p_exp, endpointsAll, annolist, visdir, matchPCP, keypointsAll, matchPCK, pidxs, endpointsAllGT, bSortPerformance)

% colorset = {[236,112,20]/255; [78,179,211]/255; [0,104,55]/255; [129,15,124]/255; 'y'; 'k'; 'r'; 'c'; 'g'; 'b'};

bVisPCP = false;

bVisGT = true;
visJointNum = true;

if (~exist(visdir, 'dir'))
    mkdir(visdir);
end

[~,parts] = util_get_parts24();

lineWidth = 3;
markerSize = 7;

figure(102);
for imgidx = 1:length(keypointsAll)
    [~, name, ~] = fileparts(annolist(imgidx).image.name);
    fprintf('processing image: %s %d/%d\n', name, imgidx, length(keypointsAll));

    clf;
    if bVisGT
        subplot(1,2,1);
    end
    imagesc(imread(annolist(imgidx).image.name)); hold on;
    axis equal; axis off;
    endpoints = endpointsAll{imgidx};
    
    for p = 1:(size(endpoints, 1))
        if (matchPCP(imgidx,p) == 1) || ~bVisPCP
            c = 'y';
        else
            c = 'r';
        end
        plot([endpoints(p, 1); endpoints(p, 3)], ...
            [endpoints(p, 2); endpoints(p, 4)], ...
            [c '-'], 'linewidth', lineWidth);
        hold on;
        plot([endpoints(p, 1); endpoints(p, 3)], ...
            [endpoints(p, 2); endpoints(p, 4)], ...
            [c 'o'], 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k', 'MarkerSize', markerSize);
        hold on;
    end
    keypoints = keypointsAll(imgidx).det;
    for p = 1:length(pidxs)
        jidx = parts(pidxs(p)+1).pos(1)+1;
        if (matchPCK(imgidx,p) == 1)
            c = 'y';
        else
            c = 'r';
        end
        plot(keypoints(jidx, 1), keypoints(jidx, 2), ...
            [c 'o'], 'MarkerFaceColor', c, 'MarkerEdgeColor', 'k', 'MarkerSize', markerSize);
        if visJointNum
            text(keypoints(jidx, 1), keypoints(jidx, 2), num2str(p), 'Color', 'g', 'FontSize', 12);
        end
        hold on;
    end
    
    if bVisGT

        set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 20])
        matchPCPimg = matchPCP(imgidx,:);
        matchPCKimg = matchPCK(imgidx,:);
        pck = sum(matchPCKimg(~isnan(matchPCKimg)));
        pcp = sum(matchPCPimg(~isnan(matchPCPimg)));
        title([sprintf('PCK: %d/%d; ',pck,sum(~isnan(matchPCKimg))), ...
               sprintf('PCP: %d/%d',pcp,sum(~isnan(matchPCPimg)))],'fontSize',36);
    %     xlabel([sprintf('PCK: %d/%d; ',pcp,sum(~isnan(matchPCKimg))), ...
    %            sprintf('PCP: %d/%d',pck,sum(~isnan(matchPCPimg)))],'fontSize',36);   
    %     set(gca,'XTickLabel',''); set(gca,'YTickLabel','');
        subplot(1,2,2);
        imagesc(imread(annolist(imgidx).image.name)); hold on;
        axis equal; axis off;
        endpointsGT = endpointsAllGT{imgidx};
        for p = 1:size(endpointsGT, 1)
            plot([endpointsGT(p, 1); endpointsGT(p, 3)], ...
                [endpointsGT(p, 2); endpointsGT(p, 4)], ...
                'g-', 'linewidth', lineWidth);
            hold on;
            plot([endpointsGT(p, 1); endpointsGT(p, 3)], ...
                [endpointsGT(p, 2); endpointsGT(p, 4)], ...
                'go', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'MarkerSize', markerSize);
            hold on;
        end

        num_joints =14;
        rect = annolist(imgidx).annorect(1);
        joints = get_anno_joints( rect, p_exp.pidxs, parts );
        if visJointNum
            for p = 1:num_joints
                pt = joints(p, :);
                text(pt(1), pt(2), num2str(p), 'Color', 'y', 'FontSize', 12);
            end
        end
        title('GT','fontSize',36);   
    end
    
%     xlabel('GT','fontSize',36);   
%     set(gca,'XTickLabel',''); set(gca,'YTickLabel','');
    
    if (bSortPerformance)
        fname = [visdir '/pck_' num2str(pck) '_pcp_' num2str(pcp) '_pred_' name '.png'];
    else
         fname = [visdir '/pred_' name '.png'];
%        fname = [visdir '/pred_' padZeros(num2str(imgidx),5) '.png'];
    end
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    print(gcf, '-dpng', fname);
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
    end
end
fprintf(' done\n');
close(102);
