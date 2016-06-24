function evalPCP(expidxs,evalidx)

fprintf('evalPCP()\n');
if (nargin < 2)
    evalidx = 1;
end

for expidx = expidxs
    fprintf('**********************************************************************************\n');
    % load experiment parameters
    p = rcnn_exp_params(expidx);
    % load ground truth
    load(p.testGT);
    if (~exist('annolist','var'))
        annolist = single_person_annolist;
    end
    annolist_gt = annolist%;(1:100);
    
    if (isfield(p,'nPartsEval'))
        nPartsEval = p.nPartsEval;
    else
        nPartsEval = 10;
    end
    
    try
        assert(false);
        load([fileparts(p.evalTest) '/endpointsAll'],'endpointsAll');
    catch
        if (exist([fileparts(p.evalTest) '/pred-pairwise'],'dir') && ~(isfield(p,'bp') && p.bp == true))
            endpointsAll = spatial2endpoints(expidx,annolist_gt,nPartsEval);
        else
            clear pidxs keypointsAll;
            fnameDist = [fileparts(p.evalTest) '/distAll'];
            try
                load(fnameDist,'pidxs','keypointsAll');
                assert(exist('keypointsAll','var') && length(pidxs) == length(p.pidxs) && ...
                    sum(pidxs ~= p.pidxs) == 0);
            catch
                warning('keypoints are not found, running evalPCK...');
                evalPCK(expidx);
                load(fnameDist,'pidxs','keypointsAll');
                assert(exist('keypointsAll','var') && length(pidxs) == length(p.pidxs) && ...
                    sum(pidxs ~= p.pidxs) == 0);
            end
            endpointsAll = keypoints2endpoints(keypointsAll);
            endpointsAll = endpointsAll(1:length(annolist_gt));
        end
        save([fileparts(p.evalTest) '/endpointsAll'],'endpointsAll');
    end
    
    matchPCP = eval_match_parts_gt(endpointsAll, annolist_gt, 1.0, evalidx, 0.5, nPartsEval);
    
    pcp = eval_plot_pcp(matchPCP,1:nPartsEval);
    tableFilename = [p.latexDir '/pcp-evalidx-' num2str(evalidx)  '-expidx' num2str(expidx) '.tex'];
    [row, header] = genTablePCP(pcp,p.name);
    fid = fopen(tableFilename,'wt');assert(fid ~= -1);
    fprintf(fid,'%s\n',row{1});fclose(fid);
%     fid = fopen([p.latexDir '/' prefix 'header.tex'],'wt');assert(fid ~= -1);
%     fprintf(fid,'%s\n',header{1});fprintf(fid,'%s\n',header{2});fclose(fid);
end
end