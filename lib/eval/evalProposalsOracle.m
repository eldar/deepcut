function evalProposalsOracle(expidxs,bUseHeadSize,bSave)

fprintf('evalProposalsOracle()\n');

if (nargin < 2)
    bUseHeadSize = true;
end

if (nargin < 3)
    bSave = true;
end

if (bUseHeadSize)
%     range = 0:0.05:0.5;
    range = 0:0.01:0.5;
    prefix = 'pck-head-oracle-';
else
    range = 0:0.02:0.2;
    prefix = 'pck-torso-oracle-';
end

fontSize = 18;
figure(100); clf; hold on;
legendName = cell(0);
set(0,'DefaultAxesFontSize', fontSize)
set(0,'DefaultTextFontSize', fontSize)

[~,parts] = util_get_parts24;
nJoints = 14;
jidxsUpperBody = 7:12;

nDetPerPart = zeros(nJoints,1);

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = rcnn_exp_params(expidx);
    % load ground truth
    load(p.testGT);
    if (~exist('annolist','var'))
        annolist = single_person_annolist;
    end
    annolist_gt = annolist;
       
    path = fileparts(p.evalTest);
    fnameDist = [path '/distAll'];
    
    clear detAll; clear keypointsAll;
    
    nDetPerClass = round(p.nDetPerImg/length(p.pidxs));
    nDetPerPart = zeros(nJoints,1);

    try
        assert(false); % no load
        load(fnameDist,'distAll','accAll','pidxs','keypointsAll'); 
        assert(exist('keypointsAll','var') && length(pidxs) == length(p.pidxs) && ...
               sum(pidxs ~= p.pidxs) == 0 && size(accAll,2) == nJoints+2);
    catch
        assert(length(p.pidxs) == nJoints);
        % try to load keypoints
        if (exist([p.evalTest '.mat'],'file')>0)
            fprintf('load %s\n',p.evalTest);
            load([p.evalTest '.mat']);
        end
        
        % convert detections to keypoints
        if (~exist('keypointsAll','var'))
            keypointsAll = [];  

            for i = 1:length(p.pidxs)
            
                pidx = p.pidxs(i);
                % part is a joint
                assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
                jidx = parts(pidx+1).pos(1);
                
                fname = [p.evalTest '_cidx_' num2str(pidx)];
                fprintf('load %s\n',fname);
                try
                    load(fname, 'detAll');
                catch
                    try
                        fprintf('try load %s\n',p.evalTest);
                        load(p.evalTest, 'detAll');
                    catch
                        warning('file not found: %s\n',fname);
                        continue;
                    end
                end
                
                % init struct
                if (isempty(keypointsAll))
                    keypointsAll = repmat(struct('imgname','','det',nan(16,3)), length(detAll), 1);
                    for imgidx = 1:length(detAll)
                        keypointsAll(imgidx).imgname = detAll(imgidx).imgname;
                        keypointsAll(imgidx).det = cell(1);
                    end
                end
                
                for imgidx = 1:length(detAll)
                    assert(strcmp(keypointsAll(imgidx).imgname,detAll(imgidx).imgname)>0);
%                     det = detAll(imgidx).det;
                    if (isfield(detAll(imgidx),'det_nonms'))
                        det = detAll(imgidx).det_nonms;
                    else
                        det = detAll(imgidx).det;
                    end
                    nDet = min(size(det,1),nDetPerClass);
                    nDetPerPart(i) = nDetPerPart(i) + nDet;
                    x = mean(det(1:nDet,[1 3]),2);
                    y = mean(det(1:nDet,[2 4]),2);
                    keypointsAll(imgidx).det{jidx+1,:} = [x' y'];
                end
            end
        end
                
        distAll = nan(length(annolist_gt),nJoints);
        accAll = zeros(length(range),nJoints+2);
        
        bFixPart = false;
        if (isfield(p,'fix_proposals_part'))
            bFixPart = p.fix_proposals_part;
        end
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            % part is a joint
            assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
            jidx = parts(pidx+1).pos(1);
            
            % compute distance to the ground truth jidx
            distAll(:,i) = getNormGTJointDistOracle(keypointsAll,annolist_gt,jidx,bUseHeadSize,bFixPart);
        end
        
        for i = 1:length(p.pidxs)
            dist = distAll(:,i);
            % remove the cases without the ground truth
            dist(isnan(dist)) = [];
            % compute accuracy for each threshold
            for k = 1:numel(range)
                accAll(k,i) = 100*mean(dist<=range(k));
            end
        end
                
        % compute avg PCKh upper body
        dist = reshape(distAll(:,jidxsUpperBody),size(distAll,1)*length(jidxsUpperBody),1);
        dist(isnan(dist)) = [];
        for k = 1:numel(range)
            accAll(k,end-1) = 100*mean(dist<=range(k));
        end
        
        % compute avg PCKh full body
        dist = reshape(distAll,size(distAll,1)*size(distAll,2),1);
        dist(isnan(dist)) = [];
        for k = 1:numel(range)
            accAll(k,end) = 100*mean(dist<=range(k));
        end
        
        pidxs = p.pidxs;
        save(fnameDist,'distAll','accAll','pidxs','keypointsAll');
    end
    
%     if (bVis)
%         visDir = [p.expDir '/' p.shortName '/cachedir/test/vis'];
%         endpointsAll = keypoints2endpoints(keypointsAll);
%         isMatchAll = eval_match_parts_gt(endpointsAll, annolist_gt, 1.0, 2);
%         pcp = eval_plot_pcp(isMatchAll,1:10);
%         plot_sticks(endpointsAll, annolist_gt, visDir, isMatchAll);
%     end
    
    tableFilename = [p.latexDir '/' prefix 'expidx' num2str(expidx) '.tex'];
    [row, header] = genTable(accAll(end,:),p.name);
    fid = fopen(tableFilename,'wt');assert(fid ~= -1);
    fprintf(fid,'%s\n',row{1});fclose(fid);
    fid = fopen([p.latexDir '/' prefix 'header.tex'],'wt');assert(fid ~= -1);
    fprintf(fid,'%s\n',header);fclose(fid);
       
    auc = area_under_curve(scale01(range),accAll(:,end));
    plot(range,accAll(:,end),'color',p.colorName,'LineStyle','-','LineWidth',3);
    legendName{end+1} = sprintf('%d proposals/part, nms %1.2f, AUC: %1.1f%%', ceil(mean(nDetPerPart./length(annolist_gt))), p.nms_thresh, auc);
    
    fprintf('%s\n',legendName{end});
end

% legend(legendName,'Location','NorthWest');
legend(legendName,'Location','SouthEast');
set(gca,'YLim',[0 100]);

xlabel('Normalized distance');
ylabel('Detection rate, %');

if (bSave)
    print(gcf, '-dpng', [p.plotsDir '/' prefix 'expidx' num2str(expidx) '.png']);
    printpdf([p.plotsDir '/' prefix 'expidx' num2str(expidx) '.pdf']);
end

end