function [keypointsAll, imgidxs_missing] = det2keypointsImgMulticut(expidx,parts,annolist_gt)

fprintf('det2keypointsImgMulticut()\n');

p = exp_params(expidx);

multicutDir = p.multicutDir;
keypointsAll = repmat(struct('imgname','','det',nan(16,3)), length(annolist_gt), 1);

nmissing = 0;
imgidxs_missing = [];
for imgidx = 1:length(annolist_gt)
    
    fprintf('.');
        
    keypointsAll(imgidx).imgname = annolist_gt(imgidx).image.name;

    finalname = [multicutDir '/prediction_' padZeros(num2str(imgidx),4)];
    %fname = [predDir '/imgidx_' padZeros(num2str(imgidx),4) '_cidx_' num2str(cidxs(1)) '_' num2str(cidxs(end))];
    try
        %load(fname,'unLab','unPos','unProb');
        load(finalname, 'detAll');
    catch
        for i = 1:length(p.pidxs)
            pidx = p.pidxs(i);
            jidx = parts(pidx+1).pos(1);
            keypointsAll(imgidx).det(jidx+1,:) = [inf inf -1];
        end
        nmissing = nmissing + 1;
        imgidxs_missing = [imgidxs_missing; imgidx];
        continue;
    end
    
    keypointsAll(imgidx).det(:,:) = detAll;

    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(keypointsAll));
    end
end
fprintf(' done\n');
fprintf('nmissing: %d\n',nmissing);

filename = fullfile(p.exp_dir, 'test', 'predictions_multicut');
fprintf('saving keypoints in %s\n', filename);
save(filename, 'keypointsAll');

end