function vis_multicut(expidx, bRecompute, firstidx, nImgs, cidxs)

p = exp_params(expidx);
exp_dir = [p.expDir '/' p.shortName];
fprintf('exp_dir: %s\n',exp_dir);

resDir = [exp_dir '/multicut/'];
visDir = [exp_dir '/multicut/vis/'];

if (isfield(p,'testGTnopad'))
    load(p.testGTnopad,'annolist');
    bProject = true;
else
    load(p.testGT,'annolist');
    bProject = false;
end

if (nargin < 2)
    bRecompute = true;
end

if (nargin < 3)
    firstidx = 1;
end

if (nargin < 4)
    nImgs = length(annolist);
end

if (nargin < 5)
    cidxs = p.cidxs;
end

lastidx = firstidx + nImgs - 1;

colors = {'r','g','b','c','m','y'};
markers = {'+','o','s'}; %,'x','.','-','s','d'
scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4) scrsz(3)/2 scrsz(4)]);

for imgidx = firstidx:lastidx
    out_img_fname = [visDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_1_14' '.png'];
    if (exist(out_img_fname, 'file') == 2) && ~bRecompute
        continue;
    end
    
    try
        templ = [resDir '/imgidx_' padZeros(num2str(imgidx),4) '_*'];
        files = dir(templ);
        fname = fullfile(resDir, files(end).name);
        %fname = [resDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
        load(fname,'unLab','unPos');
        fprintf('imgidx: %d\n',imgidx);
        clf;
        subplot(2,1,1);
        imgname = annolist(imgidx).image.name;
        img = imread(imgname);
        imagesc(img); axis equal; hold on;
        
        keypoints.imgname = imgname;
        keypoints.det = unPos;

        if (bProject)
            keypoints = projectKeypoints(keypoints,fileparts(p.testGTnopad),fileparts(p.testGT));
        end
        
        cb = keypoints.det;
        
        for j = 1:size(unLab,1)
            lp = unLab(j,1);
            cb_cur = cb(j,:);
            if (lp < 1000)
                lp = cidxs(lp+1)-1;
                if (lp <= 5)
                    plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{1}],'MarkerSize',5);
                elseif (lp > 5 && lp <= 11)
                    plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{2}],'MarkerSize',5);
                else
                    plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{3}],'MarkerSize',5);
                end
            else
                plot(cb_cur(1),cb_cur(2),'kx','MarkerSize',5);
            end
        end
        axis off;
        
        subplot(2,1,2);
        imagesc(img); axis equal; hold on;
        idxs = find(unLab(:,1) < 1000);
        lp_uniq = unique(unLab(idxs,2));
        for j = 1:length(idxs)
            lp = find(lp_uniq == unLab(idxs(j),2))-1;
            cb_cur = cb(idxs(j),:);
            if (lp <= 5)
                plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{1}],'MarkerSize',5);
            elseif (lp > 5 && lp <= 11)
                plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{2}],'MarkerSize',5);
            else
                plot(cb_cur(1),cb_cur(2),[colors{mod(lp,6)+1} markers{3}],'MarkerSize',5);
            end
        end
        axis off;
        print(gcf,'-dpng',out_img_fname);
    catch
    end
end

end