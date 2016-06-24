function vis_multicut_pipeline(expidx,firstidx,nImgs)

p = exp_params(expidx);
multicutDir = p.multicutDir;
fprintf('multicutDir: %s\n',multicutDir);

keypointsDir = multicutDir;
resDir = multicutDir;
visDir = [multicutDir '/vis/'];

if (isfield(p,'testGTnopad'))
    load(p.testGTnopad,'annolist');
    bProject = true;
else
    load(p.testGT,'annolist');
    bProject = false;
end

if (~exist(visDir,'dir'))
    mkdir(visDir)
end

lastidx = firstidx + nImgs - 1;

colors = {'r','g','b','c','m','y'};
markers = {'+','o','s'}; %,'x','.','-','s','d'

% scrsz = get(0,'ScreenSize');
% figure('Position',[1 scrsz(4) scrsz(3)/2 scrsz(4)]);

markerSize = 6;
lineWidth = 4;


if ~p.stagewise
    cidxs = p.cidxs;
else
    num_stages = length(p.cidxs_stages);
    cidxs = sort(p.cidxs_stages{num_stages});
end

clusSizeThresh = 5;
bVisDet = false;
bVisInitGraph = false;
bVisParts = false;
bVisSticks = true;
bVisClus = false;
bVisFinalGraph = false;

bPrintPdf = false;

figure(100);clf;

try
    %assert(false);
    load(fullfile(p.exp_dir, 'data', 'scores'), 'simple_scores', 'subset', 'keypointsAll16');
  
    all_scores = -Inf(length(subset), 1);
    all_scores(subset) = simple_scores;
    [sorted_scores, imlist] = sort(all_scores, 'descend');
    imlist = imlist(1:length(simple_scores), :);
    %imlist_indices = [1 2 5 7 8 10 11 16 18 19 23 25 26 27 28 34 37 42 44 47 49 55 66 73 ...
    %                  80 83 91 98 104 112 116 123 136 141 142 148 149 161 162 172 174 ...
    %                  188 195 204 214 241 260 270 279];
    imlist = imlist(imlist_indices, :);
    sorted = true;
catch
    imlist = firstidx:lastidx;
    sorted = false;
end

%imlist = [13 231 405 564 630 953 960 1025 1620 1621 488 311 1680 1692 695 1346 1253 1674 908 104 326 330 1097 1017 950 1652 568 629 1589 1183 92 1366 29 772 832 635 170 6 94 903 1116 697 210 1033 804 704 75 472 1603];
%imlist = [529];

%sorted = false;
%imlist = [672];

