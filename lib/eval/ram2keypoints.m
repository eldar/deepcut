function ram2keypoints
    fname = '/BS/leonid-projects/work/experiments-rcnn/tompson14nips/pred_for_leonid/lsp_trained_lsp_ext/te_uv_pos.mat';
    load(fname,'pos_pred');
    keypointsAll = repmat(struct('det',nan(16,3),'imgname',''),size(pos_pred,3),1);
    
    lsp_pred = permute(pos_pred, [2 1 3]);
    lsp_pred(1,:,:) = lsp_pred(1,:,:) - 4;
    
    lab = cell(14,1);
    for i=1:14
        lab{i} = num2str(i);
    end
    figure(100);clf; imagesc(imread('/BS/leonid-people-3d/work/data/lsp_dataset/images/png/im1012.png'));
    hold on; axis equal;
    hold on; pp2 = squeeze(lsp_pred(:,:,12)');
    hold on; plot(double(pp2(:,1)),double(pp2(:,2)),'b*','MarkerSize',10); axis equal
    hold on; text(double(pp2(:,1)-10),double(pp2(:,2)),lab,'FontSize',24); axis equal
    
    for imgidx=1:size(pos_pred,3)
        keypointsAll(imgidx).det(1:6,1:2) = lsp_pred(1:2,1:6,imgidx)';
        keypointsAll(imgidx).det(9:10,1:2) = lsp_pred(1:2,13:14,imgidx)';
        keypointsAll(imgidx).det(11:16,1:2) = lsp_pred(1:2,7:12,imgidx)';
    end
    
    saveDir = fileparts(fname);
    save([saveDir '/keypointsAll'],'keypointsAll');
end