for kk = 1:length(imlist)
    imgidx = imlist(kk);
    
    if ~p.stagewise
        fname = [multicutDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end)) '.mat'];
    else
        fname = [multicutDir '/imgidx_' padZeros(num2str(imgidx),4) '_stage_' num2str(num_stages) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end)) '.mat'];
    end
    
   
    
    if exist(fname, 'file') == 2
        load(fname,'unLab','unPos','unProb', 'locationRefine');
        fprintf('imgidx: %d\n',imgidx);
        
        if isfield(p, 'res_net_correct')
            %valid_idxs = unLab(:,1)<1000;
            half_stride = p.stride/2;
            unPos = unPos + half_stride/p.scale_factor;
        end
        
        imgname = annolist(imgidx).image.name;
        img = imread(imgname);
        
        keypoints = [];
        keypoints.imgname = imgname;
        keypoints.det = unPos;
        
        if (bProject)
            keypoints = projectKeypoints(keypoints,fileparts(p.testGTnopad),fileparts(p.testGT));
        end
        
        cb = keypoints.det;

        if (bVisDet)
            clf;
            imagesc(img); axis equal; hold on;
            plot(cb(:,1),cb(:,2),'r+','MarkerSize',markerSize,'LineWidth',lineWidth) ;
            axis off;
            fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_detections'];
            print(gcf,'-dpng',[fname '.png']);
            if bPrintPdf
                printpdf([fname '.pdf']);
            end
        end
        
        if (bVisInitGraph)
            clf;
            imagesc(img); axis equal; hold on;
            for n = 1:size(cb,1)
                for m = 1:size(cb,1)
                    if (rand < 0.025)
                        plot([cb(n,1) ; cb(m,1)], ...
                            [cb(n,2) ; cb(m,2)], ...
                            ['b-'], 'linewidth', 1);
                    end
                end
            end
            plot(cb(:,1),cb(:,2),'r+','MarkerSize',markerSize,'LineWidth',lineWidth) ;
            
            axis off;
            fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_init_graph'];
            if bPrintPdf
                printpdf([fname '.pdf']);
            else
                print(gcf,'-dpng',[fname '.png']);
            end
        end
        
        clusidxs = unLab(unLab(:,1)<1000,2);
        clusidxsUniq = unique(clusidxs);
        nPointClus = zeros(length(clusidxsUniq),1);
        
        for j = 1:length(clusidxsUniq)
            nPointClus(j) = sum((unLab(:,2) == clusidxsUniq(j)));
        end
        
        idxs = find(nPointClus < clusSizeThresh);
        for i=1:length(idxs)
            idxs_to_remove = unLab(:,2) == clusidxsUniq(idxs(i));
            cb(idxs_to_remove,:) = [];
            unLab(idxs_to_remove,:) = [];
            unProb(idxs_to_remove,:) = [];
            locationRefine(idxs_to_remove,:) = [];
        end
        
        if (bVisParts)
            clf;
            imagesc(img); axis equal; hold on;
            vis_parts(unLab, cb, cidxs, colors, markers, markerSize, lineWidth);
            axis off;
            fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_parts'];
            print(gcf,'-dpng',[fname '.png']);
            if bPrintPdf
                printpdf([fname '.pdf']);
            end
        end
        
        if (bVisClus)
            clf;
            imagesc(img); axis equal; hold on;
            idxs = find(unLab(:,1) < 1000);
            lp_uniq = unique(unLab(idxs,2));
            for j = 1:length(idxs)
                lp = find(lp_uniq == unLab(idxs(j),2))-1;
                cb_cur = cb(idxs(j),:);
                if (lp <= 5)
                    plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{1}],'MarkerSize',markerSize,'LineWidth',lineWidth);
                elseif (lp > 5 && lp <= 11)
                    plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{2}],'MarkerSize',markerSize,'LineWidth',lineWidth);
                else
                    plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{3}],'MarkerSize',markerSize,'LineWidth',lineWidth);
                end
            end
            axis off;
            fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_clusters'];
            print(gcf,'-dpng',[fname '.png']);
            if bPrintPdf
                printpdf([fname '.pdf']);
            end
        end
        
        if (bVisFinalGraph)
            clf;
            imagesc(img); axis equal; hold on;
            idxs = find(unLab(:,1) < 1000);
            lp_uniq = unique(unLab(idxs,2));
            for j = 1:length(lp_uniq)
                idxs = find(unLab(:,2) == lp_uniq(j));
                lp = lp_uniq(j);
                cb_cur = cb(idxs,:);
                
                if (lp <= 5)
                    cm = [colors{mod(lp,6)+1} markers{1}];
                elseif (lp > 5 && lp <= 11)
                    cm = [colors{mod(lp,6)+1} markers{2}];
                else
                    cm = [colors{mod(lp,6)+1} markers{3}];
                end
                c = colors{mod(lp,6)+1};
                
                %plot(cb_cur(:,1),cb_cur(:,2),cm,'MarkerSize',markerSize,'LineWidth',lineWidth);
                for n = 1:length(idxs)
                    for m = 1:length(idxs)
                        if (rand < 0.1)
                            plot([cb_cur(n,1) ; cb_cur(m,1)], ...
                                [cb_cur(n,2) ; cb_cur(m,2)], ...
                                [c '-'], 'linewidth', 1);
                        end
                    end
                end
                vis_parts(unLab, cb, cidxs, colors, markers, markerSize, lineWidth);
            end
            axis off;
            fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_graph'];
            if bPrintPdf
                printpdf([fname '.pdf']);
            else
                print(gcf,'-dpng',[fname '.png']);
            end
        end
        
        if (bVisSticks) %
            clf;
            imagesc(img); axis equal; hold on;
            idxs = find(unLab(:,1) < 1000);
            lc_uniq = unique(unLab(idxs,2));
            for j = 1:length(lc_uniq)
                lc = lc_uniq(j);
                idxsc = find(unLab(:,2) == lc);
                cc = colors{mod(lc,6)+1};
                lp_uniq = unique(unLab(idxsc,1));
                
                % DEBUG
                %lp_uniq = lp_uniq + 6;
                dlp = cidxs(1)-1;
                keypoints = cell(16,1);
                for i = 1:length(lp_uniq)
                    lp = lp_uniq(i);
                    if lp > 1000
                        continue;
                    end
                    idxsp = find(unLab(idxsc,1) == lp);
                    prob = unProb(idxsc(idxsp),lp+1);
                    w = prob;
                    w = w./sum(w);
                    
                    loc_refine = squeeze(locationRefine(idxsc(idxsp), lp+1, :));
                    if size(loc_refine, 2) == 1
                        loc_refine = loc_refine';
                    end
                    pos = sum((cb(idxsc(idxsp),:) + loc_refine).*[w w],1);
                    %pos = (unPos(detidxs,:)' + loc_refine')*w;

                    
                    keypoints{lp+dlp+1} = pos;
                end
                
                if (ismember(15,cidxs))
                    edges = [1 2; 2 3; 3 7; 4 7; 4 5; 5 6; 9 10; 10 11; 11 7; 12 7; 12 13; 13 14; 7 15; 15 8; 8 16];
                else
                    edges = [1 2; 2 3; 3 13; 4 13; 4 5; 5 6; 7 8; 8 9; 9 13; 10 13; 10 11; 11 12; 13 14];
                end
                %edges = [1 8; 1 4; 1 5; 2 3; 3 4; 4 8; 5 8; 5 6; 6 7; 8 9];
                for i = 1:size(edges,1)
                    pos1 = keypoints{edges(i,1)};
                    pos2 = keypoints{edges(i,2)};
                    if (~isempty(pos1) && ~isempty(pos2))
                        plot([pos1(1);pos2(1)],[pos1(2);pos2(2)],[cc '-'],'linewidth',lineWidth);
                    end
                end
                
                for i = 1:length(lp_uniq)
                    lp = lp_uniq(i);
                    if lp > 1000
                        continue;
                    end
                    pos = keypoints{lp+dlp+1};
                    cp = colors{mod(lp,6)+1};
                    plot(pos(:,1),pos(:,2),[cp 'o'],'MarkerSize',markerSize,'MarkerFaceColor',cp,'MarkerEdgeColor','k');
                end
                
            end
            axis off;
            if sorted
                %fname = [visDir '/imgidx_' padZeros(num2str(kk),4) '_' padZeros(num2str(imgidx),4) '_sticks'];
                fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_sticks'];
            else
                fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_sticks'];
            end
            if bPrintPdf
                printpdf([fname '.pdf']);
            else
                print(gcf,'-dpng',[fname '.png']);
            end
        end
        
        %{
        if (bVisSticks)
            clf;
            imagesc(img); axis equal; hold on;
            people = keypointsAll16(imgidx).det;
            for j = 1:length(people)
                parts = people(j);
                parts = parts{1};
                cc = colors{mod(j-1,6)+1};
                num_parts = length(parts);
                
                keypoints_src = cell(16,1);
                for i = 1:num_parts
                    pos = parts(i);
                    keypoints_src{i} = pos{1};
                end
                
                %keypointsAll(imgidx).det(1:6,1:2) = det(1:6,1:2);
                %keypointsAll(imgidx).det(9:10,1:2) = det(13:14,1:2);
                %keypointsAll(imgidx).det(7:14,1:2) = det(9:16,1:2);
                assoc = [1:6, 11:16, 9:10];
                keypoints = cell(16,1);
                for i = 1:14
                    keypoints{i} = keypoints_src{assoc(i)};
                end
                
                if (ismember(15,cidxs))
                    edges = [1 2; 2 3; 3 7; 4 7; 4 5; 5 6; 9 10; 10 11; 11 7; 12 7; 12 13; 13 14; 7 15; 15 8; 8 16];
                else
                    edges = [1 2; 2 3; 3 13; 4 13; 4 5; 5 6; 7 8; 8 9; 9 13; 10 13; 10 11; 11 12; 13 14];
                end
                %edges = [1 8; 1 4; 1 5; 2 3; 3 4; 4 8; 5 8; 5 6; 6 7; 8 9];
                for i = 1:size(edges,1)
                    pos1 = keypoints{edges(i,1)};
                    pos2 = keypoints{edges(i,2)};
                    if (~isempty(pos1) && ~isempty(pos2))
                        plot([pos1(1);pos2(1)],[pos1(2);pos2(2)],[cc '-'],'linewidth',lineWidth);
                    end
                end
                
                for i = 1:14
                    pos = keypoints{i};
                    cp = colors{mod(i-1,6)+1};
                    if ~isempty(pos)
                        plot(pos(:,1),pos(:,2),[cp 'o'],'MarkerSize',markerSize,'MarkerFaceColor',cp,'MarkerEdgeColor','k');
                    end
                end
                
            end
            axis off;
            fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_sticks_detroi'];
            if bPrintPdf
                printpdf([fname '.pdf']);
            else
                print(gcf,'-dpng',[fname '.png']);
            end
        end
        %}
        
    end
end

%fclose(fid);

end


function vis_parts(unLab, cb, cidxs, colors, markers, markerSize, lineWidth)
    for j = 1:size(unLab,1)
        lp = unLab(j,1);
        cb_cur = cb(j,:);
        if (lp < 1000)
            lp = cidxs(lp+1)-1;
            if (lp <= 5)
                st = [colors{mod(lp,6)+1} markers{1}];
            elseif (lp > 5 && lp <= 11)
                st = [colors{mod(lp,6)+1} markers{2}];
            else
                st = [colors{mod(lp,6)+1} markers{3}];
            end
        else
            st = 'kx';
        end
        plot(cb_cur(1),cb_cur(2),st,'MarkerSize',markerSize,'LineWidth',lineWidth);
    end
end
